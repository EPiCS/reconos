#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kthread.h>
#include <linux/mm.h>
#include <linux/vmalloc.h>
#include <linux/slab.h>
#include <linux/highmem.h>
#include <asm/page.h>
#include <asm/pgtable.h>

#include <linux/delay.h>

#include "reconos.h"
#include "mbox.h"


#define C_HWT_SLOT_NR 0  // hwt_s2h
#define B_HWT_SLOT_NR 1  // hwt_h2s
#define A_HWT_SLOT_NR 2  // hwt_ethernet_test
#define E_HWT_SLOT_NR 3  // hwt_smart_cam

#define NR_OF_PAGES 2 //32768 (2^15)

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
	int ret,i;
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

	while(1){
		mbox_put(&e_mb_put,4);
		printk("sent packets:");
		for (i=0;i<5;i++){
			ret = mbox_get(&e_mb_get);
			printk(" \tcounter(%d)=%08d",i,ret);
		}
		printk("\n");
		msleep(1000);
	}

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
