//---------------------------------------------------------------------------
// %%%RECONOS_COPYRIGHT_BEGIN%%%
// 
// This file is part of ReconOS (http://www.reconos.de).
// Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
// All rights reserved.
// 
// ReconOS is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
// 
// ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
// 
// You should have received a copy of the GNU General Public License along
// with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
// 
// %%%RECONOS_COPYRIGHT_END%%%
//---------------------------------------------------------------------------


//#include <generated/autoconf.h>
#include <linux/sched.h>
#include <linux/wait.h>
#include <linux/irq.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/module.h>
#include <linux/ioctl.h>
#include <asm/uaccess.h>

#include <linux/of_device.h>
#include <linux/of_platform.h>

#include "fsl.h"

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Andreas Agne");

static int fsl_interrupts[16] = { -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};

module_param_array(fsl_interrupts, int, NULL, S_IRUGO | S_IWUSR);
MODULE_PARM_DESC(fsl_interrupts, "Array of all FSL interrupts in use (FSL0 to FSL15). Set to -1 for unused FSLs.");

/* Write a single word to FSL interface (non-blocking):                                                 *
 *                                                                                                      *
 *     id : FSL id, there are up to 16 FSLs on the microblaze, each with a master and a slave interface *
 *    val : the word to write                                                                           *
 *                                                                                                      *
 * returns 0 if ok, 2 in case of error, and 1 when fifo is full                                                      */
static int nputfsl(int id, int val){
	int result;
	switch(id) {
		case 0x0: asm volatile ("nput\t%0,rfsl0" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x1: asm volatile ("nput\t%0,rfsl1" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x2: asm volatile ("nput\t%0,rfsl2" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x3: asm volatile ("nput\t%0,rfsl3" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x4: asm volatile ("nput\t%0,rfsl4" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x5: asm volatile ("nput\t%0,rfsl5" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x6: asm volatile ("nput\t%0,rfsl6" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x7: asm volatile ("nput\t%0,rfsl7" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x8: asm volatile ("nput\t%0,rfsl8" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x9: asm volatile ("nput\t%0,rfsl9" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0xA: asm volatile ("nput\t%0,rfsl10" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0xB: asm volatile ("nput\t%0,rfsl11" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0xC: asm volatile ("nput\t%0,rfsl12" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0xD: asm volatile ("nput\t%0,rfsl13" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0xE: asm volatile ("nput\t%0,rfsl14" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0xF: asm volatile ("nput\t%0,rfsl15" :: "d" (val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		default: return 2;
	}
	return result;
}

/* Read a single word from FSL interface (non-blocking):                                                *
 *                                                                                                      *
 *     id : FSL id, there are up to 16 FSLs on the microblaze, each with a master and a slave interface *
 *    val : the word read from the fifo will be placed here                                             *
 *                                                                                                      *
 * returns 0 if ok, 2 in case of error, and 1 when no data is available                                              */
static int ngetfsl(int id, int *val){
	int result;
	switch(id) {
		case 0x0: asm volatile ("nget\t%0,rfsl0" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x1: asm volatile ("nget\t%0,rfsl1" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x2: asm volatile ("nget\t%0,rfsl2" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x3: asm volatile ("nget\t%0,rfsl3" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x4: asm volatile ("nget\t%0,rfsl4" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x5: asm volatile ("nget\t%0,rfsl5" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x6: asm volatile ("nget\t%0,rfsl6" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x7: asm volatile ("nget\t%0,rfsl7" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x8: asm volatile ("nget\t%0,rfsl8" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0x9: asm volatile ("nget\t%0,rfsl9" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0xA: asm volatile ("nget\t%0,rfsl10" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0xB: asm volatile ("nget\t%0,rfsl11" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0xC: asm volatile ("nget\t%0,rfsl12" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0xD: asm volatile ("nget\t%0,rfsl13" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0xE: asm volatile ("nget\t%0,rfsl14" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		case 0xF: asm volatile ("nget\t%0,rfsl15" : "=d" (*val)); asm volatile ("addic\t%0,r0,0"  : "=d" (result)); break;
		default: return 2;
	}
	
	return result;
}

#define FSL_MAX 16

int fsl_major = 0;
int fsl_minor = 0;
int fsl_count = FSL_MAX;

#define FSL_IOC_MAGIC 'k'
#define FSL_IOCWRITE _IOW(FSL_IOC_MAGIC,0xF0,int)
#define FSL_IOCREAD  _IOR(FSL_IOC_MAGIC,0xF1,int)


struct fsl_dev {
	unsigned int fsl_num;                   // fsl number
	loff_t next_read;                       // next expected read offset
	loff_t next_write;                      // next expected write offset
	int irq;                                // interrupt number of FSL
	int irq_enabled;
	//struct semaphore sem;                 // mutual exclusion semaphore
	wait_queue_head_t read_queue;           // queue for blocking reads
	volatile unsigned short irq_count;      // number of occurred interrupts, should never exceed 1!
	struct cdev cdev;                       // characted device structure
};

struct fsl_dev dev_array[FSL_MAX];


///
/// Open FSL device.
///
/// This function also looks up the fsl_dev associated with the inode,
/// an makes it available for other methods.
///
int fsl_open(struct inode *inode, struct file *filp)
{
	struct fsl_dev *dev; /* device information */
	
	dev = container_of(inode->i_cdev, struct fsl_dev, cdev);
	filp->private_data = dev; /* for later use in other methods */
	
	PDEBUG("opening FSL %d\n", dev->fsl_num);
	
	// report any unhandled IRQs in the meantime
	if (dev->irq_count > 0) {
		printk(KERN_WARNING "osif: there have been %d unhandled IRQs\n", dev->irq_count);
	}
	
	// TODO: Reset OSIF and hardware thread?
	// If so, also reset the next_read and next_write variables!
	
	return 0;          // success
}

/// Close FSL device.
int fsl_release(struct inode *inode, struct file *filp) {
	
	struct fsl_dev *dev = filp->private_data;
	PDEBUG("closing FSL %d\n", dev->fsl_num);
	
	return 0;
}

// This function performs a read on an FSL slave interface.
ssize_t fsl_read(struct file *filp, char __user *buf, size_t count, loff_t *f_pos) {
	struct fsl_dev *dev = filp->private_data;
	int num_words;
	int i;
	int invalid;
	int data;
	
	if(count % 4 != 0){
		PDEBUG("ERROR trying to read %d bytes from FSL%d\n: access must be word aligned",count,dev->fsl_num);
		return -EINVAL;
	} else {
		num_words = count/4;
		PDEBUG("trying to read %d words from FSL%d\n",num_words,dev->fsl_num);
	}
	
	for(i = 0; i < num_words; i++){

		invalid = ngetfsl(dev->fsl_num,&data);
		
		// no data available:
		if(invalid){
			dev->irq_count = 0; // FIXME: this is not thread save
			// handle non-blocking read
			if(filp->f_flags & O_NONBLOCK) { 
				return i*4;
			}
			
			if(!dev->irq_enabled){
				dev->irq_enabled = 1;
				enable_irq(dev->irq);
			}
			
			// handle blocking read
			if (wait_event_interruptible(dev->read_queue, (dev->irq_count > 0))){
				return -ERESTARTSYS;
			}
			
			// repeat this loop iteration:
			i--;
			continue;
		}
		
		if(copy_to_user(buf + 4*i, &data, 4)){
			return -EFAULT;
		}
	}
	
	return count;
}

// Write to FSL
// currently this never blocks
ssize_t fsl_write(struct file *filp, const char __user *buf, size_t count, loff_t *f_pos) {
	struct fsl_dev *dev = filp->private_data;
	int data;
	int invalid;
	int num_words;
	int i;
	
	if(count % 4 != 0){
		PDEBUG("ERROR trying to write %d bytes to FSL%d\n: access must be word aligned",count,dev->fsl_num);
		return -EINVAL;
	} else {
		PDEBUG("trying to write %d words to FSL%d\n",count,dev->fsl_num);
	}
	
	num_words = count/4;
	
	if(num_words == 0) return 0;
	
	
	for(i = 0; i < num_words; i++){
		if (copy_from_user(&data, buf + 4*i, 4)){
			return -EFAULT;
		}
		
		invalid = nputfsl(dev->fsl_num,data);
		
		// no space available:
		if(invalid){
			// handle blocking and non-blocking write:
			return 4*i;
		}
	}
	
	return count;
}

long fsl_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
	int result = 0;
	struct fsl_dev *dev = filp->private_data;
	switch(cmd){
		case FSL_IOCWRITE:
			nputfsl(dev->fsl_num,arg);
			return 0;
		case FSL_IOCREAD:
			ngetfsl(dev->fsl_num,&result);
			return result;
	}
	return -ENOTTY;
}

// Interrupt handler
irqreturn_t fsl_interrupt(int irq, void *dev_id)
{	
	struct fsl_dev *dev = dev_id;
	
	// increment IRQ counter
	dev->irq_count++;
	
	// TODO: handle concurrency!
	
	PDEBUG("IRQ:%d\n",irq);
	
	// wake up blocking processes
	wake_up_interruptible(&dev->read_queue);
	
	disable_irq_nosync(irq); // since interrupt is active high, we must suppress it until all data is read
	dev->irq_enabled = 0;
	
	
	return IRQ_HANDLED;
}

// File operation struct
static struct file_operations fsl_fops = {
	.owner = THIS_MODULE,
	.unlocked_ioctl  = fsl_ioctl,
	.read = fsl_read,
	.write = fsl_write,
	.open = fsl_open,
	.release = fsl_release
};


/// Set up device
static void fsl_setup_dev(struct fsl_dev *dev, int index)
{
	int err, devno;
	
	dev->irq = fsl_interrupts[index];
	
	if(dev->irq == -1) return;
	
	err = request_irq(dev->irq, fsl_interrupt, 0, "fsl", dev);
	if (err) {
		printk(KERN_WARNING "fsl: can't get assigned IRQ %lu\n", (unsigned long)0);
		dev->irq = -1;
		return;
	}
	
	devno = MKDEV(fsl_major, fsl_minor + index);
	
	cdev_init(&dev->cdev, &fsl_fops);
	dev->cdev.owner = THIS_MODULE;
	dev->cdev.ops = &fsl_fops;
	dev->fsl_num = index;
	err = cdev_add(&dev->cdev, devno, 1);
	
	/* Fail gracefully if need be */
	if (err) {
		printk(KERN_NOTICE "Error %d adding fsl%d", err, index);
		dev->irq = -1;
		return;
	}
	
	init_waitqueue_head(&dev->read_queue);
	dev->irq_enabled = 1;
	
	printk(KERN_INFO "fsl: registered fsl%d irq %d\n", index, dev->irq);
}

/// Remove device
static void fsl_remove_dev(struct fsl_dev *dev, int index)
{
	if(dev->irq == -1) return;
	
	free_irq(dev->irq, dev);
	cdev_del(&dev->cdev);
}

int __init fsl_init(void) {
	int result,i;
	dev_t dev = 0;

	PDEBUG("registering device\n");

	if (fsl_major) {
		dev = MKDEV(fsl_major, fsl_minor);
		result = register_chrdev_region(dev, fsl_count, "fsl");
	} else {    // dynamic allocation of device numbers
		result = alloc_chrdev_region(&dev, fsl_minor, fsl_count, "fsl");
		fsl_major = MAJOR(dev);
	}

	if (result < 0) {
		printk(KERN_WARNING "fsl: can't get major %d\n", fsl_major);
		return result;
	}

	PDEBUG("registered %d char devices with major %d\n", fsl_count, fsl_major);
	
	// initialize all devices
	for(i = 0; i < FSL_MAX; i++){
		fsl_setup_dev(dev_array + i, i);
	}
	
	return result;
}

void __exit fsl_cleanup(void) {
	int i;
	dev_t fsl_dev = MKDEV(fsl_major, fsl_minor);

	unregister_chrdev_region(fsl_dev, fsl_count);

	// remove all devices
	for(i = 0; i < FSL_MAX; i++){
		fsl_remove_dev(dev_array + i, i);
	}
	
	PDEBUG("unregistered all char devices\n");
}


module_init(fsl_init);
module_exit(fsl_cleanup);

