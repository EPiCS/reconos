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

// hw threads
#define NUM_SLOTS 2
#define HWT_ICAP  0
#define HWT_DPR   1

#define ADD 0
#define SUB 1

#define THREAD_EXIT_CMD 0xFFFFFFFF

struct reconos_resource res[NUM_SLOTS][2];
struct reconos_hwt hwt[NUM_SLOTS];
struct mbox mb_in[NUM_SLOTS];
struct mbox mb_out[NUM_SLOTS];

unsigned int configured = ADD;

int test_prblock(int thread_id)
{
	unsigned int ret, val=0x60003;
	mbox_put(&mb_in[HWT_DPR],val);
	ret = mbox_get(&mb_out[HWT_DPR]);
	printf("  calc - input=%x, output=%d\n",val,ret);
	if (thread_id==ADD && ret==(val/0x10000)+(val%0x10000)) return 1;
	if (thread_id==SUB && ret==(val/0x10000)-(val%0x10000)) return 1;
	return 0;
}

int test_icapblock(void)
{
	unsigned int ret;
	mbox_put(&mb_in[HWT_ICAP],1);
	mbox_put(&mb_in[HWT_ICAP],2);
	ret = mbox_get(&mb_out[HWT_ICAP]);
	printf("  ret=%d\n",ret);
	return 0;
}

int reconfigure_prblock(int thread_id)
{
	int ret = -2;

	if (thread_id==configured) return 0;

	// send thread exit command
	mbox_put(&mb_in[HWT_DPR],THREAD_EXIT_CMD);
	
	// reconfigure hardware slot
	if (thread_id==ADD)      {ret = system("cat partial_bitstreams/partial_add.bit > /dev/icap0"); printf("  cmd: cat partial_bitstreams/partial_add.bit > /dev/icap0\n"); configured = thread_id;}
	else if (thread_id==SUB) {ret = system("cat partial_bitstreams/partial_sub.bit > /dev/icap0"); printf("  cmd: cat partial_bitstreams/partial_sub.bit > /dev/icap0\n"); configured = thread_id;}

	// reset hardware thread and start new delegate
	reconos_hwt_setresources(&hwt[HWT_DPR],res[HWT_DPR],2);
	reconos_hwt_create(&hwt[HWT_DPR],HWT_DPR,NULL);

	return ret;
}

// MAIN ////////////////////////////////////////////////////////////////////
int main(int argc, char *argv[])
{
	int i, ret,cnt=1;
	printf( "-------------------------------------------------------\n"
		    "ICAP DEMONSTRATOR\n"
		    "(" __FILE__ ")\n"
		    "Compiled on " __DATE__ ", " __TIME__ ".\n"
		    "-------------------------------------------------------\n\n" );

	printf("[icap] Initialize ReconOS.\n");
	reconos_init_autodetect();

	printf("[icap] Creating delegate threads.\n\n");
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

	while(1){
		// reconfigure partial hw slot and check thread
		printf("[icap] Test no. %03d\n",cnt);

		ret = reconfigure_prblock(ADD);
		ret = test_prblock(ADD);

		if (ret) printf("  # ADD: passed\n"); else printf("  # ADD: failed\n");

		ret = reconfigure_prblock(SUB);
		ret = test_prblock(SUB);

		if (ret) printf("  # SUB: passed\n"); else printf("  # SUB: failed\n");
		sleep(1); 
		cnt++;
	}
	return 0;
}

