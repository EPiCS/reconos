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


struct reconos_resource res[2];

struct reconos_hwt hwt;

struct mbox hw2sw,sw2hw;

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

void run_tests()
{
	int i;
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
	repeat = 16*1024;

	// initialize hwt;
	mbox_put(&sw2hw,addr_a);
	mbox_put(&sw2hw,addr_b);
	mbox_put(&sw2hw,size);
	mbox_put(&sw2hw,blen);
	mbox_put(&sw2hw,repeat);
	ack = mbox_get(&hw2sw);

	// print results
	for(i = 0; i < 2*size/4; i++){
		printf("0x%08X: 0x%08X\n", (uint32)(mem + i),mem[i]);
	}
}


int main(int argc, char ** argv)
{
	assert(argc == 1);

	res[0].type = RECONOS_TYPE_MBOX;
	res[0].ptr  = &sw2hw;
	
	res[1].type = RECONOS_TYPE_MBOX;
	res[1].ptr  = &hw2sw;
	
	mbox_init(&sw2hw,3);
	mbox_init(&hw2sw,3);
	
	reconos_init(1);
	
	reconos_hwt_setresources(&hwt,res,2);
	reconos_hwt_create(&hwt,0,NULL);
	
	printf("performing memory subsystem stress test:\n");
	run_tests();

	pthread_join(hwt.delegate,NULL);
	
	return 0;
}

