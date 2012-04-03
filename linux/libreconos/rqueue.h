#ifndef RQUEUE_H
#define RQUEUE_H

#include <semaphore.h>
#include <pthread.h>
#include <stdint.h>

#include "mbox.h"

typedef struct mbox rqueue;

extern int rq_init(rqueue *rq, size_t size);
extern void rq_close(rqueue *rq);
extern int rq_receive(rqueue *rq, uint32_t *msg, size_t size);
extern void rq_send(rqueue *rq, uint32_t *msg, size_t size);

#endif /* RQUEUE_H */
