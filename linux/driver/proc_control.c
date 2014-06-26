/*
 *                                                        ____  _____
 *                            ________  _________  ____  / __ \/ ___/
 *                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
 *                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
 *                         /_/   \___/\___/\____/_/ /_/\____//____/
 *
 * ======================================================================
 *
 *   title:        Linux Driver - ReconOS - Proc control
 *
 *   project:      ReconOS
 *   author:       Christoph Rüthing, University of Paderborn
 *   description:  Driver for the proc control of the ReconOS system. It
 *                 allows to control the dirfferent components, reset the
 *                 entire system and read out some information like the
 *                 number of OSIFs, ...
 *
 * ======================================================================
 */

#include "proc_control.h"

#include <linux/wait.h>
#include <linux/sched.h>
#include <linux/interrupt.h>
#include <linux/slab.h>
#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/ioport.h>
#include <linux/spinlock.h>
#include <asm/io.h>
#include <asm/uaccess.h>
#include <asm/pgtable.h>


/* == General definitions ============================================== */

/*
 * Definition of memory
 *
 *   base_addr - base address as configured in the hardware design
 *   mem_siz   - size of the memory region available
 */
#define BASE_ADDR 0x6FE00000
#define MEM_SIZE  0x10000

/*
 * Definition of interrupt numbers (architecture specific)
 *
 *   irq - interrupt number to which the proc control is connected
 */
#if defined(RECONOS_ARCH_zynq)
#define IRQ       91
#elif defined(RECONOS_ARCH_microblaze)
#define IRQ       5
#endif

/*
 * Register definitions as offset from base address
 *
 *   num_hwts_reg        - number of hardware threads instanciated
 *   pgd_addr_reg        - physical address of page global directory
 *   page_fault_addr_reg - addres whicch caused a page fault
 *   tlb_hits_reg        - number of tlb hits occured since reset
 *   tlb_misses_reg      - number of tlb misses occured since reset
 *   sys_reset_reg       - write to initiate system reset
 *   hwt_reset_reg       - write to set reset of hardware threads
 *   hwt_signal_reg     - write to set signal of hardware threads
 */
#define NUM_HWTS_REG           0x00
#define PGD_ADDR_REG           0x04
#define PAGE_FAULT_ADDR_REG    0x08
#define TLB_HITS_REG           0x0C
#define TLB_MISSES_REG         0x10
#define SYS_RESET_REG          0x14
#define HWT_RESET_REG(hwt)     (0x18 + HWT_REG_OFFSET(hwt) * 4)
#define HWT_SIGNAL_REG(hwt)    (HWT_RESET_REG(hwt) + DYNAMIC_REG_COUNT * 4)

/*
 * Struct representing the proc control device
 *
 *   name            - name to identify the device driver
 *   base_addr       - base addr (should always be BASE_ADDR)
 *   mem_size        - memory size (should always be MEM_SIZE)
 *   irq             - irq number (should always be IRQ)
 *
 *   mem             - pointer to the io memory
 *   wait            - wait queue for interrupts
 *   page_fault      - indication if page fault occured
 *   page_fault_addr - address which caused the page fault
 *   hwt_resets      - array representing the reset signals
 *   hwt_signals     - array representing the signals
 *
 *   mdev            - misc device data structure
 *
 *   lock            - spinlock for synchronization
 */
struct proc_control_dev {
	char name[25];
	uint32_t base_addr;
	int mem_size;
	int irq;

	void __iomem *mem;
	wait_queue_head_t wait;
	int page_fault;
	uint32_t page_fault_addr;
	uint32_t *hwt_resets;
	uint32_t *hwt_signals;

	struct miscdevice mdev;

	spinlock_t lock;
};

static struct proc_control_dev proc_control;


/* == Low level functions ============================================== */

/*
 * Reads a register
 *
 *   dev - pointer to the proc control struct
 *   reg - offset from base address to read
 *
 *   @returns read data
 */
static inline uint32_t read_reg(struct proc_control_dev *dev,
                         unsigned int reg) {
	return ioread32(dev->mem + reg);
}

/*
 * Writes a register
 *
 *   dev  - pointer to the proc control struct
 *   reg  - offset from base address to write
 *   data - data to write
 */
static inline void write_reg(struct proc_control_dev *dev,
                      unsigned int reg, uint32_t data) {
	iowrite32(data, dev->mem + reg);
}

/*
 * Flushing of the systems caches
 *
 *   no parameters
 */
#if defined(RECONOS_ARCH_zynq)
static void flush_cache(void) {
}
#elif defined(RECONOS_ARCH_microblaze)
static void flush_cache(void) {
	int i;
	int baseaddr, bytesize, linelen;

	baseaddr = 0x20000000;   // C_DCACHE_BASEADDR
	bytesize = 64 * 1024;    // C_DCACHE_BYTE_SIZE
	linelen = 4 * 4;         // C_DCACHE_LINE_LEN * 4

	for (i = 0; i < bytesize; i += linelen) {
		asm volatile ("wdc.flush %0, %1;" :: "d" (baseaddr), "d" (i));
	}
}
#endif


/* == File operations ================================================== */

/*
 * Function called when opening the device
 *
 *    @see kernel documentation
 */
static int proc_control_open(struct inode *inode, struct file *filp) {
	filp->private_data = &proc_control;

	return 0;
}

/*
 * Function called when issuing an ioctl
 *
 * @see kernel documentation
 */
static long proc_control_ioctl(struct file *filp, unsigned int cmd,
                               unsigned long arg) {
	struct proc_control_dev *dev;
	uint32_t data;
	int i, hwt;
	unsigned long ret;

	dev = (struct proc_control_dev *)filp->private_data;

	switch (cmd) {
		case RECONOS_PROC_CONTROL_GET_NUM_HWTS:
			data = NUM_HWTS;
			ret = copy_to_user((int *)arg, &data, sizeof(int));
			break;

		case RECONOS_PROC_CONTROL_GET_TLB_HITS:
			data = read_reg(dev, TLB_HITS_REG);
			ret = copy_to_user((int *)arg, &data, sizeof(int));
			break;

		case RECONOS_PROC_CONTROL_GET_TLB_MISSES:
			data = read_reg(dev, TLB_MISSES_REG);
			ret = copy_to_user((int *)arg, &data, sizeof(int));
			break;

		case RECONOS_PROC_CONTROL_GET_FAULT_ADDR:
			dev->page_fault = 0;
			enable_irq(dev->irq);

			do {
				if (wait_event_interruptible(dev->wait, dev->page_fault) < 0) {
					__printk(KERN_DEBUG "[reconos-proc-control] "
					                    "interrupted, aborting ...\n");
					disable_irq(dev->irq);
					dev->page_fault = 0;
					return -1;
				}
			} while (!dev->page_fault);

			disable_irq(dev->irq);
			ret = copy_to_user((uint32_t *)arg, &dev->page_fault_addr, sizeof(uint32_t));
			break;

		case RECONOS_PROC_CONTROL_CLEAR_PAGE_FAULT:
			dev->page_fault = 0;
			write_reg(dev, PAGE_FAULT_ADDR_REG, 0);
			break;

		case RECONOS_PROC_CONTROL_SET_PGD_ADDR:
			data = (uint32_t) virt_to_phys(current->mm->pgd);
			write_reg(dev, PGD_ADDR_REG, data);
			break;

		case RECONOS_PROC_CONTROL_SYS_RESET:
			spin_lock(&dev->lock);

			for (i = 0; i < DYNAMIC_REG_COUNT; i++) {
				dev->hwt_resets[i] = 0xFFFFFFFF;
				dev->hwt_signals[i] = 0x00000000;
			}
			write_reg(dev, SYS_RESET_REG, 0);

			spin_unlock(&dev->lock);
			break;

		case RECONOS_PROC_CONTROL_SET_HWT_RESET:
			ret = copy_from_user(&hwt, (int *)arg, sizeof(int));

			spin_lock(&dev->lock);

			if (hwt >= 0 && hwt < NUM_HWTS) {
				dev->hwt_resets[hwt / 32] |= 0x1 << hwt % 32;
				data = dev->hwt_resets[hwt / 32];

				write_reg(dev, HWT_RESET_REG(hwt), data);
			}

			spin_unlock(&dev->lock);
			break;

		case RECONOS_PROC_CONTROL_CLEAR_HWT_RESET:
			ret = copy_from_user(&hwt, (int *) arg, sizeof(int));

			spin_lock(&dev->lock);

			if (hwt >= 0 && hwt < NUM_HWTS) {
				dev->hwt_resets[hwt / 32] &= ~(0x1 << hwt % 32);
				data = dev->hwt_resets[hwt / 32];

				write_reg(dev, HWT_RESET_REG(hwt), data);
			}

			spin_unlock(&dev->lock);
			break;

		case RECONOS_PROC_CONTROL_SET_HWT_SIGNAL:
			ret = copy_from_user(&hwt, (int *)arg, sizeof(int));

			spin_lock(&dev->lock);

			if (hwt >= 0 && hwt < NUM_HWTS) {
				dev->hwt_signals[hwt / 32] |= 0x1 << hwt % 32;
				data = dev->hwt_signals[hwt / 32];

				write_reg(dev, HWT_SIGNAL_REG(hwt), data);
			}

			spin_unlock(&dev->lock);
			break;

		case RECONOS_PROC_CONTROL_CLEAR_HWT_SIGNAL:
			ret = copy_from_user(&hwt, (int *) arg, sizeof(int));

			spin_lock(&dev->lock);

			if (hwt >= 0 && hwt < NUM_HWTS) {
				dev->hwt_signals[hwt / 32] &= ~(0x1 << hwt % 32);
				data = dev->hwt_signals[hwt / 32];

				write_reg(dev, HWT_SIGNAL_REG(hwt), data);
			}

			spin_unlock(&dev->lock);
			break;

		case RECONOS_PROC_CONTROL_CACHE_FLUSH:
			flush_cache();
			break;

		default:
			return -EINVAL;
	}

	return 0;
}

/*
 * Struct for file operations to register driver
 *
 *    @see kernel documentation
 */
struct file_operations proc_control_fops = {
	.owner          = THIS_MODULE,
	.open           = proc_control_open,
	.unlocked_ioctl = proc_control_ioctl,
};


/* == Interrupt handling =============================================== */

/*
 * Interrupt handler for handling page faults
 *
 *   @see kernel documentation
 */
static irqreturn_t interrupt(int irq, void *data) {
	struct proc_control_dev *dev = data;

	__printk(KERN_INFO "[reconos-proc-control] "
	                   "page fault occured\n");

	dev->page_fault_addr = read_reg(dev, PAGE_FAULT_ADDR_REG);
	dev->page_fault = 1;
	wake_up_interruptible(&dev->wait);

	return IRQ_HANDLED;
}


/* == Init and exit functions ========================================== */

/*
 * @see header
 */
int proc_control_num_hwts_static(void) {
	void __iomem *mem;
	int num_hwts;

	// allocation io memory to read proc control registers
	if (!request_mem_region(BASE_ADDR, MEM_SIZE, "reconos-proc-control")) {
		__printk(KERN_WARNING "[reconos-proc-control] "
		                      "memory region busy\n");
		goto req_failed;
	}

	mem = ioremap(BASE_ADDR, MEM_SIZE);
	if (!mem) {
		__printk(KERN_WARNING "[reconos-proc-control] "
		                      "ioremap failed\n");
		goto map_failed;
	}

	num_hwts = ioread32(mem + NUM_HWTS_REG);

	// free io memory mapping
	iounmap(mem);
	release_mem_region(BASE_ADDR, MEM_SIZE);

	return num_hwts;

map_failed:
	release_mem_region(BASE_ADDR, MEM_SIZE);

req_failed:
	return -1;
}

/*
 * @see header
 */
int proc_control_init(void) {
	struct proc_control_dev *dev;
	int i;

	__printk(KERN_INFO "[reconos-proc-control] "
	                   "initializing driver ...\n");

	dev = &proc_control;

	// set some general information of proc control
	strncpy(dev->name, "reconos-proc-control", 25);
	dev->base_addr = BASE_ADDR;
	dev->mem_size = MEM_SIZE;
	dev->irq = IRQ;
	dev->page_fault = 0;

	// allocating reset-register
	dev->hwt_resets = kcalloc(DYNAMIC_REG_COUNT, sizeof(uint32_t), GFP_KERNEL);
	if (!dev->hwt_resets) {
		__printk(KERN_WARNING "[reconos-proc-control] "
		                      "cannot allocate proc control memory\n");
		goto hwt_resets_failed;
	}

	for (i = 0; i < DYNAMIC_REG_COUNT; i++) {
		dev->hwt_resets[i] = 0xFFFFFFFF;
	}

	// allocating signal-register
	dev->hwt_signals = kcalloc(DYNAMIC_REG_COUNT, sizeof(uint32_t), GFP_KERNEL);
	if (!dev->hwt_signals) {
		__printk(KERN_WARNING "[reconos-proc-control] "
		                      "cannot allocate proc control memory\n");
		goto hwt_signals_failed;
	}

	// allocation io memory to read proc control registers
	if (!request_mem_region(BASE_ADDR, MEM_SIZE, dev->name)) {
		__printk(KERN_WARNING "[reconos-proc-control] "
		                      "memory region busy\n");
		goto req_failed;
	}

	dev->mem = ioremap(BASE_ADDR, MEM_SIZE);
	if (!dev->mem) {
		__printk(KERN_WARNING "[reconos-proc-control] "
		                      "ioremap failed\n");
		goto map_failed;
	}

	// reset entire system
	write_reg(dev, SYS_RESET_REG, 1);

	// requesting interrupt
	if (request_irq(IRQ, interrupt, 0, "reconos-proc-control", dev)) {
		__printk(KERN_WARNING "[reconos-proc-control] "
		                      "can't get irq\n");
		goto irq_failed;
	}

	disable_irq(IRQ);

	// initialize spinlock
	spin_lock_init(&dev->lock);

	// initializing misc-device structure
	dev->mdev.minor = MISC_DYNAMIC_MINOR;
	dev->mdev.fops = &proc_control_fops;
	dev->mdev.name = dev->name;

	if (misc_register(&dev->mdev) < 0) {
		__printk(KERN_WARNING "[reconos-proc-control] "
		                      "error while registering misc-device\n");
		goto reg_failed;
	}

	// initialize remaining struct parts
	init_waitqueue_head(&dev->wait);

	__printk(KERN_INFO "[reconos-proc-control] "
	                   "driver initialized successfully\n");


	return 0;

reg_failed:
	free_irq(IRQ, dev);
	misc_deregister(&dev->mdev);

irq_failed:
	iounmap(dev->mem);

map_failed:
	release_mem_region(BASE_ADDR, MEM_SIZE);

req_failed:
	kfree(dev->hwt_signals);

hwt_signals_failed:
	kfree(dev->hwt_resets);

hwt_resets_failed:
	return -1;
}

/*
 * @see header
 */
int proc_control_exit(void) {
	struct proc_control_dev *dev;
	
	__printk(KERN_INFO "[reconos-proc-control] "
	                   "removing driver ...\n");

	dev = &proc_control;

	misc_deregister(&dev->mdev);

	kfree(dev->hwt_resets);

	free_irq(IRQ, dev);

	iounmap(dev->mem);
	release_mem_region(BASE_ADDR, MEM_SIZE);

	return 0;
}
