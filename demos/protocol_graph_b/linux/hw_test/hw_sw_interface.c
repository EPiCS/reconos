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


#define C_HWT_SLOT_NR 0
#define B_HWT_SLOT_NR 1
#define A_HWT_SLOT_NR 2
#define E_HWT_SLOT_NR 3


struct reconos_resource e_res[2];
struct reconos_hwt e_hwt;
struct reconos_resource a_res[2];
struct reconos_hwt a_hwt;
struct reconos_resource s_res[2];
struct reconos_hwt s_hwt;

struct reconos_resource b_res[2];
struct reconos_hwt b_hwt;
struct reconos_resource c_res[2];
struct reconos_hwt c_hwt;

struct mbox e_mb_put;
struct mbox e_mb_get;
struct mbox a_mb_put;
struct mbox a_mb_get;
struct mbox s_mb_put;
struct mbox s_mb_get;

struct mbox b_mb_put;
struct mbox b_mb_get;
struct mbox c_mb_put;
struct mbox c_mb_get;

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
	int i, j;
	long unsigned jiffies_before;
	long unsigned jiffies_after;
	int len_array[13] = {64, 128, 256, 512, 1024, 1280, 1500, 3000, 6000, 9000, 15000, 30000, 50000};

	printk(KERN_INFO "[reconos-interface] Init.\n");

	mbox_init(&e_mb_put, 2);
    	mbox_init(&e_mb_get, 2);
	mbox_init(&a_mb_put, 2);
    	mbox_init(&a_mb_get, 2);
	mbox_init(&b_mb_put, 2);
    	mbox_init(&b_mb_get, 2);
	mbox_init(&c_mb_put, 2);
    	mbox_init(&c_mb_get, 2);
	printk(KERN_INFO "[reconos-interface] mbox_init done, starting autodetect.\n");

	reconos_init_autodetect();

	printk(KERN_INFO "[reconos-interface] Creating hw-thread.\n");
	e_res[0].type = RECONOS_TYPE_MBOX;
	e_res[0].ptr  = &e_mb_put;	  	
    	e_res[1].type = RECONOS_TYPE_MBOX;
	e_res[1].ptr  = &e_mb_get;

	a_res[0].type = RECONOS_TYPE_MBOX;
	a_res[0].ptr  = &a_mb_put;	  	
    	a_res[1].type = RECONOS_TYPE_MBOX;
	a_res[1].ptr  = &a_mb_get;

	s_res[0].type = RECONOS_TYPE_MBOX;
	s_res[0].ptr  = &s_mb_put;	  	
    	s_res[1].type = RECONOS_TYPE_MBOX;
	s_res[1].ptr  = &s_mb_get;

	b_res[0].type = RECONOS_TYPE_MBOX;
	b_res[0].ptr  = &b_mb_put;	  	
    	b_res[1].type = RECONOS_TYPE_MBOX;
	b_res[1].ptr  = &b_mb_get;

	c_res[0].type = RECONOS_TYPE_MBOX;
	c_res[0].ptr  = &c_mb_put;	  	
    	c_res[1].type = RECONOS_TYPE_MBOX;
	c_res[1].ptr  = &c_mb_get;


	reconos_hwt_setresources(&e_hwt,e_res,2);
	reconos_hwt_create(&e_hwt,E_HWT_SLOT_NR,NULL);

    	reconos_hwt_setresources(&a_hwt,a_res,2);
	reconos_hwt_create(&a_hwt,A_HWT_SLOT_NR,NULL);

	reconos_hwt_setresources(&b_hwt,b_res,2);
	reconos_hwt_create(&b_hwt,B_HWT_SLOT_NR,NULL);

	reconos_hwt_setresources(&c_hwt,c_res,2);
	reconos_hwt_create(&c_hwt,C_HWT_SLOT_NR,NULL);

	//setup the hw -> sw thread
	printk(KERN_INFO "[reconos-interface] Allocate memory\n");
	shared_mem_h2s = __get_free_pages(GFP_KERNEL | __GFP_NOWARN, 4); //allocate 2² pages get_zeroed_page(GFP_KERNEL);
	printk(KERN_INFO "[reconos-interface] h2s memory %p\n", shared_mem_h2s);
	mbox_put(&b_mb_put, shared_mem_h2s);

	//setup the sw -> hw thread
	shared_mem_s2h = __get_free_pages(GFP_KERNEL | __GFP_NOWARN, 4); //allocate 2² pages get_zeroed_page(GFP_KERNEL);
	printk(KERN_INFO "[reconos-interface] s2h memory %p\n", shared_mem_s2h);
	mbox_put(&c_mb_put, shared_mem_s2h);
	printk(KERN_INFO "[reconos-interface] HZ= %d\n", HZ);
	jiffies_before = jiffies;

	printk(KERN_INFO "[reconos-interface] Setting up AES slot \n");
	
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
//	config_data_mode=16; //key length 128 bit, send everything to eth
	config_data_mode=20; //key length 128 bit, send everything to sw
	mbox_put(&e_mb_put, config_data_start);
	mbox_put(&e_mb_put, config_data_mode);
	mbox_put(&e_mb_put, config_data_key0);
	mbox_put(&e_mb_put, config_data_key1);
	mbox_put(&e_mb_put, config_data_key2);
	mbox_put(&e_mb_put, config_data_key3);

	mbox_put(&e_mb_put, config_data_key4);
	mbox_put(&e_mb_put, config_data_key5);
	mbox_put(&e_mb_put, config_data_key6);
	mbox_put(&e_mb_put, config_data_key7);
	config_rcv=mbox_get(&e_mb_get);
	printk(KERN_INFO "[reconos-interface] AES Setup done\n");

	while(1){
		printk(KERN_INFO "waiting for hw packets \n");
		int ret = mbox_get(&b_mb_get);
		int i;
		for (i = 0; i < 100; i+=4)
			printk(KERN_INFO "%x %x %x %x\n", shared_mem_h2s[i], shared_mem_h2s[i+1],  shared_mem_h2s[i+2],  shared_mem_h2s[i+3]);
		printk(KERN_INFO "received packet of len %u\n", ret);
		mbox_put(&b_mb_put, shared_mem_h2s );
		printk(KERN_INFO "setting up hash table \n");
		//config eth
		u32 config_eth_hash_1 = 0xabababab;
		u32 config_eth_hash_2 = 0xabababab;
		u32 config_eth_idp = 0x12341234;
		u32 config_eth_address = 1; //global 0, local 1 -> aes

		mbox_put(&a_mb_put, config_eth_hash_1 ); 
		mbox_put(&a_mb_put, config_eth_hash_2);
		mbox_put(&a_mb_put, config_eth_idp);
		mbox_put(&a_mb_put, config_eth_address);

		ret = mbox_get(&a_mb_get);
		printk(KERN_INFO "hwt_ethernet configured - 1\n");

		config_eth_hash_1 = 0xabababab;
		config_eth_hash_2 = 0xababab01;
		config_eth_idp = 0x56785678;
		config_eth_address = 5; //global 1, local 1 -> h2s

		mbox_put(&a_mb_put, config_eth_hash_1 );
		mbox_put(&a_mb_put, config_eth_hash_2);
		mbox_put(&a_mb_put, config_eth_idp);
		mbox_put(&a_mb_put, config_eth_address);

		ret = mbox_get(&a_mb_get);
		printk(KERN_INFO "hwt_ethernet configured - 2\n");
		
		ret = mbox_get(&b_mb_get);
		
		for (i = 0; i < 100; i+=4)
			printk(KERN_INFO "%x %x %x %x\n", shared_mem_h2s[i], shared_mem_h2s[i+1],  shared_mem_h2s[i+2],  shared_mem_h2s[i+3]);
		printk(KERN_INFO "received packet of len %u\n", ret);
		mbox_put(&b_mb_put, shared_mem_h2s );
//config eth
		config_eth_hash_1 = 0xabababab;
		config_eth_hash_2 = 0xabababab;
		config_eth_idp = 0x12341234;
		config_eth_address = 5; //global 1, local 1 -> h2s

		mbox_put(&a_mb_put, config_eth_hash_1 ); 
		mbox_put(&a_mb_put, config_eth_hash_2);
		mbox_put(&a_mb_put, config_eth_idp);
		mbox_put(&a_mb_put, config_eth_address);

		ret = mbox_get(&a_mb_get);
		printk(KERN_INFO "hwt_ethernet configured - 3\n");




	}


#ifdef ADD	//get interrupt time
	mbox_put(&e_mb_put, shared_mem_s2h);
	/**************************************
	 * only interrupts
	 **************************************/
	u32 data = 2147483648;
	int iterations = 1;
	jiffies_before = jiffies;
	for(i= data; i < data + iterations; i++){
		mbox_put(&e_mb_put, i);
		int ret = mbox_get(&e_mb_get);
		jiffies_after = jiffies;
//		printk(KERN_INFO "put %d, ret %d\n", i, ret);
	}
	jiffies_after = jiffies;
	printk(KERN_INFO "[reconos-interface] only interrupts: delta (in jiffies) = %lu for %d iterations", jiffies_after - jiffies_before, iterations);

	/***********************************************************************
	 * len = 64, 128, 512, 1024, 1280, 1518, 3000, 6000, 9000, 12000, 15000
	 **********************************************************************/
	for (j = 11; j < 13; j++){
		int len = len_array[j];
		printk(KERN_INFO "len = %d %p\n", len, shared_mem_s2h);
		memset(shared_mem_s2h, 0, 2*len);
		printk(KERN_INFO "len = %d\n", len);

		iterations = 1000000;

		jiffies_before = jiffies;
		for(i=0; i < iterations; i++){
			mbox_put(&e_mb_put, len);
			mbox_get(&e_mb_get);
		}
		jiffies_after = jiffies;
		int ret = memcmp(shared_mem_s2h, shared_mem_s2h+len, len);
		if (ret == 0)
			printk(KERN_INFO "copy success\n");
		else
			printk(KERN_INFO " copy failed\n");
		printk(KERN_INFO "[reconos-interface] len = %d: delta = %lu", len, jiffies_after - jiffies_before);
	
	}

//#endif
		/****************************************
		 * Reconfigure ETH to send data to dummy
		 ****************************************/
		u32 config_data = 1; //global=0, local=1
		mbox_put(&a_mb_put, config_data);

#endif


#ifdef SW_APP
//	for(i = 0; i < 10000; i++)
{
		for (j = 0; j < 7; j++){

		int packet_len = len_array[j];
		int iterations = 100000;
		int j = 0;
		int result = 0;
		memset(shared_mem_s2h, 0, 2 * packet_len);
		/************************************
		 * send packet to hardware
		 ************************************/
               	copy_packet(packet_len, 1, shared_mem_s2h, 1, 0);
		jiffies_before = jiffies;
		for(i = 0; i < iterations; i++){
                	mbox_put(&c_mb_put, packet_len + 12);
			result = mbox_get(&c_mb_get);
		}
		jiffies_after = jiffies;
		printk(KERN_INFO "[reconos-interface] iterations = %d len = %d: delta = %lu", iterations, packet_len, jiffies_after - jiffies_before);
		}
}
#endif	
#ifdef old
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
		//printk(KERN_INFO "[reconos-interface] wait for packet from hw\n");
		result = mbox_get(&b_mb_get);
		struct noc_pkt * rcv_pkt = (struct noc_pkt *)shared_mem_h2s;
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



		
	}
	jiffies_after =jiffies;

//#endif
	printk(KERN_INFO "[reconos-interface] jiffies before = %lu, jiffies after = %lu, delta = %lu", jiffies_before, jiffies_after, jiffies_after - jiffies_before);
#endif

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
