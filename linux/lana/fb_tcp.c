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

enum {
	TCP_ESTABLISHED = 1,
	TCP_SYN_SENT,
	TCP_SYN_RECV,
	TCP_FIN_WAIT1,
	TCP_FIN_WAIT2,
	TCP_TIME_WAIT,
	TCP_CLOSE,
	TCP_CLOSE_WAIT,
	TCP_LAST_ACK,
	TCP_LISTEN,
	TCP_CLOSING
};

struct tcphdr {
	uint16_t source;
	uint16_t dest;
	uint32_t seq;
	uint32_t ack_seq;
#if defined(__LITTLE_ENDIAN_BITFIELD)
	__extension__ uint16_t res1:4,
			       doff:4,
			       fin:1,
			       syn:1,
			       rst:1,
			       psh:1,
			       ack:1,
			       urg:1,
			       ece:1,
			       cwr:1;
#elif defined(__BIG_ENDIAN_BITFIELD)
	__extension__ uint16_t doff:4,
			       res1:4,
			       cwr:1,
			       ece:1,
			       urg:1,
			       ack:1,
			       psh:1,
			       rst:1,
			       syn:1,
			       fin:1;
#else
# error  "Adjust your <asm/byteorder.h> defines"
#endif  
	uint16_t window;
	uint16_t check;
	uint16_t urg_ptr;
} __attribute__((packed));

#define TCP_MAX_WSCALE	14

static __u8 fb_tcp_offer_wscale = TCP_MAX_WSCALE;

static __u32 fb_tcp_def_prev_update_ratio = 3;

static unsigned int fb_tcp_default_timeout = 1000; /* In milliseconds */

struct fb_tcp_cb {
	__u32 seq, end_seq, ack_seq;
};

#define TCP_SKB_CB(skb) ((struct fb_tcp_cb *) (SKB_CBA_LANA_INF(skb)))

struct fb_tcp_priv {
	idp_t port[2];
	seqlock_t lock;
	uint16_t own_port;
	uint16_t rem_port;
	__u32 state;
	__u32 snd_una;
	__u32 snd_nxt;
	__u16 snd_wnd;
	__u32 snd_wl1;
	__u32 snd_wl2;
	__u32 iss;
	__u32 rcv_nxt;
	__u16 rcv_wnd;
	__u16 rcv_wup;
	__u32 irs;
	__u8 rwscale, swscale;
	__u16 mss;
	__u32 tsval, tsecr;
	__u32 ack_sent, ack_missed, ack_missed_bytes;
	int sent_without_reading;
	struct sk_buff_head ofo_queue;
	struct sk_buff *send_head, *last_skb;
	struct sk_buff_head retransmit_queue;
	__u32 retransmit_timeout;
	__u32 dupack_seq, dupack_num, last_retransmit;
	__u32 seq_read;
	__u32 snd_cwnd, snd_cwnd_bytes, snd_ssthresh,
	      in_flight, in_flight_bytes;
	__u32 prev_update_ratio;
	__u32 max_rwin;
	__u32 qlen;
} ____cacheline_aligned_in_smp;

struct fb_tcp_state_machine {
	__u32 state;
	int (*run)(struct fb_tcp_priv *, struct sk_buff *);
};

#ifdef __TCP_DEBUG__
# define tcp_debug(fmt, ...)			\
	do {					\
		printk(KERN_INFO pr_fmt(fmt), ##__VA_ARGS__); \
	} while (0)
#else
# define tcp_debug(fmt, ...)
#endif

static inline unsigned char *fb_tcp_skb_data_ptr(struct sk_buff *skb)
{
	return skb->data;
}

static inline __u32 fb_tcp_skb_rwin(struct fb_tcp_priv *tp, struct sk_buff *skb)
{
	__u32 rwin = ntohs(((struct tcphdr *) fb_tcp_skb_data_ptr(skb))->window);
	return (rwin << tp->rwscale);
}

static inline __u32 fb_tcp_tp_rwin(struct fb_tcp_priv *tp)
{
	__u32 rwin = tp->rcv_wnd;
	return rwin << tp->rwscale;
}

static inline __u32 fb_tcp_tp_swin(struct fb_tcp_priv *tp)
{
	__u32 swin = tp->snd_wnd;
	return swin << tp->swscale;
}

static inline int before(__u32 seq1, __u32 seq2)
{
        return (__s32) (seq1 - seq2) < 0;
}

static inline int beforeeq(__u32 seq1, __u32 seq2)
{
        return (__s32) (seq1 - seq2) <= 0;
}

static inline int after(__u32 seq1, __u32 seq2)
{
	return (__s32) (seq2 - seq1) < 0;
}

static inline int aftereq(__u32 seq1, __u32 seq2)
{
	return (__s32) (seq2 - seq1) <= 0;
}

/* is s2 <= s1 <= s3 ? */
static inline int between(__u32 seq1, __u32 seq2, __u32 seq3)
{
	return seq3 - seq2 >= seq1 - seq2;
}

struct fb_tcp_option {
	__u8 kind, length;
	int (*callback)(struct fb_tcp_priv *tp,
			struct sk_buff *skb, __u8 *data);
};

struct fb_tcp_option_timestamp {
	__u8 kind, length;
	__u32 tsval, tsecr;
} __attribute__ ((packed));

struct fb_tcp_option_nop {
	__u8 kind;
} __attribute__ ((packed));

struct fb_tcp_option_mss {
	__u8 kind, length;
	__u16 mss;
} __attribute__ ((packed));

struct fb_tcp_option_wscale {
	__u8 kind, length;
	__u8 wscale;
} __attribute__ ((packed));

#define TCP_OPT_NOP	1
#define TCP_OPT_MSS	2
#define TCP_OPT_WSCALE	3
#define TCP_OPT_TS	8

static int fb_tcp_opt_mss(struct fb_tcp_priv *tp,
			  struct sk_buff *skb __attribute__ ((unused)),
			  __u8 *data)
{
	tp->mss = ntohs(((__u16 *) data)[0]);
	tcp_debug("%s: mss: %u\n", __func__, tp->mss);
	return 0;
}

static int fb_tcp_opt_wscale(struct fb_tcp_priv *tp,
			     struct sk_buff *skb __attribute__ ((unused)),
			     __u8 *data)
{
	if ((((struct tcphdr *) fb_tcp_skb_data_ptr(skb))->syn) &&
	    ((tp->state == TCP_SYN_SENT) || (tp->state == TCP_SYN_SENT))) {
		tp->rwscale = data[0];
		if (tp->rwscale > TCP_MAX_WSCALE)
			tp->rwscale = TCP_MAX_WSCALE;
		tp->swscale = fb_tcp_offer_wscale;
		tcp_debug("%s: rwscale: %u, swscale: %u\n", __func__,
			  tp->rwscale, tp->swscale);
	}
	return 0;
}

static int fb_tcp_opt_ts(struct fb_tcp_priv *tp,
			 struct sk_buff *skb, __u8 *data)
{
	__u32 seq = TCP_SKB_CB(skb)->seq;
	__u32 end_seq = TCP_SKB_CB(skb)->end_seq;
	__u32 packet_tsval = ntohl(((__u32 *) data)[0]);

	if (!((struct tcphdr *) fb_tcp_skb_data_ptr(skb))->ack)
		return 0;

	/* PAWS check */
	if ((tp->state == TCP_ESTABLISHED) && before(packet_tsval, tp->tsecr)) {
		tcp_debug("%s: PAWS failed: packet: seq: %u, end_seq: %u, "
			  "tsval: %u, tsecr: %u, host tsval: %u, tsecr: %u\n",
			  __func__, seq, end_seq, packet_tsval,
			  ntohl(((__u32 *) data)[1]), tp->tsval, tp->tsecr);
		return 1;
	}
	
	if (between(tp->ack_sent, seq, end_seq) ||
	    (tp->state == TCP_SYN_SENT)) {
		tp->tsecr = packet_tsval;
	} else {
		tcp_debug("%s: ack_sent: %u, seq: %u, end_seq: %u\n",
			  __func__, tp->ack_sent, seq, end_seq);
	}
	return 0;
}

static struct fb_tcp_option fb_tcp_supported_options[] = {
	[TCP_OPT_NOP] = {.kind = TCP_OPT_NOP,
			 .length = 1},
	[TCP_OPT_MSS] = {.kind = TCP_OPT_MSS,
			 .length = 4,
			 .callback = &fb_tcp_opt_mss},
	[TCP_OPT_WSCALE] = {.kind = TCP_OPT_WSCALE,
			    .length = 3,
			    .callback = &fb_tcp_opt_wscale},
	[TCP_OPT_TS] = {.kind = TCP_OPT_TS,
			.length = 10,
			.callback = &fb_tcp_opt_ts},
};

#define TCP_FLAG_SYN	0x1
#define TCP_FLAG_ACK	0x2
#define TCP_FLAG_RST	0x4
#define TCP_FLAG_PSH	0x8
#define TCP_FLAG_FIN	0x10

static inline void fb_tcp_set_state(struct fb_tcp_priv *tp, __u32 state)
{
	tcp_debug("state change: %u -> %u\n", tp->state, state);
	tp->state = state;
}

static inline int fb_tcp_skb_data_size(struct sk_buff *skb)
{
	return (int) (__u32) (TCP_SKB_CB(skb)->end_seq - TCP_SKB_CB(skb)->seq);
}

static int fb_tcp_netrx_in(const struct fblock * const fb,
			   struct sk_buff * const skb)
{
	int fdrop = 0;
	idp_t next_fb;
	unsigned int seq;
	struct tcphdr *hdr;
	struct fb_tcp_priv *fb_priv;

	fb_priv = rcu_dereference_raw(fb->private_data);
	do {
		seq = read_seqbegin(&fb_priv->lock);
		next_fb = fb_priv->port[TYPE_INGRESS];
		if (next_fb == IDP_UNKNOWN)
			fdrop = 1;
	} while (read_seqretry(&fb_priv->lock, seq));
	if (fdrop)
		goto drop;

	hdr = (struct tcphdr *) skb_pull(skb, sizeof(*hdr));
	/* blubber */

	write_next_idp_to_skb(skb, fb->idp, next_fb);
	return PPE_SUCCESS;
drop:
	kfree_skb(skb);
	return PPE_DROPPED;
}

static int fb_tcp_netrx_out(const struct fblock * const fb,
			    struct sk_buff * const skb)
{
	int fdrop = 0;
	idp_t next_fb;
	unsigned int seq;
	struct tcphdr *hdr;
	struct fb_tcp_priv *fb_priv;

	fb_priv = rcu_dereference_raw(fb->private_data);
	do {
		seq = read_seqbegin(&fb_priv->lock);
		next_fb = fb_priv->port[TYPE_EGRESS];
		if (next_fb == IDP_UNKNOWN)
			fdrop = 1;
	} while (read_seqretry(&fb_priv->lock, seq));
	if (fdrop)
		goto drop;

	hdr = (struct tcphdr *) skb_push(skb, sizeof(*hdr));
	if (!hdr)
		goto drop;

	/* blubber */

	write_next_idp_to_skb(skb, fb->idp, next_fb);
	return PPE_SUCCESS;
drop:
	kfree_skb(skb);
	return PPE_DROPPED;
}

static int fb_tcp_netrx(const struct fblock * const fb,
			struct sk_buff * const skb,
			enum path_type * const dir)
{
	int ret = PPE_SUCCESS;
	switch (*dir) {
	case TYPE_INGRESS:
		ret = fb_tcp_netrx_in(fb, skb);
		break;
	case TYPE_EGRESS:
		ret = fb_tcp_netrx_out(fb, skb);
		break;
	default:
		fblock_over_panic((struct fblock *) fb,
				  __builtin_return_address(0));
	}
	return ret;
}

static int fb_tcp_event(struct notifier_block *self, unsigned long cmd,
			void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_tcp_priv *fb_priv;

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
			printk(KERN_INFO "[tcp] src bound to %u\n", fb_priv->own_port);
		} else if (!strncmp(msg->key, "dst-port", strlen("dst-port"))) {
			fb_priv->rem_port = (uint16_t) simple_strtoul(msg->val, NULL, 10);
			printk(KERN_INFO "[tcp] dst bound to %u\n", fb_priv->rem_port);
		}
		break; }
	default:
		break;
	}

	return ret;
}

static struct fblock *fb_tcp_ctor(char *name)
{
	int ret = 0;
	struct fblock *fb;
	struct fb_tcp_priv *fb_priv;

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
	fb->netfb_rx = fb_tcp_netrx;
	fb->event_rx = fb_tcp_event;
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

static void fb_tcp_dtor(struct fblock *fb)
{
	kfree(rcu_dereference_raw(fb->private_data));
	module_put(THIS_MODULE);
}

static struct fblock_factory fb_tcp_factory = {
	.type = "ch.ethz.csg.tcp",
	.mode = MODE_DUAL,
	.ctor = fb_tcp_ctor,
	.dtor = fb_tcp_dtor,
	.owner = THIS_MODULE,
};

static int __init init_fb_tcp_module(void)
{
	return register_fblock_type(&fb_tcp_factory);
}

static void __exit cleanup_fb_tcp_module(void)
{
	synchronize_rcu();
	unregister_fblock_type(&fb_tcp_factory);
}

module_init(init_fb_tcp_module);
module_exit(cleanup_fb_tcp_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Borkmann <dborkma@tik.ee.ethz.ch>");
MODULE_AUTHOR("Evgeniy Polyakov <johnpol@2ka.mipt.ru>");
MODULE_DESCRIPTION("LANA simple TCP module");
