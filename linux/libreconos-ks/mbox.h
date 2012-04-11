/*
 * Copyright 2012 Andreas Agne <agne@upb.de>
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef MBOX_H
#define MBOX_H

#include <linux/semaphore.h>
#include <linux/mutex.h>

struct mbox {
	struct semaphore sem_read;
	struct semaphore sem_write;
	struct mutex mutex_read;
	struct mutex mutex_write;
	uint32_t *messages;
	off_t read_idx;
	off_t write_idx;
	size_t size;
};

extern int mbox_init(struct mbox *mb, size_t size);
extern void mbox_destroy(struct mbox *mb);
extern void mbox_put(struct mbox *mb, uint32_t msg);
extern uint32_t mbox_get(struct mbox *mb);

#endif /* MBOX_H */
