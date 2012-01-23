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

#define NUM_HWT 8

struct reconos_resource res[NUM_HWT][2];

struct reconos_hwt hwt[NUM_HWT];

struct mbox hw2sw[NUM_HWT],sw2hw[NUM_HWT];

int use_hwt[NUM_HWT] = {0};

#define PAGE_SIZE 4096
#define PAGE_WORDS 1024
#define PAGE_MASK 0xFFFFF000

//#define NUM_WORDS 16

//#define MAX_BURST_SIZE 1024
//#define ITERATIONS 48

uint32 * alloc_pages(int n)
{
	//int i;
	uint8 *mem;
	mem = malloc((n+1)*PAGE_SIZE);
	mem = (uint8*)((uint32)(mem + PAGE_SIZE) & PAGE_MASK);
	
	//for(i = 0; i < n; i++) mem[4096*i] = 0;

	return (uint32*)mem;
}

void simulate(int num_iter, int pos, int size, uint32 *a, uint32 *b)
{
	int cyc,rem,icyc,irem,ieff,atmp,btmp;
	
	assert(a);
	assert(b);
	
	cyc = num_iter / size;
	rem = num_iter % size;
	
	icyc = size - pos;
	irem = rem - pos;
	
	if(irem < 0) irem = 0;
	
	ieff = icyc*cyc + irem;
	
	if(pos % 2 == 1){
		int tmp = cyc;
		
		if(irem > 0) tmp = tmp + 1;
		
		tmp = tmp - 1;
		
		if(tmp < 0) tmp = 0;
		
		ieff = ieff - tmp;
	}
	
	atmp = (ieff/2)*2;
	btmp = ((ieff+1)/2)*2 - 1;
	if(btmp < 0) btmp = 0;
	
	if((pos % 2) == 0){
		*a = atmp;
		*b = btmp;
	} else {
		*a = btmp;
		*b = atmp;
	}
}

void run_tests(uint32 n)
{
	int i,j;
	uint32 addr_a, addr_b, size, blen, repeat, ack;
	uint32 *mem;
	
	// allocate 1 page
	mem = alloc_pages(100);

	// software write to the first page
	for(i = 0; i < PAGE_WORDS; i++) mem[i] = 0;

	size   = 511*4;
	addr_a = (uint32)mem;
	addr_b = size + addr_a;
	blen   = 4;
	repeat = n;

	// initialize hwts

	for(i = 0; i < NUM_HWT; i++){
		if(!use_hwt[i]) continue;
		printf("HWT %d @ 0x%08X <-> 0x%08X\n",i,addr_a + size*2*i,addr_b + size*2*i);
		mbox_put(sw2hw + i,addr_a + size*2*i);
		mbox_put(sw2hw + i,addr_b + size*2*i);
		mbox_put(sw2hw + i,size);
		mbox_put(sw2hw + i,blen);
	}
	
	for(i = 0; i < NUM_HWT; i++){
		if(!use_hwt[i]) continue;
		mbox_put(sw2hw + i,repeat);
	}

	for(i = 0; i < NUM_HWT; i++){
		if(!use_hwt[i]) continue;
		ack = mbox_get(hw2sw + i);
	}

	printf("\nRESULTS:\n");

	/* print results
	for(i = 0; i < NUM_HWT; i++){
		if(!use_hwt[i]) continue;
		printf("HWT %d:\n",i);
		for(j = 0; j < size/4; j++){
			uint32 a, b;
			a = j + i*size/2;
			b = j + i*size/2 + size/4;
			printf("0x%08X: 0x%08X        0x%08X: 0x%08X\n", (uint32)(mem + a),mem[a], (uint32)(mem + b), mem[b]);
		}
	}
	*/
	
	// check results
	for(i = 0; i < NUM_HWT; i++){
		int ok = 1;
		
		if(!use_hwt[i]) continue;
		
		printf("HWT %d: ",i);
		
		for(j = 0; j < size/4; j++){
			uint32 a, b, aidx, bidx;
			aidx = j + i*size/2;
			bidx = j + i*size/2 + size/4;
			simulate(n+1,j,size/4,&a,&b);
			if(a != mem[aidx] || b != mem[bidx]){
				ok = 0;
				printf("ERROR: expected:\n");
				printf("0x%08X: 0x%08X        0x%08X: 0x%08X\n", (uint32)(mem + aidx),a,(uint32)(mem + bidx), b);
				
				printf("ERROR: found:\n");
				printf("0x%08X: 0x%08X        0x%08X: 0x%08X\n", (uint32)(mem + aidx),mem[aidx],
							(uint32)(mem + bidx), mem[bidx]);
			}
		}
		
		if(ok) printf("ok\n");
	}
	
	printf("\n");
}

void print_mmu_stats()
{
	uint32 hits,misses,pgfaults;
	
	reconos_mmu_stats(&hits,&misses,&pgfaults);
	
	printf("MMU stats: TLB hits: %d    TLB misses: %d    page faults: %d\n",hits,misses,pgfaults);
}

int main(int argc, char ** argv)
{
	int i;
	uint32 n;

	assert(argc >= 2);
	
	n = atoi(argv[1]);

	if(argc > 2){
		for(i = 2; i < argc; i++){
			int k;
			k = atoi(argv[i]);
			assert(k >= 0);
			assert(k < NUM_HWT);
			use_hwt[k] = 1;
		}
	} else {
		for(i = 0; i < NUM_HWT; i++) use_hwt[i] = 1;
	}

	reconos_init(NUM_HWT,NUM_HWT+1);
	
	for(i = 0; i < NUM_HWT; i++){
		if(!use_hwt[i]) continue;

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
	
	print_mmu_stats();
	
	run_tests(n);

	print_mmu_stats();
	
	for(i = 0; i < NUM_HWT; i++){
		if(!use_hwt[i]) continue;
		pthread_join(hwt[i].delegate,NULL);
	}

	return 0;
}

