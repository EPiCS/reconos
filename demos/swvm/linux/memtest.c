#include "reconos.h"
#include "mbox.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>

struct reconos_resource res[2];

struct reconos_hwt hwt;

struct mbox hw2sw,sw2hw;



int main(int argc, char ** argv)
{
	uint32 addr;
	uint32 data;
	
	assert(argc == 2);
	
	addr = atoi(argv[1]);
	
	res[0].type = RECONOS_TYPE_MBOX;
	res[0].ptr  = &sw2hw;
	
	res[1].type = RECONOS_TYPE_MBOX;
	res[1].ptr  = &hw2sw;
	
	mbox_init(&sw2hw,3);
	mbox_init(&hw2sw,3);
	
	reconos_init(1);
	
	reconos_hwt_setresources(&hwt,res,2);
	reconos_hwt_create(&hwt,0,NULL);
	
	mbox_put(&sw2hw,0);
	data = mbox_get(&hw2sw);
	
	printf("0x%08X: 0x%08X\n",addr,data);
	
	pthread_join(hwt.delegate,NULL);
	
	return 0;
}

