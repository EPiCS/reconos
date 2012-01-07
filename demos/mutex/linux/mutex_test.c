#include "reconos.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>
#include <sys/time.h>


#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#define LOOP_COUNT 20

struct reconos_resource res[1];

struct reconos_hwt hwt;

pthread_mutex_t mutex_a;

int main(int argc, char ** argv)
{
	int i,j;
	struct timeval start, end; // start1
	long mtime, seconds, useconds;
	assert(argc == 1);

	res[0].type = RECONOS_TYPE_MUTEX;
	res[0].ptr  = &mutex_a;
	
	pthread_mutex_init(&mutex_a, NULL);
	pthread_mutex_lock(&mutex_a);
	
	reconos_init(1);
	
	reconos_hwt_setresources(&hwt,res,1);
	reconos_hwt_create(&hwt,0,NULL);

	//gettimeofday(&start1, NULL);
	for(i=0; i<LOOP_COUNT; i++)
	{
		pthread_mutex_unlock(&mutex_a);
		
		gettimeofday(&start, NULL);

		for(j=0; j<10; j++)
		{
			usleep(1000);
		}
		pthread_mutex_lock(&mutex_a);

		gettimeofday(&end, NULL);
		seconds  = end.tv_sec  - start.tv_sec;
		useconds = end.tv_usec - start.tv_usec;
		mtime = ((seconds) * 1000 + useconds/1000.0) + 0.5;

		if (mtime>200 && mtime<350)
			printf("mutex...successfull\n");
		else
			if (mtime <= 200)
				printf("mutex...too_fast\n");
			else
				printf("mutex...too_slow\n");
		//printf("Elapsed time: %ld milliseconds (should by much higher than 100 milliseconds)\n", mtime);

		for(j=0; j<25; j++)
		{
			usleep(1000);
		}

	}

	pthread_mutex_unlock(&mutex_a);

	/*gettimeofday(&end, NULL);
	seconds  = end.tv_sec  - start1.tv_sec;
	useconds = end.tv_usec - start1.tv_usec;
	mtime = ((seconds) * 1000 + useconds/1000.0) + 0.5;

	printf("In total: Elapsed time: %ld milliseconds (should by much higher than %d milliseconds)\n", mtime, LOOP_COUNT*350);*/

	//pthread_join(hwt.delegate,NULL);
	
	return 0;
}

