/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 * Copyright 2012 Andreas Agne <agne@upb.de>
 */

#include <linux/semaphore.h>
#include <linux/mutex.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/module.h>

#include "mbox.h"

int mbox_init(struct mbox *mb, size_t size)
{
	mb->read_idx = 0;
	mb->write_idx = 0;
	mb->size = size;

	sema_init(&mb->sem_read, 0);
	sema_init(&mb->sem_write, size);

	mutex_init(&mb->mutex_read);
	mutex_init(&mb->mutex_write);

	mb->messages = kzalloc(mb->size * sizeof(*mb->messages),
			       GFP_KERNEL);

	return !mb->messages ? -ENOMEM : 0;
}
EXPORT_SYMBOL_GPL(mbox_init);

void mbox_destroy(struct mbox *mb)
{
	kfree(mb->messages);

	mutex_destroy(&mb->mutex_read);
	mutex_destroy(&mb->mutex_write);
}
EXPORT_SYMBOL_GPL(mbox_destroy);

void mbox_put(struct mbox *mb, uint32_t msg)
{
	mutex_lock(&mb->mutex_write);
	down(&mb->sem_write);

	mb->messages[mb->write_idx] = msg;
	mb->write_idx = (mb->write_idx + 1)  % mb->size;

	up(&mb->sem_read);
	mutex_unlock(&mb->mutex_write);

}
EXPORT_SYMBOL_GPL(mbox_put);

uint32_t mbox_get(struct mbox *mb)
{
	uint32_t msg;

	mutex_lock(&mb->mutex_read);
	down(&mb->sem_read);

	msg = mb->messages[mb->read_idx];
	mb->read_idx = (mb->read_idx + 1) % mb->size;

	up(&mb->sem_write);
	mutex_unlock(&mb->mutex_read);

	return msg;
}
EXPORT_SYMBOL_GPL(mbox_get);
