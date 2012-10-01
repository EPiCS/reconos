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

struct fb_dummy_priv {
	idp_t port[2];
	seqlock_t lock;
} ____cacheline_aligned_in_smp;

static ssize_t fb_dummy_linearize(struct fblock *fb, uint8_t *binary, size_t len)
{
	struct fb_dummy_priv *fb_priv;

	if (len < sizeof(struct fb_dummy_priv))
		return -ENOMEM;

	/* mem is already flat */
	fb_priv = rcu_dereference_raw(fb->private_data);
	memcpy(binary, fb_priv, sizeof(struct fb_dummy_priv));

	return sizeof(struct fb_dummy_priv);
}

static void fb_dummy_delinearize(struct fblock *fb, uint8_t *binary, size_t len)
{
	struct fb_dummy_priv *fb_priv;
	/* mem is already flat */
	fb_priv = rcu_dereference_raw(fb->private_data);
	memcpy(fb_priv, binary, sizeof(struct fb_dummy_priv));
}

static int fb_dummy_netrx(const struct fblock * const fb,
			  struct sk_buff * const skb,
			  enum path_type * const dir)
{
	int drop = 0;
//	u8 mask = 1;
	unsigned int seq;
	struct fb_dummy_priv *fb_priv;
//	int i = 0;
	fb_priv = rcu_dereference_raw(fb->private_data);
	do {
		seq = read_seqbegin(&fb_priv->lock);
		write_next_idp_to_skb(skb, fb->idp, fb_priv->port[*dir]);
		if (fb_priv->port[*dir] == IDP_UNKNOWN)
			drop = 1;
//		printk("IDP to push: %u, path: %u\n", fb_priv->port[*dir], *dir);
		//TODO: loop through payload (skb->data, skb->len) and set last bit of every byte to 1
//		for (i = 0; i < skb->len; i++){
//			skb->data[i] = skb->data[i] | mask;
//		}
	} while (read_seqretry(&fb_priv->lock, seq));
	if (drop) {
		printk(KERN_INFO "[fb_dummy] drop packet\n");
		kfree_skb(skb);
		return PPE_DROPPED;
	}

	return PPE_SUCCESS;
}

static int fb_dummy_event(struct notifier_block *self, unsigned long cmd,
			  void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_dummy_priv *fb_priv;

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

static struct fblock *fb_dummy_ctor(char *name)
{
	int ret = 0;
	struct fblock *fb;
	struct fb_dummy_priv *fb_priv;

	fb = alloc_fblock(GFP_ATOMIC);
	if (!fb)
		return NULL;
	fb_priv = kzalloc(sizeof(*fb_priv), GFP_ATOMIC);
	if (!fb_priv)
		goto err;
	seqlock_init(&fb_priv->lock);
	fb_priv->port[0] = IDP_UNKNOWN;
	fb_priv->port[1] = IDP_UNKNOWN;
	ret = init_fblock(fb, name, fb_priv);
	if (ret)
		goto err2;
	fb->netfb_rx = fb_dummy_netrx;
	fb->event_rx = fb_dummy_event;
	fb->linearize = fb_dummy_linearize;
	fb->delinearize = fb_dummy_delinearize;
	fb->prio = 10;//FIXME fb->factory->prio;
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

static void fb_dummy_dtor(struct fblock *fb)
{
	kfree(rcu_dereference_raw(fb->private_data));
	module_put(THIS_MODULE);
}

static struct fblock_factory fb_dummy_factory = {
	.type = "ch.ethz.csg.dummy",
	.mode = MODE_DUAL,
	.ctor = fb_dummy_ctor,
	.dtor = fb_dummy_dtor,
	.owner = THIS_MODULE,
	.properties = { RELIABLE },
};

static int __init init_fb_dummy_module(void)
{
	return register_fblock_type(&fb_dummy_factory);
}

static void __exit cleanup_fb_dummy_module(void)
{
	synchronize_rcu();
	unregister_fblock_type(&fb_dummy_factory);
}

module_init(init_fb_dummy_module);
module_exit(cleanup_fb_dummy_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Borkmann <dborkma@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("LANA dummy/test module");
