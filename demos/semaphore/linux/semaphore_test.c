#include "reconos.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <semaphore.h>


struct reconos_resource res[2];

struct reconos_hwt hwt;

sem_t sem_a, sem_b;


int main(int argc, char ** argv)
{
	int i=0;
	assert(argc == 1);

	res[0].type = RECONOS_TYPE_SEM;
	res[0].ptr  = &sem_a;
	
	res[1].type = RECONOS_TYPE_SEM;
	res[1].ptr  = &sem_b;
	
	sem_init(&sem_a,0,0);
	sem_init(&sem_b,0,0);
	
	reconos_init(1);
	
	reconos_hwt_setresources(&hwt,res,2);
	reconos_hwt_create(&hwt,0,NULL);
	
	for(i=0; i<100; i++)
	{
		sem_post(&sem_a);
		printf("%03d: posted semaphore a ... ", i+1);
		sem_wait(&sem_b);
		printf("received semaphore b\n");
	}

	//pthread_join(hwt.delegate,NULL);
	
	return 0;
}

