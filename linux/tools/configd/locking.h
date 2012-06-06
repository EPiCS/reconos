/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef LOCKING_H
#define LOCKING_H

#include <pthread.h>

struct mutexlock {
	pthread_mutex_t lock;
};

static inline int mutexlock_init(struct mutexlock *l)
{
	return -pthread_mutex_init(&l->lock, 0);
}

static inline void mutexlock_destroy(struct mutexlock *l)
{
	pthread_mutex_destroy(&l->lock);
}

static inline void mutexlock_lock(struct mutexlock *l)
{
	pthread_mutex_lock(&l->lock);
}

static inline void mutexlock_unlock(struct mutexlock *l)
{
	pthread_mutex_unlock(&l->lock);
}

#endif /* LOCKING_H */
