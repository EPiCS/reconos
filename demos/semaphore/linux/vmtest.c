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

uint32 * alloc_pages(int n)
{
	uint8 *mem;
	mem = malloc((n+1)*PAGE_SIZE);
	mem = (uint8*)((uint32)(mem + PAGE_SIZE) & PAGE_MASK);
	return (uint32*)mem;
}


void hwt_read(uint32 * src, int n, uint32 * dst)
{
	int i;
	unsigned int vaddr;

	vaddr = (unsigned int)src;

	mbox_put(&sw2hw,0x00000000 | (n << 2));
        mbox_put(&sw2hw,vaddr);
        
	for(i = 0; i < n; i++){
		dst[i] = mbox_get(&hw2sw);
	}
}

void hwt_write(uint32 * src, int n, uint32 * dst)
{
	int i;
	unsigned int vaddr;

	vaddr = (unsigned int)dst;

	mbox_put(&sw2hw,0x80000000 | (n << 2));
        mbox_put(&sw2hw,vaddr);
        
	for(i = 0; i < n; i++){
		mbox_put(&sw2hw,src[i]);
	}
}

#define MAX_BURST_SIZE 128

void read_tests()
{
	int i,j,n;
	uint32 *mem;
	uint32 *data;

	// allocate 1 page
	mem = alloc_pages(1);

	// allocate buffer
	data = malloc(PAGE_SIZE);

	// all burst sized from 1 to MAX_BURST_SIZE
	for(n = 1; n < MAX_BURST_SIZE; n++){
		printf("Burst read %d\n",n);

		// software write to the first page
		for(i = 0; i < PAGE_WORDS; i++){
			mem[i] = (n << 16) | i;
			data[i] = 0;
		}
	
		// sequential n word burst reads
		for(i = 0; i < PAGE_WORDS - n; i++){
			hwt_read(mem + i, n, data + i);
			for(j = 0; j < n; j++){
				if(mem[i+j] != data[i+j]){
					fprintf(stderr,"HWT %d-burst read from 0x%08X: 0x%08X (should be 0x%08X)\n",n,(uint32)mem,data[i],mem[i]);
					exit(1);
				}
			}  
		}
	}
}

void run_tests()
{
	int i;
	uint32 tmp;
	uint32 *data;
	uint32 *mem;
	
	// allocate 3 pages
	mem = alloc_pages(3);

	// allocate buffer
	data = malloc(PAGE_SIZE);

	// software write to the first page
	for(i = 0; i < PAGE_WORDS; i++) mem[i] = 0xAFFE0000 | i;

	// read a single word
	hwt_read(mem,1,data);
	fprintf(stderr,"HWT read from 0x%08X: 0x%08X (should be 0x%08X)\n",(uint32)mem,data[0],mem[0]);

	// read a single word from fresh page
	hwt_read(mem + PAGE_WORDS,1,data);
	fprintf(stderr,"HWT read from 0x%08X: 0x%08X (should be 0x%08X)\n",(uint32)mem,data[0],mem[PAGE_WORDS]);


	// write a single word to the first page
	data[0] = 0x3456789A;
	hwt_write(data,1,mem);
	hwt_read(&tmp,1,&tmp); /* synchronize */
	fprintf(stderr,"HWT write to 0x%08X: 0x%08X (should be 0x%08X)\n",(uint32)mem,mem[0],data[0]);

	

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
	
	//run_tests();
	read_tests();

	pthread_join(hwt.delegate,NULL);
	
	return 0;
}

