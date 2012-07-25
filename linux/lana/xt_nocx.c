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
#include <linux/skbuff.h>
#include <linux/netdevice.h>

#include "xt_engine.h"
#include "xt_fblock.h"
#include "reconos.h"
#include "mbox.h"

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

#define DEBUG(fnt)		(fnt)

struct noc_slot {
	struct reconos_hwt hwt;
	struct reconos_resource res[2];
	struct mbox mb_put, mb_get;
};

static struct noc_slot noc[__MAX_HWT_SLOT_NR];

struct noc_pkt {
	u8 hw_addr_switch:4,
	   hw_addr_block:2,
	   priority:2;
	u8 direction:1,
	   latency_critical:1,
	   reserved:6;
	u32 src_idp;
	u32 dst_idp;
	u32 payload_len;
	u8* payload;
};

static struct task_struct *thread_hw2sw, *thread_sw2hw;
static wait_queue_head_t wait_queue;
static struct sk_buff_head queue_to_hw;
static u8 *shared_mem_h2s, *shared_mem_s2h;
static int order = 0;

void dump_npkt(struct noc_pkt *npkt)
{
	int i;
	printk(KERN_INFO "npkt packet dump ---->\n");
	printk(KERN_INFO " hw_addr_switch:%d\n", npkt->hw_addr_switch);
	printk(KERN_INFO " hw_addr_block:%d\n", npkt->hw_addr_block);
	printk(KERN_INFO " priority:%d\n", npkt->priority);
	printk(KERN_INFO " direction:%d\n", npkt->direction);
	printk(KERN_INFO " latency_critical:%d\n", npkt->latency_critical);
	printk(KERN_INFO " src_idp:%u\n", npkt->src_idp);
	printk(KERN_INFO " dst_idp:%u\n", npkt->dst_idp);
	printk(KERN_INFO " payload_len:%u\n", npkt->payload_len);
	for (i = 0; i < npkt->payload_len; ++i)
		printk(KERN_INFO " byte%d: 0x%x\n", i, (u8) npkt->payload[i]);
	printk(KERN_INFO "<---- end dump\n");
}

static inline struct noc_pkt *alloc_npkt(unsigned int size, gfp_t priority)
{
	struct noc_pkt *npkt;

	if (size == 0)
		return NULL;

	npkt = kzalloc(sizeof(*npkt), priority);
	if (!npkt)
		return NULL;
	npkt->payload = kzalloc(size, priority);
	if (!npkt->payload) {
		kfree(npkt);
		return NULL;
	}

	return npkt;
}

static inline void kfree_npkt(struct noc_pkt *npkt)
{
	if (!npkt)
		return;

	kfree(npkt->payload);
	kfree(npkt);
}

static struct noc_pkt *skb_to_noc_pkt(struct sk_buff *skb)
{
	struct noc_pkt *npkt = NULL;

	npkt = alloc_npkt(skb->len, GFP_KERNEL);
	if (npkt) {
		npkt->hw_addr_switch = 1;
		npkt->hw_addr_block = 0;
		npkt->priority = 0;
		npkt->direction = read_path_from_skb(skb);
		npkt->latency_critical = 0;
		npkt->reserved = 0;
		npkt->src_idp = read_last_idp_from_skb(skb);
		npkt->dst_idp = read_next_idp_from_skb(skb);
		npkt->payload_len = skb->len; //skb_headlen(skb);
		skb_copy_from_linear_data(skb, npkt->payload,
					  npkt->payload_len);
	}

	return npkt;
}

static struct sk_buff *noc_pkt_to_skb(struct noc_pkt *npkt)
{
	struct sk_buff *skb = NULL;
	struct net_device *dev = NULL;

	dev = dev_get_by_name(&init_net, "eth0"); //FIXME
	if (!dev)
		return NULL;

	skb = alloc_skb(npkt->payload_len + LL_ALLOCATED_SPACE(dev),
			GFP_KERNEL);
	if (skb) {
		skb_reserve(skb, LL_RESERVED_SPACE(dev));
		skb_reserve(skb, npkt->payload_len);
		memcpy(skb_push(skb, npkt->payload_len), npkt->payload,
		       npkt->payload_len);

		write_path_to_skb(skb, npkt->direction);
		write_next_idp_to_skb(skb, npkt->src_idp, npkt->dst_idp);
	}

	return skb;
}

static int noc_sendpkt(struct noc_pkt *npkt)
{
	u32 pkt_len = npkt->payload_len;
	size_t off = sizeof(*npkt) - sizeof(npkt->payload);

	DEBUG(printk(KERN_INFO "XXX: send npkt to hw:\n"));
	DEBUG(dump_npkt(npkt));

	memcpy(shared_mem_s2h, npkt, off);
	memcpy(shared_mem_s2h + off, npkt->payload, pkt_len);

	mbox_put(&noc[SW_TO_HW_SLOT].mb_put, pkt_len);

	return 0;
}

void packet_sw_to_hw(struct sk_buff *skb, enum path_type dir)
{
	write_path_to_skb(skb, dir);
	skb_queue_tail(&queue_to_hw, skb);
	wake_up_interruptible(&wait_queue);
}

static void packet_hw_to_sw(struct noc_pkt *npkt)
{
	struct sk_buff *skb;
	enum path_type dir;

	skb = noc_pkt_to_skb(npkt);
	if (skb) {
		dir = read_path_from_skb(skb);
		engine_backlog_tail(skb, dir);
	}
}

static int hwif_hw_to_sw_worker_thread(void *arg)
{
	struct noc_pkt *npkt;
	size_t off = sizeof(*npkt) - sizeof(npkt->payload);

	while (likely(!kthread_should_stop())) {
		/* sleeps here */
		mbox_get(&noc[HW_TO_SW_SLOT].mb_get);

		npkt = (struct noc_pkt *) shared_mem_h2s;
		npkt->payload = shared_mem_h2s + off;

		DEBUG(printk(KERN_INFO "XXX: got npkt from hw:\n"));
		DEBUG(dump_npkt(npkt));

		packet_hw_to_sw(npkt);
	}

	return 0;
}

static int hwif_sw_to_hw_worker_thread(void *arg)
{
	struct noc_pkt *npkt;
	struct sk_buff *skb;

	skb_queue_head_init(&queue_to_hw);
	init_waitqueue_head(&wait_queue);

	/* we need threads here, because mbox can lay itself to sleep */
	while (likely(!kthread_should_stop())) {
		wait_event_interruptible(wait_queue,
					 !skb_queue_empty(&queue_to_hw));
		skb = skb_dequeue(&queue_to_hw);
		if (skb == NULL)
			continue;

		npkt = skb_to_noc_pkt(skb);
		if (npkt) {
			noc_sendpkt(npkt);
			kfree_npkt(npkt);
		}
	}

	return 0;
}

static int reconos_noc_init(void)
{
	int i;

	printk(KERN_INFO "[lana] bootstraping noc (%d slots)!\n",
	       __MAX_HWT_SLOT_NR);

	reconos_init_autodetect();
	memset(noc, 0, sizeof(noc));

	reconos_proc_control_selftest();

	for (i = 0; i < ARRAY_SIZE(noc); ++i) {
		mbox_init(&noc[i].mb_put, 2);
		mbox_init(&noc[i].mb_get, 2);

		noc[i].res[0].type = RECONOS_TYPE_MBOX;
		noc[i].res[0].ptr  = &noc[i].mb_put;	  	
	    	noc[i].res[1].type = RECONOS_TYPE_MBOX;
		noc[i].res[1].ptr  = &noc[i].mb_get;

		reconos_hwt_setresources(&noc[i].hwt, noc[i].res,
					 ARRAY_SIZE(noc[i].res));
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

int init_hwif(void)
{
	int ret;

	thread_hw2sw = kthread_create(hwif_hw_to_sw_worker_thread, NULL,
				      "lana_hwif_hw2sw");
	if (IS_ERR(thread_hw2sw)) {
		printk(KERN_ERR "Cannot create hwif thread1!\n");
		return -EIO;
	}

	thread_sw2hw = kthread_create(hwif_sw_to_hw_worker_thread, NULL,
				      "lana_hwif_sw2hw");
	if (IS_ERR(thread_sw2hw)) {
		printk(KERN_ERR "Cannot create hwif thread2!\n");
		goto out_t2;
	}

	ret = reconos_noc_init();
	if (ret) {
		printk(KERN_ERR "Cannot init reconos noc!\n");
		goto out_rec;
	}

	return 0;
out_rec:
	kthread_stop(thread_sw2hw);
out_t2:
	kthread_stop(thread_hw2sw);
	return -EIO;
}

void cleanup_hwif(void)
{
	kthread_stop(thread_hw2sw);
	kthread_stop(thread_sw2hw);

	reconos_noc_cleanup();
}
