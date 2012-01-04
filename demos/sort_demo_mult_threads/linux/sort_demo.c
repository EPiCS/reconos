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
#include "config.h"
#include "merge.h"
#include "data.h"
#include "bubblesort.h"
#include "sort8k.h"
#include "timing.h"

#define PAGE_SIZE 4096
#define PAGE_WORDS 1024
#define PAGE_MASK 0xFFFFF000

#define PAGES_PER_THREAD 2

#define MAX_BURST_SIZE 1023

#define SW_THREADS 2
#define HW_THREADS 14
#define MAX_THREADS (SW_THREADS+HW_THREADS)

// software threads
pthread_t swt[SW_THREADS];
pthread_attr_t swt_attr[SW_THREADS];

// hardware threads
struct reconos_resource res[HW_THREADS][2];
struct reconos_hwt hwt[HW_THREADS];


// mailboxes
struct mbox mb_start[MAX_THREADS];
struct mbox mb_stop[MAX_THREADS];


unsigned int* malloc_page_aligned(unsigned int pages)
{
	unsigned int * temp = malloc ((pages+1)*PAGE_SIZE);
	unsigned int * data = (unsigned int*)(((unsigned int)temp / PAGE_SIZE + 1) * PAGE_SIZE);
	return data;
}

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
    int i = (int) data;
    unsigned int dummy = 23;
    printf("SW Thread %i started with mailbox index %i ...\n", i-HW_THREADS, i);
    while ( 1 ) {
        ret = mbox_get(&mb_start[i]);
	printf("SW Thread %i: Got address %p from mailbox %p.\n", i, (void*)ret, &mb_start[i]);
	if (ret == UINT_MAX)
	{
	  pthread_exit((void*)0);
	  printf("SW Thread %i: Got exit command from mailbox %p.\n", i, &mb_start[i]);
	}
	else
	{
	  bubblesort( (unsigned int*) ret, N);
	}
        
        mbox_put(&mb_stop[i], dummy);
    }

    return (void*)0;
}

int main(int argc, char ** argv)
{
	assert(argc == 1);
	int i;
	int ret;


	// init mailboxes
	for (i = 0; i < MAX_THREADS; i++)
	{
	  mbox_init(&(mb_start[i]),3);
	  mbox_init(&(mb_stop[i]) ,3);
	}

	// init reconos and communication resources
	reconos_init(0);

	for (i = 0; i < HW_THREADS; i++)
	{
	  res[i][0].type = RECONOS_TYPE_MBOX;
	  res[i][0].ptr  = &(mb_start[i]);
	  	
	  res[i][1].type = RECONOS_TYPE_MBOX;
	  res[i][1].ptr  = &(mb_stop[i]);

	  reconos_hwt_setresources(&(hwt[i]),res[i],2);
	  reconos_hwt_create(&(hwt[i]),i+1,NULL);
	  printf("Created hw-thread %i, at FSL Link %i.\n", i, hwt[i].slot);
	}

	// init software threads
	for (i = 0; i < SW_THREADS; i++)
	{
	  pthread_attr_init(&swt_attr[i]);
	  pthread_create(&swt[i], &swt_attr[i], sort_thread, (void*)i+HW_THREADS);
	  printf("Created sw-thread %i, with mailbox index %i.\n", i, i+HW_THREADS);
	}

	// create pages and generate data
	// every thread shall have its own slice of data to sort
	printf("malloc page aligned ...\n");
	unsigned int *data = malloc_page_aligned(MAX_THREADS*PAGES_PER_THREAD);
	printf("generate data ...\n");
	generate_data( data, (MAX_THREADS*PAGE_SIZE*PAGES_PER_THREAD)/4 );

	// print data of first page
	//printf("Printing of generated data skipped. \n");
	print_data(data, (MAX_THREADS*PAGE_SIZE*PAGES_PER_THREAD)/4);


	// Start sort threads
	for (i=0; i<MAX_THREADS; i++)
	{
	  printf("Starting sort thread %i via mailbox %p.\n",i,(void*)&(mb_start[i]));
	  mbox_put(&(mb_start[i]),(unsigned int)data+(i*PAGE_SIZE*PAGES_PER_THREAD));
	}

	// Wait for results
	for (i=0; i<MAX_THREADS; i++)
	{
	  printf("Waiting for result from thread %i via mailbox %p.\n",i,(void*)&(mb_stop[i]));
	  ret = mbox_get(&(mb_stop[i]));
	}  

	
	//
	// merge data
	printf("Merging sorted data slices...\n");
	unsigned int * temp = malloc_page_aligned(MAX_THREADS*PAGES_PER_THREAD);
	printf("Data buffer at address %p \n", (void*)data);
	printf("Address of temporary merge buffer: %p\n", (void*)temp);
	printf("Total size of data in bytes: %i\n",(MAX_THREADS*PAGE_SIZE*PAGES_PER_THREAD));
	printf("Size of a data slice in bytes: %i\n",(PAGE_SIZE*PAGES_PER_THREAD));
	data = recursive_merge( data, 
				temp,
				(MAX_THREADS*PAGE_SIZE*PAGES_PER_THREAD)/4, 
				(PAGE_SIZE*PAGES_PER_THREAD)/4, 
				simple_merge 
				);

	// check data
	//data[0] = 6666; // manual fault
	printf("Checking sorted data: ... ");
	ret = check_data( data, (MAX_THREADS*PAGE_SIZE*PAGES_PER_THREAD)/4);
	if (ret==-1)
	  {
	    printf("failure\n");
	    print_data(data, (MAX_THREADS*PAGE_SIZE*PAGES_PER_THREAD)/4);
	  }
	else
	  {
	    printf("success\n");
	    print_data(data, (MAX_THREADS*PAGE_SIZE*PAGES_PER_THREAD)/4);
	  }

	// terminate all threads
	for (i=0; i<MAX_THREADS; i++)
	{
	  mbox_put(&(mb_start[i]),UINT_MAX);
	  pthread_join(hwt[i].delegate,NULL);
	}

	//free(data);
	// Memory Leak on variable data!!!
	
	return 0;
}

