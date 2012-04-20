/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/errno.h>
#include <linux/miscdevice.h>
#include <linux/capability.h>
#include <linux/rcupdate.h>
#include <linux/slab.h>
#include <linux/kernel.h>
#include <asm/uaccess.h>

#include "xt_fblock.h"

static char fblock_name[FBNAMSIZ];
static volatile int fblock_set = 0;

static ssize_t ei_conf_read(struct file *file, char __user *buff, size_t len,
			    loff_t *ignore)
{
	ssize_t ret = -ENOTSUPP;
	struct fblock *fb;
	uint8_t *binary;

	if (!capable(CAP_SYS_ADMIN))
		return -EPERM;
	if (!fblock_set || len == 0)
		return -EINVAL;

	fb = search_fblock_n(fblock_name);
	if (!fb)
		return -EINVAL;

	binary = kmalloc(len, GFP_KERNEL);
	if (!binary) {
		put_fblock(fb);
		return -ENOMEM;
	}

	if (fb->linearize) {
		rcu_read_lock();
		ret = fb->linearize(fb, binary, len);
		rcu_read_unlock();
		if (copy_to_user(buff, binary, ret)) {
			ret = -EFAULT;
			goto out;
		}
	}

out:
	kfree(binary);
	put_fblock(fb);

	return ret;
}

static ssize_t ei_conf_write(struct file *file, const char __user *buff,
			     size_t len, loff_t *ignore)
{
	ssize_t ret = -ENOTSUPP;
	struct fblock *fb;
	uint8_t *binary;

	if (!capable(CAP_SYS_ADMIN))
		return -EPERM;
	if (!fblock_set || len == 0)
		return -EINVAL;

	fb = search_fblock_n(fblock_name);
	if (!fb)
		return -EINVAL;

	binary = kmalloc(len, GFP_KERNEL);
	if (!binary) {
		put_fblock(fb);
		return -ENOMEM;
	}

	if (fb->delinearize) {
		if (copy_from_user(binary, buff, len)) {
			ret = -EFAULT;
			goto out;
		}

		rcu_read_lock();
		fb->delinearize(fb, binary, len);
		rcu_read_unlock();
		ret = len;
	}

out:
	kfree(binary);
	put_fblock(fb);

	return ret;
}

#define	FBLOCK_CONF_SET_NAME	_IOWR(MISC_MAJOR, 0, char *)

static long ei_conf_ioctl(struct file *file, unsigned int cmd,
			  unsigned long arg)
{
	if (!capable(CAP_SYS_ADMIN))
		return -EPERM;

	switch (cmd) {
	case FBLOCK_CONF_SET_NAME:
		if (fblock_set)
			return -EBUSY;

		memset(fblock_name, 0 , sizeof(fblock_name));
		if (copy_from_user(fblock_name, (void __user*) arg,
				   sizeof(fblock_name)) != 0)
			return -EFAULT;
		fblock_name[sizeof(fblock_name) - 1] = 0;

		fblock_set = 1;
		break;
	default:
		return -EINVAL;
	}

	return 0;
}

static int ei_conf_close(struct inode *i, struct file *f)
{
	fblock_set = 0;
	return 0;
}

static struct file_operations ei_conf_fops __read_mostly = {
	.owner = THIS_MODULE,
	.read = ei_conf_read,
	.write = ei_conf_write,
	.unlocked_ioctl	= ei_conf_ioctl,
	.release = ei_conf_close,
};

static struct miscdevice ei_conf_misc_dev __read_mostly = {
	.fops =	&ei_conf_fops,
	.minor = MISC_DYNAMIC_MINOR,
	.name =	"lana_ei_cfg",
};

int init_ei_conf(void)
{
	return misc_register(&ei_conf_misc_dev);
}

void cleanup_ei_conf(void)
{
	misc_deregister(&ei_conf_misc_dev);
}
