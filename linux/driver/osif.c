/*
 *                                                        ____  _____
 *                            ________  _________  ____  / __ \/ ___/
 *                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
 *                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
 *                         /_/   \___/\___/\____/_/ /_/\____//____/
 *
 * ======================================================================
 *
 *   title:        Linux Driver - OSIF (AXI FIFO)
 *
 *   project:      ReconOS
 *   author:       Andreas Agne, University of Paderborn
 *                 Daniel Borkmann, ETH Zürich
 *                 Sebastian Meisner, University of Paderborn
 *                 Christoph Rüthing, University of Paderborn
 *   description:  Driver for the OSIF interface used to communicate to
 *                 the hardware-threads (successor of fsl_driver). It
 *                 contains the drivers for the AXI-FIFO and the interrupt
 *                 controller.
 *
 * ======================================================================
 */

#include "osif.h"

#include <linux/wait.h>
#include <linux/sched.h>
#include <linux/interrupt.h>
#include <linux/slab.h>
#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/ioport.h>
#include <asm/io.h>
#include <asm/uaccess.h>
#include <linux/spinlock.h>

// these ones could be made accessible by the user via module_param
#define OSIF_INTC_BASE_ADDR  0x7B400000
#define OSIF_INTC_MEM_SIZE   0x10000

#ifdef RECONOS_ARCH_zynq
#define OSIF_INTC_IRQ        90
#endif

#ifdef RECONOS_ARCH_microblaze
#define OSIF_INTC_IRQ        4
#endif

#define OSIF_FIFO_BASE_ADDR       0x75A00000
#define OSIF_FIFO_MEM_SIZE        0x10
#define OSIF_FIFO_RECV_REG        0x0
#define OSIF_FIFO_SEND_REG        0x4
#define OSIF_FIFO_RECV_STATUS_REG 0x8
#define OSIF_FIFO_SEND_STATUS_REG 0xC

#define OSIF_FIFO_RECV_STATUS_EMPTY_MASK 0x1 << 31
#define OSIF_FIFO_SEND_STATUS_FULL_MASK  0x1 << 31

#define OSIF_FIFO_RECV_STATUS_FILL_MASK 0xFFFF
#define OSIF_FIFO_SEND_STATUS_REM_MASK  0xFFFF


struct osif_fifo_dev {
	unsigned int index;
	char name[25];
	unsigned int addr;

	void __iomem *mem;
	wait_queue_head_t wait;
	struct miscdevice mdev;
	struct osif_intc_dev *irq_dev;
	unsigned int fifo_fill, fifo_rem;
};

struct osif_intc_dev {
	char name[25];
	unsigned int addr;
	int irq;

	void __iomem *mem;
	struct osif_fifo_dev *fifo;

	uint32_t *irq_reg;
	size_t irq_reg_count;
	uint32_t *irq_enable;

	unsigned int irq_enable_count;

	spinlock_t lock;
};


static struct osif_fifo_dev *osif_fifo_dev;
static struct osif_intc_dev osif_intc_dev;


// some low level functions

static int osif_fifo_hw2sw_fill(struct osif_fifo_dev *dev) {
	unsigned int status_reg;

	// status register contains empty bit at msb
	// if not set, the 16 lsbs contain number of elements
	status_reg = ioread32(dev->mem + OSIF_FIFO_RECV_STATUS_REG);
	if (status_reg & OSIF_FIFO_RECV_STATUS_EMPTY_MASK)
		return 0;
	else
		return (status_reg & OSIF_FIFO_RECV_STATUS_FILL_MASK) + 1;
}

static int osif_fifo_sw2hw_rem(struct osif_fifo_dev *dev) {
	unsigned int status_reg;

	// status register contains full bit at msb
	// it not set, the 16 lsbs contain number of free elements
	status_reg = ioread32(dev->mem + OSIF_FIFO_SEND_STATUS_REG);
	if (status_reg & OSIF_FIFO_SEND_STATUS_FULL_MASK)
		return 0;
	else
		return (status_reg & OSIF_FIFO_SEND_STATUS_REM_MASK) + 1;
}

static inline uint32_t osif_fifo_hw2sw_read(struct osif_fifo_dev *dev) {
	return ioread32(dev->mem + OSIF_FIFO_RECV_REG);
}

static inline void osif_fifo_sw2hw_write(struct osif_fifo_dev *dev,
                                         uint32_t data) {
	iowrite32(data, dev->mem + OSIF_FIFO_SEND_REG);
}

static inline void osif_intc_write_irq_enable(struct osif_intc_dev *dev) {
	int i;

	//TODO It would be nice only to write the changed registers but its
	//     not possible to figure out the changes
	for (i = 0; i < dev->irq_reg_count; i++) {
		iowrite32(dev->irq_enable[i], dev->mem + i * 4);
	}
}


// functions to control irqs

static inline void osif_intc_enable_interrupt(struct osif_intc_dev *dev,
                                              unsigned int irq) {
	unsigned long flags;

	spin_lock_irqsave(&dev->lock, flags);

	dev->irq_enable[irq / 32] |= 0x1 << irq % 32;
	osif_intc_write_irq_enable(dev);

	dev->irq_enable_count++;

	__printk(KERN_DEBUG "[reconos-osif] ... enabling interrupts: %x\n", dev->irq_enable[0]);

	spin_unlock_irqrestore(&dev->lock, flags);
}

static inline void osif_intc_disable_interrupt(struct osif_intc_dev *dev,
                                               unsigned int irq) {
	unsigned long flags;

	spin_lock_irqsave(&dev->lock, flags);

	dev->irq_enable[irq / 32] &= ~(0x1 << irq % 32);
	osif_intc_write_irq_enable(dev);

	dev->irq_enable_count--;

	spin_unlock_irqrestore(&dev->lock, flags);
}

static inline int osif_intc_get_irq(struct osif_intc_dev *dev,
                                    unsigned int irq) {
	return (dev->irq_reg[irq / 32] >> irq % 32) & 0x1;
}


// fifo file operations

static int osif_fifo_open(struct inode *inode, struct file *filp) {
	int i, minor;

	// find out fifo_dev based on the minor numbers
	minor = iminor(inode);
	for (i = 0; i < NUM_HWTS; i++) {
		if (osif_fifo_dev[i].mdev.minor == minor) {
			filp->private_data = &osif_fifo_dev[i];
			break;
		}
	}

	return 0;
}

static ssize_t osif_fifo_read(struct file *filp, char __user *buf,
                              size_t count, loff_t *pos) {
	int word_count, i;
	uint32_t data;
	struct osif_fifo_dev *dev = filp->private_data;

	// only entire words can be read
	if (count % sizeof(uint32_t) != 0 || !dev) {
	        __printk(KERN_INFO "[reconos-osif] "
	                           "wrong read count: %d\n",
	                           count);
		return -EINVAL;
	}

	// if no words requested we are done
	word_count = count / sizeof(uint32_t);
	if (word_count == 0)
		return 0;

	// read data
	dev->fifo_fill = osif_fifo_hw2sw_fill(dev);
	i = 0;

	__printk(KERN_DEBUG "[reconos-osif] ... %s %d word in fifo and trying to read %d words\n", dev->name, dev->fifo_fill, word_count);

	while (i < word_count) {
		if (dev->fifo_fill == 0) {
			__printk(KERN_DEBUG "[reconos-osif] ... osif empty, enabling interrupt index %d\n", dev->index);

			osif_intc_enable_interrupt(dev->irq_dev, dev->index);
			if (wait_event_interruptible(dev->wait, dev->fifo_fill > 0) < 0) {
				__printk(KERN_INFO "[reconos-osif] "
				                   "interrupted in read, aborting ...\n");

				osif_intc_disable_interrupt(dev->irq_dev, dev->index);

				return i * sizeof(uint32_t);
			};
		}

		if (dev->fifo_fill > 0) {
			data = osif_fifo_hw2sw_read(dev);
			if (copy_to_user(buf + sizeof(uint32_t) * i, &data, sizeof(uint32_t)))
				return -EFAULT;

			dev->fifo_fill--;
			i++;
		}
	}

	__printk(KERN_DEBUG "[reconos-osif] ... %s finished reading: last word: %x\n", dev->name, data);
	return count;
}

static ssize_t osif_fifo_write(struct file *filp, const char __user *buf,
                               size_t count, loff_t *pos) {
	int word_count, i;
	uint32_t data;
	struct osif_fifo_dev *dev = filp->private_data;

	// only entire words can be written
	if (count % sizeof(uint32_t) != 0 || !dev) {
	        __printk(KERN_INFO "[reconos-osif] "
	                           "wrong write count: %d\n",
	                           count);
		return -EINVAL;
	}

	// if no words to send we are done
	word_count = count / sizeof(uint32_t);
	if (word_count == 0)
		return 0;

	// send data
	dev->fifo_rem = osif_fifo_sw2hw_rem(dev);
	i = 0;

	__printk(KERN_DEBUG "[reconos-osif] ... trying to write %d words into fifo (%d free)\n", word_count, dev->fifo_rem);

	while (i < word_count) {
		if (dev->fifo_rem > 0) {
			if (copy_from_user(&data, buf + sizeof(uint32_t) * i, sizeof(uint32_t)))
				return -EFAULT;
			osif_fifo_sw2hw_write(dev, data);

			dev->fifo_rem--;
			i++;
		} else {
			// this is busy wait, but since the fifo should not become full
			// this should not be a drawback
			dev->fifo_rem = osif_fifo_sw2hw_rem(dev);
		}
	}

	__printk(KERN_DEBUG "[reconos-osif] ... after write %d free\n", osif_fifo_sw2hw_rem(dev));
	return count;
}

static struct file_operations osif_fops = {
	.owner  = THIS_MODULE,
	.read   = osif_fifo_read,
	.write  = osif_fifo_write,
	.open   = osif_fifo_open,
};

static int osif_fifo_init(struct osif_fifo_dev *dev) {
	// set some general information
	snprintf(dev->name, 25, "reconos-osif-%d", dev->index);
	dev->fifo_fill = 0;
	dev->fifo_rem = 0;
	dev->irq_dev = &osif_intc_dev;
	dev->addr = OSIF_FIFO_BASE_ADDR + dev->index * OSIF_FIFO_MEM_SIZE;


	// allocation io memory to read the fifo registers
	if (!request_mem_region(dev->addr, OSIF_FIFO_MEM_SIZE, dev->name)) {
		__printk(KERN_WARNING "[reconos-osif] fifo %d - "
		                      "memory region busy\n",
		                      dev->index);
		goto req_failed;
	}

	dev->mem = ioremap(dev->addr, OSIF_FIFO_MEM_SIZE);
	if (!dev->mem) {
		__printk(KERN_WARNING "[reconos-osif] fifo %d - "
		                      "ioremap failed\n",
		                      dev->index);
		goto map_failed;
	}


	// initializing misc-device structure
	dev->mdev.minor = MISC_DYNAMIC_MINOR;
	dev->mdev.fops = &osif_fops;
	dev->mdev.name = dev->name;

	if(misc_register(&dev->mdev) < 0) {
		__printk(KERN_WARNING "[reconos-osif] fifo %d - "
		                      "error while registering misc-device\n",
		                      dev->index);
		goto reg_failed;
	}


	// initialize remaining struct-parts
	init_waitqueue_head(&dev->wait);
	__printk(KERN_INFO "[reconos-osif] fifo %d - "
	                   "registered fifo at 10:%d\n",
	                   dev->index, dev->mdev.minor);

	goto out;

reg_failed:
	iounmap(dev->mem);

map_failed:
	release_mem_region(dev->addr, OSIF_FIFO_MEM_SIZE);

req_failed:
	return -1;

out:
	return 0;
}

static int osif_fifo_exit(struct osif_fifo_dev *dev) {
	iounmap(dev->mem);
	release_mem_region(dev->addr, OSIF_FIFO_MEM_SIZE);

	misc_deregister(&dev->mdev);

	return 0;
}


// interrupt controller functions

static irqreturn_t osif_intc_interrupt(int irq, void *data) {
	int i, bit, index;
	struct osif_intc_dev *dev = data;

	// read irq-registers and mask interrupts
	for (i = 0; i < dev->irq_reg_count; i++) {
		dev->irq_reg[i] = ioread32(dev->mem + i * 4) & dev->irq_enable[i];
	}

	__printk(KERN_DEBUG "[reconos-osif] ... osif interrupt: %x with mask %x\n", dev->irq_reg[0], dev->irq_enable[0]);

	// wakeup appropriate tasks
	// this might be not so efficient but there is no other way
	// than to checkout all interrupt lines
	for (i = 0; i < dev->irq_reg_count; i++) {
		for (bit = 0; bit < 32; bit++) {
			__printk(KERN_DEBUG "[reconos-osif] ... checking bit %i: %x\n", bit, dev->irq_reg[i] >> bit);
			if ((dev->irq_reg[i] >> bit) & 0x1) {
				index = i * 32 + bit;

				__printk(KERN_DEBUG "[reconos-osif] ... waking up osif %i\n", index);

				osif_intc_disable_interrupt(dev, index);

				dev->fifo[index].fifo_fill = osif_fifo_hw2sw_fill(&dev->fifo[index]);
				wake_up_interruptible(&dev->fifo[index].wait);
			}
		}
	}

	return IRQ_HANDLED;
}

static int osif_intc_init(struct osif_intc_dev *dev) {
	// set some general information of intc
	strncpy(dev->name, "reconos-osif-intc", 25);
	dev->irq = OSIF_INTC_IRQ;
	dev->addr = OSIF_INTC_BASE_ADDR;
	dev->fifo = osif_fifo_dev;
	dev->irq_reg_count = NUM_HWTS / 32 + 1;
	dev->irq_enable_count = NUM_HWTS;

	spin_lock_init(&dev->lock);


	// allocating interrupt-register
	dev->irq_reg = kcalloc(dev->irq_reg_count, sizeof(uint32_t), GFP_KERNEL);
	if (!dev->irq_reg) {
		__printk(KERN_WARNING "[reconos-osif] intc - "
		                      "cannot allocate irq-memory\n");
		goto irqreg_failed;
	}

	dev->irq_enable = kcalloc(dev->irq_reg_count, sizeof(uint32_t), GFP_KERNEL);
	if (!dev->irq_enable) {
		__printk(KERN_WARNING "[reconos-osif] intc - "
		                      "cannot allocate irq-enable\n");
		goto irqenable_failed;
	}


	// allocation io memory to read intc registers
	if (!request_mem_region(dev->addr, OSIF_INTC_MEM_SIZE, dev->name)) {
		__printk(KERN_WARNING "[reconos-osif] intc - "
		                      "memory region busy\n");
		goto req_failed;
	}

	dev->mem = ioremap(dev->addr, OSIF_INTC_MEM_SIZE);
	if(!dev->mem) {
		__printk(KERN_WARNING "[reconos-osif] intc - "
		                      "ioremap failed\n");
		goto map_failed;
	}


	// disable all interrupts to avoid useless interrupts
	osif_intc_write_irq_enable(dev);


	// requesting interrupt
	if(request_irq(dev->irq, osif_intc_interrupt, 0, "reconos-osif", dev)) {
		__printk(KERN_WARNING "[reconos-osif] intc - "
		                      "can't get irq\n");
		goto irq_failed;
	}

	__printk(KERN_INFO "[reconos-osif] intc - "
	                   "registered interrupt controller\n");

	goto out;

irq_failed:
	free_irq(dev->irq, dev);
	iounmap(dev->mem);

map_failed:
	release_mem_region(dev->addr, OSIF_INTC_MEM_SIZE);

req_failed:
	kfree(dev->irq_enable);

irqenable_failed:
	kfree(dev->irq_reg);

irqreg_failed:
	return -1;

out:
	return 0;
}

static int osif_intc_exit(struct osif_intc_dev *dev) {
	free_irq(dev->irq, dev);

	iounmap(dev->mem);
	release_mem_region(dev->addr, OSIF_INTC_MEM_SIZE);

	kfree(dev->irq_enable);
	kfree(dev->irq_reg);

	return 0;
}


// external init and exit function

int osif_init() {
	int i, err;

	__printk(KERN_INFO "[reconos-osif] "
	                   "initializing driver ...\n");

	osif_fifo_dev = kcalloc(NUM_HWTS, sizeof(struct osif_fifo_dev), GFP_KERNEL);
	if (!osif_fifo_dev) {
		__printk(KERN_WARNING "[reconos-osif] "
		                      "can't allocate fifo_dev\n");
		goto osif_fifo_dev_failed;
	}

	if (osif_intc_init(&osif_intc_dev) < 0)
		goto intc_failed;

	for (i = 0; i < NUM_HWTS; i++) {
		osif_fifo_dev[i].index = i;
		if (osif_fifo_init(&osif_fifo_dev[i]) < 0)
			goto fifo_failed;
	}

	__printk(KERN_WARNING "[reconos-osif] "
	                      "driver initialized successfully\n");

	goto out;

fifo_failed:
	osif_intc_exit(&osif_intc_dev);
	err = i;
	for (i = 0; i < err; i++)
		osif_fifo_exit(&osif_fifo_dev[i]);

intc_failed:
	kfree(osif_fifo_dev);

osif_fifo_dev_failed:
	__printk(KERN_WARNING "[reconos-osif] "
	                      "failed to initialize driver\n");
	return -1;

out:
	return 0;
}

int osif_exit() {
	int i;

	__printk(KERN_INFO "[reconos-osif] "
	                   "removing driver ...\n");

	osif_intc_exit(&osif_intc_dev);

	for (i = 0; i < NUM_HWTS; i++) {
		osif_fifo_exit(&osif_fifo_dev[i]);
	}
	kfree(osif_fifo_dev);

	return 0;
}
