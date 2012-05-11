/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef XT_FBLOCK_H
#define XT_FBLOCK_H

#ifdef __KERNEL__

#include <linux/proc_fs.h>
#include <linux/if.h>
#include <linux/cpu.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/skbuff.h>
#include <linux/notifier.h>
#include <linux/radix-tree.h>
#include <linux/rcupdate.h>
#include <linux/types.h>
#include <linux/percpu.h>
#include <linux/u64_stats_sync.h>

#include "xt_vlink.h"

#define FBLOCK_FLAGS_NONE	0
#define FBLOCK_FLAGS_TRANS_IB	1	/* Inbound transistion ('loop'
					   incoming), forward outgoing */
#define FBLOCK_FLAGS_TO_HW	2	/* Send down to HW fblock */

typedef /* volatile */ __u32   idp32_t;
typedef idp32_t idp_t;

#define IDP_EXIT_PPE	0
#define IDP_UNKNOWN	IDP_EXIT_PPE

enum path_type {
        TYPE_INGRESS = 0,
#define TYPE_INGRESS		TYPE_INGRESS
        TYPE_EGRESS,
#define TYPE_EGRESS		TYPE_EGRESS
        _TYPE_MAX,
};

extern const char *path_names[];

enum fblock_mode {
	MODE_SOURCE = 0,
#define MODE_SOURCE		MODE_SOURCE
	MODE_SINK,
#define MODE_SINK		MODE_SINK
	MODE_DUAL,
#define MODE_DUAL		MODE_DUAL
};

#define NUM_TYPES		_TYPE_MAX

#define FBLOCK_BIND_IDP		0x0001
#define FBLOCK_UNBIND_IDP	0x0002
#define FBLOCK_SET_OPT		0x0003
#define FBLOCK_DOWN_PREPARE	0x0004
#define FBLOCK_DOWN		0x0005
#define FBLOCK_WAIT		0x0006	/* Must wait for other, busy fblock */
#define FBLOCK_MEM_PRESSURE	0x0007	/* Socket under memory pressure */

#endif /* __KERNEL__ */

#define FBNAMSIZ		(IFNAMSIZ*2)
#define TYPNAMSIZ		(FBNAMSIZ*2)

#ifdef __KERNEL__

extern struct proc_dir_entry *fblock_proc_dir;

struct fblock_bind_msg {
	enum path_type dir;
	idp_t idp;
};

struct fblock_opt_msg {
	char *key;
	char *val;
};

struct fblock;

struct fblock_factory {
	char type[TYPNAMSIZ];
	enum fblock_mode mode;
	struct module *owner;
	struct fblock *(*ctor)(char *name);
	void (*dtor)(struct fblock *fb);
	void (*dtor_outside_rcu)(struct fblock *fb);
} ____cacheline_aligned;

struct fblock_notifier {
	struct fblock *self;
	struct notifier_block nb;
	struct fblock_notifier *next;
	idp_t remote;
};

struct fblock_subscrib {
	struct atomic_notifier_head subscribers;
};

struct fblock_stats {
	u64 packets;
	u64 bytes;
	struct u64_stats_sync syncp;
	u32 dropped;
	u32 time;
};

struct fblock {
	char name[FBNAMSIZ];
	void *private_data;
	int (*netfb_rx)(const struct fblock * const fb,
			struct sk_buff * const skb,
			enum path_type * const dir);
	int (*event_rx)(struct notifier_block *self, unsigned long cmd,
			void *args);
	ssize_t (*linearize)(struct fblock *fb, uint8_t *binary, size_t len);
	void (*delinearize)(struct fblock *fb, uint8_t *binary, size_t len);
	struct fblock_factory *factory;
	struct fblock_notifier *notifiers;
	struct fblock_subscrib *others;
	struct rcu_head rcu;
	atomic_t refcnt;
	idp_t idp;
	volatile unsigned int flags;
	spinlock_t lock;
	struct fblock_stats __percpu *stats;
} ____cacheline_aligned;

extern void free_fblock_rcu(struct rcu_head *rp);

static inline void get_fblock(struct fblock *fb)
{
	atomic_inc(&fb->refcnt);
}

static inline void put_fblock(struct fblock *fb)
{
	if (likely(!atomic_dec_and_test(&fb->refcnt)))
		return;
	if (fb->factory) {
		if (fb->factory->dtor_outside_rcu)
			fb->factory->dtor_outside_rcu(fb);
		call_rcu(&fb->rcu, free_fblock_rcu);
	}
}

/*
 * Note: __* variants do not hold the rcu_read_lock!
 */

/* Allocate/free a new fblock object. */
extern struct fblock *alloc_fblock(gfp_t flags);
extern void kfree_fblock(struct fblock *p);

/* Initialize/cleanup a fblock object. */
extern int init_fblock(struct fblock *fb, char *name, void *priv);
extern void cleanup_fblock(struct fblock *fb);
extern void cleanup_fblock_ctor(struct fblock *fb);

/*
 * Registers a fblock object to the stack. Latter variant allocates 
 * a new unused idp, former uses a given _free_ idp.
 */
extern int register_fblock(struct fblock *p, idp_t idp);
extern int register_fblock_namespace(struct fblock *p);

/*
 * Unregisters a fblock object from the stack. Former variant does not 
 * release the idp to name mapping, latter variant frees it, too.
 */
extern void unregister_fblock(struct fblock *p);
extern void unregister_fblock_namespace(struct fblock *p);
extern void unregister_fblock_namespace_no_rcu(struct fblock *p);

extern struct radix_tree_root fblmap;

/* Caller needs to do a put_fblock() after his work is done! */
/* Called within RCU read lock! */
#define __search_fblock(idp)					\
({								\
	struct fblock *ret = radix_tree_lookup(&fblmap, idp);	\
	if (likely(ret))					\
		get_fblock(ret);				\
	ret;							\
})

/* Returns fblock object specified by idp or name. */
extern struct fblock *search_fblock(idp_t idp);
extern struct fblock *search_fblock_n(char *name);

/* Migrate state from src to dst and drop of dst states */
extern void fblock_migrate_p(struct fblock *dst, struct fblock *src);
extern void fblock_migrate_r(struct fblock *dst, struct fblock *src);

/* Notify fblock of new option. */
extern int fblock_set_option(struct fblock *fb, char *opt_string);
extern int __fblock_set_option(struct fblock *fb, char *opt_string);

/* Binds two fblock objects, increments refcount each. */
extern int fblock_bind(struct fblock *fb1, struct fblock *fb2);
extern int __fblock_bind(struct fblock *fb1, struct fblock *fb2);

/* Unbinds two fblock objects, decrements refcount each. */
extern int fblock_unbind(struct fblock *fb1, struct fblock *fb2);
extern int __fblock_unbind(struct fblock *fb1, struct fblock *fb2);

/* Lookup idp by fblock name. */
extern idp_t get_fblock_namespace_mapping(char *name);
extern idp_t __get_fblock_namespace_mapping(char *name);

/*
 * Maps existing fblock name to a new idp, can be used if object has been
 * removed via unregister_fblock.
 */
extern int change_fblock_namespace_mapping(char *name, idp_t new); 
extern int __change_fblock_namespace_mapping(char *name, idp_t new);

extern int subscribe_to_remote_fblock(struct fblock *us,
				      struct fblock *remote);
extern void unsubscribe_from_remote_fblock(struct fblock *us,
					   struct fblock *remote);

static inline void init_fblock_subscriber(struct fblock *fb,
					  struct notifier_block *nb)
{
	nb->priority = 0;
	nb->notifier_call = fb->event_rx;
	nb->next = NULL;
}

static inline void set_fblock_flag(struct fblock *fb, unsigned int flag)
{
	rcu_dereference_raw(fb)->flags |= flag;
}

static inline void unset_fblock_flag(struct fblock *fb, unsigned int flag)
{
	rcu_dereference_raw(fb)->flags &= ~flag;
}

static inline int test_fblock_flag(struct fblock *fb, unsigned int flag)
{
	return rcu_dereference_raw(fb)->flags & flag;
}

static inline void set_fblock_transition_inbound(struct fblock *fb)
{
	set_fblock_flag(fb, FBLOCK_FLAGS_TRANS_IB);
}

static inline void unset_fblock_transition_inbound(struct fblock *fb)
{
	unset_fblock_flag(fb, FBLOCK_FLAGS_TRANS_IB);
}

static inline int fblock_transition_inbound_isset(struct fblock *fb)
{
	return test_fblock_flag(fb, FBLOCK_FLAGS_TRANS_IB);
}

static inline void set_fblock_offload(struct fblock *fb)
{
	set_fblock_flag(fb, FBLOCK_FLAGS_TO_HW);
}

static inline void unset_fblock_offload(struct fblock *fb)
{
	unset_fblock_flag(fb, FBLOCK_FLAGS_TO_HW);
}

static inline int fblock_offload_isset(struct fblock *fb)
{
	return test_fblock_flag(fb, FBLOCK_FLAGS_TO_HW);
}

static inline int
fblock_register_foreign_subscriber(struct fblock *us,
				   struct notifier_block *remote)
{
	return atomic_notifier_chain_register(&rcu_dereference_raw(us->others)->subscribers,
					      remote);
}

static inline void
fblock_unregister_foreign_subscriber(struct fblock *us,
				     struct notifier_block *remote)
{
	atomic_notifier_chain_unregister(&rcu_dereference_raw(us->others)->subscribers,
					 remote);
}

static inline int notify_fblock_subscribers(struct fblock *us,
					    unsigned long cmd, void *arg)
{
	if (unlikely(!rcu_dereference_raw(us->others)))
		return -ENOENT;
	return atomic_notifier_call_chain(&rcu_dereference_raw(us->others)->subscribers,
					  cmd, arg);
}

extern int init_fblock_tables(void);
extern void cleanup_fblock_tables(void);

/* here is the address, e.g. __builtin_return_address(0) */
static inline void fblock_over_panic(struct fblock *fb, void *here)
{
	printk(KERN_EMERG "fblock_over_panic: text:%p ptr:%p idp:%u refs:%d "
			  "name:%s priv:%p fac:%p not:%p others: %p\n",
	       here, fb, fb->idp, atomic_read(&fb->refcnt), fb->name, 
	       fb->private_data, fb->factory, fb->notifiers, fb->others);
	BUG();
}

extern int register_fblock_type(struct fblock_factory *fops);
extern void unregister_fblock_type(struct fblock_factory *fops);
extern struct fblock *build_fblock_object(char *type, char *name);
extern int init_fblock_builder(void);
extern void cleanup_fblock_builder(void);

#define MARKER_TIME_MARKED_FIRST	(1 << 0)
#define MARKER_TIME_MARKED_LAST		(1 << 1)

struct sock_lana_inf {
	idp_t		idp_dst;
	idp_t		idp_src;
	__u32		flags;
	__u32		errno;
	__u32		marker;
	enum path_type	dir;
};

#define SKB_LANA_INF(skb) ((struct sock_lana_inf *) ((skb)->cb))

#define SKB_CBA_LANA_INF(skb) ((void *) ((uint8_t *) (skb)->cb + sizeof(struct sock_lana_inf)))

static inline void write_next_idp_to_skb(struct sk_buff *skb, idp_t from,
					 idp_t to)
{
	struct sock_lana_inf *sli;
	sli = SKB_LANA_INF(skb);
	sli->idp_dst = to;
	sli->idp_src = from;
}

static inline idp_t read_next_idp_from_skb(struct sk_buff *skb)
{
	return SKB_LANA_INF(skb)->idp_dst;
}

static inline void write_path_to_skb(struct sk_buff *skb, enum path_type dir)
{
	struct sock_lana_inf *sli;
	sli = SKB_LANA_INF(skb);
	sli->dir = dir;
}

static inline enum path_type read_path_from_skb(struct sk_buff *skb)
{
	return SKB_LANA_INF(skb)->dir;
}

static inline void time_mark_skb_last(struct sk_buff *skb)
{
	struct sock_lana_inf *sli = SKB_LANA_INF(skb);
	sli->marker |= MARKER_TIME_MARKED_LAST;
}

static inline int skb_is_time_marked_last(struct sk_buff *skb)
{
	return (SKB_LANA_INF(skb)->marker &
		MARKER_TIME_MARKED_LAST) == MARKER_TIME_MARKED_LAST;
}

static inline void time_mark_skb_first(struct sk_buff *skb)
{
	struct sock_lana_inf *sli = SKB_LANA_INF(skb);
	sli->marker |= MARKER_TIME_MARKED_FIRST;
}

static inline int skb_is_time_marked_first(struct sk_buff *skb)
{
	return (SKB_LANA_INF(skb)->marker &
		MARKER_TIME_MARKED_FIRST) == MARKER_TIME_MARKED_FIRST;
}

extern int init_fblock_userctl_system(void);
extern void cleanup_fblock_userctl_system(void);

#endif /* __KERNEL__ */

#define NETLINK_USERCTL 24

enum fblock_userctl_groups {
	USERCTLGRP_NONE = VLINKNLGRP_MAX, /* Reserved */
#define USERCTLGRP_NONE		USERCTLGRP_NONE
	USERCTLGRP_CONF,
#define USERCTLGRP_CONF		USERCTLGRP_CONF
	 __USERCTLGRP_MAX
};

#define USERCTLGRP_MAX		(__USERCTLGRP_MAX - 1)
#define USERCTL_BUF_LEN         1500

#define NETLINK_USERCTL_CMD_ADD			1
#define NETLINK_USERCTL_CMD_SET			2
#define NETLINK_USERCTL_CMD_RM			3
#define NETLINK_USERCTL_CMD_BIND		4
#define NETLINK_USERCTL_CMD_UNBIND		5
#define NETLINK_USERCTL_CMD_REPLACE		6
#define NETLINK_USERCTL_CMD_SUBSCRIBE		7
#define NETLINK_USERCTL_CMD_UNSUBSCRIBE		8
#define NETLINK_USERCTL_CMD_SET_TRANS		9
#define NETLINK_USERCTL_CMD_UNSET_TRANS		10
#define NETLINK_USERCTL_CMD_SET_HW		11
#define NETLINK_USERCTL_CMD_UNSET_HW		12

struct lananlmsg_add {
	char name[FBNAMSIZ];
	char type[TYPNAMSIZ];
};

struct lananlmsg_rm {
	char name[FBNAMSIZ];
};

struct lananlmsg_flags {
	char name[FBNAMSIZ];
};

struct lananlmsg_set {
	char name[FBNAMSIZ];
	/* 0-terminated string, e.g. "myip=192.168.1.111" */
	char option[USERCTL_BUF_LEN - FBNAMSIZ];
};

struct lananlmsg_tuple {
	char name1[FBNAMSIZ];
	char name2[FBNAMSIZ];
};

struct lananlmsg_replace {
	char name1[FBNAMSIZ];
	char name2[FBNAMSIZ];
	uint8_t drop_priv;
};

struct lananlmsg {
	uint32_t cmd;
	uint8_t buff[USERCTL_BUF_LEN];
};

extern int init_ei_conf(void);
extern void cleanup_ei_conf(void);

#endif /* XT_FBLOCK_H */
