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

struct reconos_resource res[2];

struct reconos_hwt hwt;

struct mbox mb_start,mb_stop;

#define PAGE_SIZE 4096
#define PAGE_WORDS 1024
#define PAGE_MASK 0xFFFFF000

#define MAX_BURST_SIZE 1024


uint32 * alloc_pages(int n)
{
	uint8 *mem;
	mem = malloc((n+1)*PAGE_SIZE);
	mem = (uint8*)((uint32)(mem + PAGE_SIZE) & PAGE_MASK);
	return (uint32*)mem;
}






int main(int argc, char ** argv)
{
	assert(argc == 1);
	//int i;
	int ret;

	res[0].type = RECONOS_TYPE_MBOX;
	res[0].ptr  = &mb_start;
	
	res[1].type = RECONOS_TYPE_MBOX;
	res[1].ptr  = &mb_stop;
	
	mbox_init(&mb_start,3);
	mbox_init(&mb_stop, 3);
	
	reconos_init(1);
	
	reconos_hwt_setresources(&hwt,res,2);
	reconos_hwt_create(&hwt,0,NULL);

	// create pages
	printf("malloc pages\n");
	unsigned int * temp = malloc (2*PAGE_SIZE);
	unsigned int * data = (unsigned int*)(((unsigned int)temp / PAGE_SIZE + 1) * PAGE_SIZE);
	//unsigned int * temp = malloc (SIZE*sizeof(unsigned int));
	printf("generate data\n");
	// generate data
	generate_data( data, SIZE );

	int i;
	for (i=0; i<SIZE; i++)
	{
		printf("(%04d) %04d \t", i, data[i]);
		if ((i+1)%10 == 0) printf("\n");
	}
	printf("\n");

	printf("sort data\n");
	// sort data
	/*for (i=0; i<SIZE/N; i++)
	{
		bubblesort( &data[i*N], N );
	}*/

	//bubblesort( data, N );

	mbox_put(&mb_start,(unsigned int)data);
	ret = mbox_get(&mb_stop);
	
	//printf("merge data\n");
	// merge data
	//data = recursive_merge( data, temp, SIZE, N, simple_merge );
	printf("check data: ");
	// check data
	//data[0] = 6666; // manual fault
	ret = check_data( data, SIZE);
	if (ret==-1)
	{
		printf("failure\n");
		//int i;
		for (i=0; i<SIZE; i++)
		{
			printf("(%04d) %04d \t", i, data[i]);
			if ((i+1)%10 == 0) printf("\n");
		}
		printf("\n");
	}
	else
	{
		printf("success\n");
		//int i;
		for (i=0; i<SIZE; i++)
		{
			printf("(%04d) %04d \t", i, data[i]);
			if ((i+1)%10 == 0) printf("\n");
		}
		printf("\n");
	}

	mbox_put(&mb_start,UINT_MAX);
	pthread_join(hwt.delegate,NULL);

	
	free(temp);
	
	return 0;
}

