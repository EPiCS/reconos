/* options: src-port=3333, dst-port=6666 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/notifier.h>
#include <linux/rcupdate.h>
#include <linux/seqlock.h>
#include <linux/prefetch.h>

#include "xt_fblock.h"
#include "xt_engine.h"

struct udphdr {
	uint16_t source;
	uint16_t dest;
	uint16_t len;
	uint16_t check;
} __attribute__((packed));

struct fb_udp_priv {
	idp_t port[2];
	seqlock_t lock;
	uint16_t own_port;
	uint16_t rem_port;
} ____cacheline_aligned_in_smp;

static int fb_udp_netrx_in(const struct fblock * const fb,
			   struct sk_buff * const skb)
{
	int fdrop = 0;
	idp_t next_fb;
	unsigned int seq;
	struct udphdr *hdr;
	struct fb_udp_priv *fb_priv;

	fb_priv = rcu_dereference_raw(fb->private_data);
	do {
		seq = read_seqbegin(&fb_priv->lock);
		next_fb = fb_priv->port[TYPE_INGRESS];
		if (next_fb == IDP_UNKNOWN)
			fdrop = 1;
	} while (read_seqretry(&fb_priv->lock, seq));
	if (fdrop)
		goto drop;

	hdr = (struct udphdr *) skb_pull(skb, sizeof(*hdr));
	if (unlikely(fb_priv->own_port != ntohl(hdr->dest)))
		goto drop;
	if (unlikely(fb_priv->rem_port != ntohl(hdr->source)))
		goto drop;

	write_next_idp_to_skb(skb, fb->idp, next_fb);
	return PPE_SUCCESS;
drop:
	kfree_skb(skb);
	return PPE_DROPPED;
}

static int fb_udp_netrx_out(const struct fblock * const fb,
			    struct sk_buff * const skb)
{
	int fdrop = 0;
	idp_t next_fb;
	unsigned int seq;
	struct udphdr *hdr;
	struct fb_udp_priv *fb_priv;

	fb_priv = rcu_dereference_raw(fb->private_data);
	do {
		seq = read_seqbegin(&fb_priv->lock);
		next_fb = fb_priv->port[TYPE_EGRESS];
		if (next_fb == IDP_UNKNOWN)
			fdrop = 1;
	} while (read_seqretry(&fb_priv->lock, seq));
	if (fdrop)
		goto drop;

	hdr = (struct udphdr *) skb_push(skb, sizeof(*hdr));
	if (!hdr)
		goto drop;

	hdr->source = htons(fb_priv->own_port);
	hdr->dest = htons(fb_priv->rem_port);
	hdr->len = htons(skb->len);
	hdr->check = 0;

	write_next_idp_to_skb(skb, fb->idp, next_fb);
	return PPE_SUCCESS;
drop:
	kfree_skb(skb);
	return PPE_DROPPED;
}

static int fb_udp_netrx(const struct fblock * const fb,
			struct sk_buff * const skb,
			enum path_type * const dir)
{
	int ret = PPE_SUCCESS;
	switch (*dir) {
	case TYPE_INGRESS:
		ret = fb_udp_netrx_in(fb, skb);
		break;
	case TYPE_EGRESS:
		ret = fb_udp_netrx_out(fb, skb);
		break;
	default:
		fblock_over_panic((struct fblock *) fb,
				  __builtin_return_address(0));
	}
	return ret;
}

static int fb_udp_event(struct notifier_block *self, unsigned long cmd,
			void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_udp_priv *fb_priv;

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
	case FBLOCK_SET_OPT: {
		struct fblock_opt_msg *msg = args;
		if (!strncmp(msg->key, "src-port", strlen("src-port"))) {
			fb_priv->own_port = (uint16_t) simple_strtoul(msg->val, NULL, 10);
			printk(KERN_INFO "[udp] src bound to %u\n", fb_priv->own_port);
		} else if (!strncmp(msg->key, "dst-port", strlen("dst-port"))) {
			fb_priv->rem_port = (uint16_t) simple_strtoul(msg->val, NULL, 10);
			printk(KERN_INFO "[udp] dst bound to %u\n", fb_priv->rem_port);
		}
		break; }
	default:
		break;
	}

	return ret;
}

static struct fblock *fb_udp_ctor(char *name)
{
	int ret = 0;
	struct fblock *fb;
	struct fb_udp_priv *fb_priv;

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
	fb->netfb_rx = fb_udp_netrx;
	fb->event_rx = fb_udp_event;
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

static void fb_udp_dtor(struct fblock *fb)
{
	kfree(rcu_dereference_raw(fb->private_data));
	module_put(THIS_MODULE);
}

static struct fblock_factory fb_udp_factory = {
	.type = "ch.ethz.csg.udp",
	.mode = MODE_DUAL,
	.ctor = fb_udp_ctor,
	.dtor = fb_udp_dtor,
	.owner = THIS_MODULE,
};

static int __init init_fb_udp_module(void)
{
	return register_fblock_type(&fb_udp_factory);
}

static void __exit cleanup_fb_udp_module(void)
{
	synchronize_rcu();
	unregister_fblock_type(&fb_udp_factory);
}

module_init(init_fb_udp_module);
module_exit(cleanup_fb_udp_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Borkmann <dborkma@tik.ee.ethz.ch>");
MODULE_AUTHOR("Evgeniy Polyakov <johnpol@2ka.mipt.ru>");
MODULE_DESCRIPTION("LANA simple UDP module");
