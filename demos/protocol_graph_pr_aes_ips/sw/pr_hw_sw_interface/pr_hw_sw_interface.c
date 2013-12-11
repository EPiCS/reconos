#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kthread.h>
#include <linux/mm.h>
#include <linux/vmalloc.h>
#include <linux/slab.h>
#include <linux/highmem.h>
#include <linux/proc_fs.h>
#include <asm/page.h>
#include <asm/pgtable.h>

#include <linux/delay.h>

#include "reconos.h"
#include "mbox.h"


#define S2H_HWT_SLOT_NR 0  // hwt_s2h
#define H2S_HWT_SLOT_NR 1  // hwt_h2s
#define ETH_HWT_SLOT_NR 2  // hwt_ethernet_test
#define DPR_HWT_SLOT_NR 3  // dynamic partial reconfiguable (DPR) hwt

#define NR_OF_PAGES 2 //32768 (2^15)

struct reconos_resource dpr_res[2];
struct reconos_hwt dpr_hwt;
struct reconos_resource eth_res[2];
struct reconos_hwt eth_hwt;
//struct reconos_resource s_res[2];
//struct reconos_hwt s_hwt;

struct reconos_resource h2s_res[2];
struct reconos_hwt h2s_hwt;
struct reconos_resource s2h_res[2];
struct reconos_hwt s2h_hwt;

struct mbox dpr_mb_put;
struct mbox dpr_mb_get;
struct mbox eth_mb_put;
struct mbox eth_mb_get;
//struct mbox s_mb_put;
//struct mbox s_mb_get;

struct mbox h2s_mb_put;
struct mbox h2s_mb_get;
struct mbox s2h_mb_put;
struct mbox s2h_mb_get;

char * shared_mem_h2s;
char * shared_mem_s2h;

struct task_struct *receive_thread;
int config;

int reconfig_done = 0;
int current_mapping = 0; //sw

static struct proc_dir_entry *example_dir;
static struct proc_dir_entry *scheduler_proc;
DECLARE_WAIT_QUEUE_HEAD(wait_queue);


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

void config_eth(int addr){
//	printk(KERN_INFO "[XT_NOCX] setup for eth");

	u32 config_eth_hash_1 = 0xcdcdcdcd;
	u32 config_eth_hash_2 = 0xcdcdcdcd;
	u32 config_eth_idp = 0x2; //TODO
	u32 config_eth_address = addr; //global 0, local 1 -> aes
	mbox_put(&eth_mb_put, config_eth_hash_1 );
	mbox_put(&eth_mb_put, config_eth_hash_2);
	mbox_put(&eth_mb_put, config_eth_idp);
	mbox_put(&eth_mb_put, config_eth_address);
	int ret = mbox_get(&eth_mb_get);
//	printk(KERN_INFO "[XT_NOCX] setup for eth done, ret = %d", ret);


}
void config_eth_ips(int addr){
//	printk(KERN_INFO "[XT_NOCX] setup for eth");

	u32 config_eth_hash_1 = 0xabababab;
	u32 config_eth_hash_2 = 0xabababab;
	u32 config_eth_idp = 0x3; //TODO
	u32 config_eth_address = addr; //global 0, local 1 -> aes
	mbox_put(&eth_mb_put, config_eth_hash_1 );
	mbox_put(&eth_mb_put, config_eth_hash_2);
	mbox_put(&eth_mb_put, config_eth_idp);
	mbox_put(&eth_mb_put, config_eth_address);
	int ret = mbox_get(&eth_mb_get);
//	printk(KERN_INFO "[XT_NOCX] setup for eth done, ret = %d", ret);


}

void config_aes(){
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

	mbox_put(&dpr_mb_put, config_data_start);
	mbox_put(&dpr_mb_put, config_data_mode);
	mbox_put(&dpr_mb_put, config_data_key0);
	mbox_put(&dpr_mb_put, config_data_key1);
	mbox_put(&dpr_mb_put, config_data_key2);
	mbox_put(&dpr_mb_put, config_data_key3);

	mbox_put(&dpr_mb_put, config_data_key4);
	mbox_put(&dpr_mb_put, config_data_key5);
	mbox_put(&dpr_mb_put, config_data_key6);
	mbox_put(&dpr_mb_put, config_data_key7);
	config_rcv=mbox_get(&dpr_mb_get);
	printk(KERN_INFO "[XT_NOCX] setup for aes done: ret = %d\n", config_rcv);



}

void config_ips(){
	printk(KERN_INFO "[XT_NOCX] setup for ips");
	u32 address = 5; 	//send to sw
	u32 header_len = ('h' << 24) | 1;	//the data vs. control byte
	mbox_put(&dpr_mb_put, header_len);
	mbox_put(&dpr_mb_put, address);
	int ret = mbox_get(&dpr_mb_get);
	printk(KERN_INFO "[XT_NOCX] setup for ips done: ret = %d\n", ret);


}

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

static int hw_sw_interface_thread_entry(void *arg)
{
	struct noc_pkt * rcv_pkt;
	unsigned char packet_content[64];
	int result, j,ret;
	int packet_count = 0;
	int dst_idp;
	int i = 0;
	while(likely(!kthread_should_stop())){
//		if (packet_count%10 == 0) {
		//	printk(KERN_INFO "[pr_hw_sw_interface] wait for message %d\n", packet_count );
//		}
	//	msleep(500);
		result = mbox_get(&h2s_mb_get);
		packet_count++;
		rcv_pkt = (struct noc_pkt *)shared_mem_h2s;
	//	printk(KERN_INFO "[reconos-interface] packet received with len from mbox %d, from memory %d\n", result, rcv_pkt->payload_len);		
	//	printk(KERN_INFO "packet received\n");
	//	print_packet(rcv_pkt);
	//	for (j = 0; j < 64; j++){ 
	//		packet_content[j] = shared_mem_h2s[j]; 
	//	}
	//	for (j = 0; j < 8; j++){ 
	//		printk(KERN_INFO "%02x %02x  %02x %02x  %02x %02x  %02x %02x\n", packet_content[(j*8)+0],packet_content[(j*8)+1],packet_content[(j*8)+2],packet_content[(j*8)+3], 
	//			packet_content[(j*8)+4],packet_content[(j*8)+5],packet_content[(j*8)+6],packet_content[(j*8)+7]);
	//	}
		mbox_put(&h2s_mb_put, (unsigned int) shared_mem_h2s);

		// try this reconfiguration
		// a) redirect packets directly from eth to sw

#ifdef BASIC
		if (packet_count == 50){
			config_eth(5);
			config_eth_ips(5);

			mbox_put(&dpr_mb_put,0xffffffff);
			msleep(2000);
			reconfig_done = 0;
			current_mapping = 2;
			wake_up_interruptible(&wait_queue);
			wait_event_interruptible(wait_queue, reconfig_done == 1); 

			reconos_hwt_setresources(&dpr_hwt,dpr_res,2);
			reconos_hwt_create(&dpr_hwt,DPR_HWT_SLOT_NR,NULL);
			//msleep(1000);

			config_ips();

		}
		if (packet_count == 100){
			config_eth(1);
			config_eth_ips(1);
		}
		if (packet_count == 150){
			config_eth(5);
			config_eth_ips(5);
		//	msleep(500);

			mbox_put(&dpr_mb_put,0xffffffff);
		
			reconfig_done = 0;
			current_mapping = 3;
			wake_up_interruptible(&wait_queue);
			wait_event_interruptible(wait_queue, reconfig_done == 1); 

			reconos_hwt_setresources(&dpr_hwt,dpr_res,2);
			reconos_hwt_create(&dpr_hwt,DPR_HWT_SLOT_NR,NULL);
		//	reconos_slot_reset(DPR_HWT_SLOT_NR,1);
		//	msleep(1000);
		//	reconos_slot_reset(DPR_HWT_SLOT_NR,0);

			config_ips();

		}
		if (packet_count == 200){
			config_eth(1);
			config_eth_ips(1);
		}
		if (packet_count == 250){
			printk(KERN_INFO "----------250\n");
			config_eth(5);
			config_eth_ips(5);
		//	msleep(500);

		//	mbox_put(&dpr_mb_put,0xffffffff);
		//	reconos_hwt_setresources(&dpr_hwt,dpr_res,2);
		//	reconos_hwt_create(&dpr_hwt,DPR_HWT_SLOT_NR,NULL);
	//		reconos_slot_reset(DPR_HWT_SLOT_NR,1);
	//		msleep(1000);
	//		reconos_slot_reset(DPR_HWT_SLOT_NR,0);
			mbox_put(&dpr_mb_put,0xffffffff);
			reconfig_done = 0;
			current_mapping = 2;
			wake_up_interruptible(&wait_queue);
			wait_event_interruptible(wait_queue, reconfig_done == 1); 

			reconos_hwt_setresources(&dpr_hwt,dpr_res,2);
			reconos_hwt_create(&dpr_hwt,DPR_HWT_SLOT_NR,NULL);
		//	msleep(1000);

			config_ips();

		}
		if (packet_count == 300){
			config_eth(1);
			config_eth_ips(1);
		}

#endif
		memcpy(&dst_idp, shared_mem_h2s + 8, 4);
	//	printk(KERN_INFO "destination idp: %d, len = %d\n", dst_idp, result);
//		if (dst_idp == 0){
	//	for (i = 0; i < 20; i+=4){
	//		printk(KERN_ERR "%#x %#x %#x %#x", shared_mem_h2s[i], shared_mem_h2s[i+1], shared_mem_h2s[i+2], shared_mem_h2s[i+3]);

	//	}
	//	}
		if (packet_count %1000 == 0){
		printk(KERN_INFO "destination idp: %d, len = %d\n", dst_idp, result);
		for (i = 0; i < 20; i+=4){
			printk(KERN_ERR "%#x %#x %#x %#x", shared_mem_h2s[i], shared_mem_h2s[i+1], shared_mem_h2s[i+2], shared_mem_h2s[i+3]);

		}
	//	if (packet_count %10 == 0){

			printk(KERN_INFO "beginning reconfig%d\n", packet_count);
			config_eth(5);
			config_eth_ips(5);

			if (current_mapping == 3){
				current_mapping = 2;
				mbox_put(&dpr_mb_put,0xffffffff);
				reconfig_done = 0;
				reconos_slot_reset(DPR_HWT_SLOT_NR,1);
				wake_up_interruptible(&wait_queue);
				wait_event_interruptible(wait_queue, reconfig_done == 1); 
				reconos_hwt_setresources(&dpr_hwt,dpr_res,2);
				reconos_hwt_create(&dpr_hwt,DPR_HWT_SLOT_NR,NULL);
				config_aes();
				config_eth(1);



			}
			else {
				current_mapping = 3;
				mbox_put(&dpr_mb_put,0xffffffff);
				reconfig_done = 0;
				reconos_slot_reset(DPR_HWT_SLOT_NR,1);
				wake_up_interruptible(&wait_queue);
				wait_event_interruptible(wait_queue, reconfig_done == 1); 
				reconos_hwt_setresources(&dpr_hwt,dpr_res,2);
				reconos_hwt_create(&dpr_hwt,DPR_HWT_SLOT_NR,NULL);
				config_ips();
				config_eth_ips(1);



			}
		//	mbox_put(&dpr_mb_put,0xffffffff);
		//	reconfig_done = 0;
		//	reconos_slot_reset(DPR_HWT_SLOT_NR,1);

		//	wake_up_interruptible(&wait_queue);
		//	wait_event_interruptible(wait_queue, reconfig_done == 1); 
		//	msleep(1000);

		//	reconos_hwt_setresources(&dpr_hwt,dpr_res,2);
		//	reconos_hwt_create(&dpr_hwt,DPR_HWT_SLOT_NR,NULL);
		//	config_ips();
		//	config_eth(1);
		//	config_eth_ips(1);
			printk(KERN_INFO "ending reconfig\n");

		}


	//	mbox_put(&h2s_mb_put, (unsigned int) shared_mem_h2s);

	
	//	mbox_put(&dpr_mb_put,4);  // 4: -> to eth
	//	ret = mbox_get(&dpr_mb_get);
	//	printk(KERN_INFO "[partial slot] PR %x\n", ret);

		// b) terminate delegate thread and hw thread
//		mbox_put(&dpr_mb_put,0xffffffff);

		// c) partial slot reset='1' 
//		reconos_slot_reset(DPR_HWT_SLOT_NR,1);
//		printk(KERN_INFO "[partial slot] reconfig. START\n");
//		if (config == 0)
//			printk(KERN_INFO "[partial slot] in the next 25 seconds, please configure AES\n");
//		else
//			printk(KERN_INFO "[partial slot] in the next 25 seconds, please configure IPS\n");

		// d) reconfigure slot
		// wait for about 20 seconds		
//		for (j=0;j<30;j++) msleep(1000);
//		printk(KERN_INFO "[partial slot] reconfig. STOP\n");

		// e) partial slot reset='0'
		//reconos_slot_reset(DPR_HWT_SLOT_NR,0);
		//printk(KERN_INFO "[partial slot] reset = 0 (reconfig. stop)\n");
		//for (j=0;j<2;j++) msleep(1000);	

		// f) create new delegate thread for dpr hw slot
//		reconos_hwt_setresources(&dpr_hwt,dpr_res,2);
//		reconos_hwt_create(&dpr_hwt,DPR_HWT_SLOT_NR,NULL);
//		msleep(2000);
//		config_aes();
//		if(packet_count == 60){
//			config_eth(1);
//		}
		//ff) configure hwt. 
//		if (config == 0){
//			config = 1;
//			config_aes();
//		}else{
//			config = 0;
//			config_ips();
//		}

	//	config_aes();

		// g) redirect packets over partial slot
		//mbox_put(&dpr_mb_put,5); mbox_put(&dpr_mb_put,5);
		//ret = mbox_get(&dpr_mb_get);
		//printk(KERN_INFO "[partial slot] PR %x\n", ret);

		//config_eth(1);
		//mbox_put(&eth_mb_put,1); // 1: -> partial block, 5: -> h2s
		//ret = mbox_get(&eth_mb_get);
		//ret = mbox_get(&eth_mb_get);

		//mbox_put(&dpr_mb_put,1);

	}
	return 0;
}


static int schedular_procfs_write(struct file *file, const char __user *buffer, unsigned long count, void *data){
	printk(KERN_INFO "[lana] got ack from userspace\n");
	reconfig_done = 1;
	wake_up_interruptible(&wait_queue);
	return 1;

}

static int schedular_procfs_read(char *page, char **start, off_t offset, 
			int count, int *eof, void *data)
{
	int last_mapping;
	if(offset) //simple hack to avoid "cat read twice problem"
		return 0;

	last_mapping = current_mapping;

	wait_event_interruptible(wait_queue, last_mapping != current_mapping); //&&current_mapping != 1
	//current_mapping = 2;
	if(current_mapping == 1){
		printk(KERN_INFO "[lana] both processes in SW, the userspace does not care");
		sprintf(page, "none");
	}
	if(current_mapping == 2){
		printk(KERN_INFO "[lana] mapping aes hw, ips sw");
		//sprintf(page, "partial_aes.bit");
		sprintf(page, "partial_aes.bit");
		
	}
	if(current_mapping == 3){
		printk(KERN_INFO "[lana] mapping aes sw, ips hw");
		//sprintf(page, "partial_ips.bit");
		sprintf(page, "partial_ips.bit");

	}
	*eof = 1;
	return 16;
	//return 14;
}


static int __init init_pr_hw_sw_interface_module(void)
{
	//int ret2,i;
	//char * shared_mem_h2s;
	//char * shared_mem_s2h;
	//long unsigned jiffies_before;
	//long unsigned jiffies_after;
	//int result,j;
	//int ret3, ret4;
	//struct noc_pkt * rcv_pkt;
	//unsigned char packet_content[64];
	int ret;
	printk(KERN_INFO "[pr_hw_sw_interface] Init.\n");

	mbox_init(&dpr_mb_put, 200);
    	mbox_init(&dpr_mb_get, 200);
	mbox_init(&eth_mb_put, 200);
    	mbox_init(&eth_mb_get, 200);
	mbox_init(&h2s_mb_put, 2);
    	mbox_init(&h2s_mb_get, 2);
	mbox_init(&s2h_mb_put, 2);
    	mbox_init(&s2h_mb_get, 2);
	printk(KERN_INFO "[pr_hw_sw_interface] mbox_init done, starting autodetect.\n");

	reconos_init_autodetect();

	printk(KERN_INFO "[pr_hw_sw_interface] Creating hw-thread.\n");
	dpr_res[0].type = RECONOS_TYPE_MBOX;
	dpr_res[0].ptr  = &dpr_mb_put;	  	
    	dpr_res[1].type = RECONOS_TYPE_MBOX;
	dpr_res[1].ptr  = &dpr_mb_get;

	eth_res[0].type = RECONOS_TYPE_MBOX;
	eth_res[0].ptr  = &eth_mb_put;	  	
    	eth_res[1].type = RECONOS_TYPE_MBOX;
	eth_res[1].ptr  = &eth_mb_get;

	//s_res[0].type = RECONOS_TYPE_MBOX;
	//s_res[0].ptr  = &s_mb_put;	  	
    	//s_res[1].type = RECONOS_TYPE_MBOX;
	//s_res[1].ptr  = &s_mb_get;

	h2s_res[0].type = RECONOS_TYPE_MBOX;
	h2s_res[0].ptr  = &h2s_mb_put;	  	
    	h2s_res[1].type = RECONOS_TYPE_MBOX;
	h2s_res[1].ptr  = &h2s_mb_get;

	s2h_res[0].type = RECONOS_TYPE_MBOX;
	s2h_res[0].ptr  = &s2h_mb_put;	  	
    	s2h_res[1].type = RECONOS_TYPE_MBOX;
	s2h_res[1].ptr  = &s2h_mb_get;


	reconos_hwt_setresources(&dpr_hwt,dpr_res,2);
	reconos_hwt_create(&dpr_hwt,DPR_HWT_SLOT_NR,NULL);

    	reconos_hwt_setresources(&eth_hwt,eth_res,2);
	reconos_hwt_create(&eth_hwt,ETH_HWT_SLOT_NR,NULL);

	reconos_hwt_setresources(&h2s_hwt,h2s_res,2);
	reconos_hwt_create(&h2s_hwt,H2S_HWT_SLOT_NR,NULL);

	reconos_hwt_setresources(&s2h_hwt,s2h_res,2);
	reconos_hwt_create(&s2h_hwt,S2H_HWT_SLOT_NR,NULL);

	//printk(KERN_INFO "[xt_nocx] changing eth config for aes: flag hw");

	

	// forward incoming packets (from physical ETH interface to partial reconfigurable functional block hwt_pr_0) 
	config_eth(5);
	config_eth_ips(5);
	//mbox_put(&eth_mb_put,1); // 1: -> partial block, 5: -> h2s
	//ret = mbox_get(&eth_mb_get);
	//ret = mbox_get(&eth_mb_get);

	//setup the hw -> sw thread
	printk(KERN_INFO "[pr_hw_sw_interface] Allocate memory\n");
	shared_mem_h2s = (char *) __get_free_pages(GFP_KERNEL | __GFP_NOWARN, 4); //allocate 2² pages get_zeroed_page(GFP_KERNEL);
	printk(KERN_INFO "[pr_hw_sw_interface] h2s memory %p\n", shared_mem_h2s);
	mbox_put(&h2s_mb_put, (unsigned int) shared_mem_h2s);

	//setup the sw -> hw thread
	shared_mem_s2h = (char *) __get_free_pages(GFP_KERNEL | __GFP_NOWARN, 4); //allocate 2² pages get_zeroed_page(GFP_KERNEL);
	printk(KERN_INFO "[pr_hw_sw_interface] s2h memory %p\n", shared_mem_s2h);
	mbox_put(&s2h_mb_put, (unsigned int) shared_mem_s2h);
	printk(KERN_INFO "[pr_hw_sw_interface] HZ= %d\n", HZ);

	memset(shared_mem_s2h, 0, 3000);
	memset(shared_mem_h2s, 0, 3000);

	config = 0;
	config_ips();
	
	/*while(1){
		result = mbox_get(&h2s_mb_get);
		rcv_pkt = (struct noc_pkt *)shared_mem_h2s;
		//packet_len = *(int *)shared_mem_h2s;
		printk(KERN_INFO "[reconos-interface] packet received with len from mbox %d, from memory %d\n", result, rcv_pkt->payload_len);

		//printk(KERN_INFO "packet sent\n");
		//print_packet(snd_pkt);		
		printk(KERN_INFO "packet received\n");
		print_packet(rcv_pkt);


		for (j = 0; j < 64; j++){ 
			packet_content[j] = shared_mem_h2s[j]; 
		}
		for (j = 0; j < 8; j++){ 
			printk(KERN_INFO "%02x %02x  %02x %02x  %02x %02x  %02x %02x\n", packet_content[(j*8)+0],packet_content[(j*8)+1],packet_content[(j*8)+2],packet_content[(j*8)+3], 
				packet_content[(j*8)+4],packet_content[(j*8)+5],packet_content[(j*8)+6],packet_content[(j*8)+7]);
		}
		mbox_put(&h2s_mb_put, (unsigned int) shared_mem_h2s);
		//printk(KERN_INFO "[pr_hw_sw_interface] wait for next message\n");
		//// send generated packets to HWT Ethernet Test
		//mbox_put(&eth_mb_put,5);
		//ret3 = mbox_get(&eth_mb_get);
		//ret4 = mbox_get(&eth_mb_get);
		////printk("packets: [Smart CAM] received=%08d   sent=%08d,   [ETH] received=%08d   sent=%08d\n",ret,ret2,ret3,ret4);
		//printk("packets: [ETH] received=%08d   sent=%08d\n",ret3,ret4);
		////printk("\n");
		//msleep(1000);
	}*/

	example_dir = proc_mkdir("example", NULL);
	scheduler_proc = create_proc_entry("scheduler", 0644, example_dir);
	if (!scheduler_proc)
		goto out;
	scheduler_proc->read_proc = schedular_procfs_read;
	scheduler_proc->write_proc = schedular_procfs_write;

	receive_thread = kthread_create(hw_sw_interface_thread_entry, 0,"hw_sw_iface_receive_thread");
        if (IS_ERR(receive_thread)) {
                printk(KERN_ERR "[pr_hw_sw_interface] Error creating 'receive' thread!\n");
                return -EIO;
        }

        wake_up_process(receive_thread);

out:
	return 0;
}


static void __exit cleanup_pr_hw_sw_interface_module(void)
{
	reconos_cleanup();
	kthread_stop(receive_thread);
	printk("[pr_hw_sw_interface] unloaded\n");
}

module_init(init_pr_hw_sw_interface_module);
module_exit(cleanup_pr_hw_sw_interface_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ariane Keller <ariane.keller@tik.ee.ethz.ch>");
MODULE_AUTHOR("Markus Happe  <markus.happe@tik.ee.ethz.ch>");
MODULE_DESCRIPTION("EmbedNet HW/SW interface");
