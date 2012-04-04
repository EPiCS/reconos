/*
 * Copyright 2012 Andreas Agne <agne@upb.de>
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <errno.h>

#include "mbox.h"
#include "xutils.h"

int mbox_init(struct mbox *mb, size_t size)
{
	int ret;

	mb->read_idx = 0;
	mb->write_idx = 0;
	mb->size = size;

	ret = sem_init(&mb->sem_read, 0, 0);
	if (ret)
		goto out_err;
	ret = sem_init(&mb->sem_write, 0, size);
	if (ret)
		goto out_err;
	ret = pthread_mutex_init(&mb->mutex_read, NULL);
	if (ret)
		goto out_err;
	ret = pthread_mutex_init(&mb->mutex_write, NULL);
	if (ret)
		goto out_err;

	mb->messages = xmalloc_aligned(mb->size * sizeof(*mb->messages),
				       sizeof(void *) * 8);
	return 0;
out_err:
	return -EIO;
}

void mbox_destroy(struct mbox *mb)
{
	free(mb->messages);

	sem_destroy(&mb->sem_write);
	sem_destroy(&mb->sem_read);

	pthread_mutex_destroy(&mb->mutex_read);
	pthread_mutex_destroy(&mb->mutex_write);
}

void mbox_put(struct mbox *mb, uint32_t msg)
{
	pthread_mutex_lock(&mb->mutex_write);
	sem_wait(&mb->sem_write);

	mb->messages[mb->write_idx] = msg;
	mb->write_idx = (mb->write_idx + 1)  % mb->size;

	sem_post(&mb->sem_read);
	pthread_mutex_unlock(&mb->mutex_write);
}

uint32_t mbox_get(struct mbox *mb)
{
	uint32_t msg;
	
	pthread_mutex_lock(&mb->mutex_read);
	sem_wait(&mb->sem_read);

	msg = mb->messages[mb->read_idx];
	mb->read_idx = (mb->read_idx + 1) % mb->size;

	sem_post(&mb->sem_write);
	pthread_mutex_unlock(&mb->mutex_read);
	
	return msg;
}
