#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kthread.h>
#include <linux/mm.h>
#include <linux/vmalloc.h>
#include <linux/slab.h>
#include <linux/highmem.h>
#include <asm/page.h>
#include <asm/pgtable.h>

#include "reconos.h"
#include "mbox.h"

#define ETH_SLOT_NR 0
#define H2S_SLOT_NR 1
#define S2H_SLOT_NR 2
#define AES_SLOT_NR 3
#define ADD1_SLOT_NR 4
#define ADD2_SLOT_NR 5

#define NR_OF_PAGES 2 //32768 (2^15)

struct reconos_resource eth_res[2];
struct reconos_hwt eth_hwt;
struct reconos_resource h2s_res[2];
struct reconos_hwt h2s_hwt;
struct reconos_resource s2h_res[2];
struct reconos_hwt s2h_hwt;
struct reconos_resource aes_res[2];
struct reconos_hwt aes_hwt;
struct reconos_resource add1_res[2];
struct reconos_hwt add1_hwt;
struct reconos_resource add2_res[2];
struct reconos_hwt add2_hwt;

struct mbox eth_mb_put;
struct mbox eth_mb_get;
struct mbox h2s_mb_put;
struct mbox h2s_mb_get;
struct mbox s2h_mb_put;
struct mbox s2h_mb_get;
struct mbox aes_mb_put;
struct mbox aes_mb_get;
struct mbox add1_mb_put;
struct mbox add1_mb_get;
struct mbox add2_mb_put;
struct mbox add2_mb_get;

//static uint32_t init_data = 0xDEADBEEF;

struct config_data {
	u32 dst_idp:8,
	    src_idp:8,
	    res:6,
	    latency_critical:1,
	    direction:1,
	    priority:2,
	    global_addr:4,
	    local_addr:2;
};

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
	u8* payload;
};


void copy_packet(int len, int start_val, char * addr, int global, int local){
	//hwaddrglobal hwaddrlocal, priority
	struct noc_pkt pkt;
	int i = 0;	
	pkt.hw_addr_switch = global; //(1/0 -> Ethernet, 1/1 -> loop back to SW);
	pkt.hw_addr_block = local;
	pkt.priority = 1;
	pkt.direction = 0;
	pkt.latency_critical = 1;
	pkt.reserved = 0;
	pkt.payload_len = len;
	pkt.src_idp = 0xaabbccaa;
	pkt.dst_idp = 0xddeeffdd;
	memcpy(addr, &pkt, sizeof(struct noc_pkt));
	while (len - i > 0){
		addr[12 + i] = (start_val + i) % 256;
		i++;
	}
}

void print_packet(struct noc_pkt * pkt){
	printk(KERN_INFO "global addr: %d\n", pkt->hw_addr_switch);
	printk(KERN_INFO "local addr: %d\n", pkt->hw_addr_block);
	printk(KERN_INFO "priority: %d\n", pkt->priority);
	printk(KERN_INFO "direction: %d\n", pkt->direction);
	printk(KERN_INFO "latency critical: %d\n", pkt->latency_critical);
	printk(KERN_INFO "payload_len: %d\n", pkt->payload_len);
	printk(KERN_INFO "src idp: %d\n", pkt->src_idp);
	printk(KERN_INFO "dst idp: %d\n", pkt->dst_idp);
}


static int __init init_reconos_test_module(void)
{
	char * shared_mem_h2s;
	char * shared_mem_s2h;
	int i;
	long unsigned jiffies_before;
	long unsigned jiffies_after;

	printk(KERN_INFO "[reconos-interface] Init.\n");

	mbox_init(&eth_mb_put, 2);
    	mbox_init(&eth_mb_get, 2);
	mbox_init(&h2s_mb_put, 2);
    	mbox_init(&h2s_mb_get, 2);
	mbox_init(&s2h_mb_put, 2);
    	mbox_init(&s2h_mb_get, 2);
	mbox_init(&aes_mb_put, 2);
	mbox_init(&aes_mb_get, 2);
	mbox_init(&add1_mb_put, 2);
    	mbox_init(&add1_mb_get, 2);
	mbox_init(&add2_mb_put, 2);
    	mbox_init(&add2_mb_get, 2);

	printk(KERN_INFO "[reconos-interface] mbox_init done, starting autodetect.\n");

	reconos_init_autodetect();

	printk(KERN_INFO "[reconos-interface] Creating hw-thread.\n");
	eth_res[0].type = RECONOS_TYPE_MBOX;
	eth_res[0].ptr  = &eth_mb_put;	  	
    	eth_res[1].type = RECONOS_TYPE_MBOX;
	eth_res[1].ptr  = &eth_mb_get;

	s2h_res[0].type = RECONOS_TYPE_MBOX;
	s2h_res[0].ptr  = &s2h_mb_put;	  	
    	s2h_res[1].type = RECONOS_TYPE_MBOX;
	s2h_res[1].ptr  = &s2h_mb_get;

	h2s_res[0].type = RECONOS_TYPE_MBOX;
	h2s_res[0].ptr  = &h2s_mb_put;	  	
    	h2s_res[1].type = RECONOS_TYPE_MBOX;
	h2s_res[1].ptr  = &h2s_mb_get;

	aes_res[0].type = RECONOS_TYPE_MBOX;
	aes_res[0].ptr  = &aes_mb_put;	  	
    	aes_res[1].type = RECONOS_TYPE_MBOX;
	aes_res[1].ptr  = &aes_mb_get;

	add1_res[0].type = RECONOS_TYPE_MBOX;
	add1_res[0].ptr  = &add1_mb_put;	  	
    	add1_res[1].type = RECONOS_TYPE_MBOX;
	add1_res[1].ptr  = &add1_mb_get;

	add2_res[0].type = RECONOS_TYPE_MBOX;
	add2_res[0].ptr  = &add2_mb_put;	  	
    	add2_res[1].type = RECONOS_TYPE_MBOX;
	add2_res[1].ptr  = &add2_mb_get;


	reconos_hwt_setresources(&eth_hwt,eth_res,2);
	reconos_hwt_create(&eth_hwt,ETH_SLOT_NR,NULL);

    	reconos_hwt_setresources(&h2s_hwt,h2s_res,2);
  	reconos_hwt_create(&h2s_hwt,H2S_SLOT_NR,NULL);

	reconos_hwt_setresources(&s2h_hwt,s2h_res,2);
	reconos_hwt_create(&s2h_hwt,S2H_SLOT_NR,NULL);

	reconos_hwt_setresources(&aes_hwt,aes_res,2);
	reconos_hwt_create(&aes_hwt,AES_SLOT_NR,NULL);

//	reconos_hwt_setresources(&add1_hwt,add1_res,2);
//	reconos_hwt_create(&add1_hwt,ADD1_SLOT_NR,NULL);

//	reconos_hwt_setresources(&add2_hwt,add2_res,2);
//	reconos_hwt_create(&add2_hwt,ADD2_SLOT_NR,NULL);


	//setup the hw -> sw thread
//	printk(KERN_INFO "[reconos-interface] Allocate memory\n");
//	shared_mem_h2s = alloc_pages_exact(NR_OF_PAGES, GFP_KERNEL); //get_zeroed_page(GFP_KERNEL);
//	memset(shared_mem_h2s, 0, 4096); 
//	printk(KERN_INFO "[reconos-interface] h2s memory %p\n", shared_mem_h2s);
//	mbox_put(&h2s_mb_put, shared_mem_h2s);

	//setup the sw -> hw thread
	shared_mem_s2h = alloc_pages_exact(NR_OF_PAGES, GFP_KERNEL); //get_zeroed_page(GFP_KERNEL);
	printk(KERN_INFO "[reconos-interface] s2h memory %p\n", shared_mem_s2h);
	mbox_put(&s2h_mb_put, shared_mem_s2h);
	printk(KERN_INFO "[reconos-interface] HZ= %d\n", HZ);
	jiffies_before = jiffies;
//#endif
		int nr_of_packets = 50;


//	for(i = 0; i < 100; i++)
{
#ifdef blub	

		int packet_len = 64;
	//	int nr_of_packets = 50;
		int j = 0;
		int result = 0;
		int init = 0;
		int iteration = 100;
	//	memset(shared_mem_s2h, 0, 2 * packet_len);
		/************************************
		 * send packet to hardware
		 ************************************/
		for(j = 0; j < nr_of_packets; j++){
			copy_packet(packet_len, j, shared_mem_s2h + j*(packet_len + 12), 0, 0);
		}
	//	copy_packet(packet_len, 100, shared_mem_s2h + packet_len + 12, 1, 0);
		mbox_put(&s2h_mb_put, nr_of_packets * (packet_len + 12));
		for (j = 0; j < 200; j++){
			printk(KERN_INFO "%x", shared_mem_s2h[j]);
		} 

	//	mbox_put(&c_mb_put, packet_len+12);
	//	printk(KERN_INFO "[reconos-interface] packet sent to hw\n");
		result = mbox_get(&s2h_mb_get);
	//	printk(KERN_INFO "[reconos-interface] packet sent received ack from hw, total packet len %d \n", result);

//#ifdef blub	
	
		/************************************
		 * send packet to hardware
		 ************************************/
                copy_packet(packet_len, 2, shared_mem_s2h, 1, 1);
		struct noc_pkt * snd_pkt = (struct noc_pkt *)shared_mem_s2h;
                mbox_put(&c_mb_put, packet_len);
		//printk(KERN_INFO "[reconos-interface] packet sent to hw\n");
                result = mbox_get(&c_mb_get);
         	printk(KERN_INFO "[reconos-interface] packet sent received ack from hw, total packet len %d \n", result);

		/************************************
		 * receive packet from hardware
		 ************************************/
for(j = 0; j < iteration; j++){
//		printk(KERN_INFO "[reconos-interface] wait for packet from hw\n");
		result = mbox_get(&b_mb_get);
		if (init == 0){
			jiffies_before = jiffies;
			nr_of_packets = 0;
			init = 1;
		}
		struct noc_pkt * rcv_pkt = (struct noc_pkt *)shared_mem_h2s;
	//	packet_len = *(int *)shared_mem_h2s;
	//	
	//	printk(KERN_INFO "[reconos-interface] packet received with len from mbox %d, from memory %d\n", result, rcv_pkt->payload_len);
		nr_of_packets++;	
		int len = rcv_pkt->payload_len+12;
		char * cur = shared_mem_h2s;
		while (len < result){
			cur = cur + rcv_pkt->payload_len + 12; 
			rcv_pkt = (struct noc_pkt*)cur;
	//		printk(KERN_INFO "[reconos-interface] packet received with len %d\n", rcv_pkt->payload_len);
			len = len + rcv_pkt->payload_len + 12;
			nr_of_packets++;	
		}
//		printk(KERN_INFO "packet sent\n");
//		print_packet(snd_pkt);		
//		printk(KERN_INFO "packet received\n");
//		print_packet(rcv_pkt);
//		for (j = 0; j < 200; j++){
//			printk(KERN_INFO "%x", shared_mem_h2s[j]);
//		} 

	mbox_put(&b_mb_put, result);
} 
//#ifdef blub
	  char * tmp = shared_mem_h2s + rcv_pkt->payload_len+12;
	  rcv_pkt = (struct noc_pkt *)tmp;
		printk(KERN_INFO "[reconos-interface] packet received with len from mbox %d, from memory %d\n", result, rcv_pkt->payload_len);
		printk(KERN_INFO "packet received\n");
		print_packet(rcv_pkt);

	
		for (j = 0; j < result; j++){ 
			unsigned char written_val = shared_mem_s2h[j];
			unsigned char read_val = shared_mem_h2s[j];
			printk(KERN_INFO "%x %x", written_val, read_val);
			if ((j + 1) % 8 == 0){
				printk(KERN_INFO "    ");
			}
			if ((j + 1) % 16 == 0){
				printk(KERN_INFO "\n");
			}
		}
		printk(KERN_INFO "\n");
	
		mbox_put(&b_mb_put, result); //dummy_value. it will be the amount of data read in a ring buffer scenario
		


		/**********************************************
		 * send packet to hardware (s2h -> ADD -> eth)
		 **********************************************/
                copy_packet(packet_len, 3, shared_mem_s2h, 0, 1);
                mbox_put(&c_mb_put, packet_len);
		//printk(KERN_INFO "[reconos-interface] packet sent to hw\n");
         
	        result = mbox_get(&c_mb_get);
         	printk(KERN_INFO "[reconos-interface] packet sent received ack from hw, total packet len %d \n", result);

		/***************************************
		 * reconfigure ADD to send packet to SW
		 ***************************************/
		u32 config_data = 5; //global=1, local=1
		mbox_put(&e_mb_put, config_data);

		config_data = mbox_get(&e_mb_get);
		printk(KERN_INFO "ADD replies : %d\n", config_data);
		config_data = mbox_get(&e_mb_get);
		printk(KERN_INFO "ADD replies : %d\n", config_data);
		config_data = mbox_get(&e_mb_get);
		printk(KERN_INFO "ADD replies : %d\n", config_data);
		config_data = mbox_get(&e_mb_get);
		printk(KERN_INFO "ADD replies : %d\n", config_data);
		config_data = mbox_get(&e_mb_get);
		printk(KERN_INFO "ADD replies : %d\n", config_data);


		/**********************************************
		 * send packet to hardware (s2h -> ADD -> h2s)
		 **********************************************/
                copy_packet(packet_len, 4, shared_mem_s2h, 0, 1);
                mbox_put(&c_mb_put, packet_len);
		//printk(KERN_INFO "[reconos-interface] packet sent to hw\n");
                result = mbox_get(&c_mb_get);
         	printk(KERN_INFO "[reconos-interface] packet sent received ack from hw, total packet len %d \n", result);


		/************************************
		 * receive packet from hardware (ADD)
		 ************************************/
		//printk(KERN_INFO "[reconos-interface] wait for packet from hw\n");
		result = mbox_get(&b_mb_get);
		rcv_pkt = (struct noc_pkt *)shared_mem_h2s;
	//	packet_len = *(int *)shared_mem_h2s;
		printk(KERN_INFO "[reconos-interface] packet received with len from mbox %d, from memory %d\n", result, rcv_pkt->payload_len);

		printk(KERN_INFO "packet sent\n");
		print_packet(snd_pkt);		
		printk(KERN_INFO "packet received\n");
		print_packet(rcv_pkt);


		for (j = 0; j < packet_len + 12; j++){ 
			unsigned char written_val = shared_mem_s2h[j];
			unsigned char read_val = shared_mem_h2s[j];
			printk(KERN_INFO "%x %x", written_val, read_val);
			if ((j + 1) % 8 == 0){
				printk(KERN_INFO "    ");
			}
			if ((j + 1) % 16 == 0){
				printk(KERN_INFO "\n");
			}
		}
		printk(KERN_INFO "\n");
	
		mbox_put(&b_mb_put, shared_mem_h2s); //dummy_value. it will be the amount of data read in a ring buffer scenario

		/************************************
		 * receive packet from hardware (ETH -> h2s)
		 ************************************/
		//printk(KERN_INFO "[reconos-interface] wait for packet from hw\n");
		result = mbox_get(&b_mb_get);
		rcv_pkt = (struct noc_pkt *)shared_mem_h2s;
	//	packet_len = *(int *)shared_mem_h2s;
		printk(KERN_INFO "[reconos-interface] packet received with len from mbox %d, from memory %d\n", result, rcv_pkt->payload_len);

		printk(KERN_INFO "packet sent\n");
		print_packet(snd_pkt);		
		printk(KERN_INFO "packet received\n");
		print_packet(rcv_pkt);


		for (j = 0; j < packet_len + 12; j++){ 
			unsigned char written_val = shared_mem_s2h[j];
			unsigned char read_val = shared_mem_h2s[j];
			printk(KERN_INFO "%x %x", written_val, read_val);
			if ((j + 1) % 8 == 0){
				printk(KERN_INFO "    ");
			}
			if ((j + 1) % 16 == 0){
				printk(KERN_INFO "\n");
			}
		}
		printk(KERN_INFO "\n");
	
		mbox_put(&b_mb_put, shared_mem_h2s); //dummy_value. it will be the amount of data read in a ring buffer scenario

		/*****************************************
		 * Reconfigure ETH to send packets to ADD
		 *****************************************/
		struct config_data config;
		config.dst_idp = 170;
		config.src_idp = 187;
		config.latency_critical = 1;
		config.direction = 0; //0 = ingress
		config.priority = 1;
		config.global_addr = 0;
		config.local_addr = 1;
		mbox_put(&a_mb_put, config_data);

		config_data = mbox_get(&a_mb_get);
		printk(KERN_INFO "ADD replies : %d\n", config_data);
		config_data = mbox_get(&a_mb_get);
		printk(KERN_INFO "ADD replies : %d\n", config_data);
	

		/************************************
		 * receive packet from hardware (ETH -> ADD -> h2s)
		 ************************************/
		//printk(KERN_INFO "[reconos-interface] wait for packet from hw\n");
		result = mbox_get(&b_mb_get);
		rcv_pkt = (struct noc_pkt *)shared_mem_h2s;
	//	packet_len = *(int *)shared_mem_h2s;
		printk(KERN_INFO "[reconos-interface] packet received with len from mbox %d, from memory %d\n", result, rcv_pkt->payload_len);

		printk(KERN_INFO "packet sent\n");
		print_packet(snd_pkt);		
		printk(KERN_INFO "packet received\n");
		print_packet(rcv_pkt);


		for (j = 0; j < packet_len + 12; j++){ 
			unsigned char written_val = shared_mem_s2h[j];
			unsigned char read_val = shared_mem_h2s[j];
			printk(KERN_INFO "%x %x", written_val, read_val);
			if ((j + 1) % 8 == 0){
				printk(KERN_INFO "    ");
			}
			if ((j + 1) % 16 == 0){
				printk(KERN_INFO "\n");
			}
		}
		printk(KERN_INFO "\n");
	
		mbox_put(&b_mb_put, shared_mem_h2s); //dummy_value. it will be the amount of data read in a ring buffer scenario

#endif

		
	}
	jiffies_after =jiffies;
	printk(KERN_INFO "[reconos-interface] jiffies before = %lu, jiffies after = %lu, delta = %lu", jiffies_before, jiffies_after, jiffies_after - jiffies_before);
	struct noc_pkt * rcv_pkt = (struct noc_pkt *)shared_mem_h2s;

	printk(KERN_INFO "[reconos-interface] nr of packets = %lu packet size = %lu", nr_of_packets, rcv_pkt->payload_len);

	printk(KERN_INFO "[reconos-interface] done\n");
	return 0;
}

static void __exit cleanup_reconos_test_module(void)
{
	reconos_cleanup();

	printk("[reconos-interface] unloaded\n");
}

module_init(init_reconos_test_module);
module_exit(cleanup_reconos_test_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ariane Keller <ariane.keller@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("EmbedNet HW/SW interface");
