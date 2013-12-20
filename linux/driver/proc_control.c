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

#define PROC_CONTROL_BASE_ADDR 0x6FE00000
#define PROC_CONTROL_MEM_SIZE  0x10000

#ifdef RECONOS_ARCH_zynq
#define PROC_CONTROL_IRQ       91
#endif

#ifdef RECONOS_ARCH_microblaze
#define PROC_CONTROL_IRQ       5
#endif

#define PROC_CONTROL_NUM_HWTS_REG        0x00
#define PROC_CONTROL_PGD_ADDR_REG        0x04
#define PROC_CONTROL_PAGE_FAULT_ADDR_REG 0x08
#define PROC_CONTROL_TLB_HITS_REG        0x0C
#define PROC_CONTROL_TLB_MISSES_REG      0x10
#define PROC_CONTROL_SYS_RESET_REG       0x14
#define PROC_CONTROL_HWT_RESET_REG       0x18


struct proc_control_dev {
	char name[25];
	unsigned int addr;
	int irq;

	void __iomem *mem;
	wait_queue_head_t wait;
	int page_fault;
	uint32_t page_fault_addr;
	uint32_t *hwt_reset;
	size_t hwt_reset_count;

	struct miscdevice mdev;

	spinlock_t lock;
};


static struct proc_control_dev proc_control_dev;


// some low level functions
uint32_t proc_control_read_reg(struct proc_control_dev *dev,
                               unsigned int reg) {
	return ioread32(dev->mem + reg);
}

void proc_control_write_reg(struct proc_control_dev *dev,
                            unsigned int reg, uint32_t data) {
	iowrite32(data, dev->mem + reg);
}

static int proc_control_open(struct inode *inode, struct file *filp) {
	filp->private_data = &proc_control_dev;

	return 0;
}


#ifdef RECONOS_ARCH_zynq
// do page table walk
static unsigned long do_ptw(unsigned long addr) {
	pgd_t *pgd;
	pte_t *pte;
	pud_t *pud;
	pmd_t *pmd;
	struct page *page;
	unsigned int pfn;

	struct mm_struct *mm = current->mm;

	unsigned long page_addr = 0;

	__printk(KERN_INFO "Perfoming page table walk ...\n");

	pgd = pgd_offset(mm, addr);
	if (pgd_none(*pgd) || pgd_bad(*pgd))
		goto out;
	__printk(KERN_INFO "PGD valid ... at 0x%x\n", virt_to_phys(pgd));
	__printk(KERN_INFO "PGD data (for HW) = 0x%x\n", (unsigned int) *((unsigned int *)pgd));

	pud = pud_offset(pgd, addr);
	if (pud_none(*pud) || pud_bad(*pud))
		goto out;
	__printk(KERN_INFO "PUD valid ... at 0x%x\n", virt_to_phys(pud));

	pmd = pmd_offset(pud, addr);
	if (pmd_none(*pmd) || pmd_bad(*pmd))
		goto out;
	__printk(KERN_INFO "PMD valid ... at 0x%x\n", virt_to_phys(pmd));

	pte = pte_offset_map(pmd, addr);
	if (pte_none(*pte))
		goto out;
	__printk(KERN_INFO "PTE valid ... at 0x%x\n", virt_to_phys(pte));
	__printk(KERN_INFO "PTE (for HW) at 0x%x\n", (unsigned int)virt_to_phys((void *) (((unsigned int *)pte) + 0x200)));
	__printk(KERN_INFO "PTE data (for HW) = 0x%x\n", (unsigned int) *(((unsigned int *)pte) + 0x200));

	page = pte_page(*pte);
	pfn = page_to_pfn(page);
	__printk(KERN_INFO "Page is at 0x%x\n", page_to_phys(page));

	pte_unmap(pte);

out:
	return page_addr;
}

static void flush_cache(void) {
}
#endif

#ifdef RECONOS_ARCH_microblaze
static unsigned long do_ptw(unsigned long addr) {
	return 0;
}

static void flush_cache(void) {
	int i;
	int baseaddr, bytesize,linelen;

	// these parameters need to be adjusted to the architecture
	// C_DCACHE_BASEADDR
	baseaddr = 0x20000000;
	// C_DCACHE_BYTE_SIZE
	bytesize = 64 * 1024;
	// C_DCACHE_LINE_LEN * 4
	linelen = 4 * 4;

	for (i = 0; i < bytesize; i += linelen)
		asm volatile ("wdc.flush %0, %1;" :: "d" (baseaddr), "d" (i));
}
#endif


static long proc_control_ioctl(struct file *filp, unsigned int cmd,
                               unsigned long arg) {
	struct proc_control_dev *dev = filp->private_data;
	uint32_t data;
	int i, hwt_num;
	unsigned long flags;

	switch (cmd) {
		case RECONOS_PROC_CONTROL_GET_NUM_HWTS:
			copy_to_user((int *)arg, &NUM_HWTS, sizeof(int));
			break;

		case RECONOS_PROC_CONTROL_GET_TLB_HITS:
			data = proc_control_read_reg(dev, PROC_CONTROL_TLB_HITS_REG);
			copy_to_user((int *)arg, &data, sizeof(int));
			break;

		case RECONOS_PROC_CONTROL_GET_TLB_MISSES:
			data = proc_control_read_reg(dev, PROC_CONTROL_TLB_MISSES_REG);
			copy_to_user((int *)arg, &data, sizeof(int));
			break;

		case RECONOS_PROC_CONTROL_GET_FAULT_ADDR:
			// there is no need for synchronization with the interrupt handler
			// since it should be disabled at this point
			dev->page_fault = 0;

			enable_irq(dev->irq);

			do {
				if (wait_event_interruptible(dev->wait, dev->page_fault != 0) < 0) {
					__printk(KERN_DEBUG "[reconos-proc-control] "
					                    "interrupted while waiting, aborting ...\n");
					disable_irq(dev->irq);
					dev->page_fault = 0;
					return -1;
				}
			} while (dev->page_fault == 0);

			disable_irq(dev->irq);

			copy_to_user((uint32_t *)arg, &dev->page_fault_addr, sizeof(uint32_t));
			break;

		case RECONOS_PROC_CONTROL_CLEAR_PAGE_FAULT:
			dev->page_fault = 0;
			proc_control_write_reg(dev, PROC_CONTROL_PAGE_FAULT_ADDR_REG, 0);
			break;

		case RECONOS_PROC_CONTROL_SET_PGD_ADDR:
			data = (uint32_t) virt_to_phys(current->mm->pgd);
			__printk(KERN_DEBUG "[reconos-proc-control] Current PGD: %x\n", data);
			proc_control_write_reg(dev, PROC_CONTROL_PGD_ADDR_REG, data);
			break;

		case RECONOS_PROC_CONTROL_SYS_RESET:
			spin_lock_irqsave(&dev->lock, flags);

			// set all resets to 1
			for (i = 0; i < dev->hwt_reset_count; i++)
				dev->hwt_reset[i] = 0xFFFFFFFF;

			proc_control_write_reg(dev, PROC_CONTROL_SYS_RESET_REG, 0);

			spin_unlock_irqrestore(&dev->lock, flags);

			break;

		// TODO this method is ok for single resets but does not take advantage
		//      of the reset capabilities. Another method to pass an entire
		//      reset vector would be useful.
		case RECONOS_PROC_CONTROL_SET_HWT_RESET:
			copy_from_user(&hwt_num, (int *) arg, sizeof(int));

			spin_lock_irqsave(&dev->lock, flags);

			if (hwt_num >= 0 && hwt_num < NUM_HWTS) {
				dev->hwt_reset[hwt_num / 32] |= 0x1 << hwt_num % 32;
				data = dev->hwt_reset[hwt_num / 32];

				proc_control_write_reg(dev, PROC_CONTROL_HWT_RESET_REG + hwt_num / 32 * 4, data);
			}

			spin_unlock_irqrestore(&dev->lock, flags);

			break;

		case RECONOS_PROC_CONTROL_CLEAR_HWT_RESET:
			copy_from_user(&hwt_num, (int *) arg, sizeof(int));

			spin_lock_irqsave(&dev->lock, flags);

			if (hwt_num >= 0 && hwt_num < NUM_HWTS) {
				dev->hwt_reset[hwt_num / 32] &= ~(0x1 << hwt_num % 32);
				data = dev->hwt_reset[hwt_num / 32];

				proc_control_write_reg(dev, PROC_CONTROL_HWT_RESET_REG + hwt_num / 32 * 4, data);
			}

			spin_unlock_irqrestore(&dev->lock, flags);

			break;

		case RECONOS_PROC_CONTROL_DO_PTW:
			do_ptw(arg);
			break;

		case RECONOS_PROC_CONTROL_CACHE_FLUSH:
			flush_cache();
			break;

		default:
			return -EINVAL;
	}

	return 0;
}

static struct file_operations proc_control_fops = {
	.owner          = THIS_MODULE,
	.open           = proc_control_open,
	.unlocked_ioctl = proc_control_ioctl,
};


static irqreturn_t proc_control_interrupt(int irq, void *data) {
	struct proc_control_dev *dev = data;

	__printk(KERN_INFO "[reconos-proc-control] "
	                   "page fault occured\n");

	dev->page_fault_addr = proc_control_read_reg(dev, PROC_CONTROL_PAGE_FAULT_ADDR_REG);
	dev->page_fault = 1;
	wake_up_interruptible(&dev->wait);

	return IRQ_HANDLED;
}


int proc_control_init() {
	int i;

	__printk(KERN_INFO "[reconos-proc-control] "
	                   "initializing driver ...\n");


	// set some general information of proc control
	strncpy(proc_control_dev.name, "reconos-proc-control", 25);
	proc_control_dev.irq = PROC_CONTROL_IRQ;
	proc_control_dev.addr = PROC_CONTROL_BASE_ADDR;
	proc_control_dev.page_fault = 0;
	proc_control_dev.hwt_reset_count = NUM_HWTS / 32 + 1;


	// allocating reset-register
	proc_control_dev.hwt_reset = kcalloc(proc_control_dev.hwt_reset_count, sizeof(uint32_t), GFP_KERNEL);
	if (!proc_control_dev.hwt_reset) {
		__printk(KERN_WARNING "[reconos-proc-control] "
		                      "cannot allocate proc control memory\n");
		goto hwt_reset_failed;
	}


	// allocation io memory to read proc control registers
	if (!request_mem_region(proc_control_dev.addr, PROC_CONTROL_MEM_SIZE, proc_control_dev.name)) {
		__printk(KERN_WARNING "[reconos-proc-control] "
		                      "memory region busy\n");
		goto req_failed;
	}

	proc_control_dev.mem = ioremap(proc_control_dev.addr, PROC_CONTROL_MEM_SIZE);
	if (!proc_control_dev.mem) {
		__printk(KERN_WARNING "[reconos-proc-control] "
		                      "ioremap failed\n");
		goto map_failed;
	}

	// reset entire system
	for (i = 0; i < proc_control_dev.hwt_reset_count; i++)
		proc_control_dev.hwt_reset[i] = 0xFFFFFFFF;
	proc_control_write_reg(&proc_control_dev, PROC_CONTROL_SYS_RESET_REG, 0);

	// requesting interrupt
	if (request_irq(proc_control_dev.irq, proc_control_interrupt, 0, "reconos-proc-control", &proc_control_dev)) {
		__printk(KERN_WARNING "[reconos-proc-control] "
		                      "can't get irq\n");
		goto irq_failed;
	}
	disable_irq(proc_control_dev.irq);

	// initialize spinlock
	spin_lock_init(&proc_control_dev.lock);

	// initializing misc-device structure
	proc_control_dev.mdev.minor = MISC_DYNAMIC_MINOR;
	proc_control_dev.mdev.fops = &proc_control_fops;
	proc_control_dev.mdev.name = proc_control_dev.name;

	if (misc_register(&proc_control_dev.mdev) < 0) {
		__printk(KERN_WARNING "[reconos-proc-control] "
		                      "error while registering misc-device\n");
		goto reg_failed;
	}


	// initialize remaining struct parts
	init_waitqueue_head(&proc_control_dev.wait);


	NUM_HWTS = proc_control_read_reg(&proc_control_dev, PROC_CONTROL_NUM_HWTS_REG);
	__printk(KERN_INFO "[reconos-proc-control] "
	                   "detected %d HWTs\n", NUM_HWTS);


	__printk(KERN_INFO "[reconos-proc-control] "
	                   "driver initialized successfully\n");


	goto out;

reg_failed:
	free_irq(proc_control_dev.irq, &proc_control_dev);
	misc_deregister(&proc_control_dev.mdev);

irq_failed:
	iounmap(proc_control_dev.mem);

map_failed:
	release_mem_region(proc_control_dev.addr, PROC_CONTROL_MEM_SIZE);

req_failed:
	kfree(proc_control_dev.hwt_reset);

hwt_reset_failed:
	return -1;

out:
	return 0;
}

int proc_control_exit() {
	__printk(KERN_INFO "[reconos-proc-control] "
	                   "removing driver ...\n");


	kfree(proc_control_dev.hwt_reset);

	free_irq(proc_control_dev.irq, &proc_control_dev);

	iounmap(proc_control_dev.mem);
	release_mem_region(proc_control_dev.addr, PROC_CONTROL_MEM_SIZE);

	misc_deregister(&proc_control_dev.mdev);


	return 0;
}
