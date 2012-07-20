/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 * Copyright 2012 Ariane Keller <ariane.keller@tik.ee.ethz.ch>
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/errno.h>
#include <linux/slab.h>
#include <linux/wait.h>
#include <linux/kernel.h>
#include <linux/kthread.h>

#include "xt_engine.h"
#include "reconos.h"
#include "mbox.h"

#ifndef array_size
# define array_size(x)  (sizeof(x) / sizeof((x)[0]) + __must_be_array(x))
#endif

#ifndef __must_be_array
# define __must_be_array(x)                                             \
        build_bug_on_zero(__builtin_types_compatible_p(typeof(x),       \
                                                       typeof(&x[0])))
#endif

#ifndef build_bug_on_zero
# define build_bug_on_zero(e)   (sizeof(char[1 - 2 * !!(e)]) - 1)
#endif

enum noc_hw_slots {
	C_HWT_SLOT_NR = 0,
#define C_HWT_SLOT_NR		0
	B_HWT_SLOT_NR,
#define B_HWT_SLOT_NR		1
	A_HWT_SLOT_NR,
#define A_HWT_SLOT_NR		2
	E_HWT_SLOT_NR,
#define E_HWT_SLOT_NR		3
	__MAX_HWT_SLOT_NR
#define __MAX_HWT_SLOT_NR	4
};

#define HW_TO_SW_SLOT		B_HWT_SLOT_NR
#define SW_TO_HW_SLOT		C_HWT_SLOT_NR

struct noc_slot {
	struct reconos_hwt hwt;
	struct reconos_resource res[2];
	struct mbox mb_put, mb_get;
};

static struct noc_slot noc[__MAX_HWT_SLOT_NR];

struct noc_pkt {
	u8 hw_addr_block;	/* local hardware address */
	u8 hw_addr_switch;	/* global hardware address */
	u8 priority:2,		/* range [0..3] */
	   direction:1,		/* 1 for ingress, 0 for egress */
	   latency_critical:1;	/* 1 lat. critical, 0 not latency critical */
	u32 src_idp;		/* src IDP of the packet */
	u32 dst_idp;		/* dst IDP of the packet */
	u32 payload_len;	/* payload length in bytes */
	u8* payload;		/* pointer to the actual payload */
};

static struct task_struct *thread;
static wait_queue_head_t wait_queue;

static u8 *shared_mem_h2s, *shared_mem_s2h;
static int order = 0;

static int reconos_noc_init(void)
{
	int i;

	printk(KERN_INFO "[lana] bootstraping noc (%d slots)!\n",
	       __MAX_HWT_SLOT_NR);

	reconos_init_autodetect();
	memset(noc, 0, sizeof(noc));

	reconos_proc_control_selftest();

	for (i = 0; i < array_size(noc); ++i) {
		mbox_init(&noc[i].mb_put, 2);
		mbox_init(&noc[i].mb_get, 2);

		noc[i].res[0].type = RECONOS_TYPE_MBOX;
		noc[i].res[0].ptr  = &noc[i].mb_put;	  	
	    	noc[i].res[1].type = RECONOS_TYPE_MBOX;
		noc[i].res[1].ptr  = &noc[i].mb_get;

		reconos_hwt_setresources(&noc[i].hwt, noc[i].res,
					 array_size(noc[i].res));
		reconos_hwt_create(&noc[i].hwt, i, NULL);

		printk(KERN_INFO "[lana] noc hwt slot%d up and running!\n", i);
	}

	/* FIXME: might break in some cases on 64 bit */
	shared_mem_h2s = (u8 *) __get_free_pages(GFP_KERNEL | __GFP_NOWARN,
						 order);
	mbox_put(&noc[HW_TO_SW_SLOT].mb_put, (uint32_t) shared_mem_h2s);
	printk(KERN_INFO "[lana] noc hw->sw memory %p (order%d, slot%d)\n",
	       shared_mem_h2s, order, HW_TO_SW_SLOT);

	/* FIXME: might break in some cases on 64 bit */
	shared_mem_s2h = (u8 *) __get_free_pages(GFP_KERNEL | __GFP_NOWARN,
						 order);
	mbox_put(&noc[SW_TO_HW_SLOT].mb_put, (uint32_t) shared_mem_s2h);
	printk(KERN_INFO "[lana] noc sw->hw memory %p (order%d, slot%d)\n",
	       shared_mem_s2h, order, SW_TO_HW_SLOT);

	return 0;
}

static void reconos_noc_cleanup(void)
{
	reconos_cleanup();
	free_pages((unsigned long) shared_mem_h2s, order);
	free_pages((unsigned long) shared_mem_s2h, order);

	printk(KERN_INFO "[lana] noc halted!\n");
}

static int reconos_noc_sendpkt(struct noc_pkt *npkt)
{
	/* stub */
	return 0;
}

static void reconos_noc_register_rcv_handler(void (*fcnt)(struct noc_pkt *npkt))
{
	/* stub */
}

static struct noc_pkt *skb_to_noc_pkt(struct sk_buff *skb)
{
	/* stub */
	return NULL;
}

static struct sk_buff *noc_pkt_to_skb(struct noc_pkt *npkt)
{
	/* stub */
	return NULL;
}

void enqueue_for_hw_fblock(struct sk_buff *skb, enum path_type dir)
{
	/* stub */
}

void noc_new_packet_callback(struct noc_pkt *npkt)
{
#if 0
	struct sk_buff *skb;
	enum path_type dir;

	skb = noc_pkt_to_skb(npkt);
	if (skb) {
		dir = read_path_from_skb(skb);
		engine_backlog_tail(skb, dir);
	}
#endif
}

static int hwif_worker_thread(void *arg)
{
#if 0
	struct noc_pkt *npkt;
	struct sk_buff *skb;

	while (likely(!kthread_should_stop())) {
		wait_event_interruptible(wait_queue,
					 !skb_queue_empty(&queue_to_hw));

		skb = skb_dequeue(&queue_to_hw);
		if (skb == NULL)
			continue;

		npkt = skb_to_noc_pkt(skb);
		if (npkt)
			reconos_noc_sendpkt(&noc, npkt);
	}
#endif
	return 0;
}

int init_hwif(void)
{
	int ret;

//	thread = kthread_create(hwif_worker_thread, NULL, "lana_hwif");
//	if (IS_ERR(thread)) {
//		printk(KERN_ERR "Cannot create hwif thread!\n");
//		return -EIO;
//	}

	ret = reconos_noc_init();
	if (ret) {
		printk(KERN_ERR "Cannot init reconos noc!\n");
//		kthread_stop(thread);
		return -EIO;
	}

//	reconos_noc_register_rcv_handler(&noc, noc_new_packet_callback);
	return 0;
}

void cleanup_hwif(void)
{
//	kthread_stop(thread);
	reconos_noc_cleanup();
}
