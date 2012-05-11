/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/rcupdate.h>
#include <linux/atomic.h>
#include <linux/types.h>
#include <linux/cpu.h>
#include <linux/spinlock.h>
#include <linux/rwlock.h>
#include <linux/slab.h>
#include <linux/proc_fs.h>
#include <linux/radix-tree.h>
#include <linux/init.h>
#include <linux/socket.h>
#include <linux/net.h>
#include <linux/skbuff.h>
#include <net/netlink.h>
#include <net/sock.h>

#include "xt_fblock.h"
#include "xt_critbit.h"

struct idp_elem {
	char name[FBNAMSIZ];
	idp_t idp;
	struct rcu_head rcu;
} ____cacheline_aligned;

static struct critbit_tree idpmap;

static struct critbit_tree fbmap;

RADIX_TREE(fblmap, GFP_ATOMIC);

static atomic64_t idp_counter;

static struct kmem_cache *fblock_cache = NULL;

extern struct proc_dir_entry *lana_proc_dir;

static struct proc_dir_entry *fblocks_proc;

const char *path_names[] = {
        "ingress",
        "egress",
};
EXPORT_SYMBOL(path_names);

static struct sock *fblock_userctl_sock = NULL;

static inline idp_t provide_new_fblock_idp(void)
{
	return (idp_t) atomic64_inc_return(&idp_counter);
}

static int register_to_fblock_namespace(char *name, idp_t val)
{
	struct idp_elem *elem;
	if (critbit_contains(&idpmap, name))
		return -EEXIST;
	elem = kzalloc(sizeof(*elem), GFP_ATOMIC);
	if (!elem)
		return -ENOMEM;
	strlcpy(elem->name, name, sizeof(elem->name));
	elem->idp = val;
	return critbit_insert(&idpmap, elem->name);
}

static void fblock_namespace_do_free_rcu(struct rcu_head *rp)
{
	struct idp_elem *p = container_of(rp, struct idp_elem, rcu);
	kfree(p);
}

static int unregister_from_fblock_namespace(char *name)
{
	int ret;
	struct idp_elem *elem;
	elem = struct_of(critbit_get(&idpmap, name), struct idp_elem);
	if (!elem)
		return -ENOENT;
	ret = critbit_delete(&idpmap, elem->name);
	if (ret)
		return ret;
	call_rcu(&elem->rcu, fblock_namespace_do_free_rcu);
	return 0;
}

/* Called within RCU read lock! */
idp_t __get_fblock_namespace_mapping(char *name)
{
	struct idp_elem *elem = struct_of(__critbit_get(&idpmap, name),
					  struct idp_elem);
	if (unlikely(!elem))
		return IDP_UNKNOWN;
	smp_rmb();
	return elem->idp;
}
EXPORT_SYMBOL_GPL(__get_fblock_namespace_mapping);

idp_t get_fblock_namespace_mapping(char *name)
{
	idp_t ret;
	rcu_read_lock();
	ret = __get_fblock_namespace_mapping(name);
	rcu_read_unlock();
	return ret;
}
EXPORT_SYMBOL_GPL(get_fblock_namespace_mapping);

/* Called within RCU read lock! */
int __change_fblock_namespace_mapping(char *name, idp_t new)
{
	struct idp_elem *elem = struct_of(__critbit_get(&idpmap, name),
					  struct idp_elem);
	if (unlikely(!elem))
		return -ENOENT;
	elem->idp = new;
	smp_wmb();
	return 0;
}
EXPORT_SYMBOL_GPL(__change_fblock_namespace_mapping);

int change_fblock_namespace_mapping(char *name, idp_t new)
{
	int ret;
	rcu_read_lock();
	ret = __change_fblock_namespace_mapping(name, new);
	rcu_read_unlock();
	return ret;
}
EXPORT_SYMBOL_GPL(change_fblock_namespace_mapping);

struct fblock *search_fblock(idp_t idp)
{
	struct fblock *ret;
	if (unlikely(idp == IDP_UNKNOWN))
		return NULL;
	rcu_read_lock();
	ret = __search_fblock(idp);
	rcu_read_unlock();
	return ret;
}
EXPORT_SYMBOL_GPL(search_fblock);

/* Note: user needs to do a put_fblock */
struct fblock *search_fblock_n(char *name)
{
	idp_t id;
	struct fblock *ret;
	if (unlikely(!name))
		return NULL;
	rcu_read_lock();
	id = __get_fblock_namespace_mapping(name);
	ret = __search_fblock(id);
	rcu_read_unlock();
	return ret;
}
EXPORT_SYMBOL_GPL(search_fblock_n);

/* opt_string must be of type "key=val" and 0-terminated */
int __fblock_set_option(struct fblock *fb, char *opt_string)
{
	int ret = 0;
	char *val = opt_string;
	struct fblock_opt_msg msg;
	/* Hack: we let the fb think that this belongs to his own chain to
	 * get the reference back to itself. */
	struct fblock_notifier fbn;

	memset(&fbn, 0, sizeof(fbn));
	memset(&msg, 0, sizeof(msg));

	msg.key = opt_string;
	while (*val != '=' && *val != '\0')
		val++;
	if (*val == '\0')
		return -EINVAL;
	val++;
	*(val - 1) = '\0';
	msg.val = val;
	fbn.self = fb;

	get_fblock(fb);
	ret = fb->event_rx(&fbn.nb, FBLOCK_SET_OPT, &msg);
	put_fblock(fb);

	return ret;
}
EXPORT_SYMBOL_GPL(__fblock_set_option);

int fblock_set_option(struct fblock *fb, char *opt_string)
{
	int ret;
	if (unlikely(!opt_string || !fb))
		return -EINVAL;
	rcu_read_lock();
	ret = __fblock_set_option(fb, opt_string);
	rcu_read_unlock();
	return ret;
}
EXPORT_SYMBOL_GPL(fblock_set_option);

/* Must already hold spin_lock */
static void fblock_update_selfref(struct fblock_notifier *head,
				  struct fblock *self)
{
	while (rcu_dereference_raw(head) != NULL) {
		rcu_assign_pointer(head->self, self);
		rcu_assign_pointer(head, head->next);
	}
}

/*
 * Migrate src to dst, both are of same type, working data is
 * transferred to dst and droped from src. src gets dsts old data,
 * so that on free, we do not need to explicitly ignore srcs
 * private data and dsts remaining data.
 */
void fblock_migrate_p(struct fblock *dst, struct fblock *src)
{
	void *priv_old;

	get_fblock(dst);
	get_fblock(src);

	rcu_assign_pointer(priv_old, dst->private_data);
	rcu_assign_pointer(dst->private_data, src->private_data);
	rcu_assign_pointer(src->private_data, priv_old);

	put_fblock(dst);
	put_fblock(src);
}
EXPORT_SYMBOL_GPL(fblock_migrate_p);

void fblock_migrate_r(struct fblock *dst, struct fblock *src)
{
	struct fblock_notifier *not_old;
	struct fblock_subscrib *sub_old;

	get_fblock(dst);
	get_fblock(src);

	spin_lock(&dst->lock);
	spin_lock(&src->lock);

	dst->idp = src->idp;
	strlcpy(dst->name, src->name, sizeof(dst->name));

	rcu_assign_pointer(not_old, dst->notifiers);
	rcu_assign_pointer(dst->notifiers, src->notifiers);
	rcu_assign_pointer(src->notifiers, not_old);

	fblock_update_selfref(dst->notifiers, dst);
	fblock_update_selfref(src->notifiers, src);

	rcu_assign_pointer(sub_old, dst->others);
	rcu_assign_pointer(dst->others, src->others);
	rcu_assign_pointer(src->others, sub_old);

	atomic_xchg(&dst->refcnt, atomic_xchg(&src->refcnt,
					      atomic_read(&dst->refcnt)));

	spin_unlock(&src->lock);
	spin_unlock(&dst->lock);

	put_fblock(dst);
	put_fblock(src);
}
EXPORT_SYMBOL_GPL(fblock_migrate_r);

/*
 * fb1 on top of fb2 in the stack
 */
int __fblock_bind(struct fblock *fb1, struct fblock *fb2)
{
	int ret;
	struct fblock_bind_msg msg;
	/* Hack: we let the fb think that this belongs to his own chain to
	 * get the reference back to itself. */
	struct fblock_notifier fbn;

	memset(&fbn, 0, sizeof(fbn));
	memset(&msg, 0, sizeof(msg));

	get_fblock(fb1);
	get_fblock(fb2);

	msg.dir = TYPE_EGRESS;
	msg.idp = fb2->idp;
	fbn.self = fb1;
	ret = fb1->event_rx(&fbn.nb, FBLOCK_BIND_IDP, &msg);
	if (ret != NOTIFY_OK) {
		put_fblock(fb1);
		put_fblock(fb2);
		return -EBUSY;
	}

	msg.dir = TYPE_INGRESS;
	msg.idp = fb1->idp;
	fbn.self = fb2;
	ret = fb2->event_rx(&fbn.nb, FBLOCK_BIND_IDP, &msg);
	if (ret != NOTIFY_OK) {
		/* Release previous binding */
		msg.dir = TYPE_EGRESS;
		msg.idp = fb2->idp;
		fbn.self = fb1;
		ret = fb1->event_rx(&fbn.nb, FBLOCK_UNBIND_IDP, &msg);
		if (ret != NOTIFY_OK)
			panic("Cannot release previously bound fblock!\n");
		put_fblock(fb1);
		put_fblock(fb2);
		return -EBUSY;
	}

	ret = subscribe_to_remote_fblock(fb1, fb2);
	if (ret) {
		__fblock_unbind(fb1, fb2);
		return -ENOMEM;
	}

	ret = subscribe_to_remote_fblock(fb2, fb1);
	if (ret) {
		__fblock_unbind(fb1, fb2);
		return -ENOMEM;
	}

	/* We don't give refcount back! */
	return 0;
}
EXPORT_SYMBOL_GPL(__fblock_bind);

int fblock_bind(struct fblock *fb1, struct fblock *fb2)
{
	int ret;
	rcu_read_lock();
	ret = __fblock_bind(fb1, fb2);
	rcu_read_unlock();
	return ret;
}
EXPORT_SYMBOL_GPL(fblock_bind);

/*
 * fb1 on top of fb2 in the stack
 */
int __fblock_unbind(struct fblock *fb1, struct fblock *fb2)
{
	int ret;
	struct fblock_bind_msg msg;
	/* Hack: we let the fb think that this belongs to his own chain to
	 * get the reference back to itself. */
	struct fblock_notifier fbn;

	/* We still have refcnt, we drop it on exit! */

	memset(&fbn, 0, sizeof(fbn));
	memset(&msg, 0, sizeof(msg));

	msg.dir = TYPE_EGRESS;
	msg.idp = fb2->idp;
	fbn.self = fb1;
	ret = fb1->event_rx(&fbn.nb, FBLOCK_UNBIND_IDP, &msg);
	if (ret != NOTIFY_OK) {
		/* We are not bound to fb2 */
		return -EBUSY;
	}

	msg.dir = TYPE_INGRESS;
	msg.idp = fb1->idp;
	fbn.self = fb2;
	ret = fb2->event_rx(&fbn.nb, FBLOCK_UNBIND_IDP, &msg);
	if (ret != NOTIFY_OK) {
		/* We are not bound to fb1, but fb1 was bound to us, so only
		 * release fb1 */
		put_fblock(fb1);
		return -EBUSY;
	}

	unsubscribe_from_remote_fblock(fb1, fb2);
	unsubscribe_from_remote_fblock(fb2, fb1);

	put_fblock(fb2);
	put_fblock(fb1);

	return 0;
}
EXPORT_SYMBOL_GPL(__fblock_unbind);

int fblock_unbind(struct fblock *fb1, struct fblock *fb2)
{
	int ret;
	rcu_read_lock();
	ret = __fblock_unbind(fb1, fb2);
	rcu_read_unlock();
	return ret;
}
EXPORT_SYMBOL_GPL(fblock_unbind);

/*
 * register_fblock is called when the idp is preknown to the
 * caller and has already been registered previously. The previous
 * registration has then called unregister_fblock to remove the 
 * fblock but to keep the namespace and idp number.
 */
int register_fblock(struct fblock *p, idp_t idp)
{
	p->idp = idp;
	return radix_tree_insert(&fblmap, idp, p);
}
EXPORT_SYMBOL_GPL(register_fblock);

/*
 * register_fblock_namespace is called when a new functional block
 * instance is registered to the system. Then, its name will be 
 * registered into the namespace and it receives a new idp number.
 */
int register_fblock_namespace(struct fblock *p)
{
	int ret;
	p->idp = provide_new_fblock_idp();
	ret = radix_tree_insert(&fblmap, p->idp, p);
	if (ret < 0)
		return ret;
	return register_to_fblock_namespace(p->name, p->idp);
}
EXPORT_SYMBOL_GPL(register_fblock_namespace);

void free_fblock_rcu(struct rcu_head *rp)
{
	struct fblock *p = container_of(rp, struct fblock, rcu);
	cleanup_fblock(p);
	kfree_fblock(p);
}
EXPORT_SYMBOL_GPL(free_fblock_rcu);

/*
 * unregister_fblock releases the functional block _only_ from the idp to
 * fblock translation table, but not from the namespace. The idp can then
 * later be reused, e.g. by another fblock.
 */
void unregister_fblock(struct fblock *p)
{
	radix_tree_delete(&fblmap, p->idp);
	put_fblock(p);
}
EXPORT_SYMBOL_GPL(unregister_fblock);

/*
 * Removes the functional block from the system along with its namespace
 * mapping.
 */
static void __unregister_fblock_namespace(struct fblock *p, int rcu)
{
	radix_tree_delete(&fblmap, p->idp);
	unregister_from_fblock_namespace(p->name);
	if (rcu)
		put_fblock(p);
}

void unregister_fblock_namespace(struct fblock *p)
{
	__unregister_fblock_namespace(p, 1);
}
EXPORT_SYMBOL_GPL(unregister_fblock_namespace);

void unregister_fblock_namespace_no_rcu(struct fblock *p)
{
	__unregister_fblock_namespace(p, 0);
}
EXPORT_SYMBOL_GPL(unregister_fblock_namespace_no_rcu);

/* If state changes on 'remote' fb, we ('us') want to be notified. */
int subscribe_to_remote_fblock(struct fblock *us, struct fblock *remote)
{
	struct fblock_notifier *fn = kmalloc(sizeof(*fn), GFP_ATOMIC);
	if (!fn)
		return -ENOMEM;
	/* hold ref */
	get_fblock(us);
	get_fblock(remote);

	spin_lock(&us->lock);
	fn->self = us;
	fn->remote = remote->idp;
	init_fblock_subscriber(us, &fn->nb);
	fn->next = rcu_dereference_raw(us->notifiers);
	rcu_assign_pointer(us->notifiers, fn);
	spin_unlock(&us->lock);

	return fblock_register_foreign_subscriber(remote,
			&rcu_dereference_raw(us->notifiers)->nb);
}
EXPORT_SYMBOL_GPL(subscribe_to_remote_fblock);

void unsubscribe_from_remote_fblock(struct fblock *us, struct fblock *remote)
{
	int found = 0;
	struct fblock_notifier *fn;

	if (unlikely(!rcu_dereference_raw(us->notifiers)))
		return;
	spin_lock(&us->lock);
	fn = rcu_dereference_raw(us->notifiers);
	if (fn->remote == remote->idp)
		rcu_assign_pointer(us->notifiers, us->notifiers->next);
	else {
		struct fblock_notifier *f1;
		while ((f1 = fn->next)) {
			if (f1->remote == remote->idp) {
				found = 1;
				fn->next = f1->next;
				fn = f1; /* free f1 */
				break;
			} else
				fn = f1;
		}
	}
	spin_unlock(&us->lock);
	if (found) {
		fblock_unregister_foreign_subscriber(remote, &fn->nb);
		kfree(fn);
	}

	/* drop ref */
	put_fblock(us);
	put_fblock(remote);
}
EXPORT_SYMBOL_GPL(unsubscribe_from_remote_fblock);

static void ctor_fblock(void *obj)
{
	struct fblock *p = obj;
	memset(p, 0, sizeof(*p));
	spin_lock_init(&p->lock);
	p->idp = IDP_UNKNOWN;
}

struct fblock *alloc_fblock(gfp_t flags)
{
	struct fblock *fb;
#ifndef __USE_KMALLOC
	fb = kmem_cache_alloc(fblock_cache, flags);
	if (likely(fb))
		__module_get(THIS_MODULE);
#else
	fb = kmalloc(sizeof(*fb), flags);
	if (fb) {
		ctor_fblock(fb);
		__module_get(THIS_MODULE);
	}
#endif
	memset(fb, 0, sizeof(*fb));
	return fb;
}
EXPORT_SYMBOL_GPL(alloc_fblock);

int init_fblock(struct fblock *fb, char *name, void *priv)
{
	spin_lock(&fb->lock);
	strlcpy(fb->name, name, sizeof(fb->name));
	rcu_assign_pointer(fb->private_data, priv);
	fb->others = kmalloc(sizeof(*(fb->others)), GFP_ATOMIC);
	if (!fb->others)
		return -ENOMEM;
	ATOMIC_INIT_NOTIFIER_HEAD(&fb->others->subscribers);
	spin_unlock(&fb->lock);
	atomic_set(&fb->refcnt, 1);
	fb->stats= alloc_percpu(struct fblock_stats);
	if (!fb->stats) {
		kfree(fb->others);
		return -ENOMEM;
	}
	return 0;
}
EXPORT_SYMBOL_GPL(init_fblock);

void kfree_fblock(struct fblock *p)
{
#ifndef __USE_KMALLOC
	kmem_cache_free(fblock_cache, p);
#else
	kfree(p);
#endif
	module_put(THIS_MODULE);
}
EXPORT_SYMBOL_GPL(kfree_fblock);

void cleanup_fblock(struct fblock *fb)
{
	notify_fblock_subscribers(fb, FBLOCK_DOWN, &fb->idp);
	if (fb->factory)
		fb->factory->dtor(fb);
	kfree(rcu_dereference_raw(fb->others));
	free_percpu(fb->stats);
}
EXPORT_SYMBOL_GPL(cleanup_fblock);

void cleanup_fblock_ctor(struct fblock *fb)
{
	kfree(rcu_dereference_raw(fb->others));
}
EXPORT_SYMBOL_GPL(cleanup_fblock_ctor);

static int procfs_fblocks(char *page, char **start, off_t offset,
			  int count, int *eof, void *data)
{
	int i, has_sub;
	off_t len = 0;
	struct fblock *fb;
	struct fblock_notifier *fn;
	long long max = atomic64_read(&idp_counter);
	u64 tpkts = 0, tbytes = 0, tdropped = 0, jiff = 0;

	rcu_read_lock();
	for (i = 0; i <= max; ++i) {
		fb = radix_tree_lookup(&fblmap, i);
		if (!fb)
			continue;
		has_sub = 0;
		tpkts = tbytes = tdropped = jiff = 0;
		len += sprintf(page + len, "%s %s %p %u %d [",
			       fb->name, fb->factory ? fb->factory->type : "vlink",
			       fb, fb->idp,
			       atomic_read(&fb->refcnt));
		fn = rcu_dereference_raw(fb->notifiers);
		while (fn) {
			len += sprintf(page + len, "%u ", fn->remote);
			rcu_assign_pointer(fn, fn->next);
			has_sub = 1;
		}
		len -= has_sub; /* remove last space */
		for_each_possible_cpu(i) {
			u64 bytes, packets;
			u32 dropped;
			unsigned int start;
			const struct fblock_stats *stats;

			stats = per_cpu_ptr(fb->stats, i);
			do {
				start = u64_stats_fetch_begin(&stats->syncp);
				bytes = stats->bytes;
				packets = stats->packets;
			} while (u64_stats_fetch_retry(&stats->syncp, start));

			dropped = stats->dropped;
			if (stats->time > 0)
				jiff = stats->time;

			tpkts += packets;
			tbytes += bytes;
			tdropped += dropped;
		}
		len += sprintf(page + len, "] %llu %llu %llu %llujf\n",
			       tpkts, tbytes, tdropped, jiff);
	}
	rcu_read_unlock();

	/* FIXME: fits in page? */
	*eof = 1;
	return len;
}

int init_fblock_tables(void)
{
	int ret = 0;

	get_critbit_cache();
	critbit_init_tree(&idpmap);
	fblock_cache = kmem_cache_create("fblock", sizeof(struct fblock),
					 0, SLAB_HWCACHE_ALIGN |
					 SLAB_MEM_SPREAD | SLAB_RECLAIM_ACCOUNT,
					 ctor_fblock);
	if (!fblock_cache)
		goto err;
	atomic64_set(&idp_counter, 0);
	fblocks_proc = create_proc_read_entry("fblocks", 0400, lana_proc_dir,
					      procfs_fblocks, NULL);
	if (!fblocks_proc)
		goto err2;
	return 0;
err2:
	kmem_cache_destroy(fblock_cache);
err:
	put_critbit_cache();
	return ret;
}
EXPORT_SYMBOL_GPL(init_fblock_tables);

void cleanup_fblock_tables(void)
{
	remove_proc_entry("fblocks", lana_proc_dir);
	put_critbit_cache();
	rcu_barrier();
	kmem_cache_destroy(fblock_cache);
}
EXPORT_SYMBOL_GPL(cleanup_fblock_tables);

int register_fblock_type(struct fblock_factory *fops)
{
	return critbit_insert(&fbmap, fops->type);
}
EXPORT_SYMBOL_GPL(register_fblock_type);

void unregister_fblock_type(struct fblock_factory *fops)
{
	critbit_delete(&fbmap, fops->type);
}
EXPORT_SYMBOL_GPL(unregister_fblock_type);

struct fblock *build_fblock_object(char *type, char *name)
{
	struct fblock *fb;
	struct fblock_factory *factory = struct_of(critbit_get(&fbmap, type),
						   struct fblock_factory);
	if (!factory) {
		printk(KERN_ERR "[lana] So such type available!\n");
		return NULL;
	}
	fb = factory->ctor(name);
	if (!fb)
		return NULL;
	fb->factory = factory;
	return fb;
}
EXPORT_SYMBOL(build_fblock_object);

int init_fblock_builder(void)
{
	get_critbit_cache();
	critbit_init_tree(&fbmap);
	return 0;
}
EXPORT_SYMBOL_GPL(init_fblock_builder);

void cleanup_fblock_builder(void)
{
	put_critbit_cache();
}
EXPORT_SYMBOL_GPL(cleanup_fblock_builder);

static int fblock_userctl_add(struct lananlmsg *lmsg)
{
	struct fblock *fb;
	struct lananlmsg_add *msg = (struct lananlmsg_add *) lmsg->buff;
	fb = search_fblock_n(msg->name);
	if (fb) {
		put_fblock(fb);
		return -EINVAL;
	}
	fb = build_fblock_object(msg->type, msg->name);
	return !fb ? -ENOMEM : 0;
}

static int fblock_userctl_set(struct lananlmsg *lmsg)
{
	int ret;
	struct fblock *fb;
	struct lananlmsg_set *msg = (struct lananlmsg_set *) lmsg->buff;
	fb = search_fblock_n(msg->name);
	if (!fb)
		return -EINVAL;
	ret = fblock_set_option(fb, msg->option);
	put_fblock(fb);
	return ret;
}

static int fblock_userctl_replace(struct lananlmsg *lmsg)
{
	int ret;
	struct fblock *fb1, *fb2;
	struct lananlmsg_replace *msg =	(struct lananlmsg_replace *) lmsg->buff;
	/*
	 * XXX: vlink blocks may not be replaced during runtime, since they
	 * are directly bound to hardware. Fuckup? Yes or no? Too many side
	 * effects. These blocks should not be changed anyway.
	 */
	fb1 = search_fblock_n(msg->name1);
	if (!fb1 || !fb1->factory)
		return -EINVAL;
	fb2 = search_fblock_n(msg->name2);
	if (!fb2 || !fb2->factory) {
		put_fblock(fb1);
		return -EINVAL;
	}
	if (atomic_read(&fb2->refcnt) > 2) {
		/* Still in use by others */
		printk(KERN_ERR "[lana] %s is still in use by others. "
		       "Drop refs first!\n", fb2->name);
		put_fblock(fb1);
		put_fblock(fb2);
		return -EBUSY;
	}
	unregister_fblock_namespace_no_rcu(fb2);
	if (!strncmp(fb1->factory->type, fb2->factory->type,
		     sizeof(fb1->factory->type)) && !msg->drop_priv)
		fblock_migrate_p(fb2, fb1);
	fblock_migrate_r(fb2, fb1);
	unregister_fblock(fb1);
	ret = register_fblock(fb2, fb2->idp);
	put_fblock(fb1);
	put_fblock(fb2);
	return ret;
}

static int fblock_userctl_subscribe(struct lananlmsg *lmsg)
{
	int ret;
	struct fblock *fb1, *fb2;
	struct lananlmsg_tuple *msg = (struct lananlmsg_tuple *) lmsg->buff;
	fb1 = search_fblock_n(msg->name1);
	if (!fb1)
		return -EINVAL;
	fb2 = search_fblock_n(msg->name2);
	if (!fb2) {
		put_fblock(fb1);
		return -EINVAL;
	}
	/*
	 * fb1 is remote block, fb2 is the one that
	 * wishes to be notified.
	 */
	ret = subscribe_to_remote_fblock(fb2, fb1);
	put_fblock(fb1);
	put_fblock(fb2);
	return ret;
}

static int fblock_userctl_unsubscribe(struct lananlmsg *lmsg)
{
	struct fblock *fb1, *fb2;
	struct lananlmsg_tuple *msg = (struct lananlmsg_tuple *) lmsg->buff;
	fb1 = search_fblock_n(msg->name1);
	if (!fb1)
		return -EINVAL;
	fb2 = search_fblock_n(msg->name2);
	if (!fb2) {
		put_fblock(fb1);
		return -EINVAL;
	}
	unsubscribe_from_remote_fblock(fb2, fb1);
	put_fblock(fb1);
	put_fblock(fb2);
	return 0;
}

static int fblock_userctl_remove(struct lananlmsg *lmsg)
{
	struct fblock *fb;
	struct lananlmsg_rm *msg = (struct lananlmsg_rm *) lmsg->buff;
	fb = search_fblock_n(msg->name);
	if (!fb)
		return -EINVAL;
	if (!fb->factory) {
		/* vlink types have no factory */
		put_fblock(fb);
		return -EINVAL;
	}
	if (atomic_read(&fb->refcnt) > 2) {
		/* Still in use by others */
		put_fblock(fb);
		return -EBUSY;
	}
	unregister_fblock_namespace(fb);
	put_fblock(fb);
	return 0;
}

static int fblock_userctl_bind(struct lananlmsg *lmsg)
{
	int ret;
	struct fblock *fb1, *fb2;
	struct lananlmsg_tuple *msg = (struct lananlmsg_tuple *) lmsg->buff;
	fb1 = search_fblock_n(msg->name1);
	if (!fb1)
		return -EINVAL;
	fb2 = search_fblock_n(msg->name2);
	if (!fb2) {
		put_fblock(fb1);
		return -EINVAL;
	}
	ret = fblock_bind(fb1, fb2);
	put_fblock(fb1);
	put_fblock(fb2);
	return ret;
}

static int fblock_userctl_unbind(struct lananlmsg *lmsg)
{
	int ret;
	struct fblock *fb1, *fb2;
	struct lananlmsg_tuple *msg = (struct lananlmsg_tuple *) lmsg->buff;
	fb1 = search_fblock_n(msg->name1);
	if (!fb1)
		return -EINVAL;
	fb2 = search_fblock_n(msg->name2);
	if (!fb2) {
		put_fblock(fb1);
		return -EINVAL;
	}
	ret = fblock_unbind(fb1, fb2);
	put_fblock(fb1);
	put_fblock(fb2);
	return ret;
}

static int __fblock_userctl_rcv(struct sk_buff *skb, struct nlmsghdr *nlh)
{
	int ret = 0;
	struct lananlmsg *lmsg;
	if (security_netlink_recv(skb, CAP_NET_ADMIN))
		return -EPERM;
	if (nlh->nlmsg_len < NLMSG_LENGTH(sizeof(struct lananlmsg)))
		return 0;
	lmsg = NLMSG_DATA(nlh);
	switch (lmsg->cmd) {
	case NETLINK_USERCTL_CMD_ADD:
		ret = fblock_userctl_add(lmsg);
		break;
	case NETLINK_USERCTL_CMD_SET:
		ret = fblock_userctl_set(lmsg);
		break;
	case NETLINK_USERCTL_CMD_REPLACE:
		ret = fblock_userctl_replace(lmsg);
		break;
	case NETLINK_USERCTL_CMD_SUBSCRIBE:
		ret = fblock_userctl_subscribe(lmsg);
		break;
	case NETLINK_USERCTL_CMD_UNSUBSCRIBE:
		ret = fblock_userctl_unsubscribe(lmsg);
		break;
	case NETLINK_USERCTL_CMD_RM:
		ret = fblock_userctl_remove(lmsg);
		break;
	case NETLINK_USERCTL_CMD_BIND:
		ret = fblock_userctl_bind(lmsg);
		break;
	case NETLINK_USERCTL_CMD_UNBIND:
		ret = fblock_userctl_unbind(lmsg);
		break;
	default:
		printk(KERN_INFO "[lana] Unknown command!\n");
		ret = -ENOENT;
		break;
	}
	return ret;
}

static void fblock_userctl_rcv(struct sk_buff *skb)
{
	netlink_rcv_skb(skb, &__fblock_userctl_rcv);
}

int init_fblock_userctl_system(void)
{
	fblock_userctl_sock = netlink_kernel_create(&init_net, NETLINK_USERCTL,
					     USERCTLGRP_MAX, fblock_userctl_rcv,
					     NULL, THIS_MODULE);
	return !fblock_userctl_sock ? -ENOMEM : 0;
}
EXPORT_SYMBOL_GPL(init_fblock_userctl_system);

void cleanup_fblock_userctl_system(void)
{
	netlink_kernel_release(fblock_userctl_sock);
}
EXPORT_SYMBOL_GPL(cleanup_fblock_userctl_system);

