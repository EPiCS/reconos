#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <math.h>

// ReconOS
#include "reconos.h"
#include "mbox.h"

#include "timing.h"
#include "pr_demo.h"

struct reconos_resource res[NUM_SLOTS][2];
struct reconos_hwt hwt[NUM_SLOTS];
struct mbox mb_in[NUM_SLOTS];
struct mbox mb_out[NUM_SLOTS];

unsigned char *shared_mem_h2s;
unsigned char *shared_mem_s2h;

unsigned int configured = NONE;

unsigned int trigger_reconfig = 0;

sem_t do_reconfig;

int reconfigure_prblock(int thread_id)
{
	timing_t t_start, t_stop;
	ms_t t_check;
	int ret = -2;
	if (thread_id==configured) return 0;
	// send thread exit command
	t_start = gettime();
	mbox_put(&mb_in[HWT_DPR],THREAD_EXIT_CMD);
	//sleep(1);
	usleep(100);
	//sleep(0);
	reconos_slot_reset(HWT_DPR,1);
	//printf("Starting reconfiguration\n");
	// reconfigure hardware slot
	ret = hw_icap_load(thread_id);
	configured = thread_id;
	reconos_slot_reset(HWT_DPR,0);
	t_stop = gettime();
	t_check = calc_timediff_ms(t_start, t_stop);
	printf("Reconfiguration done in %lu ms\n", t_check);
	// reset hardware thread and start new delegate
	//reconos_hwt_setresources(&hwt[HWT_DPR],res[HWT_DPR],2);
	//reconos_hwt_create(&hwt[HWT_DPR],HWT_DPR,NULL);
	return ret;
}

void config_eth_aes(int addr)
{
	int ret = 0;
	unsigned int config_eth_hash_1 = 0xcdcdcdcd;
	unsigned int config_eth_hash_2 = 0xcdcdcdcd;
	unsigned int config_eth_idp = 0x2; //TODO
	unsigned int config_eth_address = addr; //global 0, local 1 -> aes
	mbox_put(&mb_in[HWT_ETH], config_eth_hash_1 );
	mbox_put(&mb_in[HWT_ETH], config_eth_hash_2);
	mbox_put(&mb_in[HWT_ETH], config_eth_idp);
	mbox_put(&mb_in[HWT_ETH], config_eth_address);
	ret = mbox_get(&mb_out[HWT_ETH]);
}

void config_eth_ips(int addr)
{
	int ret = 0;
	unsigned int config_eth_hash_1 = 0xabababab;
	unsigned int config_eth_hash_2 = 0xabababab;
	unsigned int config_eth_idp = 0x3; //TODO
	unsigned int config_eth_address = addr; //global 0, local 1 -> ips
	mbox_put(&mb_in[HWT_ETH], config_eth_hash_1 );
	mbox_put(&mb_in[HWT_ETH], config_eth_hash_2);
	mbox_put(&mb_in[HWT_ETH], config_eth_idp);
	mbox_put(&mb_in[HWT_ETH], config_eth_address);
	ret = mbox_get(&mb_out[HWT_ETH]);
}


void config_aes(void){
	int ret = 0;
	printf("[aes] setup for aes\n");
	mbox_put(&mb_in[HWT_DPR], 1);
	mbox_put(&mb_in[HWT_DPR], 20); // -> sw=20, -> eth=16 
	mbox_put(&mb_in[HWT_DPR], 0x16157e2b); // key[0]
	mbox_put(&mb_in[HWT_DPR], 0xa6d2ae28);
	mbox_put(&mb_in[HWT_DPR], 0x8815f7ab);
	mbox_put(&mb_in[HWT_DPR], 0x3c4fcf09);
	mbox_put(&mb_in[HWT_DPR], 0x13121110);
	mbox_put(&mb_in[HWT_DPR], 0x17161514);
	mbox_put(&mb_in[HWT_DPR], 0x1b1a1918);
	mbox_put(&mb_in[HWT_DPR], 0x1f1e1d1c); // key[7]
	ret=mbox_get(&mb_out[HWT_DPR]);
	printf("[aes] setup for aes done: ret = %d\n", ret);
}

void config_ips(void){
	int ret = 0;
	unsigned int address = 5; 	//send to sw
	unsigned int header_len = ('h' << 24) | 1;	//the data vs. control byte
	printf("[ips] setup for ips\n");
	mbox_put(&mb_in[HWT_DPR], header_len);
	mbox_put(&mb_in[HWT_DPR], address);
	ret = mbox_get(&mb_out[HWT_DPR]);
	printf("[ips] setup for ips done: ret = %d\n", ret);
}


void setup_noc(int thread_id)
{
	shared_mem_h2s = malloc(4096); 
	memset(shared_mem_h2s, 0, 4096);
	shared_mem_s2h = malloc(4096); 
	memset(shared_mem_s2h, 0, 4096);
	mbox_put(&mb_in[HWT_H2S], (unsigned int) shared_mem_h2s);
	mbox_put(&mb_in[HWT_S2H], (unsigned int) shared_mem_s2h);
	config_eth_aes(5);
	config_eth_ips(5);
	if (thread_id==AES)
	{
		config_aes();
		config_eth_aes(1);
	}
	if (thread_id==IPS)
	{
		config_ips();
		config_eth_ips(1);
	}
}

void * receive_pkts( void * data )
{
	int result,dst_idp,i;
	unsigned int num_packets = 0;
	printf("[receive] started thread\n");
	while(1)
	{
		result = mbox_get(&mb_out[HWT_H2S]);
		reconos_cache_flush();
		num_packets++;
		//printf("[receive] packet no. %d\n", num_packets);
		printf(".");

		memcpy(&dst_idp, shared_mem_h2s + 8, 4);
		if (num_packets%249 == 0){ // 250
			printf("\n[receive] destination idp: %d, len = %d\n", dst_idp, result);
			for (i = 0; i < 20; i+=4){
				printf("        %#x %#x %#x %#x\n", shared_mem_h2s[i], shared_mem_h2s[i+1], shared_mem_h2s[i+2], shared_mem_h2s[i+3]);
			}
		}
		reconos_cache_flush();
		mbox_put(&mb_in[HWT_H2S], (unsigned int) shared_mem_h2s);
		//////////if (num_packets %10000 == 0 && do_reconfig == 0) do_reconfig = 1;
		if (num_packets%4000 == 0 && trigger_reconfig == 0) { trigger_reconfig = 1; sem_post(&do_reconfig); }
	}
	return NULL;	
}

void * reconfigure_noc( void * data )
{
	printf("[reconfig] started thread\n");
	while(1)
	{
		// 1. IPS -> HW
		sem_wait(&do_reconfig);
		config_eth_ips(5);
		config_eth_aes(5);
		printf("[reconfig] IPS...start\n");
		reconfigure_prblock(IPS);
		printf("[reconfig] IPS...done\n");
		config_ips();
		config_eth_ips(1);
		trigger_reconfig = 0;

		// 2. AES -> HW
		sem_wait(&do_reconfig);
		config_eth_ips(5);
		config_eth_aes(5);
		printf("[reconfig] AES...start\n");
		//printf("[reconfig] IPS no. 2...start\n"); // try
		reconfigure_prblock(AES);
		//reconfigure_prblock(IPS); // try
		printf("[reconfig] AES...done\n");
		//printf("[reconfig] IPS no. 2...done\n"); // try
		config_aes();
		//config_ips(); // try
		config_eth_aes(1);	
		trigger_reconfig = 0;
	}
	return NULL;		
}


// MAIN ////////////////////////////////////////////////////////////////////
int main(int argc, char *argv[])
{
	int i;
	pthread_t thread_receive, thread_reconf;

	printf( "-------------------------------------------------------\n"
		    "PROTOCOL GRAPH PR AES IPS DEMONSTRATOR\n"
		    "(" __FILE__ ")\n"
		    "Compiled on " __DATE__ ", " __TIME__ ".\n"
		    "-------------------------------------------------------\n\n" );

	printf("[app] Initialize ReconOS.\n");
	reconos_init_autodetect();

	printf("[app] Creating delegate threads.\n\n");
	for (i=0; i<NUM_SLOTS; i++){
		// mbox init
		mbox_init(&mb_in[i],  10);
		mbox_init(&mb_out[i], 10);
		// define resources
		res[i][0].type = RECONOS_TYPE_MBOX;
		res[i][0].ptr  = &mb_in[i];	  	
		res[i][1].type = RECONOS_TYPE_MBOX;
		res[i][1].ptr  = &mb_out[i];
		// start delegate threads
		reconos_hwt_setresources(&hwt[i],res[i],2);
		reconos_hwt_create(&hwt[i],i,NULL);
	}

	trigger_reconfig = 0;
	sem_init(&do_reconfig, 0, 0);

	// configure NoC
	printf( "[app] configure NoC\n");
	//setup_noc(AES);
	//setup_noc(IPS);
	setup_noc(NONE);

	// cache partial bitstreams in memory
	printf( "[app] cache bitstreams\n");
	cache_bitstream(AES, "partial_bitstreams/partial_aes.bit");
	cache_bitstream(IPS, "partial_bitstreams/partial_ips.bit");

	// thread 1: reconfigure NoC
	printf( "[app] create thread: reconfigure NoC on-the-fly\n");
	pthread_create( &thread_reconf, NULL, reconfigure_noc, 0);

	// thread 2: receive packets
	printf( "[app] create thread: receive packets\n");
	pthread_create( &thread_receive, NULL, receive_pkts, 0);
	printf( "[app] wait for packets\n");

	// wait until threads are done
	pthread_join( thread_reconf, NULL);
	pthread_join( thread_receive, NULL);

	// clean up
	sem_destroy(&do_reconfig);
	free(shared_mem_h2s);
	free(shared_mem_s2h);
	return 0;
}

