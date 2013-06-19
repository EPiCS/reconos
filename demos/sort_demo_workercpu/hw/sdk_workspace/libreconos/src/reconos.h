/*
 * reconos.h
 *
 *  Created on: Apr 22, 2013
 *      Author: meise
 */

#include <stddef.h>
#include <stdint.h>
#include <sys/types.h> /* Provides ssize_t */

#ifndef RECONOS_H_
#define RECONOS_H_

#define OSIF_FSL 0
#define MEMIF_FSL 1

#define OSIF_CMD_SEM_POST 0x000000B0
#define OSIF_CMD_SEM_WAIT 0x000000B1

#define OSIF_CMD_MUTEX_LOCK    0x000000C0
#define OSIF_CMD_MUTEX_UNLOCK  0x000000C1
#define OSIF_CMD_MUTEX_TRYLOCK 0x000000C2

#define OSIF_CMD_COND_WAIT      0x000000D0
#define OSIF_CMD_COND_SIGNAL    0x000000D1
#define OSIF_CMD_COND_BROADCAST 0x000000D2

#define OSIF_CMD_RQ_RECEIVE 0x000000E0
#define OSIF_CMD_RQ_SEND    0x000000E1

#define OSIF_CMD_MBOX_PUT 0x000000F1
#define OSIF_CMD_MBOX_GET 0x000000F0

#define OSIF_CMD_THREAD_GET_INIT_DATA 0x000000A0
#define OSIF_CMD_THREAD_EXIT          0x000000A2
#define OSIF_CMD_THREAD_LOAD_PROGRAM	 0x000000A7 // From reconos.h

/**
 * Struct is used as handle for resource on ReconOS main processor
 */
struct mbox {
	uint32_t handle;
};
extern void mbox_put(struct mbox *mb, uint32_t msg);
extern uint32_t mbox_get(struct mbox *mb);

typedef uint32_t rqueue;
extern ssize_t rq_receive(rqueue *rq, uint32_t *msg, size_t size);
extern void rq_send(rqueue *rq, uint32_t *msg, size_t size);

typedef uint32_t sem_t;
extern int sem_wait (sem_t *__sem);
extern int sem_post (sem_t *__sem);

typedef uint32_t pthread_mutex_t;
extern int pthread_mutex_trylock (pthread_mutex_t *__mutex);
extern int pthread_mutex_lock (pthread_mutex_t *__mutex);
extern int pthread_mutex_unlock (pthread_mutex_t *__mutex);

typedef uint32_t pthread_cond_t;
extern int pthread_cond_wait (pthread_cond_t *__restrict __cond,
			      pthread_mutex_t *__restrict __mutex);
extern int pthread_cond_signal (pthread_cond_t *__cond);
extern int pthread_cond_broadcast (pthread_cond_t *__cond);

extern void pthread_exit(void *retval);

extern void * reconos_get_init_data();

#endif /* RECONOS_H_ */
