/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/notifier.h>
#include <linux/rcupdate.h>
#include <linux/seqlock.h>
#include <linux/prefetch.h>

#include "xt_fblock.h"
#include "xt_engine.h"

struct fb_tee_priv {
	idp_t port[2];
	idp_t port_clone;
	seqlock_t lock;
} ____cacheline_aligned_in_smp;

static int fb_tee_netrx(const struct fblock * const fb,
			struct sk_buff * const skb,
			enum path_type * const dir)
{
	idp_t port_clone = 0;
	int drop = 0;
	unsigned int seq;
	struct sk_buff *cloned_skb = NULL;
	struct fb_tee_priv *fb_priv;

	fb_priv = rcu_dereference_raw(fb->private_data);
	prefetchw(skb->cb);
	do {
		seq = read_seqbegin(&fb_priv->lock);
		write_next_idp_to_skb(skb, fb->idp, fb_priv->port[*dir]);
		if (fb_priv->port[*dir] == IDP_UNKNOWN)
			drop = 1;
		if (fb_priv->port_clone != IDP_UNKNOWN)
			port_clone = fb_priv->port_clone;
	} while (read_seqretry(&fb_priv->lock, seq));
	if (port_clone != 0) {
		cloned_skb = skb_copy(skb, GFP_ATOMIC);
		if (cloned_skb) {
			write_next_idp_to_skb(cloned_skb, fb->idp, port_clone);
			engine_backlog_tail(cloned_skb, *dir);
		}
	}
	if (drop) {
		kfree_skb(skb);
		return PPE_DROPPED;
	}
	return PPE_SUCCESS;
}

static int fb_tee_event(struct notifier_block *self, unsigned long cmd,
			void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_tee_priv *fb_priv;

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

static struct fblock *fb_tee_ctor(char *name)
{
	int ret = 0;
	struct fblock *fb;
	struct fb_tee_priv __percpu *fb_priv;

	fb = alloc_fblock(GFP_ATOMIC);
	if (!fb)
		return NULL;
	fb_priv = kzalloc(sizeof(*fb_priv), GFP_ATOMIC);
	if (!fb_priv)
		goto err;
	seqlock_init(&fb_priv->lock);
	fb_priv->port[0] = IDP_UNKNOWN;
	fb_priv->port[1] = IDP_UNKNOWN;
	fb_priv->port_clone = IDP_UNKNOWN;
	ret = init_fblock(fb, name, fb_priv);
	if (ret)
		goto err2;
	fb->netfb_rx = fb_tee_netrx;
	fb->event_rx = fb_tee_event;
	ret = register_fblock_namespace(fb);
	if (ret)
		goto err3;
	__module_get(THIS_MODULE);
	return fb;
err3:
	cleanup_fblock_ctor(fb);
err2:
	kfree(fb_priv);
err:
	kfree_fblock(fb);
	return NULL;
}

static void fb_tee_dtor(struct fblock *fb)
{
	kfree(rcu_dereference_raw(fb->private_data));
	module_put(THIS_MODULE);
}

static struct fblock_factory fb_tee_factory = {
	.type = "ch.ethz.csg.tee",
	.mode = MODE_DUAL,
	.ctor = fb_tee_ctor,
	.dtor = fb_tee_dtor,
	.owner = THIS_MODULE,
};

static int __init init_fb_tee_module(void)
{
	return register_fblock_type(&fb_tee_factory);
}

static void __exit cleanup_fb_tee_module(void)
{
	synchronize_rcu();
	unregister_fblock_type(&fb_tee_factory);
}

module_init(init_fb_tee_module);
module_exit(cleanup_fb_tee_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Borkmann <dborkma@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("LANA tee module");
