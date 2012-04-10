/*
 * Copyright 2012 Andreas Agne <agne@upb.de>
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <linux/sched.h>
#include <linux/wait.h>
#include <linux/irq.h>
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/atomic.h>
#include <linux/module.h>
#include <linux/ioctl.h>
#include <linux/miscdevice.h>
#include <asm/uaccess.h>
#include <linux/of_device.h>
#include <linux/of_platform.h>

#define FSL_MAX		16
#define FSL_MAX_NAMSIZ	64

struct fsl_dev {
	int irq;
	unsigned int fsl_num;
	volatile int irq_enabled;
	wait_queue_head_t read_queue;
	atomic_t irq_count;
	struct miscdevice mdev;
};

static struct fsl_dev dev_array[FSL_MAX];

static int fsl_interrupts[FSL_MAX] = {
 -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 };
module_param_array(fsl_interrupts, int, NULL, S_IRUGO | S_IWUSR);

/* Returns: 0 - ok, 1 - no data available, 2 - error */
int __must_check nputfsl(int id, int val)
{
	int ret;
	switch (id) {
	case 0x0:
		asm volatile ("nput\t%0,rfsl0" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x1:
		asm volatile ("nput\t%0,rfsl1" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x2:
		asm volatile ("nput\t%0,rfsl2" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x3:
		asm volatile ("nput\t%0,rfsl3" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x4:
		asm volatile ("nput\t%0,rfsl4" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x5:
		asm volatile ("nput\t%0,rfsl5" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x6:
		asm volatile ("nput\t%0,rfsl6" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x7:
		asm volatile ("nput\t%0,rfsl7" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x8:
		asm volatile ("nput\t%0,rfsl8" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x9:
		asm volatile ("nput\t%0,rfsl9" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xA:
		asm volatile ("nput\t%0,rfsl10" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xB:
		asm volatile ("nput\t%0,rfsl11" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xC:
		asm volatile ("nput\t%0,rfsl12" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xD:
		asm volatile ("nput\t%0,rfsl13" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xE:
		asm volatile ("nput\t%0,rfsl14" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xF:
		asm volatile ("nput\t%0,rfsl15" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	default:
		return 2;
	}
	return ret;
}
EXPORT_SYMBOL(nputfsl);

/* Returns: 0 - ok, 1 - no data available, 2 - error */
int __must_check ngetfsl(int id, int *val)
{
	int ret;
	switch (id) {
	case 0x0:
		asm volatile ("nget\t%0,rfsl0" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x1:
		asm volatile ("nget\t%0,rfsl1" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x2:
		asm volatile ("nget\t%0,rfsl2" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x3:
		asm volatile ("nget\t%0,rfsl3" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x4:
		asm volatile ("nget\t%0,rfsl4" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x5:
		asm volatile ("nget\t%0,rfsl5" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x6:
		asm volatile ("nget\t%0,rfsl6" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x7:
		asm volatile ("nget\t%0,rfsl7" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x8:
		asm volatile ("nget\t%0,rfsl8" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x9:
		asm volatile ("nget\t%0,rfsl9" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xA:
		asm volatile ("nget\t%0,rfsl10" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xB:
		asm volatile ("nget\t%0,rfsl11" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xC:
		asm volatile ("nget\t%0,rfsl12" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xD:
		asm volatile ("nget\t%0,rfsl13" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xE:
		asm volatile ("nget\t%0,rfsl14" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xF:
		asm volatile ("nget\t%0,rfsl15" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	default:
		return 2;
	}
	return ret;
}
EXPORT_SYMBOL(ngetfsl);

static int fsl_open(struct inode *inode, struct file *filp)
{
	int i, minor;
	minor = iminor(inode);
	for(i = 0; i < FSL_MAX; i++) {
		if (minor == dev_array[i].mdev.minor) {
			filp->private_data = &dev_array[i];
			break;
		}
	}
	return 0;
}

static ssize_t fsl_read(struct file *filp, char __user *buf,
			size_t count, loff_t *pos)
{
	int data, ret, num_words, i;
	struct fsl_dev *dev = filp->private_data;

	if (count % sizeof(uint32_t) != 0)
		return -EINVAL;

	num_words = count / sizeof(uint32_t);
	if (num_words == 0)
		return 0;

	for (i = 0; i < num_words; i++) {
		ret = ngetfsl(dev->fsl_num, &data);
		if (ret) {
			atomic_set(&dev->irq_count, 0);
			if(filp->f_flags & O_NONBLOCK)
				return i * sizeof(uint32_t);
			if (!dev->irq_enabled) {
				dev->irq_enabled = 1;
				enable_irq(dev->irq);
			}
			ret = wait_event_interruptible(dev->read_queue,
				atomic_read(&dev->irq_count) > 0);
			if (ret)
				return ret;
			i--;
			continue;
		}

		if (copy_to_user(buf + sizeof(uint32_t) * i,
				 &data, sizeof(uint32_t)))
			return -EFAULT;
	}

	return count;
}

static ssize_t fsl_write(struct file *filp, const char __user *buf,
			 size_t count, loff_t *pos)
{
	int data, ret, num_words, i;
	struct fsl_dev *dev = filp->private_data;

	if (count % sizeof(uint32_t) != 0)
		return -EINVAL;

	num_words = count / sizeof(uint32_t);
	if (num_words == 0)
		return 0;

	for (i = 0; i < num_words; i++) {
		if (copy_from_user(&data, buf + sizeof(uint32_t) * i,
				   sizeof(uint32_t)))
			return -EFAULT;
		ret = nputfsl(dev->fsl_num, data);
		if (ret)
			return i * sizeof(uint32_t);
	}

	return count;
}

static irqreturn_t fsl_interrupt(int irq, void *fsldev)
{	
	struct fsl_dev *dev = fsldev;

	atomic_inc(&dev->irq_count);
	wake_up_interruptible(&dev->read_queue);
	disable_irq_nosync(irq);
	dev->irq_enabled = 0;

	return IRQ_HANDLED;
}

static struct file_operations fsl_fops __read_mostly = {
	.owner		=	THIS_MODULE,
	.read		=	fsl_read,
	.write		=	fsl_write,
	.open		=	fsl_open,
};

static void fsl_setup_dev(struct fsl_dev *dev, int index)
{
	int err;
	size_t nlen = FSL_MAX_NAMSIZ;

	dev->irq = fsl_interrupts[index];
	if(dev->irq == -1)
		return;
	err = request_irq(dev->irq, fsl_interrupt, 0, "fsl", dev);
	if (err) {
		printk(KERN_WARNING "[fsl] can't get assigned IRQ %d\n",
		       dev->irq);
		dev->irq = -1;
		return;
	}

	dev->mdev.minor = MISC_DYNAMIC_MINOR;
	dev->mdev.fops = &fsl_fops;
	dev->mdev.name = kzalloc(nlen, GFP_KERNEL);
	if (err)
		goto out;

	snprintf((char *) dev->mdev.name, nlen - 1, "fsl%d", index);
	err = misc_register(&dev->mdev);
	if (err)
		goto out_free;

	init_waitqueue_head(&dev->read_queue);
	atomic_set(&dev->irq_count, 0);
	dev->fsl_num = index;
	dev->irq_enabled = 1;

	printk(KERN_INFO "[fsl] registered fsl%d irq %d\n", index, dev->irq);
	return;
out_free:
	kfree(dev->mdev.name);
out:
	free_irq(dev->irq, dev);
	return;
}

static void fsl_remove_dev(struct fsl_dev *dev)
{
	if (dev->irq == -1)
		return;
	free_irq(dev->irq, dev);
	misc_deregister(&dev->mdev);
	kfree(dev->mdev.name);
}

static __init int fsl_init(void)
{
	int i;
	for (i = 0; i < FSL_MAX; i++)
		fsl_setup_dev(&dev_array[i], i);
	return 0;
}

static __exit void fsl_cleanup(void)
{
	int i;
	for (i = 0; i < FSL_MAX; i++)
		fsl_remove_dev(&dev_array[i]);
}

module_init(fsl_init);
module_exit(fsl_cleanup);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Andreas Agne <agne@upb.de>");
MODULE_AUTHOR("Daniel Borkmann <daniel.borkmann@tik.ee.ethz.ch>");
MODULE_PARM_DESC(fsl_interrupts, "FSL interrupts in use (FSL0 to FSL15)");
