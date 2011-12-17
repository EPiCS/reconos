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

unsigned long pgd;

void pmem_init()
{
	int res,fd;

	fd = open("/dev/getpgd",O_RDONLY);
	if(fd == -1){
		perror("open /dev/getpgd");
		exit(1);
	}

	res = read(fd,&pgd,4);
	if(res != 4){
		perror("read from /dev/getpgd");
		exit(1);
	}
	
	fprintf(stderr,"PGD = 0x%08lX\n",pgd);

	close(fd);
}

unsigned int pmem(unsigned int paddr)
{
	/*mbox_put(&sw2hw,paddr);
	mbox_get(&hw2sw);*/
	mbox_put(&sw2hw,paddr);
	return mbox_get(&hw2sw);
}

unsigned long physical_address(void * ptr)
{
	unsigned int paddr, vaddr;

	unsigned int pgdidx, ptidx, offset, pgde, pte;

	vaddr = (unsigned int)ptr;

	fprintf(stderr,"virtual address = 0x%08X\n",vaddr);

	pgdidx = 0x03FF & (vaddr >> 22);
	ptidx  = 0x03FF & (vaddr >> 12);
	offset = 0x0FFF & vaddr;

	fprintf(stderr,"pgdidx = 0x%08X, ptidx = 0x%08X, offset = 0x%08X\n", pgdidx,ptidx,offset);

	pgde = pmem(pgd + 4*pgdidx);

	fprintf(stderr,"pgd entry = 0x%08X\n",pgde);

	pte  = pmem((0xFFFFF000 & pgde) - 0xC0000000 + 4*ptidx);

	fprintf(stderr,"page table entry = 0x%08X\n",pte);

	paddr = ((pte & 0xFFFFF000)) + offset;

	fprintf(stderr,"physical address = 0x%08X\n",paddr);
	
	return paddr;
}

unsigned int vmread(void * ptr)
{
	unsigned int vaddr;

	vaddr = (unsigned int)ptr;

        mbox_put(&sw2hw,vaddr);
        return mbox_get(&hw2sw);
}

volatile uint32 data = 0xF00BA211;


int main(int argc, char ** argv)
{
	unsigned int fooba211;

	assert(argc == 2);

	fprintf(stderr,"data = 0x%08X\n",data);
	
	data = atoi(argv[1]);
	
	res[0].type = RECONOS_TYPE_MBOX;
	res[0].ptr  = &sw2hw;
	
	res[1].type = RECONOS_TYPE_MBOX;
	res[1].ptr  = &hw2sw;
	
	mbox_init(&sw2hw,3);
	mbox_init(&hw2sw,3);
	
	reconos_init(1);
	
	reconos_hwt_setresources(&hwt,res,2);
	reconos_hwt_create(&hwt,0,NULL);
	
	fooba211 = vmread((void*)&data);

	fprintf(stderr,"data = 0x%08X\n",fooba211);

	pthread_join(hwt.delegate,NULL);
	
	return 0;
}

