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
#include <linux/kernel_stat.h>
#include <linux/tick.h>

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

#define ETH_SLOT		A_HWT_SLOT_NR
#define HW_TO_SW_SLOT		B_HWT_SLOT_NR
#define SW_TO_HW_SLOT		C_HWT_SLOT_NR
#define AES_SLOT		E_HWT_SLOT_NR
#define IPS_SLOT		E_HWT_SLOT_NR

#define DEBUG(fnt)		(fnt)
//#define DEBUG(fnt)
extern struct proc_dir_entry *lana_proc_dir;
static struct proc_dir_entry *scheduler_proc;

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

static struct task_struct *thread_hw2sw, *thread_sw2hw, *thread_scheduler;
static struct sk_buff_head queue_to_hw;
static u8 *shared_mem_h2s, *shared_mem_s2h;
static int order = 0;
static u64 hw2sw_packets;

int current_mapping = 0; //sw

DECLARE_WAIT_QUEUE_HEAD(wait_queue);


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

void set_hw_flag(struct fblock *fb, unsigned int flag)
{
	//TODO: Do this depending on the fblock - for now we only support eth.
	//printk(KERN_INFO "[xt_nocx] setting\n");
	//we have only one hw slot, so the hw address is always the same...
	if(memcmp(fb->name, "ips", 3) == 0){
		if (flag == 2){
			printk(KERN_INFO "[xt_nocx] changing eth config for ips: flag hw");
			u32 config_eth_hash_1 = 0xabababab;
			u32 config_eth_hash_2 = 0xabababab;
			u32 config_eth_idp = 0x2;
			u32 config_eth_address = 1; //global 0, local 1 -> ips

			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_hash_1 ); 
			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_hash_2);
			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_idp);
			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_address);
			int ret = mbox_get(&noc[ETH_SLOT].mb_get);
			//printk(KERN_INFO "hwt_ethernet configured - 2\n");
		}
		else{
			//printk(KERN_INFO "[xt_nocx] unknown flag %d\n", flag);
		}
	}
	if(memcmp(fb->name, "aes", 3) == 0){
		if (flag == 2){
			printk(KERN_INFO "[xt_nocx] changing eth config for aes: flag hw");
			u32 config_eth_hash_1 = 0xcdcdcdcd;
			u32 config_eth_hash_2 = 0xcdcdcdcd;
			u32 config_eth_idp = 0x5; //TODO
			u32 config_eth_address = 1; //global 0, local 1 -> aes

			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_hash_1 ); 
			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_hash_2);
			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_idp);
			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_address);
			int ret = mbox_get(&noc[ETH_SLOT].mb_get);
			//printk(KERN_INFO "hwt_ethernet configured - 2\n");
		}
		else{
			//printk(KERN_INFO "[xt_nocx] unknown flag %d\n", flag);
		}
	}
}

void reconfig_hw_block(char *name){
	if(memcmp(name, "aes", 3) == 0){
		printk(KERN_INFO "[XT_NOCX] setup for aes");
	/* setup AES slot.  */
	u32 config_data_start=1;
	u32 config_rcv=0;
	u32 config_data_mode=0;	//"....1100"=12=mode128, mode192=13, mode256=14,15
	u32 config_data_key0=0x16157e2b; // 50462976;	//X"03020100"
	u32 config_data_key1=0xa6d2ae28; //117835012;	//X"07060504"
	u32 config_data_key2=0x8815f7ab; //185207048;	//X"0b0a0908"
	u32 config_data_key3=0x3c4fcf09; //252579084;	//X"0f0e0d0c"

	u32 config_data_key4=319951120;	//X"13121110"
	u32 config_data_key5=387323156;	//X"17161514"
	u32 config_data_key6=454695192;	//X"1b1a1918"
	u32 config_data_key7=522067228;	//X"1f1e1d1c"
	u32 exit_sig=4294967295;
	config_data_mode=16; //key length 128 bit, send everything to eth
	config_data_mode=20; //key length 128 bit, send everything to sw

	mbox_put(&noc[AES_SLOT].mb_put, config_data_start);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_mode);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key0);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key1);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key2);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key3);

	mbox_put(&noc[AES_SLOT].mb_put, config_data_key4);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key5);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key6);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key7);
	config_rcv=mbox_get(&noc[AES_SLOT].mb_get);
	printk(KERN_INFO "[XT_NOCX] setup for aes done\n");


	}
	if(memcmp(name, "ips", 3) == 0){
	printk(KERN_INFO "[XT_NOCX] setup for ips");
	u32 address = 5; 	//send to sw
	u32 header_len = ('h' << 24) | 1;	//the data vs. control byte
	mbox_put(&noc[IPS_SLOT].mb_put, address);
	mbox_put(&noc[IPS_SLOT].mb_put, header_len);
	printk(KERN_INFO "[XT_NOCX] setup for ips done\n");

	}

}

void unset_hw_flag(struct fblock *fb, unsigned int flag)
{
	//TODO: Do this depending on the fblock - for now we only support eth.
	//printk(KERN_INFO "[xt_nocx] unsetting\n");
	if(memcmp(fb->name, "ips", 3) == 0){
		if (flag == 2){
		printk(KERN_INFO "[xt_nocx] changing eth config for ips: unflag hw");
			u32 config_eth_hash_1 = 0xabababab;
			u32 config_eth_hash_2 = 0xabababab;
			u32 config_eth_idp = 0x2;
			u32 config_eth_address = 5; //global 0, local 1 -> ips

			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_hash_1 ); 
			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_hash_2);
			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_idp);
			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_address);
			int ret = mbox_get(&noc[ETH_SLOT].mb_get);
			//printk(KERN_INFO "hwt_ethernet configured - 2\n");
		}
		else{
			//printk(KERN_INFO "[xt_nocx] unknown flag %d\n", flag);
		}
	}
	if(memcmp(fb->name, "aes", 3) == 0){
		if (flag == 2){
			printk(KERN_INFO "[xt_nocx] changing eth config for aes: flag hw");
			u32 config_eth_hash_1 = 0xcdcdcdcd;
			u32 config_eth_hash_2 = 0xcdcdcdcd;
			u32 config_eth_idp = 0x5; //TODO
			u32 config_eth_address = 5; //global 0, local 1 -> aes

			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_hash_1 ); 
			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_hash_2);
			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_idp);
			mbox_put(&noc[ETH_SLOT].mb_put, config_eth_address);
			int ret = mbox_get(&noc[ETH_SLOT].mb_get);
			//printk(KERN_INFO "hwt_ethernet configured - 2\n");
		}
		else{
			//printk(KERN_INFO "[xt_nocx] unknown flag %d\n", flag);
		}
	}

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
	if (npkt) {
		if (dst_idp == 2){ //fb1
			npkt->hw_addr_switch = 0;
			npkt->hw_addr_block = 1;
		} else{ //default, send it to ethernet
			npkt->hw_addr_switch = 1;
			npkt->hw_addr_block = 0;
		}
		npkt->priority = 1;
		npkt->direction = 0; //read_path_from_skb(skb);
		npkt->latency_critical = 1;
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
	//printk(KERN_INFO "[xt_nocx] noc_pkt_to_skb:\n");

	dev = dev_get_by_name(&init_net, "lo"); //we don't have eth0... "eth0"); //FIXME
	if (!dev)
		return NULL;
//	DEBUG(printk(KERN_INFO "[xt_nocx] noc_pkt_to_skb 1:\n"));
//	DEBUG(printk(KERN_INFO "[xt_nocx]: noc_pkt_to_skb first payload: %x\n", npkt->payload[0]));

	skb = alloc_skb(npkt->payload_len + LL_ALLOCATED_SPACE(dev),
			GFP_KERNEL);
	if (skb) {
		struct fblock *fb;
		//printk(KERN_INFO "[xt_nocx] noc_pkt_to_skb2:\n");

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
	//	write_next_idp_to_skb(skb, 1, 2);
	//	write_next_idp_to_skb(skb, 2, 3); //TODO: change here
		//printk("received packet with dst idp %d\n", npkt->dst_idp);
		fb = __search_fblock(npkt->dst_idp);
		if (fb){
			if (fblock_offload_isset(fb)) {
				//printk(KERN_INFO "[xt_nocx] was in hw -> forwarding to 3\n");
				if(npkt->dst_idp == 2){
					write_next_idp_to_skb(skb, npkt->src_idp, 3); //TODO: can I somehow figure out what the next IDP would be?
				}
				if(npkt->dst_idp == 5){
					write_next_idp_to_skb(skb, npkt->src_idp, 6); //TODO: can I somehow figure out what the next IDP would be?

				}

			}
			else {
				//printk(KERN_INFO "[xt_nocx] was not in hw -> forwarding to %d\n", npkt->dst_idp);

				write_next_idp_to_skb(skb, npkt->src_idp, npkt->dst_idp);
			}
		}
		else	{
			printk(KERN_INFO "[xt_noxc] could not find fblock with idp %d\n", npkt->dst_idp);
			write_next_idp_to_skb(skb, npkt->src_idp, npkt->dst_idp); //we send it anyway.
		}


//		DEBUG(printk(KERN_INFO "[xt_nocx] noc_pkt_to_skb3:\n"));

	}
//	DEBUG(printk(KERN_INFO "[xt_nocx] noc_pkt_to_skb4:\n"));

	return skb;
}

static int noc_sendpkt(struct noc_pkt *npkt)
{
	static u32 total_len = 0;
	u32 pkt_len = npkt->payload_len;
	u32 tmp_len = 0; //104;
	u32 i;
	size_t off = sizeof(*npkt) - sizeof(npkt->payload);

	//DEBUG(printk(KERN_INFO "[xt_nocx] send npkt to hw:\n"));
	//DEBUG(dump_npkt(npkt));
	//memcpy(shared_mem_s2h, &tmp_len, 4);
	memcpy(shared_mem_s2h + total_len, npkt, off);
	memcpy(shared_mem_s2h + total_len + off, npkt->payload, pkt_len);
	total_len += npkt->payload_len + 12;

/*	for(i = 0; i < tmp_len; i++){
		unsigned char val = shared_mem_s2h[i];
		printk(KERN_INFO "%x ", val);
	}
*/

/*
		shared_mem_s2h[12] = 0x6b;
		shared_mem_s2h[13] = 0xc1;
		shared_mem_s2h[14] = 0xbe;
		shared_mem_s2h[15] = 0xe2;
		shared_mem_s2h[16] = 0x2e;
		shared_mem_s2h[17] = 0x40;
		shared_mem_s2h[18] = 0x9f;
		shared_mem_s2h[19] = 0x96;
		shared_mem_s2h[20] = 0xe9;
		shared_mem_s2h[21] = 0x3d;
		shared_mem_s2h[22] = 0x7e;
		shared_mem_s2h[23] = 0x11;
		shared_mem_s2h[24] = 0x73;
		shared_mem_s2h[25] = 0x93;
		shared_mem_s2h[26] = 0x17;
		shared_mem_s2h[27] = 0x2a;

*/

	//printk(KERN_ERR "current total length: %d off %d\n", total_len, off);
//	if (total_len > 2580){
	if (total_len > 64){
		mbox_put(&noc[SW_TO_HW_SLOT].mb_put, total_len);
		//wait until hw has read the buffer!
	//	for(i = 0; i < 200; i++){
	//	unsigned char val = shared_mem_s2h[i];
	//	printk(KERN_INFO "%x ", val);
	//	}
		total_len = 0;
		tmp_len = mbox_get(&noc[SW_TO_HW_SLOT].mb_get);
	}
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
	//printk(KERN_INFO "[xt_nocx] packet_hw_to_sw 1\n");

	skb = noc_pkt_to_skb(npkt);
//	DEBUG(printk(KERN_INFO "[xt_nocx] packet_hw_to_sw 2\n"));

	if (skb) {
//		DEBUG(printk(KERN_INFO "[xt_nocx] packet_hw_to_sw 3\n"));
		dir = read_path_from_skb(skb);
		engine_backlog_tail(skb, dir);
//		DEBUG(printk(KERN_INFO "[xt_nocx] packet_hw_to_sw 4\n"));
	}
//		DEBUG(printk(KERN_INFO "[xt_nocx] packet_hw_to_sw 5\n"));


}

static void shared_mem_to_noc_pkt(struct noc_pkt * npkt, char *shared_mem){
	npkt->hw_addr_switch = 0;
	npkt->hw_addr_block = 0;
	npkt->priority = 0;
	npkt->direction = TYPE_INGRESS;
	npkt->latency_critical = 0;
	npkt->reserved = 0;
	memcpy(&(npkt->payload_len), shared_mem + 2, 2);
//	npkt->src_idp = 0;
//	npkt->dst_idp = 0; //TODO change this!
	memcpy(&(npkt->src_idp), shared_mem + 4, 4);
	memcpy(&(npkt->dst_idp), shared_mem + 8, 4);
	npkt->payload = shared_mem + 12;
}

static int hwif_hw_to_sw_worker_thread(void *arg)
{
	struct noc_pkt npkt;
	size_t off = sizeof(npkt) - sizeof(npkt.payload);
	hw2sw_packets = 0;
	//printk(KERN_INFO "[xt_nocx] off = %d\n", off);
	while (likely(!kthread_should_stop())) {
		/* sleeps here */
		u8 * pkt_start;
		int ret = 0;
		int i = 0;
		//DEBUG(printk(KERN_INFO "[xt_nocx] waiting for hw packet \n"));
		ret = mbox_get(&noc[HW_TO_SW_SLOT].mb_get);
		//DEBUG(printk(KERN_INFO "[xt_nocx] received packet with len %d \n", ret));

		pkt_start = shared_mem_h2s;
		shared_mem_to_noc_pkt(&npkt, pkt_start);
	//	npkt = (struct noc_pkt *) pkt_start;

//		npkt->payload = pkt_start + off;
//		for(i = 0; i < 32; i = i+2)
//			printk(KERN_INFO "[xt_nocx] %x %x", npkt.payload[i], npkt.payload[i+1]);
		//for(i = 0; i < 32; i = i+2)
		//	printk(KERN_INFO "[xt_nocx] %x %x", shared_mem_h2s[i], shared_mem_h2s[i+1]);

		//for now, as long as the hw uses a different pkt format...
	//	DEBUG(printk(KERN_INFO "[xt_nocx]: got npkt from hw: first payload: %x\n", npkt.payload[0]));
	//	DEBUG(dump_npkt(&npkt));
		//TODO: loop here through all packets
		packet_hw_to_sw(&npkt);
		//update statistics, later, this needs to be done on a per connection basis.
		hw2sw_packets++;
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
		//DEBUG(printk(KERN_INFO "[xt_nocx] waiting for sw packet\n"));

		wait_event_interruptible(wait_queue,
					 !skb_queue_empty(&queue_to_hw));
		//DEBUG(printk(KERN_INFO "[xt_nocx] received sw to hw packet\n"));
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

static int scheduler (void *arg)
{
	int prev_cpu = 0;
	int cur_cpu = 0;
	int delta_cpu = 0;
	u64 prev_packets = 0;
	u64 cur_packets = 0;
	int delta_packets = 0;
	int counter = 0;
	msleep(40000); // sleep 20 second;
	printk(KERN_INFO "[xt_nocx] scheduler start");

	prev_cpu = get_cpu_idle_time_us(0, NULL); //we only have one CPU
	prev_packets = hw2sw_packets;
	msleep(1000); // sleep 10 second;
	

	while(likely(!kthread_should_stop())){
		cur_cpu = kstat_cpu(0).cpustat.idle;
		delta_cpu = cur_cpu - prev_cpu;
		prev_cpu = cur_cpu;
		cur_packets = hw2sw_packets;
		delta_packets = cur_packets - prev_packets;
		prev_packets = cur_packets;
		if (counter == 9){
			printk(KERN_INFO "[xt_nocx] idle time: %d [%], number of packets %d\n", delta_cpu, delta_packets);
			counter = 0;
		}
		counter++;
		
		if (delta_cpu < 55) { //30%idle time
			if (current_mapping == 0){ //in sw
				struct lananlmsg msg;
				struct lananlmsg_flags flags_msg;
				printk(KERN_INFO "[xt_nocx] idle time below 30%, setting hw flag");
				//memcpy(flags_msg.name, "ips", 4);
				memcpy(msg.buff, "ips", 4);
				fblock_userctl_set_flags(&msg, FBLOCK_FLAGS_TRANS_IB);
				if (fblock_userctl_set_flags(&msg, FBLOCK_FLAGS_TO_HW) < 0){
					printk(KERN_INFO "[xt_nocx] set hw flag failed");
				}
				else {
					printk(KERN_INFO "[xt_nocx] set hw flag success");
					wake_up_interruptible(&wait_queue);
				}
				fblock_userctl_unset_flags(&msg, FBLOCK_FLAGS_TRANS_IB);
				current_mapping = 1;
			}
		}
		else {
			if (delta_packets < 50){ // 5 packets per second
				if (current_mapping == 1){ //hw
					struct lananlmsg msg;
					struct lananlmsg_flags flags_msg;
					printk(KERN_INFO "[xt_nocx] packets below 50 per second, unsetting hw flag");
					//memcpy(flags_msg.name, "ips", 4);
					memcpy(msg.buff, "ips", 4);
	
					fblock_userctl_set_flags(&msg, FBLOCK_FLAGS_TRANS_IB);
					if (fblock_userctl_unset_flags(&msg, FBLOCK_FLAGS_TO_HW) < 0){
						printk(KERN_INFO "[xt_nocx] unset hw flag failed");
					}
					else {
						printk(KERN_INFO "[xt_nocx] unset hw flag success");
						wake_up_interruptible(&wait_queue);

					}
					fblock_userctl_unset_flags(&msg, FBLOCK_FLAGS_TRANS_IB);
					current_mapping = 0;
				}
			}
		}
		
		msleep(1000); // sleep a second;
	}
	return 0;
}


static int schedular_procfs(char *page, char **start, off_t offset, 
			int count, int *eof, void *data)
{
	int last_mapping;
	if(offset) //simple hack to avoid "cat read twice problem"
		return 0;

	last_mapping = current_mapping;

	wait_event_interruptible(wait_queue, last_mapping != current_mapping);

	//todo: locking!?
//	while(1){
//		if (last_mapping != current_mapping){
//			printk(KERN_INFO "[lana] change mapping");
//			last_mapping = current_mapping;
//			break;
//		}
//	}
	if (current_mapping == 0){
		printk(KERN_INFO "[lana] reconfigure to config_a");
		sprintf(page, "config_a"); 
	}
	if (current_mapping == 1){
		printk(KERN_INFO "[lana] reconfigure to config_b");
		sprintf(page, "config_b");
	}
	*eof = 1;
	return 9;

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


	/* setup AES slot. Note, this should be done by a controller */
#ifdef AES_CONFIGURED
	u32 config_data_start=1;
	u32 config_rcv=0;
	u32 config_data_mode=0;	//"....1100"=12=mode128, mode192=13, mode256=14,15
	u32 config_data_key0=0x16157e2b; // 50462976;	//X"03020100"
	u32 config_data_key1=0xa6d2ae28; //117835012;	//X"07060504"
	u32 config_data_key2=0x8815f7ab; //185207048;	//X"0b0a0908"
	u32 config_data_key3=0x3c4fcf09; //252579084;	//X"0f0e0d0c"

	u32 config_data_key4=319951120;	//X"13121110"
	u32 config_data_key5=387323156;	//X"17161514"
	u32 config_data_key6=454695192;	//X"1b1a1918"
	u32 config_data_key7=522067228;	//X"1f1e1d1c"
	u32 exit_sig=4294967295;
	config_data_mode=16; //key length 128 bit, send everything to eth
	config_data_mode=20; //key length 128 bit, send everything to sw

	mbox_put(&noc[AES_SLOT].mb_put, config_data_start);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_mode);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key0);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key1);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key2);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key3);

	mbox_put(&noc[AES_SLOT].mb_put, config_data_key4);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key5);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key6);
	mbox_put(&noc[AES_SLOT].mb_put, config_data_key7);
	config_rcv=mbox_get(&noc[AES_SLOT].mb_get);
	printk(KERN_INFO "[lana] noc setup hw aes\n");
#endif

//#ifdef IPS_CONFIGURED
	u32 address = 5; 	//send to sw
	u32 header_len = ('h' << 24) | 1;	//the data vs. control byte
	mbox_put(&noc[IPS_SLOT].mb_put, address);
	mbox_put(&noc[IPS_SLOT].mb_put, header_len);
//#endif
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

//	thread_scheduler = kthread_run(scheduler, NULL, "lana_scheduler");
//	if (IS_ERR(thread_scheduler)){
//		printk(KERN_ERR "caoont creat lana_scheduler thread\n");
//		goto out_t3;
//	}

	scheduler_proc = 
	create_proc_read_entry("scheduler", 0400, lana_proc_dir, schedular_procfs, NULL);
	if (!scheduler_proc)
		goto out_t4;

	return 0;

out_t4:
//	kthread_stop(thread_scheduler);
out_t3:
	kthread_stop(thread_sw2hw);
out_t2:
	kthread_stop(thread_hw2sw);
out_rec:
	reconos_noc_cleanup();
	return -EIO;
}

void cleanup_hwif(void)
{
	printk(KERN_INFO "[lana] cleanup_hwif!\n");
	kthread_stop(thread_hw2sw);
	kthread_stop(thread_sw2hw);
//	kthread_stop(thread_scheduler);
	remove_proc_entry("scheduler", lana_proc_dir);
	reconos_noc_cleanup();
}
#endif /* WITH_RECONOS */
