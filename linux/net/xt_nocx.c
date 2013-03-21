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
#ifdef WITH_RECONOS
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

//#define DEBUG(fnt)		(fnt)
//#define DEBUG(fnt)		

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
	u16 payload_len;
	u32 src_idp;
	u32 dst_idp;
//	u32 payload_len;
	u8* payload;
};

static struct task_struct *thread_hw2sw, *thread_sw2hw;
static wait_queue_head_t wait_queue;
static struct sk_buff_head queue_to_hw;
static u8 *shared_mem_h2s, *shared_mem_s2h;
static int order = 0;

void dump_npkt(struct noc_pkt *npkt)
{
	//int i;
	printk(KERN_INFO "npkt packet dump ---->\n");
	printk(KERN_INFO " hw_addr_switch:%d\n", npkt->hw_addr_switch);
	printk(KERN_INFO " hw_addr_block:%d\n", npkt->hw_addr_block);
	printk(KERN_INFO " priority:%d\n", npkt->priority);
	printk(KERN_INFO " direction:%d\n", npkt->direction);
	printk(KERN_INFO " latency_critical:%d\n", npkt->latency_critical);
	printk(KERN_INFO " src_idp:%u\n", npkt->src_idp);
	printk(KERN_INFO " dst_idp:%u\n", npkt->dst_idp);
	printk(KERN_INFO " payload_len:%u\n", npkt->payload_len);
	//for (i = 0; i < npkt->payload_len; ++i)
	//	printk(KERN_INFO " byte%d: 0x%x\n", i, (u8) npkt->payload[i]);
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
	u32 dst_idp = read_next_idp_from_skb(skb);
	//TODO: Build system that mapps IDPs to locations. From the user side I imagine setting another attribute
	//./fbctl set fb1 hw_addr=5 where 5 = "0001" (global addr (switch)) concatenated with "01" (local addr(block)).
	//here, we would read this mapping and fill the noc pkt correspondingly
	//for now, we assume eth1 = IDP1 = "0001" "00" = 4 and 
	//fb1 = IDP2 = "0000" "01" = 1
	npkt = alloc_npkt(skb->len, GFP_KERNEL);
	//printk(KERN_ERR "---------skb_to_noc_pkt: %d\n", skb->len);
	if (npkt) {
	//	if (dst_idp == 2){ //fb1
	//		npkt->hw_addr_switch = 0;
	//		npkt->hw_addr_block = 1;
	//	} else{ //default, send it to ethernet
			npkt->hw_addr_switch = 1;
			npkt->hw_addr_block = 0;
	//	}
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

	dev = dev_get_by_name(&init_net, "lo"); //we don't have eth0... "eth0"); //FIXME
	if (!dev)
		return NULL;
	skb = alloc_skb(npkt->payload_len + LL_ALLOCATED_SPACE(dev),
			GFP_KERNEL);
	if (skb) {
		skb_reserve(skb, LL_RESERVED_SPACE(dev));
		skb_reserve(skb, npkt->payload_len);
		memcpy(skb_push(skb, npkt->payload_len), npkt->payload,
		       npkt->payload_len);

		//just inverse direction of original packet
	//	write_path_to_skb(skb, npkt->direction);
	//	write_next_idp_to_skb(skb, npkt->src_idp, npkt->dst_idp);
	//	write_path_to_skb(skb, !npkt->direction);
	//	write_next_idp_to_skb(skb, npkt->dst_idp, npkt->src_idp);
		write_path_to_skb(skb, TYPE_INGRESS);
		write_next_idp_to_skb(skb, 1, 2);

	}

	return skb;
}

static int noc_sendpkt(struct noc_pkt *npkt)
{
	u32 pkt_len = npkt->payload_len + 12;
	u32 tmp_len = 0;
	//u32 i;
	size_t off = sizeof(*npkt) - sizeof(npkt->payload);

	DEBUG(printk(KERN_INFO "[xt_nocx] send npkt to hw:\n"));
	DEBUG(dump_npkt(npkt));
	//memcpy(shared_mem_s2h, &tmp_len, 4);
	memcpy(shared_mem_s2h, npkt, off);
	memcpy(shared_mem_s2h + off, npkt->payload, pkt_len);

/*	for(i = 0; i < tmp_len; i++){
		unsigned char val = shared_mem_s2h[i];
		printk(KERN_INFO "%x ", val);
	}
*/
	mbox_put(&noc[SW_TO_HW_SLOT].mb_put, tmp_len); //pkt_len);
	//wait until hw has read the buffer!

	tmp_len = mbox_get(&noc[SW_TO_HW_SLOT].mb_get);
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
		u8 * pkt_start;
		int ret = 0;
		DEBUG(printk(KERN_INFO "[xt_nocx] waiting for hw packet \n"));	
		ret = mbox_get(&noc[HW_TO_SW_SLOT].mb_get);
		DEBUG(printk(KERN_INFO "[xt_nocx] received packet with len %d \n", ret));
	
		pkt_start = shared_mem_h2s;
		npkt = (struct noc_pkt *) pkt_start;
		
		npkt->payload = pkt_start + off;
		//for now, as long as the hw uses a different pkt format...
		DEBUG(printk(KERN_INFO "[xt_nocx]: got npkt from hw:\n"));
		DEBUG(dump_npkt(npkt));

		packet_hw_to_sw(npkt);
		//notify hw that we read the data
		mbox_put(&noc[HW_TO_SW_SLOT].mb_put, shared_mem_h2s);
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
		DEBUG(printk(KERN_INFO "[xt_nocx] waiting for sw packet\n"));

		wait_event_interruptible(wait_queue,
					 !skb_queue_empty(&queue_to_hw));
		DEBUG(printk(KERN_INFO "[xt_nocx] received sw to hw packet\n"));
		skb = skb_dequeue(&queue_to_hw);
		if (skb == NULL)
			continue;

		npkt = skb_to_noc_pkt(skb);
		if (npkt) {
			noc_sendpkt(npkt);
			kfree_npkt(npkt);
		}

		kfree_skb(skb);
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

//	reconos_proc_control_selftest();

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
	ret = reconos_noc_init();
	if (ret) {
		printk(KERN_ERR "Cannot init reconos noc!\n");
		return -EIO;
	}

	thread_hw2sw = kthread_run(hwif_hw_to_sw_worker_thread, NULL,
				      "lana_hwif_hw2sw");
	if (IS_ERR(thread_hw2sw)) {
		printk(KERN_ERR "Cannot create hwif thread1!\n");
		goto out_rec;
	}

	thread_sw2hw = kthread_run(hwif_sw_to_hw_worker_thread, NULL,
				      "lana_hwif_sw2hw");
	if (IS_ERR(thread_sw2hw)) {
		printk(KERN_ERR "Cannot create hwif thread2!\n");
		goto out_t2;
	}

	return 0;
out_rec:
	reconos_noc_cleanup();
out_t2:
	kthread_stop(thread_hw2sw);
	return -EIO;
}

void cleanup_hwif(void)
{
	printk(KERN_INFO "[lana] cleanup_hwif!\n");
	kthread_stop(thread_hw2sw);
	kthread_stop(thread_sw2hw);

	reconos_noc_cleanup();
}
#endif /* WITH_RECONOS */
