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

#define MAX_THREADS 2

struct reconos_resource res[MAX_THREADS][2];

struct reconos_hwt hwt[MAX_THREADS];

struct mbox mb_start[MAX_THREADS];
struct mbox mb_stop[MAX_THREADS];

#define PAGE_SIZE 4096
#define PAGE_WORDS 1024
#define PAGE_MASK 0xFFFFF000

#define MAX_BURST_SIZE 1023



unsigned int* alloc_aligned_page()
{
	unsigned int * temp = malloc (2*PAGE_SIZE);
	unsigned int * data = (unsigned int*)(((unsigned int)temp / PAGE_SIZE + 1) * PAGE_SIZE);
	//unsigned int * temp = malloc (SIZE*sizeof(unsigned int));
	return data;
}

void print_data(unsigned int* data)
{
	int i;
	for (i=0; i<SIZE; i++)
	{
		printf("(%04d) %04d \t", i, data[i]);
		if ((i+1)%4 == 0) printf("\n");
	}
	printf("\n");
}

int main(int argc, char ** argv)
{
	assert(argc == 1);
	int i;
	int ret;


	// Init reconos and communication resources
	reconos_init(0);

	for (i = 0; i < MAX_THREADS; i++)
	{
	  res[i][0].type = RECONOS_TYPE_MBOX;
	  res[i][0].ptr  = &(mb_start[i]);
	  	
	  res[i][1].type = RECONOS_TYPE_MBOX;
	  res[i][1].ptr  = &(mb_stop[i]);

	  mbox_init(&(mb_start[i]),3);
	  mbox_init(&(mb_stop[i]) ,3);

	  reconos_hwt_setresources(&(hwt[i]),res[i],2);
	  reconos_hwt_create(&(hwt[i]),i+1,NULL);
	  printf("Created thread %i, at FSL Link %i.\n", i, hwt[i].slot);
	}
				

	// create pages and generate data
	unsigned int *data[MAX_THREADS];
	for (i=0; i<MAX_THREADS; i++)
	{
	  printf("malloc page %i\n", i);
	  data[i]= alloc_aligned_page();
	  printf("generate data for page %i\n",i);
	  generate_data( data[i], SIZE );
	}
		

	// print data of first page
	printf("Printing of generated data skipped. \n");
	//print_data(data[0]);


	// sort data
	//printf("sort data\n");
	//for (i=0; i<SIZE/N; i++)
	//{
	//	bubblesort( &data[i*N], N );
	//}

	//bubblesort( data, N );

	// Start sort threads
	for (i=0; i<MAX_THREADS; i++)
	{
	  printf("Starting sort thread %i via mailbox %p.\n",i,(void*)&(mb_start[i]));
	  mbox_put(&(mb_start[i]),(unsigned int)data[i]);
	}

	for (i=0; i<MAX_THREADS; i++)
	{
	  printf("Waiting for result from thread %i via mailbox %p.\n",i,(void*)&(mb_stop[i]));
	  ret = mbox_get(&(mb_stop[i]));
	}  

	
	//printf("merge data\n");
	// merge data
	//data = recursive_merge( data, temp, SIZE, N, simple_merge );

	// check data

	//data[0] = 6666; // manual fault

	for (i=0; i<MAX_THREADS; i++)
	{
	  printf("Check data of thread %i: ",i);
	  ret = check_data( data[i], SIZE);
	  if (ret==-1)
	    {
		printf("failure\n");
		print_data(data[i]);
	    }
	  else
	    {
		printf("success\n");
		//print_data(data[i])
	    }
	}

	for (i=0; i<MAX_THREADS; i++)
	{
	  mbox_put(&(mb_start[i]),UINT_MAX);
	  pthread_join(hwt[i].delegate,NULL);
	}

	//free(temp);
	// Memory Leak on variable data!!!
	
	return 0;
}

