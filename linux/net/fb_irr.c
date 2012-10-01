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
#include <linux/hrtimer.h>
#include <linux/interrupt.h>

#include "xt_fblock.h"
#include "xt_engine.h"

struct fb_irr_priv {
	idp_t port[2];
	seqlock_t lock;
	struct tasklet_hrtimer htimer;
	struct sk_buff *hold;
} ____cacheline_aligned_in_smp;

struct irr_hdr {
	uint8_t ack:1,
		psh:1,
		unused:6;
};

#define while_seqrd(fb_priv,instr) \
	{unsigned int seq; do {\
	 seq = read_seqbegin(&(fb_priv)->lock); \
	 (instr); \
	} while (read_seqretry(&(fb_priv)->lock, seq));}

#define KTSEC	(3)

static int fb_irr_netrx_ingress(const struct fblock * const fb,
				struct sk_buff * const skb)
{
	struct irr_hdr *hdr;
	struct fb_irr_priv *fb_priv;

	fb_priv = rcu_dereference_raw(fb->private_data);

	hdr = (struct irr_hdr *) skb->data;
	if (hdr->psh && !hdr->ack) {
		struct irr_hdr *ack_hdr;
		struct sk_buff *ack;

		ack = skb_copy(skb, GFP_ATOMIC);
		if (unlikely(!ack)) {
			printk("Unable to ACK packet!\n");
			return -ENOMEM;
		}

		ack_hdr = (struct irr_hdr *) ack->data;
		ack_hdr->ack = 1;
		ack_hdr->psh = 0;

		while_seqrd(fb_priv, { write_next_idp_to_skb(ack, fb->idp,
				fb_priv->port[TYPE_EGRESS]); });
		engine_backlog_tail(ack, TYPE_EGRESS);

		skb_pull(skb, sizeof(*hdr));
		while_seqrd(fb_priv, { write_next_idp_to_skb(skb, fb->idp,
				fb_priv->port[TYPE_INGRESS]); });

		return PPE_SUCCESS;
	} else if (!hdr->psh && hdr->ack) {
		tasklet_hrtimer_cancel(&fb_priv->htimer);
		kfree_skb(fb_priv->hold);
		fb_priv->hold = NULL;
		
		kfree_skb(skb);
		return PPE_DROPPED;
	} else {
		printk(KERN_INFO "[fb_irr] drop packet\n");
		kfree_skb(skb);
		return PPE_DROPPED;
	}

	return PPE_SUCCESS;
}

static enum hrtimer_restart irr_timer_handler(struct hrtimer *self)
{
	struct sk_buff *skb;
	struct tasklet_hrtimer *thr = container_of(self, struct tasklet_hrtimer, timer);
	struct fb_irr_priv *fb_priv = container_of(thr, struct fb_irr_priv, htimer);

	if (!fb_priv->hold)
		return HRTIMER_NORESTART;

	skb = skb_copy(fb_priv->hold, GFP_ATOMIC);
	if (unlikely(!skb)) {
		printk("Unable to resend packet!\n");
		return HRTIMER_NORESTART;
	}

	rcu_read_lock();
	process_packet(skb, TYPE_EGRESS);
	rcu_read_unlock();

	tasklet_hrtimer_start(thr, ktime_set(KTSEC, 0), HRTIMER_MODE_REL);
	return HRTIMER_NORESTART;
}

static int fb_irr_netrx_egress(const struct fblock * const fb,
			       struct sk_buff * const skb)
{
	struct irr_hdr *hdr;
	struct fb_irr_priv *fb_priv;

	fb_priv = rcu_dereference_raw(fb->private_data);
	if (fb_priv->hold != NULL) {
		engine_backlog_tail(skb, TYPE_EGRESS);
		return PPE_HALT_NO_REDUCE;
	}

	hdr = (struct irr_hdr *) skb_push(skb, sizeof(*hdr));
	hdr->psh = 1;
	hdr->ack = 0;

	while_seqrd(fb_priv, { write_next_idp_to_skb(skb, fb->idp,
			fb_priv->port[TYPE_EGRESS]); });

	fb_priv->hold = skb_copy(skb, GFP_ATOMIC);
	if (unlikely(!fb_priv->hold)) {
		printk("Unable to hold packet!\n");
		kfree_skb(skb);
		return PPE_DROPPED;
	}

	tasklet_hrtimer_init(&fb_priv->htimer, irr_timer_handler,
			     CLOCK_REALTIME, HRTIMER_MODE_ABS);
	tasklet_hrtimer_start(&fb_priv->htimer,
			      ktime_set(KTSEC, 0),
			      HRTIMER_MODE_REL);

	return PPE_SUCCESS;
}

static int fb_irr_netrx(const struct fblock * const fb,
			  struct sk_buff * const skb,
			  enum path_type * const dir)
{
	int ret;
	if (*dir == TYPE_INGRESS)
		ret = fb_irr_netrx_ingress(fb, skb);
	else
		ret = fb_irr_netrx_egress(fb, skb);
	return ret;
}

static int fb_irr_event(struct notifier_block *self, unsigned long cmd,
			  void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_irr_priv *fb_priv;

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

static struct fblock *fb_irr_ctor(char *name)
{
	int ret = 0;
	struct fblock *fb;
	struct fb_irr_priv *fb_priv;

	fb = alloc_fblock(GFP_ATOMIC);
	if (!fb)
		return NULL;
	fb_priv = kzalloc(sizeof(*fb_priv), GFP_ATOMIC);
	if (!fb_priv)
		goto err;
	seqlock_init(&fb_priv->lock);
	fb_priv->hold = NULL;
	fb_priv->port[0] = IDP_UNKNOWN;
	fb_priv->port[1] = IDP_UNKNOWN;
	ret = init_fblock(fb, name, fb_priv);
	if (ret)
		goto err2;
	fb->netfb_rx = fb_irr_netrx;
	fb->event_rx = fb_irr_event;
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

static void fb_irr_dtor(struct fblock *fb)
{
	struct fb_irr_priv *fb_priv;

	fb_priv = rcu_dereference_raw(fb->private_data);

	if (fb_priv->hold) {
		tasklet_hrtimer_cancel(&fb_priv->htimer);
		kfree(fb_priv->hold);
	}
	kfree(fb_priv);

	module_put(THIS_MODULE);
}

static struct fblock_factory fb_irr_factory = {
	.type = "ch.ethz.csg.irr",
	.mode = MODE_DUAL,
	.ctor = fb_irr_ctor,
	.dtor = fb_irr_dtor,
	.owner = THIS_MODULE,
	.properties = { RELIABLE },
};

static int __init init_fb_irr_module(void)
{
	return register_fblock_type(&fb_irr_factory);
}

static void __exit cleanup_fb_irr_module(void)
{
	synchronize_rcu();
	unregister_fblock_type(&fb_irr_factory);
}

module_init(init_fb_irr_module);
module_exit(cleanup_fb_irr_module);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("LANA irr/test module");
