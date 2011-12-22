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

#define NUM_HWT 1

struct reconos_resource res[NUM_HWT][2];

struct reconos_hwt hwt[NUM_HWT];

struct mbox hw2sw[NUM_HWT],sw2hw[NUM_HWT];

#define PAGE_SIZE 4096
#define PAGE_WORDS 1024
#define PAGE_MASK 0xFFFFF000

//#define MAX_BURST_SIZE 1024
//#define ITERATIONS 48

uint32 * alloc_pages(int n)
{
	uint8 *mem;
	mem = malloc((n+1)*PAGE_SIZE);
	mem = (uint8*)((uint32)(mem + PAGE_SIZE) & PAGE_MASK);
	return (uint32*)mem;
}

void run_tests(uint32 n)
{
	int i,j;
	uint32 addr_a, addr_b, size, blen, repeat, ack;
	uint32 *mem;
	
	// allocate 1 page
	mem = alloc_pages(1);

	// software write to the first page
	for(i = 0; i < PAGE_WORDS; i++) mem[i] = 0;

	size   = 16*4;
	addr_a = (uint32)mem;
	addr_b = size + addr_a;
	blen   = 4;
	repeat = n;

	// initialize hwts

	for(i = 0; i < NUM_HWT; i++){
		mbox_put(sw2hw + i,addr_a + size*2*i);
		mbox_put(sw2hw + i,addr_b + size*2*i);
		mbox_put(sw2hw + i,size);
		mbox_put(sw2hw + i,blen);
		mbox_put(sw2hw + i,repeat);
	}

	for(i = 0; i < NUM_HWT; i++){
		ack = mbox_get(hw2sw + i);
	}

	// print results
	for(i = 0; i < NUM_HWT; i++){
		for(j = 0; j < size/4; j++){
			uint32 a, b;
			a = j + i*size/2;
			b = j + i*size/2 + size/4;
			printf("0x%08X: 0x%08X        0x%08X: 0x%08X\n", (uint32)(mem + a),mem[a], (uint32)(mem + b), mem[b]);
		}
	}
}


int main(int argc, char ** argv)
{
	int i;
	uint32 n;

	assert(argc == 2);
	
	n = atoi(argv[1]);

	reconos_init(15);
	
	for(i = 0; i < NUM_HWT; i++){
		res[i][0].type = RECONOS_TYPE_MBOX;
		res[i][0].ptr  = sw2hw + i;
	
		res[i][1].type = RECONOS_TYPE_MBOX;
		res[i][1].ptr  = hw2sw + i;
	
		mbox_init(sw2hw + i,3);
		mbox_init(hw2sw + i,3);
		
		printf("starting delegate thread %d\n",i);	
		reconos_hwt_setresources(hwt + i,res[i],2);
		reconos_hwt_create(hwt + i,i,NULL);
	}
	
	printf("performing memory subsystem stress test (%d iterations):\n",n);
	run_tests(n);

	for(i = 0; i < NUM_HWT; i++){
		pthread_join(hwt[i].delegate,NULL);
	}

	return 0;
}

