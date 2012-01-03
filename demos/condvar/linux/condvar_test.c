#include "reconos.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>


struct reconos_resource res[4];

struct reconos_hwt hwt;

// conditional variables
pthread_mutex_t mutex_a, mutex_b;
pthread_cond_t condvar_a, condvar_b;

// additional software thread
pthread_t swthread;

void * wait_on_condvar(void * arg){
	while(1)
	{
		pthread_mutex_lock(&mutex_b);
		pthread_cond_wait(&condvar_b, &mutex_b);
		//printf("pthread_cond_wait(&condvar_b, &mutex_b) => 0x%X\n",err);
		printf("condition b\n");
		pthread_mutex_unlock(&mutex_b);
	}
}

int main(int argc, char ** argv)
{
	int i=0,j;
	assert(argc == 1);

	res[0].type = RECONOS_TYPE_MUTEX;
	res[0].ptr  = &mutex_a;
	
	res[1].type = RECONOS_TYPE_COND;
	res[1].ptr  = &condvar_a;

	res[2].type = RECONOS_TYPE_MUTEX;
	res[2].ptr  = &mutex_b;
	
	res[3].type = RECONOS_TYPE_COND;
	res[3].ptr  = &condvar_b;
	
	printf("begin condvar_test_posix\n");
		
	// initialize mutexes with default attributes
	pthread_mutex_init(&mutex_a, NULL);
	pthread_mutex_init(&mutex_b, NULL);
	pthread_cond_init(&condvar_a, NULL);
	pthread_cond_init(&condvar_b, NULL);

	// create software thread
	pthread_create(&swthread,NULL,wait_on_condvar,NULL);

	// create hardware thread
	printf("creating hw thread... ");	
	reconos_init(1);	
	reconos_hwt_setresources(&hwt,res,4);
	reconos_hwt_create(&hwt,0,NULL);
	printf("ok\n");
	
	// give the second sw thread some time to run...
	for(j=0; j<10; j++)
	{
		usleep(1000);
	}

	for(i = 0; i < 10; i++){
		pthread_mutex_lock(&mutex_a);
		printf("signaling condition a\n");
		pthread_cond_signal(&condvar_a);
		pthread_mutex_unlock(&mutex_a);
		for(j=0; j<10; j++)
		{
			usleep(1000);
		}
	}
	
	printf("condvar_test_posix done.\n");
	
	//pthread_join(hwt.delegate,NULL);
	
	
	return 0;
}

