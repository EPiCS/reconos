/*
 *                                                        ____  _____
 *                            ________  _________  ____  / __ \/ ___/
 *                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
 *                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
 *                         /_/   \___/\___/\____/_/ /_/\____//____/
 *
 * ======================================================================
 *
 *   title:        Linux Driver - OSIF INTC (AXI FIFO)
 *
 *   project:      ReconOS
 *   author:       Andreas Agne, University of Paderborn
 *                 Daniel Borkmann, ETH Zürich
 *                 Sebastian Meisner, University of Paderborn
 *                 Christoph Rüthing, University of Paderborn
 *   description:  Driver for the OSIF interface. To speed up the FIFO
 *                 access, this driver now only includes the interrupt
 *                 handling, while the actual data access is done from
 *                 user space.
 *
 * ======================================================================
 */

#include "osif_intc.h"

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


struct osif_intc_dev {
	char name[25];
	unsigned int addr;
	int irq;

	void __iomem *mem;

	uint32_t *irq_reg;
	size_t irq_reg_count;
	uint32_t *irq_enable;

	wait_queue_head_t wait;
	spinlock_t lock;

	struct miscdevice mdev;
};


static struct osif_intc_dev osif_intc_dev;


// some low level functions

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

	dev->irq_reg[irq / 32] &= ~(0x1 << irq % 32);

	dev->irq_enable[irq / 32] |= 0x1 << irq % 32;
	osif_intc_write_irq_enable(dev);

	__printk(KERN_DEBUG "[reconos-osif-intc] ... enabling interrupts: %x\n", dev->irq_enable[0]);

	spin_unlock_irqrestore(&dev->lock, flags);
}

static inline void osif_intc_disable_interrupt(struct osif_intc_dev *dev,
                                               unsigned int irq) {
	unsigned long flags;

	spin_lock_irqsave(&dev->lock, flags);

	dev->irq_enable[irq / 32] &= ~(0x1 << irq % 32);
	osif_intc_write_irq_enable(dev);

	spin_unlock_irqrestore(&dev->lock, flags);
}

static inline int osif_intc_get_irq(struct osif_intc_dev *dev,
                                    unsigned int irq) {
	return (dev->irq_reg[irq / 32] >> irq % 32) & 0x1;
}


// intc file operations

static int osif_intc_open(struct inode *inode, struct file *filp) {
	filp->private_data = &osif_intc_dev;

	return 0;
}

static long osif_intc_ioctl(struct file *filp, unsigned int cmd,
                               unsigned long arg) {
	struct osif_intc_dev *dev = filp->private_data;

	unsigned int index;

	index = copy_from_user(&index, (unsigned int *)arg, sizeof(unsigned int));
	if (index > NUM_HWTS) {
		__printk(KERN_WARNING "[reconos-osif-intc] "
		                      "index out of range, aborting wait ...\n");

		return 0;
	}

	switch (cmd) {
		case RECONOS_OSIF_INTC_WAIT:
			osif_intc_enable_interrupt(dev, index);

			// wait for irq_reg becoming (like in osif_intc_get_irq)
			//if (wait_event_interruptible(dev->wait, (dev->irq_reg[index / 32] >> index % 32) & 0x1) < 0) {
			//	__printk(KERN_INFO "[reconos-osif-intc] "
			//	                   "interrupted in waiting, aborting ...\n");

			//	osif_intc_disable_interrupt(dev, index);
			//}
			break;

		default:
			return -EINVAL;
	}

	return 0;
}

static struct file_operations osif_intc_fops = {
	.owner          = THIS_MODULE,
	.open           = osif_intc_open,
	.unlocked_ioctl = osif_intc_ioctl,
};


// interrupt controller functions

static irqreturn_t osif_intc_interrupt(int irq, void *data) {
	int i;
	struct osif_intc_dev *dev = data;

	// read irq-registers and mask interrupts
	for (i = 0; i < dev->irq_reg_count; i++) {
		dev->irq_reg[i] = ioread32(dev->mem + i * 4) & dev->irq_enable[i];
	}

	__printk(KERN_DEBUG "[reconos-osif-intc] "
	                    "... osif interrupt: 0x%x with mask 0x%x\n", dev->irq_reg[0], dev->irq_enable[0]);

	// disabling all triggered interrupts
	for (i = 0; i < dev->irq_reg_count; i++) {
		dev->irq_enable[i] &= ~dev->irq_reg[i];
	}
	osif_intc_write_irq_enable(dev);

	wake_up_interruptible(&dev->wait);

	return IRQ_HANDLED;
}


// external init and exit functions

int osif_intc_init() {
	struct osif_intc_dev *dev = &osif_intc_dev;

	// set some general information of intc
	strncpy(dev->name, "reconos-osif-intc", 25);
	dev->irq = OSIF_INTC_IRQ;
	dev->addr = OSIF_INTC_BASE_ADDR;
	dev->irq_reg_count = NUM_HWTS / 32 + 1;

	init_waitqueue_head(&dev->wait);
	spin_lock_init(&dev->lock);


	// allocating interrupt-register
	dev->irq_reg = kcalloc(dev->irq_reg_count, sizeof(uint32_t), GFP_KERNEL);
	if (!dev->irq_reg) {
		__printk(KERN_WARNING "[reconos-osif-intc] "
		                      "cannot allocate irq-memory\n");
		goto irqreg_failed;
	}

	dev->irq_enable = kcalloc(dev->irq_reg_count, sizeof(uint32_t), GFP_KERNEL);
	if (!dev->irq_enable) {
		__printk(KERN_WARNING "[reconos-osif-intc] "
		                      "cannot allocate irq-enable\n");
		goto irqenable_failed;
	}


	// allocation io memory to read intc registers
	if (!request_mem_region(dev->addr, OSIF_INTC_MEM_SIZE, dev->name)) {
		__printk(KERN_WARNING "[reconos-osif-intc] "
		                      "memory region busy\n");
		goto req_failed;
	}

	dev->mem = ioremap(dev->addr, OSIF_INTC_MEM_SIZE);
	if(!dev->mem) {
		__printk(KERN_WARNING "[reconos-osif-intc] "
		                      "ioremap failed\n");
		goto map_failed;
	}


	// disable all interrupts to avoid useless interrupts
	osif_intc_write_irq_enable(dev);


	// requesting interrupt
	if(request_irq(dev->irq, osif_intc_interrupt, 0, "reconos-osif-intc", dev)) {
		__printk(KERN_WARNING "[reconos-osif-intc] "
		                      "can't get irq\n");
		goto irq_failed;
	}

	// registering misc device
	dev->mdev.minor = MISC_DYNAMIC_MINOR;
	dev->mdev.fops = &osif_intc_fops;
	dev->mdev.name = dev->name;

	if (misc_register(&dev->mdev) < 0) {
		__printk(KERN_WARNING "[reconos-osif-intc] "
		                      "error while registering misc-device\n");

		goto reg_failed;
	}


	__printk(KERN_INFO "[reconos-osif-intc] "
	                   "registered interrupt controller\n");

	goto out;

reg_failed:
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

int osif_intc_exit() {
	struct osif_intc_dev *dev = &osif_intc_dev;

	__printk(KERN_INFO "[reconos-osif-intc] "
	                   "removing driver ...\n");

	misc_deregister(&dev->mdev);

	free_irq(dev->irq, dev);

	iounmap(dev->mem);
	release_mem_region(dev->addr, OSIF_INTC_MEM_SIZE);

	kfree(dev->irq_enable);
	kfree(dev->irq_reg);

	return 0;
}
