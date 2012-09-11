/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

/* options: src-ip=1.1.1.1, dst-ip=1.1.1.1, proto=5 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/notifier.h>
#include <linux/rcupdate.h>
#include <linux/seqlock.h>
#include <linux/prefetch.h>

#include "xt_fblock.h"
#include "xt_engine.h"

struct ipv4hdr {
#if defined(__LITTLE_ENDIAN_BITFIELD)
	__extension__ uint8_t h_ihl:4,
			      h_version:4;
#elif defined (__BIG_ENDIAN_BITFIELD)
	__extension__ uint8_t h_version:4,
			      h_ihl:4;
#else
# error "Please fix <asm/byteorder.h>"
#endif
	uint8_t h_tos;
	uint16_t h_tot_len;
	uint16_t h_id;
	uint16_t h_frag_off;
	uint8_t h_ttl;
	uint8_t h_protocol;
	uint16_t h_check;
	uint32_t h_saddr;
	uint32_t h_daddr;
} __attribute__((packed));

struct fb_ipv4_priv {
	idp_t port[2];
	seqlock_t lock;
	uint32_t own_addr;
	uint32_t rem_addr;
	uint8_t proto;
} ____cacheline_aligned_in_smp;

static inline __u16 in_csum(__u16 *addr, unsigned int len)
{
	unsigned int nleft = len;
	__u16 *w = addr;
	unsigned int sum = 0;
	__u16 answer = 0;

	while (nleft > 1) {
		sum += *w++;
		nleft -= 2;
	}
						
	if (nleft == 1) {
		*(__u8 *)(&answer) = *(__u8 *)w;
		sum += answer;
	}
							    
	sum = (sum >> 16) + (sum & 0xffff);
	sum += (sum >> 16);
	answer = ~sum;
	return answer;
}

static int fb_ipv4_netrx_in(const struct fblock * const fb,
			    struct sk_buff * const skb)
{
	int fdrop = 0;
	idp_t next_fb;
	unsigned int seq;
	struct ipv4hdr *hdr;
	struct fb_ipv4_priv *fb_priv;

	fb_priv = rcu_dereference_raw(fb->private_data);
	do {
		seq = read_seqbegin(&fb_priv->lock);
		next_fb = fb_priv->port[TYPE_INGRESS];
		if (next_fb == IDP_UNKNOWN)
			fdrop = 1;
	} while (read_seqretry(&fb_priv->lock, seq));
	if (fdrop)
		goto drop;

	hdr = (struct ipv4hdr *) skb_pull(skb, sizeof(*hdr));
	if (unlikely(hdr->h_ihl < 5))
		goto drop;
	if (unlikely(hdr->h_version != 4))
		goto drop;

	skb_pull(skb, hdr->h_ihl * 4 - sizeof(*hdr));
	skb_trim(skb, ntohs(hdr->h_tot_len) - hdr->h_ihl * 4);

	if (unlikely(fb_priv->own_addr != ntohl(hdr->h_daddr)))
		goto drop;
	if (unlikely(fb_priv->rem_addr != ntohl(hdr->h_saddr)))
		goto drop;
	if (unlikely(fb_priv->proto != hdr->h_protocol))
		goto drop;

	write_next_idp_to_skb(skb, fb->idp, next_fb);
	return PPE_SUCCESS;
drop:
	kfree_skb(skb);
	return PPE_DROPPED;
}

static int fb_ipv4_netrx_out(const struct fblock * const fb,
			     struct sk_buff * const skb)
{
	int fdrop = 0;
	idp_t next_fb;
	unsigned int seq;
	struct ipv4hdr *hdr;
	struct fb_ipv4_priv *fb_priv;

	fb_priv = rcu_dereference_raw(fb->private_data);
	do {
		seq = read_seqbegin(&fb_priv->lock);
		next_fb = fb_priv->port[TYPE_EGRESS];
		if (next_fb == IDP_UNKNOWN)
			fdrop = 1;
	} while (read_seqretry(&fb_priv->lock, seq));
	if (fdrop)
		goto drop;

	hdr = (struct ipv4hdr *) skb_push(skb, sizeof(*hdr));
	if (!hdr)
		goto drop;

	hdr->h_saddr = htonl(fb_priv->own_addr);
	hdr->h_daddr = htonl(fb_priv->rem_addr);
	hdr->h_check = 0;
	hdr->h_tos = 0x10;
	hdr->h_tot_len = htons(skb->len);
	hdr->h_ttl = 64;
	hdr->h_id = (__u16) net_random();
	hdr->h_frag_off = htons(0x4000);
	hdr->h_version = 4;
	hdr->h_ihl = 5;
	hdr->h_protocol = fb_priv->proto;
	hdr->h_check = in_csum((__u16 *) hdr, hdr->h_ihl * 4);

	write_next_idp_to_skb(skb, fb->idp, next_fb);
	return PPE_SUCCESS;
drop:
	kfree_skb(skb);
	return PPE_DROPPED;
}

static int fb_ipv4_netrx(const struct fblock * const fb,
			 struct sk_buff * const skb,
			 enum path_type * const dir)
{
	int ret = PPE_SUCCESS;
	switch (*dir) {
	case TYPE_INGRESS:
		ret = fb_ipv4_netrx_in(fb, skb);
		break;
	case TYPE_EGRESS:
		ret = fb_ipv4_netrx_out(fb, skb);
		break;
	default:
		fblock_over_panic((struct fblock *) fb,
				  __builtin_return_address(0));
	}
	return ret;
}

static inline uint32_t fb_ipv4_num2ip(const uint32_t a1, const uint32_t a2,
				      const uint32_t a3, const uint32_t a4)
{
	uint32_t r = a1;
	r <<= 8;
	r |= a2;
	r <<= 8;
	r |= a3;
	r <<= 8;
	r |= a4;
	return r;
}

static inline uint32_t fb_ipv4_str2ip(const char *str, size_t len)
{
	int ret;
	uint32_t a1, a2, a3, a4;
	ret = sscanf(str, "%u.%u.%u.%u", &a1, &a2, &a3, &a4);
	if (ret != 4)
		return 0;
	return fb_ipv4_num2ip(a1, a2, a3, a4);
}

static int fb_ipv4_event(struct notifier_block *self, unsigned long cmd,
			 void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_ipv4_priv *fb_priv;

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
		if (!strncmp(msg->key, "src-ip", strlen("src-ip"))) {
			fb_priv->own_addr = fb_ipv4_str2ip(msg->val, strlen(msg->val));
			if (fb_priv->own_addr)
				printk(KERN_INFO "[ipv4] src bound to %s\n", msg->val);
		} else if (!strncmp(msg->key, "dst-ip", strlen("dst-ip"))) {
			fb_priv->rem_addr = fb_ipv4_str2ip(msg->val, strlen(msg->val));
			if (fb_priv->rem_addr)
				printk(KERN_INFO "[ipv4] dst bound to %s\n", msg->val);
		} else if (!strncmp(msg->key, "proto", strlen("proto"))) {
			fb_priv->proto = (uint8_t) simple_strtoul(msg->val, NULL, 10);
			printk(KERN_INFO "[ipv4] proto bound to %u\n", fb_priv->proto);
		}
		break; }
	default:
		break;
	}

	return ret;
}

static struct fblock *fb_ipv4_ctor(char *name)
{
	int ret = 0;
	struct fblock *fb;
	struct fb_ipv4_priv *fb_priv;

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
	fb->netfb_rx = fb_ipv4_netrx;
	fb->event_rx = fb_ipv4_event;
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

static void fb_ipv4_dtor(struct fblock *fb)
{
	kfree(rcu_dereference_raw(fb->private_data));
	module_put(THIS_MODULE);
}

static struct fblock_factory fb_ipv4_factory = {
	.type = "ch.ethz.csg.ipv4",
	.mode = MODE_DUAL,
	.ctor = fb_ipv4_ctor,
	.dtor = fb_ipv4_dtor,
	.owner = THIS_MODULE,
};

static int __init init_fb_ipv4_module(void)
{
	return register_fblock_type(&fb_ipv4_factory);
}

static void __exit cleanup_fb_ipv4_module(void)
{
	synchronize_rcu();
	unregister_fblock_type(&fb_ipv4_factory);
}

module_init(init_fb_ipv4_module);
module_exit(cleanup_fb_ipv4_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Borkmann <dborkma@tik.ee.ethz.ch>");
MODULE_AUTHOR("Evgeniy Polyakov <johnpol@2ka.mipt.ru>");
MODULE_DESCRIPTION("LANA simple IP module");
