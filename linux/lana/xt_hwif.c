/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/errno.h>
#include <linux/slab.h>
#include <linux/wait.h>
#include <linux/kernel.h>
#include <linux/kthread.h>

#include "xt_engine.h"

struct noc_if {
	int blaaa;
};

struct noc_pkt {
	u8 hw_addr_block;	/* local hardware address */
	u8 hw_addr_switch;	/* global hardware address */
	u8 priority:2,		/* range [0..3] */
	   direction:1,		/* 1 for ingress, 0 for egress */
	   latencyCritical:1;	/* 1 lat. critical, 0 not latency critical */
	u32 src_idp;		/* src IDP of the packet */
	u32 dst_idp;		/* dst IDP of the packet */
	u32 payload_len;	/* payload length in bytes */
	u8* payload;		/* pointer to the actual payload */
};

static struct task_struct *thread;
static struct sk_buff_head queue_to_hw;
static wait_queue_head_t wait_queue;
static struct noc_if noc;

static int reconos_noc_init(struct noc_if *noc)
{
	/* stub */
	return 0;
}

static void reconos_noc_cleanup(struct noc_if *noc)
{
	/* stub */
}

static int reconos_noc_sendpkt(struct noc_if *noc, struct noc_pkt *npkt)
{
	/* stub */
	return 0;
}

static void reconos_noc_register_rcv_handler(struct noc_if *noc,
					     void (*fcnt)(struct noc_pkt *npkt))
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
	write_path_to_skb(skb, dir);
	skb_queue_tail(&queue_to_hw, skb);
	wake_up_interruptible(&wait_queue);
}

void noc_new_packet_callback(struct noc_pkt *npkt)
{
	struct sk_buff *skb;
	enum path_type dir;

	skb = noc_pkt_to_skb(npkt);
	if (skb) {
		dir = read_path_from_skb(skb);
		engine_backlog_tail(skb, dir);
	}
}

static int hwif_worker_thread(void *arg)
{
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

	return 0;
}

int init_hwif(void)
{
	int ret;

	thread = kthread_create(hwif_worker_thread, NULL, "lana_hwif");
	if (IS_ERR(thread)) {
		printk(KERN_ERR "Cannot create hwif thread!\n");
		return -EIO;
	}

	ret = reconos_noc_init(&noc);
	if (ret) {
		printk(KERN_ERR "Cannot init reconos noc!\n");
		kthread_stop(thread);
		return -EIO;
	}

	reconos_noc_register_rcv_handler(&noc, noc_new_packet_callback);
	return 0;
}

void cleanup_hwif(void)
{
	kthread_stop(thread);
	reconos_noc_cleanup(&noc);
}
