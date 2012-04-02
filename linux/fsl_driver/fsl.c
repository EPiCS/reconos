#include <linux/sched.h>
#include <linux/wait.h>
#include <linux/irq.h>
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/module.h>
#include <linux/ioctl.h>
#include <linux/miscdevice.h>
#include <asm/uaccess.h>
#include <linux/of_device.h>
#include <linux/of_platform.h>

#define PDEBUG(c, ...)

#define FSL_MAX 16

#define FSL_IOC_MAGIC 'k'
#define FSL_IOC_WRITE _IOW(FSL_IOC_MAGIC, 0xF0, int)
#define FSL_IOC_READ  _IOR(FSL_IOC_MAGIC, 0xF1, int)

static int fsl_interrupts[16] = { -1, -1, -1, -1, -1, -1, -1, -1,
				  -1, -1, -1, -1, -1, -1, -1, -1 };
module_param_array(fsl_interrupts, int, NULL, S_IRUGO | S_IWUSR);

static inline int nputfsl(int id, int val)
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
		return -EIO;
	}
	return ret;
}

static inline int ngetfsl(int id, int *val)
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
		return -EIO;
	}
	return ret;
}

int fsl_major = 0;
int fsl_minor = 0;
int fsl_count = FSL_MAX;

struct fsl_dev {
	unsigned int fsl_num;                   // fsl number
	int irq;                                // interrupt number of FSL
	int irq_enabled;
	loff_t next_read;                       // next expected read offset
	loff_t next_write;                      // next expected write offset
	wait_queue_head_t read_queue;           // queue for blocking reads
	volatile unsigned short irq_count;      // number of occurred interrupts, should never exceed 1!
	struct miscdevice mdev;
};

static struct fsl_dev dev_array[FSL_MAX];

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

static ssize_t fsl_read(struct file *filp, char __user *buf, size_t count,
			loff_t *f_pos)
{
	int num_words, i, invalid, data;
	struct fsl_dev *dev = filp->private_data;

	if(count % 4 != 0){
		PDEBUG("ERROR trying to read %d bytes from FSL%d\n: access must be word aligned",count,dev->fsl_num);
		return -EINVAL;
	} else {
		num_words = count/4;
		PDEBUG("trying to read %d words from FSL%d\n",num_words,dev->fsl_num);
	}
	
	for (i = 0; i < num_words; i++) {
		invalid = ngetfsl(dev->fsl_num, &data);
		
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
		PDEBUG("trying to write %d words to FSL%d\n",count/4,dev->fsl_num);
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
			printk( KERN_WARNING "fsl.ko: WARNING: No space left in FSL%d\n",dev->fsl_num);
			// handle blocking and non-blocking write:
			return 4*i;
		}
	}
	
	return count;
}

static long fsl_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
	int result = 0;
	struct fsl_dev *dev = filp->private_data;
	switch(cmd) {
	case FSL_IOC_WRITE:
		nputfsl(dev->fsl_num,arg);
		return 0;
	case FSL_IOC_READ:
		ngetfsl(dev->fsl_num,&result);
		return result;
	}
	return -ENOTTY;
}

static irqreturn_t fsl_interrupt(int irq, void *dev_id)
{	
	struct fsl_dev *dev = dev_id;
	dev->irq_count++;
	// TODO: handle concurrency!
	PDEBUG("IRQ:%d\n",irq);
	wake_up_interruptible(&dev->read_queue);
	disable_irq_nosync(irq); // since interrupt is active high, we must suppress it until all data is read
	dev->irq_enabled = 0;
	return IRQ_HANDLED;
}

static struct file_operations fsl_fops __read_mostly = {
	.owner		=	THIS_MODULE,
	.unlocked_ioctl	=	fsl_ioctl,
	.read		=	fsl_read,
	.write		=	fsl_write,
	.open		=	fsl_open,
};

static void fsl_setup_dev(struct fsl_dev *dev, int index)
{
	int err;
	size_t nlen = 128;

	dev->irq = fsl_interrupts[index];
	if(dev->irq == -1)
		return;

	err = request_irq(dev->irq, fsl_interrupt, 0, "fsl", dev);
	if (err) {
		printk(KERN_WARNING "fsl: can't get assigned IRQ 0\n");
		dev->irq = -1;
		return;
	}
	
	dev->mdev.minor = MISC_DYNAMIC_MINOR;
	dev->mdev.fops = &fsl_fops;
	dev->mdev.name = kzalloc(nlen, GFP_KERNEL);
	if (err) {
		printk(KERN_WARNING "fsl: no mem left!\n");
		goto out;
	}

	snprintf((char *) dev->mdev.name, nlen - 1, "fsl%d", index);
	err = misc_register(&dev->mdev);
	if (err) {
		printk(KERN_WARNING "fsl: can't register miscdev%i\n", index);
		goto out_free;
	}

	init_waitqueue_head(&dev->read_queue);
	dev->irq_enabled = 1;

	printk(KERN_INFO "fsl: registered fsl%d irq %d\n", index, dev->irq);
	return;
out_free:
	kfree(dev->mdev.name);
out:
	free_irq(dev->irq, dev);
	return;
}

static void fsl_remove_dev(struct fsl_dev *dev, int index)
{
	if (dev->irq == -1)
		return;
	free_irq(dev->irq, dev);
	misc_deregister(&dev->mdev);
	kfree(dev->mdev.name);
}

int __init fsl_init(void)
{
	int i;
	for (i = 0; i < FSL_MAX; i++)
		fsl_setup_dev(&dev_array[i], i);
	return 0;
}

void __exit fsl_cleanup(void)
{
	int i;
	for (i = 0; i < FSL_MAX; i++)
		fsl_remove_dev(&dev_array[i], i);
}

module_init(fsl_init);
module_exit(fsl_cleanup);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Andreas Agne <agne@upb.de>");
MODULE_AUTHOR("Daniel Borkmann <daniel.borkmann@tik.ee.ethz.ch>");
MODULE_PARM_DESC(fsl_interrupts, "FSL interrupts in use (FSL0 to FSL15)");
