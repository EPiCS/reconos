#include "reconos.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <unistd.h>

#include "mbox.h"


struct reconos_resource res[1];

struct reconos_hwt hwt;

struct mbox mb_1;

uint32 init_data = 0xDEADBEEF;


int main(int argc, char ** argv)
{
	uint32 ret = 0;
	assert(argc == 1);

	res[0].type = RECONOS_TYPE_MBOX;
	res[0].ptr  = &mb_1;
	
	mbox_init(&mb_1,3);
	
	reconos_init_autodetect();
	
	reconos_hwt_setresources(&hwt,res,2);
	reconos_hwt_setinitdata(&hwt,(void *) init_data);
	reconos_hwt_create(&hwt,0,NULL);
	
	ret = mbox_get(&mb_1);

	if (ret==init_data)
		printf("get_init_data: success (%X=%X)\n", init_data,ret);
	else
		printf("get_init_data: failure (%X!=%X)\n",init_data,ret);

	pthread_join(hwt.delegate,NULL);
	
	return 0;
}

