/*
 * Copyright 2012 Markus Happe <markus.happe@upb.de>
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef RQUEUE_H
#define RQUEUE_H

#include <pthread.h>
#include <semaphore.h>
#include <stdint.h>

#include "mbox.h"

/* XXX: Is this really a good idea?
 *      If we change mbox we can break rq ... ---DB */
typedef struct mbox rqueue;

extern int rq_init(rqueue *rq, size_t size);
extern void rq_close(rqueue *rq);
extern ssize_t rq_receive(rqueue *rq, uint32_t *msg, size_t size);
extern void rq_send(rqueue *rq, uint32_t *msg, size_t size);

#endif /* RQUEUE_H */
