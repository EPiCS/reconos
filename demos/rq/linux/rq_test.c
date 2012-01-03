#include "reconos.h"
#include "mbox.h"
#include "rq.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

#define MAX_MSG_NUM 512 //12
#define TRUE  1
#define FALSE 0


struct reconos_resource res[2];

struct reconos_hwt hwt;

rqueue rq_1, rq_2;

int main(int argc, char ** argv)
{
	int i,j=0,j_end;
	uint32 * msg1, * msg2;
	int test_failed = FALSE;
	int result = 1;
	uint msg_size, msg_size_rec = MAX_MSG_NUM*sizeof(uint32);
	assert(argc == 1);
	srandom( 123456 );


	rq_init(&rq_1,10);
	rq_init(&rq_2,10);

	
	res[0].type = RECONOS_TYPE_RQ;
	res[0].ptr  = &rq_1;
	res[1].type = RECONOS_TYPE_RQ;
	res[1].ptr  = &rq_2;
	
	reconos_init(1);
	
	reconos_hwt_setresources(&hwt,res,2);
	reconos_hwt_create(&hwt,0,NULL);
	
	msg2 = malloc(msg_size_rec);
	
	
	for(i=0; i<100; i++)
	{
		// create msg1, msg2
		msg_size = (sizeof(uint32)*( uint32 ) ((random(  ) % MAX_MSG_NUM)+1));
		if (i==5) msg_size =  MAX_MSG_NUM*sizeof(uint32);
		if (i==6) msg_size =  sizeof(uint32);
		msg1 = malloc(msg_size);
		//printf("%03d: created message:\n", i+1);
		j_end=msg_size/sizeof(uint32);
		for (j=0; j<j_end;j++)
		{
			msg1[j] = ( uint32 ) ((random(  ) % 1000));
			//printf("    %02d: %03d\n", j, msg1[j]);
		}
		//printf("\n");
		rq_send (&rq_1, msg1, msg_size);
		printf("%03d: sent message ... ", i+1);
		result = rq_receive (&rq_2, msg2, msg_size_rec);
		printf("received message (%04d bytes): ", result);
		if (result == 0)
		{
			printf("ERROR: did not receive a correct message\n"); 
			free (msg2); 
			rq_close(&rq_1);
			rq_close(&rq_2);
			return 0;
		}
		//j_end = result/sizeof(uint32);
		j_end = msg_size/sizeof(uint32);
		/*for (j=0; j<j_end;j++)
		{
			printf("    %02d: %03d\n", j, msg2[j]);
		}
		printf("\n");*/
		for (j=0; j<j_end;j++)
		{
			if (msg2[j] != msg1[j]+1)
			{
				//printf("run no. %02d: msg[%02d] = %03d != %03d + 1 : ", i+1,j,msg1[j],msg2[j]);
				test_failed = TRUE;
			}
		}
		if (test_failed==TRUE)
			printf("failure\n");
		else
			printf("success\n");
		free(msg1);
	}

	
	rq_send (&rq_1, msg2, 0);

	pthread_join(hwt.delegate,NULL);
	free (msg2);

	rq_close(&rq_1);
	rq_close(&rq_2);
	return 0;
}

