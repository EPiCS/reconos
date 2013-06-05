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

#define C_USE_EXTENDED_FSL_INSTR 0
#define WRITE_BUFFER_SIZE 128 //Bytes
#define READ_BUFFER_SIZE 256  //Bytes

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

static int __must_check nputfsl(int id, int val)
{
	int ret;
#if C_USE_EXTENDED_FSL_INSTR
        if (id<0  || id > 16 ){ return 2;}
       
        asm volatile ("nputd\t%0,%1" :: "d" (val), "d" (id));
        asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
               
        return ret;
#else
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
#endif
}

/* Returns: 0 - ok, 1 - no data available, 2 - error */
static int __must_check ngetfsl(int id, int *val)
{
	int ret;
	
#if C_USE_EXTENDED_FSL_INSTR
        if (id<0  || id > 16 ){ return 2;}
        
        asm volatile ("ngetd\t%0,%1" : "=d" (*val): "d" (id));
        asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
        return ret;
#else
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
#endif
}

static int fsl_open(struct inode *inode, struct file *filp)
{
	int i, minor;
	minor = iminor(inode);
	for (i = 0; i < FSL_MAX; i++) {
		if (minor == dev_array[i].mdev.minor) {
			filp->private_data = &dev_array[i];
			break;
		}
	}
	return 0;
}

static struct fsl_dev *fsl_get_dev_by_num(int num)
{
	int i;
	struct fsl_dev *ret = NULL;

	for (i = 0; i < FSL_MAX; i++) {
		if (num == dev_array[i].fsl_num) {
			ret = &dev_array[i];
			break;
		}
	}

	return ret;
}

static ssize_t fsl_do_read(int devnum, char __user *ubuf, char *kbuf,
			   size_t count, int nonblock)
{
	int data[READ_BUFFER_SIZE/sizeof(uint32_t)];
	int ret, num_words, i;
	int remaining_bytes, copied_bytes;
	
	struct fsl_dev *dev = fsl_get_dev_by_num(devnum);

	if (count % sizeof(uint32_t) != 0 || !dev)
		return -EINVAL;

	num_words = count / sizeof(uint32_t);
	if (num_words == 0)
		return 0;

	remaining_bytes = count;
	while (remaining_bytes > 0 ){
	  copied_bytes = remaining_bytes > READ_BUFFER_SIZE ? READ_BUFFER_SIZE : remaining_bytes;
	  
	  for (i = 0; i < copied_bytes/sizeof(uint32_t); i++) {
		ret = ngetfsl(dev->fsl_num, &data[i]);
		if (ret) {
			atomic_set(&dev->irq_count, 0);
			if (nonblock)
				return i * sizeof(uint32_t)+(count - remaining_bytes);
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
	  }
	  if (kbuf) {
		  memcpy(kbuf, data, copied_bytes);
		  kbuf += copied_bytes/sizeof(char);
	  } else if (ubuf) {
		  if (copy_to_user(ubuf , data, copied_bytes)){
		     return -EFAULT;
		  } else {
		    ubuf += copied_bytes/sizeof(char);
		  }
	  } else {
		  BUG();
	  }
	  remaining_bytes -= copied_bytes;  
	}
	
	return count;
}

static inline ssize_t fsl_do_read_to_user(int devnum, char __user *ubuf,
					  size_t count, int nonblock)
{
	return fsl_do_read(devnum, ubuf, NULL, count, nonblock);
}

static inline ssize_t fsl_do_read_to_kern(int devnum, char *kbuf,
					  size_t count)
{
	return fsl_do_read(devnum, NULL, kbuf, count, 0);
}

uint32_t fsl_read_word(int num)
{
	ssize_t ret;
	uint32_t val;

	/* Same API as from user space. */
	ret = fsl_do_read_to_kern(num, (char *) &val, sizeof(val));
	if (ret < 0) {
		printk(KERN_WARNING "[fsl] could not read value: %d\n", ret);
		val = 0;
	}

	return val;
}
EXPORT_SYMBOL_GPL(fsl_read_word);

static ssize_t fsl_read(struct file *filp, char __user *buf,
			size_t count, loff_t *pos)
{
	struct fsl_dev *dev = filp->private_data;
	return fsl_do_read_to_user(dev->fsl_num, buf, count,
				   filp->f_flags & O_NONBLOCK);
}

static ssize_t fsl_do_write(int devnum, const char __user *ubuf,
			    const char *kbuf, size_t count)
{
	int data[WRITE_BUFFER_SIZE/sizeof(uint32_t)];
	int ret, num_words, i;
	int remaining_bytes, copied_bytes;
	struct fsl_dev *dev = fsl_get_dev_by_num(devnum);

	if (count % sizeof(uint32_t) != 0)
		return -EINVAL;

	num_words = count / sizeof(uint32_t);
	if (num_words == 0)
		return 0;

	remaining_bytes = count;
	
	while(remaining_bytes > 0){
	  copied_bytes = remaining_bytes > WRITE_BUFFER_SIZE ? WRITE_BUFFER_SIZE : remaining_bytes;
	  if (kbuf) {
		  memcpy(data, kbuf, copied_bytes);
		  kbuf += copied_bytes/sizeof(char);
	  } else if (ubuf) {
		  if (copy_from_user(data, ubuf , copied_bytes) ){
			  return -EFAULT;
		  } else {
		    ubuf += copied_bytes/sizeof(char);
		  }
	  } else {
		  BUG();
	  }
	  
	  for (i = 0; i < copied_bytes/sizeof(uint32_t); i++) {
		  ret = nputfsl(dev->fsl_num, data[i]);
		  if (ret)
			  return i * sizeof(uint32_t)+(count - remaining_bytes);
	  }
	  remaining_bytes -= copied_bytes;
	}
	return count;
}

static inline ssize_t fsl_do_write_from_user(int devnum,
					     const char __user *ubuf,
					     size_t count)
{
	return fsl_do_write(devnum, ubuf, NULL, count);
}

static inline ssize_t fsl_do_write_from_kern(int devnum, const char *kbuf,
					     size_t count)
{
	return fsl_do_write(devnum, NULL, kbuf, count);
}

ssize_t fsl_write_word(int num, uint32_t val)
{
	ssize_t ret;

	/* Same API as from user space. */
	ret = fsl_do_write_from_kern(num, (char *) &val, sizeof(val));
	if (ret < 0)
		printk(KERN_WARNING "[fsl] could not write value: %d\n", ret);

	return ret;
}
EXPORT_SYMBOL_GPL(fsl_write_word);

static ssize_t fsl_write(struct file *filp, const char __user *buf,
			 size_t count, loff_t *pos)
{
	struct fsl_dev *dev = filp->private_data;
	return fsl_do_write_from_user(dev->fsl_num, buf, count);
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
