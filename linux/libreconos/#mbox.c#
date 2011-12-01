#include "mbox.h"
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

int mbox_init(struct mbox * mb, int size)
{
	int error;
	
	mb->read_idx = 0;
	mb->write_idx = 0;
	
	error = sem_init(&mb->sem_read,0,0);
	if(error){
		perror("sem_init: sem_read");
		return -1;
	}
	
	error = sem_init(&mb->sem_write,0,size);
	if(error){
		perror("sem_init: sem_write");
		return -1;
	}
	
	error = pthread_mutex_init(&mb->mutex_read,NULL);
	if(error){
		perror("mutex_init: mutex_read");
		return -1;
	}
	
	error = pthread_mutex_init(&mb->mutex_write,NULL);
	if(error){
		perror("mutex_init: mutex_write");
		return -1;
	}
	
	mb->size = size;
	mb->messages = malloc(size*sizeof*mb->messages);
	assert(mb->messages);
	
	return 0;
}


void mbox_destroy(struct mbox * mb)
{
	free(mb->messages);
	sem_destroy(&mb->sem_write);
	sem_destroy(&mb->sem_read);
	pthread_mutex_destroy(&mb->mutex_read);
	pthread_mutex_destroy(&mb->mutex_write);
}

//#define SEM_DEBUG(where) do{int a,b; sem_getvalue(&mb->sem_read,&a); sem_getvalue(&mb->sem_write,&b); fprintf(stderr,where "R %d W %d\n",a,b); }while(0)
#define SEM_DEBUG(where)

void mbox_put(struct mbox * mb, uint32 msg)
{
	pthread_mutex_lock(&mb->mutex_write);

	SEM_DEBUG("put entry");
	sem_wait(&mb->sem_write);
	mb->messages[mb->write_idx] = msg;
	mb->write_idx = (mb->write_idx + 1) % mb->size;
	sem_post(&mb->sem_read);
	SEM_DEBUG("put exit");
	pthread_mutex_unlock(&mb->mutex_write);
}

uint32 mbox_get(struct mbox * mb)
{
	uint32 msg;
	
	pthread_mutex_lock(&mb->mutex_read);
	SEM_DEBUG("get entry");
	sem_wait(&mb->sem_read);
	msg = mb->messages[mb->read_idx];
	mb->read_idx = (mb->read_idx + 1) % mb->size;
	sem_post(&mb->sem_write);
	SEM_DEBUG("get exit");
	pthread_mutex_unlock(&mb->mutex_read);
	
	return msg;
}

