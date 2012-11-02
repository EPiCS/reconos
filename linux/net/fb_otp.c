/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

/* e.g. dd if=/dev/urandom of=/proc/net/lana/fblock/fb0 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/notifier.h>
#include <linux/rcupdate.h>
#include <linux/seqlock.h>
#include <linux/prefetch.h>
#include <linux/slab.h>
#include <linux/seq_file.h>

#include "xt_fblock.h"
#include "xt_engine.h"

struct fb_otp_priv {
	idp_t port[2];
	seqlock_t lock;
	uint8_t *key;
	size_t len, off;
	rwlock_t klock;
} ____cacheline_aligned_in_smp;

static int fb_otp_netrx(const struct fblock * const fb,
			  struct sk_buff * const skb,
			  enum path_type * const dir)
{
	unsigned int seq;
	struct fb_otp_priv *fb_priv;
	size_t i;

	fb_priv = rcu_dereference_raw(fb->private_data);
	do {
		seq = read_seqbegin(&fb_priv->lock);
		write_next_idp_to_skb(skb, fb->idp, fb_priv->port[*dir]);
		if (fb_priv->port[*dir] == IDP_UNKNOWN)
			goto drop;
	} while (read_seqretry(&fb_priv->lock, seq));

	read_lock(&fb_priv->klock);
	for (i = 0; i < skb->len && fb_priv->off < fb_priv->len; i++)
		skb->data[i] = skb->data[i] ^ fb_priv->key[fb_priv->off++];
	read_unlock(&fb_priv->klock);
	if (i != skb->len)
		goto drop;

	return PPE_SUCCESS;
drop:
	printk(KERN_INFO "[fb_otp] drop packet. Out of key material?\n");
	kfree_skb(skb);
	return PPE_DROPPED;
}

static int fb_otp_event(struct notifier_block *self, unsigned long cmd,
			  void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_otp_priv *fb_priv;

	rcu_read_lock();
	fb = rcu_dereference_raw(container_of(self, struct fblock_notifier, nb)->self);
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();

	switch (cmd) {
	case FBLOCK_BIND_IDP: {
		struct fblock_bind_msg *msg = args;
		if (fb_priv->port[msg->dir] == IDP_UNKNOWN) {
			write_seqlock(&fb_priv->lock);
			fb_priv->port[msg->dir] = msg->idp;
			write_sequnlock(&fb_priv->lock);
		} else {
			ret = NOTIFY_BAD;
		}
		break; }
	case FBLOCK_UNBIND_IDP: {
		struct fblock_bind_msg *msg = args;
		if (fb_priv->port[msg->dir] == msg->idp) {
			write_seqlock(&fb_priv->lock);
			fb_priv->port[msg->dir] = IDP_UNKNOWN;
			write_sequnlock(&fb_priv->lock);
		} else {
			ret = NOTIFY_BAD;
		}
		break; }
	default:
		break;
	}

	return ret;
}

static int fb_otp_proc_show(struct seq_file *m, void *v)
{
	struct fblock *fb = (struct fblock *) m->private;
	struct fb_otp_priv *fb_priv;
	char sline[64];

	rcu_read_lock();
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();

	memset(sline, 0, sizeof(sline));

	read_lock(&fb_priv->klock);
	snprintf(sline, sizeof(sline), "%zd\n", (fb_priv->len - fb_priv->off));
	read_unlock(&fb_priv->klock);

	seq_puts(m, sline);
	return 0;
}

static int fb_otp_proc_open(struct inode *inode, struct file *file)
{
	return single_open(file, fb_otp_proc_show, PDE(inode)->data);
}

#define MAX_BUFF_SIZ	(1024 * 1024 * 100)

static ssize_t fb_otp_proc_write(struct file *file, const char __user * ubuff,
				 size_t count, loff_t * offset)
{
	uint8_t *code, *tmp = NULL;
	size_t len = MAX_BUFF_SIZ;
	struct fblock *fb = PDE(file->f_path.dentry->d_inode)->data;
	struct fb_otp_priv *fb_priv;

	if (count > MAX_BUFF_SIZ)
		return -EINVAL;
	if (count < MAX_BUFF_SIZ)
		len = count;

	rcu_read_lock();
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();

	code = vmalloc(len);
	if (!code)
		return -ENOMEM;

	if (copy_from_user(code, ubuff, len)) {
		vfree(code);
		return -EIO;
	}

	write_lock(&fb_priv->klock);
	if (fb_priv->len)
		tmp = fb_priv->key;
	fb_priv->key = code;
	fb_priv->len = len;
	fb_priv->off = 0;
	write_unlock(&fb_priv->klock);

	printk(KERN_INFO "[fb_otp] wrote new key!\n");
	if (tmp)
		vfree(tmp);
	return len;
}

static const struct file_operations fb_otp_proc_fops = {
	.owner   = THIS_MODULE,
	.open    = fb_otp_proc_open,
	.read    = seq_read,
	.llseek  = seq_lseek,
	.write   = fb_otp_proc_write,
	.release = single_release,
};

static struct fblock *fb_otp_ctor(char *name)
{
	int ret = 0;
	struct fblock *fb;
	struct fb_otp_priv *fb_priv;
	struct proc_dir_entry *fb_proc;

	fb = alloc_fblock(GFP_ATOMIC);
	if (!fb)
		return NULL;
	fb_priv = kzalloc(sizeof(*fb_priv), GFP_ATOMIC);
	if (!fb_priv)
		goto err;
	seqlock_init(&fb_priv->lock);
	rwlock_init(&fb_priv->klock);
	fb_priv->port[0] = IDP_UNKNOWN;
	fb_priv->port[1] = IDP_UNKNOWN;
	fb_priv->key = NULL;
	fb_priv->len = fb_priv->off = 0;
	ret = init_fblock(fb, name, fb_priv);
	if (ret)
		goto err2;
	fb->netfb_rx = fb_otp_netrx;
	fb->event_rx = fb_otp_event;
//	fb->linearize = fb_otp_linearize;
//	fb->delinearize = fb_otp_delinearize;
	fb_proc = proc_create_data(fb->name, 0444, fblock_proc_dir,
				   &fb_otp_proc_fops, (void *)(long) fb);
	if (!fb_proc)
		goto err3;

	ret = register_fblock_namespace(fb);
	if (ret)
		goto err4;

	__module_get(THIS_MODULE);

	return fb;
err4:
	remove_proc_entry(fb->name, fblock_proc_dir);
err3:
	cleanup_fblock_ctor(fb);
err2:
	kfree(fb_priv);
err:
	kfree_fblock(fb);
	return NULL;
}

static void fb_otp_dtor(struct fblock *fb)
{
	kfree(rcu_dereference_raw(fb->private_data));
	remove_proc_entry(fb->name, fblock_proc_dir);
	module_put(THIS_MODULE);
}

static struct fblock_factory fb_otp_factory = {
	.type = "ch.ethz.csg.otp",
	.mode = MODE_DUAL,
	.ctor = fb_otp_ctor,
	.dtor = fb_otp_dtor,
	.owner = THIS_MODULE,
	.properties = { [0] = "privacy" },
};

static int __init init_fb_otp_module(void)
{
	return register_fblock_type(&fb_otp_factory);
}

static void __exit cleanup_fb_otp_module(void)
{
	synchronize_rcu();
	unregister_fblock_type(&fb_otp_factory);
}

module_init(init_fb_otp_module);
module_exit(cleanup_fb_otp_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Borkmann <dborkma@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("LANA OTP module");
