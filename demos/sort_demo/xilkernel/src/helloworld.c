/*
 * Copyright (c) 2009 Xilinx, Inc.  All rights reserved.
 *
 * Xilinx, Inc.
 * XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A
 * COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
 * ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
 * STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
 * IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
 * FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
 * XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
 * THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
 * ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
 * FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.
 *
 */

/* helloworld_xmk.c: launch a thread that prints out Hello World */

#include "xmk.h"
#include "sys/init.h"
#include "platform.h"
#include "mb_interface.h"

#include <stdio.h>
#include <stdlib.h>

#include "reconos.h"
#include "mbox.h"

#include "reconos.h"
#include "mbox.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>
#include "mergesort.h"
#include "data.h"
#include "bubblesort.h"
#include "timing.h"
#include "logging.h"


#define BLOCK_WORDS 2048

#define NUM_HWTS 14
#define NUM_SWTS 0
#define NUM_BLOCKS 128


// software threads
pthread_t swt[NUM_SWTS];
pthread_attr_t swt_attr[NUM_SWTS];

// hardware threads
struct reconos_resource res[2];
struct reconos_hwt hwt[NUM_HWTS];


// mailboxes
struct mbox mb_start;
struct mbox mb_stop;

// size is given in words, not bytes!
void print_data(unsigned int* data, unsigned int size)
{
	int i;
	for (i=0; i<size; i++)
	{
		printf("(%04d) %04d \t", i, data[i]);
		if ((i+1)%4 == 0) printf("\n");
	}
	printf("\n");
}

// sort thread shall behave the same as hw thread:
// - get pointer to data buffer
// - if valid address: sort data and post answer
// - if exit command: issue thread exit os call
void *sort_thread(void* data)
{
	unsigned int ret;
	unsigned int dummy = 23;
	struct reconos_resource *res  = (struct reconos_resource*) data;
	struct mbox *mb_start = res[0].ptr;
	struct mbox *mb_stop  = res[1].ptr;

	while ( 1 ) {
		ret = mbox_get(mb_start);
		if(ret == UINT_MAX){
			pthread_exit((void*)0);
		} else {
			bubblesort( (unsigned int*) ret, BLOCK_WORDS);
		}
		mbox_put(mb_stop, dummy);
	}
	return NULL;
}

void* sort_main(void * arg)
{
	int i;
	int hw_threads;
	int sw_threads;
	unsigned int *data, *copy;

	logging_init();

	unsigned int generate_ms;
	unsigned int sort_ms;
	unsigned int merge_ms;
	unsigned int check_ms;

	hw_threads = NUM_HWTS;
	sw_threads = NUM_SWTS;

	// init mailboxes
	mbox_init(&mb_start,NUM_BLOCKS);
    mbox_init(&mb_stop ,NUM_BLOCKS);

	// init reconos and communication resources
	reconos_init(14,15);

	res[0].type = RECONOS_TYPE_MBOX;
	res[0].ptr  = &mb_start;
        res[1].type = RECONOS_TYPE_MBOX;
	res[1].ptr  = &mb_stop;

	INFO("Creating %i hw-threads: ", hw_threads);
	for (i = 0; i < hw_threads; i++)
	{
		INFO(" %i",i);
	  reconos_hwt_setresources(&(hwt[i]),res,2);
	  reconos_hwt_create(&(hwt[i]),i,NULL);
	}
	INFO("\n");

	// init software threads
	INFO("Creating %i sw-threads: ",sw_threads);
	for (i = 0; i < sw_threads; i++)
	{
		INFO(" %i",i);
	  pthread_attr_init(&swt_attr[i]);
	  pthread_create(&swt[i], &swt_attr[i], sort_thread, (void*)res);
	}
	INFO("\n");

	// create pages and generate data
	generate_ms = time_ms();

	INFO("malloc page aligned ...\n");
	data = malloc(NUM_BLOCKS*BLOCK_WORDS*sizeof*data);
	copy = malloc(NUM_BLOCKS*BLOCK_WORDS*sizeof*data);;
	INFO("generate data ...\n");
	generate_data(data,NUM_BLOCKS*BLOCK_WORDS);
	memcpy(copy,data,NUM_BLOCKS*BLOCK_WORDS*sizeof*data);

	generate_ms = time_ms() - generate_ms;

	// Start sort threads
	sort_ms = time_ms();

	INFO("Putting %i blocks into job queue: ", NUM_BLOCKS);
	for (i = 0; i < NUM_BLOCKS; i++)
	{
		INFO(" %i",i);
		mbox_put(&mb_start,(unsigned int)data+(i*BLOCK_WORDS));
	}

	// Wait for results
	INFO("\nWaiting for %i acknowledgements: ", NUM_BLOCKS);
	for (i = 0; i < NUM_BLOCKS; i++)
	{
		INFO(" %i",i);
		mbox_get(&mb_stop);
	}
	INFO("\n");

	sort_ms = time_ms() - sort_ms;

	// merge data
	merge_ms = time_ms();

	INFO("Merging sorted data slices...\n");


	unsigned int * temp = malloc(NUM_BLOCKS*BLOCK_WORDS*sizeof*temp);
	mergesort(data,temp,BLOCK_WORDS,NUM_BLOCKS);
	data = temp;
	/*
	data = recursive_merge( data,
				temp,
				NUM_BLOCKS*BLOCK_WORDS,
				BLOCK_WORDS,
				simple_merge
				);
	*/
	merge_ms = time_ms() - merge_ms;

	// check data
	check_ms = time_ms();

	INFO("Quick check sorted data (checksum = %d): ... ",generate_checksum(copy,NUM_BLOCKS*BLOCK_WORDS));

	if(quick_check_data(data,NUM_BLOCKS*BLOCK_WORDS,generate_checksum(copy,NUM_BLOCKS*BLOCK_WORDS)) != 0){
		INFO("FAILURE\r\n");
	} else {
		INFO("success\n");
	}
	/*

  	INFO("Checking sorted data: ... ");

	ret = check_data( data, copy, TO_WORDS(buffer_size));
	if (ret >= 0)
	  {
		INFO("failure at word index %i\n", -ret);
		INFO("expected 0x%08X    found 0x%08X\n",copy[ret],data[ret]);
		INFO("dumping the first 2048 words:\n");
            for(i = 0; i < 2048; i++){
            	INFO("%08X ",data[i]);
              if((i % 8) == 7) INFO("\n");
            }
	  }
	else
	  {
		INFO("success\n");
	    //print_data(data, TO_WORDS(buffer_size));
	  }
	*/
	check_ms = time_ms() - check_ms;

	// terminate all threads
	INFO("Sending terminate message to %i threads:", hw_threads + sw_threads);

	for (i = 0; i < hw_threads + sw_threads; i++)
	{
		INFO(" %i",i);
		mbox_put(&mb_start,UINT_MAX);
	}

	INFO("\n");

	INFO("Waiting for termination...\n");
	for (i=0; i<hw_threads; i++)
	{
	  pthread_join(hwt[i].delegate,NULL);
	}
	for (i=0; i<sw_threads; i++)
	{
	  pthread_join(swt[i],NULL);
	}

	INFO("done\n");
	INFO("Running times (size: %d words, %d hw-threads, %d sw-threads):\n", NUM_BLOCKS*BLOCK_WORDS, hw_threads, sw_threads);
	INFO("\tGenerate data: %lu ms\n",generate_ms);
	INFO("\tSort data    : %lu ms\n",sort_ms);
	INFO("\tMerge data   : %lu ms\n",merge_ms);
	INFO("\tCheck data   : %lu ms\n",check_ms);
	INFO("Total computation time (sort & merge): %lu ms\n",sort_ms + merge_ms);



	//free(data);
	// Memory Leak on variable data!!!

	return NULL;
}


int main()
{
    init_platform();

    /* Initialize xilkernel */
    xilkernel_init();

    /* add a thread to be launched once xilkernel starts */
    xmk_add_static_thread(sort_main, 0);

    /* start xilkernel - does not return control */
    xilkernel_start();

    /* Never reached */
    cleanup_platform();

    return 0;
}
