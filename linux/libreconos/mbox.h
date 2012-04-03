#ifndef MBOX_H
#define MBOX_H

/* This is the linux implementation of ecos message boxes.
   It uses two counting semaphores and two mutexes to enable
   synchronous access */

#include <semaphore.h>
#include <pthread.h>

struct mbox {
	sem_t sem_read;
	sem_t sem_write;
	pthread_mutex_t mutex_read;
	pthread_mutex_t mutex_write;	
	uint32 *messages;
	int read_idx;
	int write_idx;
	int size;
};

int mbox_init(struct mbox * mb, int size);
void mbox_destroy(struct mbox * mb);
void mbox_put(struct mbox * mb, uint32 msg);
uint32 mbox_get(struct mbox * mb);

#endif

