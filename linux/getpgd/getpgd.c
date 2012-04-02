#include <linux/init.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/errno.h>
#include <linux/miscdevice.h>
#include <linux/sched.h>
#include <asm/uaccess.h>
#include <asm/page.h>
#include <asm/pgtable.h>

static void flush_dcache(void)
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

static ssize_t getpgd_read(struct file *filp, char __user *buf, size_t len,
			   loff_t *ignore)
{
	long res;
	unsigned long data = (unsigned long) current->mm->pgd - 0xC0000000;

	if (len != sizeof(data))
		return -EINVAL;

	res = copy_to_user(buf, &data, sizeof data);

	return res <= 0 ? -EIO : res;
}

static ssize_t getpgd_write(struct file *filp, const char __user *buf,
			    size_t len, loff_t *ignore)
{
	flush_dcache();
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
		printk(KERN_INFO "[getpgd] load failed with %d!\n", ret);
	else
		printk(KERN_INFO "[getpgd] loaded with minor %d!\n",
		       getpgd_misc_dev.minor);
	return ret;
}

static __exit void getpgd_exit(void)
{
	misc_deregister(&getpgd_misc_dev);
	printk(KERN_INFO "[getpgd] unloaded!\n");
}

module_init(getpgd_init);
module_exit(getpgd_exit);

MODULE_LICENSE("Dual BSD/GPL");
MODULE_AUTHOR("Andreas Agne <agne@upb.de>");
MODULE_AUTHOR("Daniel Borkmann <daniel.borkmann@tik.ee.ethz.ch>");
