/*
 * Copyright 2012 Andreas Agne <agne@upb.de>
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/errno.h>
#include <linux/miscdevice.h>
#include <linux/sched.h>
#include <asm/uaccess.h>
#include <asm/page.h>
#include <asm/pgtable.h>

void getpgd_flush_dcache(void)
{
	int i;
	int baseaddr, bytesize,linelen;

	// FIXME
	baseaddr = 0;
	bytesize = 64 * 1024;
	linelen  = 4 * 4;

	for (i = 0; i < bytesize; i += linelen)
		asm volatile ("wdc.flush %0, %1;" :: "d" (baseaddr), "d" (i));
}
EXPORT_SYMBOL(getpgd_flush_dcache);

unsigned long getpgd_fetch_pgd(int userland)
{
	if (userland)
		return (unsigned long) current->mm->pgd - 0xC0000000;
	else
		return (unsigned long) init_mm.pgd - 0xC0000000;
}
EXPORT_SYMBOL(getpgd_fetch_pgd);

static ssize_t getpgd_read(struct file *filp, char __user *buf, size_t len,
			   loff_t *ignore)
{
	unsigned long data = getpgd_fetch_pgd(1);

	if (len != sizeof(data))
		return -EINVAL;

	return copy_to_user(buf, &data, sizeof(data)) ? -EIO : len;
}

static ssize_t getpgd_write(struct file *filp, const char __user *buf,
			    size_t len, loff_t *ignore)
{
	getpgd_flush_dcache();
	return len;
}

static struct file_operations getpgd_fops __read_mostly = {
	.owner		=	THIS_MODULE,
	.read		=	getpgd_read,
	.write		=	getpgd_write,
};

static struct miscdevice getpgd_misc_dev __read_mostly = {
	.fops	=	&getpgd_fops,
	.minor	=	MISC_DYNAMIC_MINOR,
	.name	=	"getpgd",
};

static __init int getpgd_init(void)
{
	int ret = misc_register(&getpgd_misc_dev);
	if (ret < 0 )
		printk(KERN_INFO "[getpgd] registration failed with %d\n",
		       ret);
	else
		printk(KERN_INFO "[getpgd] registered\n");
	return ret;
}

static __exit void getpgd_exit(void)
{
	misc_deregister(&getpgd_misc_dev);
	printk(KERN_INFO "[getpgd] unregistered\n");
}

module_init(getpgd_init);
module_exit(getpgd_exit);

MODULE_LICENSE("Dual BSD/GPL");
MODULE_AUTHOR("Andreas Agne <agne@upb.de>");
MODULE_AUTHOR("Daniel Borkmann <daniel.borkmann@tik.ee.ethz.ch>");
