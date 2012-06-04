/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <linux/kernel.h>
#include <linux/types.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/slab.h>
#include <linux/cache.h>
#include <linux/rcupdate.h>
#include <linux/atomic.h>

#include "xt_critbit.h"

typedef long intptr_t;

struct critbit_node {
	void *child[2];
	struct rcu_head rcu;
	u32 byte;
	u8 otherbits;
} ____cacheline_aligned;

struct critbit_node_cache {
	struct kmem_cache *cache;
	atomic_t refcnt;
};

static struct critbit_node_cache critbit_cache = { 0 };

static void critbit_ctor(void *obj)
{
	struct critbit_node *node = obj;
	node->child[0] = node->child[1] = NULL;
}

static inline struct critbit_node *critbit_alloc_node_aligned(gfp_t flags)
{
	struct critbit_node *cn;
#ifndef __USE_KMALLOC
	cn = kmem_cache_alloc(critbit_cache.cache, flags);
	if (likely(cn))
		__module_get(THIS_MODULE);
#else
	cn = kmalloc(sizeof(*cn), flags);
	if (likely(cn)) {
		critbit_ctor(cn);
		__module_get(THIS_MODULE);
	}
#endif
	return cn;
}

static inline void critbit_free_node(struct critbit_node *p)
{
#ifndef __USE_KMALLOC
	kmem_cache_free(critbit_cache.cache, p);
#else
	kfree(p);
#endif
	module_put(THIS_MODULE);
}

int __critbit_contains(struct critbit_tree *tree, const char *elem)
{
	const u8 *ubytes = (void *) elem;
	const size_t ulen = strlen(elem);
	u8 c, *p;
	struct critbit_node *q;
	int direction;

	if (unlikely(!rcu_read_lock_held())) {
		printk(KERN_ERR "No rcu_read_lock held!\n");
		BUG();
	}
	p = rcu_dereference_raw(tree->root);
	if (!p)
		return 0;
	while (1 & (intptr_t) p) {
		c = 0;
		q = (void *) (p - 1);
		if (q->byte < ulen)
			c = ubytes[q->byte];
		direction = (1 + (q->otherbits | c)) >> 8;
		p = rcu_dereference_raw(q->child[direction]);
	}

	return (0 == strcmp(elem, (char *) p));
}
EXPORT_SYMBOL(__critbit_contains);

int critbit_contains(struct critbit_tree *tree, const char *elem)
{
	int ret;
	rcu_read_lock();
	ret = __critbit_contains(tree, elem);
	rcu_read_unlock();
	return ret;
}
EXPORT_SYMBOL(critbit_contains);

char *__critbit_get(struct critbit_tree *tree, const char *elem)
{
	const u8 *ubytes = (void *) elem;
	const size_t ulen = strlen(elem);
	u8 c, *p;
	struct critbit_node *q;
	int direction;

	if (unlikely(!rcu_read_lock_held())) {
		printk(KERN_ERR "No rcu_read_lock held!\n");
		BUG();
	}
	p = rcu_dereference_raw(tree->root);
	if (!p)
		return NULL;
	while (1 & (intptr_t) p) {
		c = 0;
		q = (void *) (p - 1);
		if (q->byte < ulen)
			c = ubytes[q->byte];
		direction = (1 + (q->otherbits | c)) >> 8;
		p = rcu_dereference_raw(q->child[direction]);
	}

	return (0 == strcmp(elem, (char *) p)) ? (char *) p : NULL;
}
EXPORT_SYMBOL(__critbit_get);

char *critbit_get(struct critbit_tree *tree, const char *elem)
{
	char *ret;
	rcu_read_lock();
	ret = __critbit_get(tree, elem);
	rcu_read_unlock();
	return ret;
}
EXPORT_SYMBOL(critbit_get);

int __critbit_insert(struct critbit_tree *tree, char *elem)
{
	const u8 *const ubytes = (void *) elem;
	const size_t ulen = strlen(elem);
	u8 c, *p = rcu_dereference_raw(tree->root);
	u32 newbyte, newotherbits;
	struct critbit_node *q, *newnode;
	int direction, newdirection;
	void **wherep;

	if (unlikely(!IS_ALIGNED((unsigned long) elem, SMP_CACHE_BYTES))) {
		printk(KERN_ERR "[lana] Your string is not power "
		       "of two aligned!\n");
		BUG();
	}
	if (!p) {
		rcu_assign_pointer(tree->root, elem);
		return 0;
	}

	while (1 & (intptr_t) p) {
		c = 0;
		q = (void *) (p - 1);
		if (q->byte < ulen)
			c = ubytes[q->byte];
		direction = (1 + (q->otherbits | c)) >> 8;
		p = rcu_dereference_raw(q->child[direction]);
	}

	for (newbyte = 0; newbyte < ulen; ++newbyte) {
		if (p[newbyte] != ubytes[newbyte]) {
			newotherbits = p[newbyte] ^ ubytes[newbyte];
			goto different_byte_found;
		}
	}

	if (p[newbyte] != 0) {
		newotherbits = p[newbyte];
		goto different_byte_found;
	}

	return -EEXIST;

different_byte_found:
	while (newotherbits & (newotherbits - 1))
		newotherbits &= newotherbits - 1;
	newotherbits ^= 255;
	c = p[newbyte];
	newdirection = (1 + (newotherbits | c)) >> 8;
	newnode = critbit_alloc_node_aligned(GFP_ATOMIC | __GFP_ZERO);
	if (!newnode)
		return -ENOMEM;
	newnode->byte = newbyte;
	newnode->otherbits = newotherbits;
	newnode->child[1 - newdirection] = elem;

	for (wherep = &tree->root;;) {
		u8 *p = *wherep;
		if (!(1 & (intptr_t) p))
			break;
		q = (void *) (p - 1);
		if (q->byte > newbyte)
			break;
		if (q->byte == newbyte && q->otherbits > newotherbits)
			break;
		c = 0;
		if (q->byte < ulen)
			c = ubytes[q->byte];
		direction = (1 + (q->otherbits | c)) >> 8;
		wherep = q->child + direction;
	}

	newnode->child[newdirection] = *wherep;
	rcu_assign_pointer(*wherep, (void *) (1 + (char *) newnode));
	return 0;
}
EXPORT_SYMBOL(__critbit_insert);

int critbit_insert(struct critbit_tree *tree, char *elem)
{
	int ret;
	unsigned long flags;
	spin_lock_irqsave(&tree->wr_lock, flags);
	ret = __critbit_insert(tree, elem);
	spin_unlock_irqrestore(&tree->wr_lock, flags);
	return ret;
}
EXPORT_SYMBOL(critbit_insert);

static void critbit_do_free_rcu(struct rcu_head *rp)
{
	struct critbit_node *p = container_of(rp, struct critbit_node, rcu);
	critbit_free_node(p);
}

int __critbit_delete(struct critbit_tree *tree, const char *elem)
{
	const u8 *ubytes = (void *) elem;
	const size_t ulen = strlen(elem);
	u8 c, *p = rcu_dereference_raw(tree->root);
	void **wherep = &tree->root;
	void **whereq = NULL;
	struct critbit_node *q = NULL;
	int direction = 0;

	if (!p)
		return 0;
	while (1 & (intptr_t) p) {
		whereq = wherep;
		q = (void *) (p - 1);
		c = 0;
		if (q->byte < ulen)
			c = ubytes[q->byte];
		direction = (1 + (q->otherbits | c)) >> 8;
		wherep = q->child + direction;
		p = *wherep;
	}

	if (0 != strcmp(elem, (char *) p))
		return -ENOENT;
	/* Here, we could decrement a refcount to the elem. */
	if (!whereq) {
		tree->root = NULL;
		return 0;
	}

	rcu_assign_pointer(*whereq, q->child[1 - direction]);
	call_rcu(&q->rcu, critbit_do_free_rcu);
	return 0;
}
EXPORT_SYMBOL(__critbit_delete);

int critbit_delete(struct critbit_tree *tree, const char *elem)
{
	int ret;
	unsigned long flags;
	spin_lock_irqsave(&tree->wr_lock, flags);
	ret = __critbit_delete(tree, elem);
	spin_unlock_irqrestore(&tree->wr_lock, flags);
	return ret;
}
EXPORT_SYMBOL(critbit_delete);

static int critbit_node_cache_init(void)
{
	atomic_set(&critbit_cache.refcnt, 1);
	critbit_cache.cache = kmem_cache_create("critbit",
						sizeof(struct critbit_node),
						0, SLAB_HWCACHE_ALIGN |
						SLAB_MEM_SPREAD |
						SLAB_RECLAIM_ACCOUNT,
						critbit_ctor);
	if (!critbit_cache.cache)
		return -ENOMEM;
	return 0;
}

static void critbit_node_cache_destroy(void)
{
	rcu_barrier();
	kmem_cache_destroy(critbit_cache.cache);
}

void get_critbit_cache(void)
{
	if (unlikely(!atomic_read(&critbit_cache.refcnt))) {
		if (critbit_node_cache_init())
			panic("No mem left for critbit cache!\n");
	} else
		atomic_inc(&critbit_cache.refcnt);
}
EXPORT_SYMBOL(get_critbit_cache);

void put_critbit_cache(void)
{
	if (likely(!atomic_dec_and_test(&critbit_cache.refcnt)))
		return;
	critbit_node_cache_destroy();
}
EXPORT_SYMBOL(put_critbit_cache);
