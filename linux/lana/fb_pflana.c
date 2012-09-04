/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

/* options: iface=eth0 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/notifier.h>
#include <linux/rcupdate.h>
#include <linux/seqlock.h>
#include <linux/bug.h>
#include <linux/prefetch.h>
#include <linux/atomic.h>
#include <linux/slab.h>
#include <net/sock.h>

#include "xt_fblock.h"
#include "xt_engine.h"

#define AF_LANA			27      /* For now.. */
#define PF_LANA			AF_LANA

#define LANA_PROTO_AUTO 	0	/* Auto-select if none is given */
#define LANA_PROTO_RAW  	1	/* LANA raw proto */

#define LANA_NPROTO     	2
#define MEM_PRESSURE_THRES	(130*1024)

#define SIOCLANAGETFBLOCK	(SIOCPROTOPRIVATE + 0)

struct lana_protocol {
	int protocol;
	const struct proto_ops *ops;
	struct proto *proto;
	struct module *owner;
};

struct fb_pflana_priv {
	idp_t port[2];
	seqlock_t lock;
	struct lana_sock *sock_self;
	struct sk_buff_head backlog;
	volatile int overload;
	volatile int mem_pressure;
	atomic_t backlog_used;
} ____cacheline_aligned_in_smp;

struct lana_sock {
	struct sock sk;
	struct fblock *fb;
	int ifindex;
	int bound;
};

#define PFLANA_CTL_TYPE_DATA	1
#define PFLANA_CTL_TYPE_CONF	2
struct pflana_ctl {
	uint8_t type;
};

static DEFINE_MUTEX(proto_tab_lock);

static struct lana_protocol *proto_tab[LANA_NPROTO] __read_mostly;

static int fb_pflana_netrx(const struct fblock * const fb,
			   struct sk_buff *skb,
			   enum path_type * const dir)
{
	u8 *skb_head = skb->data;
	int drop = 0, skb_len = skb->len, inuse;
	unsigned int seq;
	struct sock *sk;
	struct fb_pflana_priv *fb_priv;
	struct pflana_ctl *ctlhdr;

	fb_priv = rcu_dereference_raw(fb->private_data);

	if (*dir == TYPE_EGRESS)
		goto forward_skb;

	sk = &fb_priv->sock_self->sk;
	if (skb_shared(skb)) {
		struct sk_buff *nskb = skb_clone(skb, GFP_ATOMIC);
		if (skb_head != skb->data) {
			skb->data = skb_head;
			skb->len = skb_len;
		}
		if (nskb == NULL) {
			write_next_idp_to_skb(skb, fb->idp, IDP_UNKNOWN);
			goto out;
		}
		kfree_skb(skb);
		skb = nskb;
	}
	write_next_idp_to_skb(skb, fb->idp, IDP_UNKNOWN);
	skb_queue_tail(&fb_priv->backlog, skb);
	inuse = atomic_add_return(skb_len, &fb_priv->backlog_used);
	if (inuse > MEM_PRESSURE_THRES) {
		if (fb_priv->mem_pressure == 0) {
			int one = 1;
			fb_priv->mem_pressure = 1;
			notify_fblock_subscribers((struct fblock *) fb,
						  FBLOCK_MEM_PRESSURE, &one);
		}
	} else {
		if (fb_priv->mem_pressure == 1) {
			int zero = 0;
			fb_priv->mem_pressure = 0;
			notify_fblock_subscribers((struct fblock *) fb,
						  FBLOCK_MEM_PRESSURE, &zero);
		}
	}
out:
	return PPE_HALT;
forward_skb:
	/* Only conf data from configd passes through here ... */
	/* configd -> config -> pflana -> ... -> ethX */
	ctlhdr = (struct pflana_ctl *) skb_push(skb, sizeof(*ctlhdr));
	ctlhdr->type = PFLANA_CTL_TYPE_CONF;

	do {
		seq = read_seqbegin(&fb_priv->lock);
		write_next_idp_to_skb(skb, fb->idp, fb_priv->port[*dir]);
		if (fb_priv->port[*dir] == IDP_UNKNOWN)
			drop = 1;
	} while (read_seqretry(&fb_priv->lock, seq));
	if (drop) {
		kfree_skb(skb);
		return PPE_DROPPED;
	}

	return PPE_SUCCESS;
}

static int fb_pflana_event(struct notifier_block *self, unsigned long cmd,
			   void *args)
{
	int ret = NOTIFY_OK;
	struct fblock *fb;
	struct fb_pflana_priv *fb_priv;

	rcu_read_lock();
	fb = rcu_dereference_raw(container_of(self, struct fblock_notifier, nb)->self);
	fb_priv = rcu_dereference_raw(fb->private_data);
	rcu_read_unlock();

	switch (cmd) {
	case FBLOCK_WAIT: {
		int *overload = args;
		fb_priv->overload = !!(*overload);
		break; }
	case FBLOCK_BIND_IDP: {
		struct fblock_bind_msg *msg = args;
		printk(KERN_INFO "[fb_pflana] bind IDP in direction %d to value %d\n", msg->dir, msg->idp);
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
		if (!strncmp(msg->key, "iface", strlen("iface"))) {
			/* iface=eth0 */
			struct net_device *dev = dev_get_by_name(&init_net,
								 msg->val);
			if (dev == NULL)
				return -ENODEV;
			fb_priv->sock_self->ifindex = dev->ifindex;
			fb_priv->sock_self->bound = 1;
			dev_put(dev);
			printk(KERN_INFO "[pflana] socket bound to %s\n",
			       msg->val);
		}
		break; }
	default:
		break;
	}

	return ret;
}

static struct fblock *get_bound_fblock(struct fblock *self,
				       enum path_type dir)
{
	idp_t fbidp;
	unsigned int seq;
	struct fb_pflana_priv *fb_priv;
	fb_priv = rcu_dereference_raw(self->private_data);
	do {
		seq = read_seqbegin(&fb_priv->lock);
                fbidp = fb_priv->port[dir];
	} while (read_seqretry(&fb_priv->lock, seq));
	return search_fblock(fbidp);
}

static inline struct lana_sock *to_lana_sk(const struct sock *sk)
{
	return container_of(sk, struct lana_sock, sk);
}

static struct fblock *fb_pflana_build_fblock(char *name);

static int lana_sk_init(struct sock* sk)
{
	char name[32];
	struct lana_sock *lana = to_lana_sk(sk);
	memset(name, 0, sizeof(name));
	snprintf(name, sizeof(name), "%p", &lana->sk);
	lana->fb = fb_pflana_build_fblock(name);
	if (!lana->fb)
		return -ENOMEM;
	((struct fb_pflana_priv *) lana->fb->private_data)->sock_self = lana;
	smp_wmb();
	return 0;
}

static void fb_pflana_destroy_fblock(struct fblock *fb);

static void lana_sk_free(struct sock *sk)
{
	struct fblock *fb_bound;
	struct lana_sock *lana;
	lana = to_lana_sk(sk);
	fb_bound = get_bound_fblock(lana->fb, TYPE_INGRESS);
	if (fb_bound) {
		fblock_unbind(fb_bound, lana->fb);
		put_fblock(fb_bound);
	}
	fb_bound = get_bound_fblock(lana->fb, TYPE_EGRESS);
	if (fb_bound) {
		fblock_unbind(lana->fb, fb_bound);
		put_fblock(fb_bound);
	}
	fb_pflana_destroy_fblock(lana->fb);
}

static int lana_raw_release(struct socket *sock)
{
	struct sock *sk = sock->sk;
	if (sk) {
		sock->sk = NULL;
		sk->sk_prot->close(sk, 0);
		lana_sk_free(sk);
	}
	return 0;
}

static unsigned int lana_raw_poll(struct file *file, struct socket *sock,
				  poll_table *wait)
{
	unsigned int mask = 0;
	struct sock *sk = sock->sk;
	struct lana_sock *lana = to_lana_sk(sk);
	struct fblock *fb = lana->fb;
	struct fb_pflana_priv *fb_priv;
	printk(KERN_INFO "[fb_pflana] lana raw poll\n");

	rcu_read_lock();
	fb_priv = rcu_dereference(fb->private_data);
	rcu_read_unlock();

	poll_wait(file, sk_sleep(sk), wait);
	if (!skb_queue_empty(&fb_priv->backlog))
		mask |= POLLIN | POLLRDNORM;

	return mask;
}

static int lana_raw_sendmsg(struct kiocb *iocb, struct socket *sock,
			    struct msghdr *msg, size_t len)
{
	struct sock *sk = sock->sk;
	return sk->sk_prot->sendmsg(iocb, sk, msg, len);
}

static int lana_proto_sendmsg(struct kiocb *iocb, struct sock *sk,
			      struct msghdr *msg, size_t len)
{
	int err, ret;
	unsigned int seq;
	struct net *net = sock_net(sk);
	struct net_device *dev = NULL;
	struct sk_buff *skb;
	struct lana_sock *lana = to_lana_sk(sk);
	struct fblock *fb = lana->fb;
	struct fb_pflana_priv *fb_priv;
	struct pflana_ctl *ctlhdr;
//	printk(KERN_INFO "[fb_pflana] lana_proto_sendmsg\n");

	if (lana->bound == 0){
//		printk(KERN_INFO "[fb_pflana] not bound, returning -EINVAL\n");
		return -EINVAL;
	}
	rcu_read_lock();
	fb_priv = rcu_dereference(fb->private_data);
	rcu_read_unlock();
	lock_sock(sk);
	if (sk->sk_bound_dev_if || lana->bound) {
		dev = dev_get_by_index(net, lana->bound ? lana->ifindex :
				       sk->sk_bound_dev_if);
	}
	release_sock(sk);
	if (!dev || !(dev->flags & IFF_UP) || unlikely(len > dev->mtu) ||
	    fb_priv->overload) {
		err = fb_priv->overload ? -EBUSY : -EIO;
		printk(KERN_INFO "[fb_pflana] no device found\n");		
		goto drop_put;
	}
	/* This is a big LANA fuckup! We allocate more space than we
	 * actually need, since we don't know what fbs are bound until
	 * the fb_eth. Actual len is in 'len' instead of dev->mtu */
	skb = sock_alloc_send_skb(sk, LL_ALLOCATED_SPACE(dev) + dev->mtu +
				  sizeof(*ctlhdr),
				  msg->msg_flags & MSG_DONTWAIT, &err);
	if (!skb){
		printk(KERN_INFO "[fb_pflana] no skb\n");			
		goto drop_put;
	}

	skb_reserve(skb, LL_RESERVED_SPACE(dev));
	skb_reserve(skb, dev->mtu);

	skb_reset_mac_header(skb);
	skb_reset_network_header(skb);

	err = memcpy_fromiovec((void *) skb_push(skb, len), msg->msg_iov, len);
	if (err < 0){
		printk(KERN_INFO "[fb_pflana] memcpy error\n");					
		goto drop;
	}

	/* Mark as data payload ... */
	ctlhdr = (struct pflana_ctl *) skb_push(skb, sizeof(*ctlhdr));
	ctlhdr->type = PFLANA_CTL_TYPE_DATA;

	skb->dev = dev;
	skb->sk = sk;
	skb->protocol = htons(ETH_P_ALL); //FIXME

	skb_orphan(skb);
	dev_put(dev);

	rcu_read_lock();
	do {
		seq = read_seqbegin(&fb_priv->lock);
		DEBUG(printk(KERN_INFO "[fb_pflana] next idp: %d\n", fb_priv->port[TYPE_EGRESS]));		
		write_next_idp_to_skb(skb, fb->idp,
				      fb_priv->port[TYPE_EGRESS]);
        } while (read_seqretry(&fb_priv->lock, seq));
        ret = process_packet(skb, TYPE_EGRESS);

	rcu_read_unlock();

	return (err >= 0) ? len : err;
drop:
	kfree_skb(skb);
drop_put:
	dev_put(dev);
	return err;
}

static int lana_proto_recvmsg(struct kiocb *iocb, struct sock *sk,
			      struct msghdr *msg, size_t len, int noblock,
			      int flags, int *addr_len)
{
	int err = 0;
	struct sk_buff *skb;
	size_t copied = 0;
	struct lana_sock *lana = to_lana_sk(sk);
	struct fblock *fb = lana->fb;
	struct fb_pflana_priv *fb_priv;
	//printk(KERN_INFO "[fb_pflana] lana_proto_recvmsg\n");

	rcu_read_lock();
	fb_priv = rcu_dereference(fb->private_data);
	rcu_read_unlock();
//	do {
		skb = skb_dequeue(&fb_priv->backlog);
//	} while (!skb);
	if (!skb){
	//	printk(KERN_INFO "[fb_pflana] dequeue failed\n");
		return -EAGAIN;
	}
	atomic_sub(skb->len, &fb_priv->backlog_used);

	msg->msg_namelen = 0;
	if (addr_len)
		*addr_len = msg->msg_namelen;
	copied = skb->len;
	if (len < copied) {
		msg->msg_flags |= MSG_TRUNC;
		copied = len;
	}
	err = skb_copy_datagram_iovec(skb, 0, msg->msg_iov, copied);
	if (err == 0)
		sock_recv_ts_and_drops(msg, sk, skb);
	skb_free_datagram(sk, skb);

	return err ? : copied;
}

static int lana_proto_backlog_rcv(struct sock *sk, struct sk_buff *skb)
{
	int err = -EPROTONOSUPPORT;
	kfree_skb(skb);
	return err ? NET_RX_DROP : NET_RX_SUCCESS;
}

static void lana_proto_destruct(struct sock *sk)
{
	skb_queue_purge(&sk->sk_receive_queue);
}

static int lana_proto_init(struct sock *sk)
{
	sk->sk_destruct = lana_proto_destruct;
	return 0;
}

static void lana_proto_close(struct sock *sk, long timeout)
{
	sk_common_release(sk);
}

static void lana_proto_hash(struct sock *sk)
{
}

static void lana_proto_unhash(struct sock *sk)
{
}

static int lana_proto_get_port(struct sock *sk, unsigned short sport)
{
	return 0;
}

static int lana_raw_ioctl(struct socket *sock, unsigned int cmd,
			  unsigned long arg)
{
	struct sock *sk = sock->sk;
	struct lana_sock *lana = to_lana_sk(sk);
	void __user *argp = (void __user *) arg;
	struct fblock *fb = lana->fb;

	if (cmd == SIOCLANAGETFBLOCK)
		return copy_to_user(argp, fb->name,
				    sizeof(fb->name)) ? -EFAULT : 0;

	return sk->sk_prot->ioctl(sk, cmd, arg);
}

static struct lana_protocol *pflana_proto_get(int proto)
{
	struct lana_protocol *ret = NULL;
	if (proto < 0 || proto >= LANA_NPROTO)
		return NULL;
	rcu_read_lock();
	ret = rcu_dereference_raw(proto_tab[proto]);
	rcu_read_unlock();
	return ret;
}

static int lana_family_create(struct net *net, struct socket *sock,
			      int protocol, int kern)
{
	struct sock *sk;
	struct lana_protocol *lp;
	struct lana_sock *ls;
	if (!net_eq(net, &init_net))
		return -EAFNOSUPPORT;
	if (protocol == LANA_PROTO_AUTO) {
		switch (sock->type) {
		case SOCK_RAW:
			if (!capable(CAP_SYS_ADMIN))
				return -EPERM;
			protocol = LANA_PROTO_RAW;
			break;
		default:
			return -EPROTONOSUPPORT;
		}
	}
	lp = pflana_proto_get(protocol);
	if (!lp)
		return -EPROTONOSUPPORT;
	sk = sk_alloc(net, PF_LANA, GFP_KERNEL, lp->proto);
	if (!sk)
		return -ENOMEM;
	if (lana_sk_init(sk) < 0) {
		sock_put(sk);
		return -ENOMEM;
	}
	sock_init_data(sock, sk);
	sock->state = SS_UNCONNECTED;
	sock->ops = lp->ops;
	sk->sk_backlog_rcv = sk->sk_prot->backlog_rcv;
	sk->sk_protocol = protocol;
	sk->sk_family = PF_LANA;
	sk->sk_type = sock->type;
	sk->sk_prot->init(sk);
	ls = to_lana_sk(sk);
	ls->bound = 0;
	return 0;
}

static const struct net_proto_family lana_family_ops = {
	.family = PF_LANA,
	.create = lana_family_create,
	.owner	= THIS_MODULE,
};

static const struct proto_ops lana_raw_ops = {
	.family	     = PF_LANA,
	.owner       = THIS_MODULE,
	.release     = lana_raw_release,
	.recvmsg     = sock_common_recvmsg,
	.sendmsg     = lana_raw_sendmsg,
	.poll	     = lana_raw_poll,
	.bind	     = sock_no_bind,
	.setsockopt  = sock_no_setsockopt,
	.getsockopt  = sock_no_getsockopt,
	.connect     = sock_no_connect,
	.socketpair  = sock_no_socketpair,
	.accept      = sock_no_accept,
	.getname     = sock_no_getname,
	.ioctl       = lana_raw_ioctl,
	.listen      = sock_no_listen,
	.shutdown    = sock_no_shutdown,
	.mmap	     = sock_no_mmap,
	.sendpage    = sock_no_sendpage,
};

static struct proto lana_proto __read_mostly = {
	.name	  	= "LANA",
	.owner	  	= THIS_MODULE,
	.obj_size 	= sizeof(struct lana_sock),
	.backlog_rcv	= lana_proto_backlog_rcv,
	.close		= lana_proto_close,
	.init		= lana_proto_init,
	.recvmsg	= lana_proto_recvmsg,
	.sendmsg	= lana_proto_sendmsg,
	.hash		= lana_proto_hash,
	.unhash		= lana_proto_unhash,
	.get_port	= lana_proto_get_port,
};

static struct lana_protocol lana_proto_raw __read_mostly = {
	.protocol = LANA_PROTO_RAW,
	.ops = &lana_raw_ops,
	.proto = &lana_proto,
	.owner = THIS_MODULE,
};

int pflana_proto_register(int proto, struct lana_protocol *lp)
{
	int err;

	if (!lp || proto < 0 || proto >= LANA_NPROTO)
		return -EINVAL;
	if (rcu_dereference_raw(proto_tab[proto]))
		return -EBUSY;
	err = proto_register(lp->proto, 1);
	if (err)
		return err;
	mutex_lock(&proto_tab_lock);
	lp->protocol = proto;
	rcu_assign_pointer(proto_tab[proto], lp);
	mutex_unlock(&proto_tab_lock);
	synchronize_rcu();
	if (lp->owner != THIS_MODULE)
		__module_get(lp->owner);
	return 0;
}
EXPORT_SYMBOL(pflana_proto_register);

void pflana_proto_unregister(struct lana_protocol *lp)
{
	if (!lp)
		return;
	if (lp->protocol < 0 || lp->protocol >= LANA_NPROTO)
		return;
	if (!rcu_dereference_raw(proto_tab[lp->protocol]))
		return;
	BUG_ON(proto_tab[lp->protocol] != lp);
	mutex_lock(&proto_tab_lock);
	rcu_assign_pointer(proto_tab[lp->protocol], NULL);
	mutex_unlock(&proto_tab_lock);
	synchronize_rcu();
	proto_unregister(lp->proto);
	if (lp->owner != THIS_MODULE)
		module_put(lp->owner);
}
EXPORT_SYMBOL(pflana_proto_unregister);

static int init_fb_pflana(void)
{
	int ret, i;
	for (i = 0; i < LANA_NPROTO; ++i)
		rcu_assign_pointer(proto_tab[i], NULL);
	ret = pflana_proto_register(LANA_PROTO_RAW, &lana_proto_raw);
	if (ret)
		return ret;
	ret = sock_register(&lana_family_ops);
	if (ret) {
		pflana_proto_unregister(&lana_proto_raw);
		return ret;
	}
	printk("PF_LANA %u loaded!\n", SIOCLANAGETFBLOCK);
	return 0;
}

static void cleanup_fb_pflana(void)
{
	int i;
	sock_unregister(PF_LANA);
	for (i = 0; i < LANA_NPROTO; ++i)
		pflana_proto_unregister(rcu_dereference_raw(proto_tab[i]));
}

static struct fblock *fb_pflana_build_fblock(char *name)
{
	int ret = 0;
	struct fblock *fb;
	struct fb_pflana_priv *fb_priv;

	fb = alloc_fblock(GFP_ATOMIC);
	if (!fb)
		return NULL;
	fb_priv = kzalloc(sizeof(*fb_priv), GFP_ATOMIC);
	if (!fb_priv)
		goto err;
	seqlock_init(&fb_priv->lock);
	fb_priv->port[0] = IDP_UNKNOWN;
	fb_priv->port[1] = IDP_UNKNOWN;
	fb_priv->overload = 0;
	fb_priv->mem_pressure = 0;
	skb_queue_head_init(&fb_priv->backlog);
	ret = init_fblock(fb, name, fb_priv);
	if (ret)
		goto err2;
	fb->netfb_rx = fb_pflana_netrx;
	fb->event_rx = fb_pflana_event;
	fb->factory = NULL;
	fb->prio = 63; //XXX
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
	fb = NULL;
	return NULL;
}

static void fb_pflana_destroy_fblock(struct fblock *fb)
{
	struct fb_pflana_priv *fb_priv = rcu_dereference_raw(fb->private_data);
	unregister_fblock_namespace_no_rcu(fb);
	cleanup_fblock(fb);
	skb_queue_purge(&fb_priv->backlog);
	kfree(fb_priv);
	kfree_fblock(fb);
	module_put(THIS_MODULE);
}

static int __init init_fb_pflana_module(void)
{
	return init_fb_pflana();
}

static void __exit cleanup_fb_pflana_module(void)
{
	synchronize_rcu();
	cleanup_fb_pflana();
}

module_init(init_fb_pflana_module);
module_exit(cleanup_fb_pflana_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Borkmann <dborkma@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("LANA PF_LANA module");
