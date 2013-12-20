/*
 * Copyright 2012 Andreas Agne <agne@upb.de>
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef MBOX_H
#define MBOX_H

#include <semaphore.h>
#include <pthread.h>
#include <stdint.h>

struct mbox {
	sem_t sem_read;
	sem_t sem_write;
	pthread_mutex_t mutex_read;
	pthread_mutex_t mutex_write;	
	uint32_t *messages;
	off_t read_idx;
	off_t write_idx;
	size_t size;
};

extern int mbox_init(struct mbox *mb, size_t size);
extern void mbox_destroy(struct mbox *mb);
extern void mbox_put(struct mbox *mb, uint32_t msg);
extern uint32_t mbox_get(struct mbox *mb);
extern int mbox_tryget(struct mbox *mb, uint32_t *msg);
extern int mbox_tryput(struct mbox *mb, uint32_t msg);

#endif /* MBOX_H */
