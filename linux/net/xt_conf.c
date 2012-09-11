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
#include <linux/kthread.h>
#include <linux/slab.h>
#include <linux/kernel.h>
#include <linux/skbuff.h>
#include <linux/wait.h>
#include <linux/poll.h>
#include <asm/uaccess.h>

#include "xt_fblock.h"

//TODO: locking for both dev files e.g. mutex

#define	FBLOCK_CONF_SET_NAME	_IOWR(MISC_MAJOR, 0, char *)

static char ei_fblock_name[FBNAMSIZ], re_fblock_name[FBNAMSIZ];
static volatile int ei_fblock_set = 0, re_fblock_set = 0;

static wait_queue_head_t wait_queue;
static struct sk_buff_head queue_to_configd;

void packet_sw_to_configd(struct sk_buff *skb)
{
	skb_queue_tail(&queue_to_configd, skb);
	wake_up_interruptible(&wait_queue);
}
EXPORT_SYMBOL(packet_sw_to_configd);

static long __conf_ioctl(struct file *file, unsigned int cmd,
			 unsigned long arg, char *dst,
			 volatile int *fblock_set)
{
	if (!capable(CAP_SYS_ADMIN))
		return -EPERM;

	switch (cmd) {
	case FBLOCK_CONF_SET_NAME:
		if (*fblock_set)
			return -EBUSY;

		memset(dst, 0 , FBNAMSIZ);
		if (copy_from_user(dst, (void __user*) arg, FBNAMSIZ) != 0)
			return -EFAULT;
		dst[FBNAMSIZ - 1] = 0;
		*fblock_set = 1;
		printk("[xt_conf] configure %s!\n", dst);
		break;
	default:
		return -EINVAL;
	}

	return 0;
}

static unsigned int re_conf_poll(struct file *file, struct poll_table_struct *wait)
{
	unsigned int mask = 0;

	poll_wait(file, &wait_queue, wait);
	if (!skb_queue_empty(&queue_to_configd))
		mask |= POLLIN | POLLRDNORM;

	return mask;
}

static ssize_t re_conf_read(struct file *file, char __user *buff, size_t len,
			    loff_t *ignore)
{
	struct sk_buff *skb;
	ssize_t slen;

	if (!capable(CAP_SYS_ADMIN))
		return -EPERM;
	if (re_fblock_set == 0)
		return -EINVAL;

	wait_event_interruptible(wait_queue, !skb_queue_empty(&queue_to_configd));

	skb = skb_dequeue(&queue_to_configd);
	if (skb == NULL)
		return -EAGAIN;

	slen = skb->len;
	/* TODO: handle non-linear data i.e. fragments */
	if (copy_to_user(buff, skb->data, skb->len))
		return -EIO;

	kfree_skb(skb);

	return slen;
}

static ssize_t re_conf_write(struct file *file, const char __user *buff,
			     size_t len, loff_t *ignore)
{
	ssize_t ret = 0;
	struct fblock *fb;
	struct lana_sock_io_args args;
	struct fblock_notifier fbn;

	if (!capable(CAP_SYS_ADMIN))
		return -EPERM;
	if (re_fblock_set == 0)
		return -EINVAL;

	fb = search_fblock_n(re_fblock_name);
	if (!fb) {
		printk("[xt_conf] no such functional block!\n");
		return -EINVAL;
	}

	args.buff = buff;
	args.len = len;

	fbn.self = fb;

	/* We let the fb handle all the rest, since there can be more
	 * than just PF_LANA fbs. Thus, it's implementation specific. */
	ret = fb->event_rx(&fbn.nb, FBLOCK_CTL_PUSH, &args);

	put_fblock(fb);

	return ret;
}

static long re_conf_ioctl(struct file *file, unsigned int cmd,
			  unsigned long arg)
{
	return __conf_ioctl(file, cmd, arg, re_fblock_name, &re_fblock_set);
}

static int re_conf_close(struct inode *i, struct file *f)
{
	re_fblock_set = 0;
	return 0;
}

static ssize_t ei_conf_read(struct file *file, char __user *buff, size_t len,
			    loff_t *ignore)
{
	ssize_t ret = -ENOTSUPP;
	struct fblock *fb;
	uint8_t *binary;

	if (!capable(CAP_SYS_ADMIN))
		return -EPERM;
	if (!ei_fblock_set || len == 0)
		return -EINVAL;

	fb = search_fblock_n(ei_fblock_name);
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
	if (!ei_fblock_set || len == 0)
		return -EINVAL;

	fb = search_fblock_n(ei_fblock_name);
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

static long ei_conf_ioctl(struct file *file, unsigned int cmd,
			  unsigned long arg)
{
	return __conf_ioctl(file, cmd, arg, ei_fblock_name, &ei_fblock_set);
}

static int ei_conf_close(struct inode *i, struct file *f)
{
	ei_fblock_set = 0;
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

static struct file_operations re_conf_fops __read_mostly = {
	.owner = THIS_MODULE,
	.read = re_conf_read,
	.write = re_conf_write,
	.poll = re_conf_poll,
	.unlocked_ioctl	= re_conf_ioctl,
	.release = re_conf_close,
};

static struct miscdevice re_conf_misc_dev __read_mostly = {
	.fops =	&re_conf_fops,
	.minor = MISC_DYNAMIC_MINOR,
	.name =	"lana_re_cfg",
};

int init_ei_conf(void)
{
	skb_queue_head_init(&queue_to_configd);
	init_waitqueue_head(&wait_queue);

	printk("[xt_conf] %d\n", FBLOCK_CONF_SET_NAME);

	return misc_register(&ei_conf_misc_dev) ||
	       misc_register(&re_conf_misc_dev);
}

void cleanup_ei_conf(void)
{
	misc_deregister(&ei_conf_misc_dev);
	misc_deregister(&re_conf_misc_dev);
}
