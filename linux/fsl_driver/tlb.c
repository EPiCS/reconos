///
/// \file tlb.c
///
/// This file is part of the reconos device driver.
/// 
/// This driver provides character devices (e.g. /dev/tlbnnn) for
/// accessing TLB registers from user space, in particular
/// from a delegate thread.
/// 
/// \author     Andreas Agne <agne@upb.de>
/// \date       22.08.2010
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
// Major Changes:
// 
// 22.08.2010   Andreas Agne   File created

#include <linux/autoconf.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/fs.h>       /* everything... */
#include <linux/errno.h>    /* error codes */
#include <linux/types.h>    /* size_t */
#include <linux/proc_fs.h>
#include <linux/fcntl.h>    /* O_ACCMODE */
#include <linux/seq_file.h>
#include <linux/cdev.h>
#include <linux/interrupt.h>
#include <asm/uaccess.h>
#include <asm/io.h>
#include <asm/dcr.h>

// open firmware
#include <linux/of_device.h>
#include <linux/of_platform.h>
#include "reconos.h"

struct tlb_dev {
    unsigned int tlb_num;                  // number of tlbs
    dcr_host_t dcr_host;                    // dcr access structure
    unsigned int dcr_len;                   // length of DCR address space (4)
    struct cdev cdev;                       // characted device structure
};

int tlb_major = TLB_MAJOR;
int tlb_minor = 0;
int tlb_numtlbs = TLB_NUMTLBS;

extern struct of_platform_driver tlb_of_driver;

module_param(tlb_major, int, S_IRUGO);
module_param(tlb_numtlbs, int, S_IRUGO);

// FILE OPERATIONS =============================================

int tlb_open(struct inode *inode, struct file *filp)
{
	struct tlb_dev *dev; /* device information */

	dev = container_of(inode->i_cdev, struct tlb_dev, cdev);
	filp->private_data = dev; /* for other methods */

	PDEBUG("opening tlb %d at 0x%08X\n", 
			dev->tlb_num, DCR_ADDR(dev->dcr_host));

	return 0;          /* success */
}

ssize_t tlb_read(struct file *filp, char __user *buf, size_t count, loff_t *f_pos) {
	struct tlb_dev *dev = filp->private_data;
	unsigned long reg = 0;

	PDEBUG("trying to read %d bytes from pos %ld\n",
			count, (unsigned long int)*f_pos);


	if(count != 4){
		printk(KERN_WARNING "can only read a single TLB register at a time.\n");
		return -EINVAL;
	}
	
	if(!(*f_pos == 0 || *f_pos == 4)){
		printk(KERN_WARNING "read offset must be 0 or 4.\n");
		return -EINVAL;
	}
	
	reg = dcr_read(dev->dcr_host, (*f_pos)/4);
	
	// bytewise copy data from read buffer to user space
	if (copy_to_user(buf, &reg, 4)) return -EFAULT;
	
	return 0;
}

ssize_t tlb_write(struct file *filp, const char __user *buf, size_t count, loff_t *f_pos) {
	struct tlb_dev *dev = filp->private_data;
	unsigned long reg = 0;
	unsigned int dcrn_offset;
	ssize_t retval = 0;
	
	PDEBUG("trying to write %d bytes to pos %ld\n",
	count, (unsigned long int)*f_pos);

	if(count != 4){
		printk(KERN_WARNING "can only write a single TLB register at a time.\n");
		return -EINVAL;
	}
	
	if(!(*f_pos == 0 || *f_pos == 4)){
		printk(KERN_WARNING "write offset must be 0 or 4.\n");
		return -EINVAL;
	}
	
	dcrn_offset = *f_pos/4;

	// bytewise copy data from user space to write buffer
	if ((retval = copy_from_user(&reg, buf, 4))) return -EFAULT;

	dcr_write(dev->dcr_host, dcrn_offset, reg);
	PDEBUG("tlb_write: wrote 0x%08lX to DCRN %d (TLB + %d)\n",
			reg, DCR_ADDR(dev->dcr_host) + dcrn_offset,dcrn_offset);

	return retval;
}

int tlb_release(struct inode *inode, struct file *filp) {
    return 0;
}

static struct file_operations tlb_fops = {
    .owner = THIS_MODULE,
    .read  = tlb_read,
    .write = tlb_write,
    .open = tlb_open,
    .release = tlb_release
};

static void tlb_setup_cdev(struct tlb_dev *dev, int index)
{
	int err, devno = MKDEV(tlb_major, tlb_minor + index);

	cdev_init(&dev->cdev, &tlb_fops);
	dev->cdev.owner = THIS_MODULE;
	dev->cdev.ops = &tlb_fops;
	err = cdev_add(&dev->cdev, devno, 1);
	/* Fail gracefully if need be */
	if (err) {
		printk(KERN_NOTICE "Error %d adding tlb%d", err, index);
	}
	printk(KERN_INFO "tlb: registered tlb%d at 0x%08X\n", index, DCR_ADDR(dev->dcr_host));
}

int __devinit tlb_of_probe( struct of_device *ofdev, const struct of_device_id *match)
{
	struct tlb_dev *tlb_inst;
	int result = 0;

	PDEBUG("of_probe %s\n", ofdev->node->full_name);

	reconos_tlb_dcrn = dcr_resource_start(ofdev->node, 0);
	PDEBUG("Found TLB @ %u\n", reconos_tlb_dcrn);

	// allocate device data (TODO: does this need to be thread-safe?)
	tlb_inst = kmalloc(sizeof(struct tlb_dev), GFP_KERNEL);

	if (!tlb_inst) {
		result = -ENOMEM;
		goto fail;  /* Make this more graceful */
	}
	memset(tlb_inst, 0, sizeof(struct tlb_dev));

	PDEBUG("probing DCR\n");
	// lookup dcr base address
	tlb_inst->dcr_len = dcr_resource_len(ofdev->node, 0);
	tlb_inst->dcr_host = dcr_map(ofdev->node, reconos_tlb_dcrn, tlb_inst->dcr_len);
	if (!DCR_MAP_OK(tlb_inst->dcr_host)) {
		printk( KERN_ERR "tlb: invalid dcr address\n" );
		result = -ENODEV;
		goto fail1;
	}
	PDEBUG("DCR from %u, len %u\n", reconos_tlb_dcrn, tlb_inst->dcr_len);

	// register device data with device
	dev_set_drvdata(&ofdev->dev, tlb_inst);

	/* Initialize device data */
	tlb_inst->tlb_num = 0;   // FIXME: this is hardcoded, can we extract this from ofdev?

	tlb_setup_cdev(tlb_inst, tlb_inst->tlb_num); // FIXME minor number

	// TODO: add to some kind of list for later reference?
	//       or is the reference via the filp->private_data (in open()) and 
	//       the dev_set_drvdata() enough?

	return 0;

fail1:
	kfree(tlb_inst);
fail:
	return result;
}

int __devexit tlb_of_remove( struct of_device *ofdev ) {
    struct tlb_dev *tlb_inst = dev_get_drvdata(&ofdev->dev);
    
    printk(KERN_INFO "tlb: unregistering tlb%d\n", tlb_inst->tlb_num);

    // unregister char device
    cdev_del(&tlb_inst->cdev);

    // unmap DCR bus
    dcr_unmap(tlb_inst->dcr_host, tlb_inst->dcr_len);

    // free device structure
    kfree(tlb_inst);

    // unregister device data
    dev_set_drvdata(&ofdev->dev, NULL);

    return 0;
}




