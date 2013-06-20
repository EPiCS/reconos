/*
 * reconos.c
 *
 *  Created on: Apr 22, 2013
 *      Author: meise
 */

#include <stddef.h>
#include <stdint.h>
#include <mb_interface.h>
#include "reconos.h"


void mbox_put(struct mbox *mb, uint32_t msg){
	uint32_t retval;
	putfsl(OSIF_CMD_MBOX_PUT, OSIF_FSL);
	putfsl(mb->handle, OSIF_FSL);
	putfsl(msg, OSIF_FSL);
	getfsl(retval, OSIF_FSL);
}

uint32_t mbox_get(struct mbox *mb){
	uint32_t retval;
	putfsl(OSIF_CMD_MBOX_GET, OSIF_FSL);
	putfsl(mb->handle, OSIF_FSL);
	getfsl(retval, OSIF_FSL);
	return retval;
}

/**
 * @param size gives maximum size of message we can accept.
 * @return gives how many bytes we really did receive
 */
ssize_t rq_receive(rqueue *rq, uint32_t *msg, size_t size){
	int i;
	uint32_t recv_bytes;

	putfsl(OSIF_CMD_RQ_RECEIVE, OSIF_FSL);
	putfsl(*rq, OSIF_FSL);
	putfsl(size, OSIF_FSL);

	getfsl(recv_bytes, OSIF_FSL);
	for (i = 0; i < recv_bytes / sizeof(uint32_t); ++i)
			getfsl(msg[i], OSIF_FSL);

	return recv_bytes;
}

void rq_send(rqueue *rq, uint32_t *msg, size_t size){
	int i;
	uint32_t retval;

	putfsl(OSIF_CMD_RQ_SEND, OSIF_FSL);
	putfsl(*rq, OSIF_FSL);
	putfsl(size, OSIF_FSL);

	for (i = 0; i < size / sizeof(uint32_t); ++i)
			putfsl(msg[i], OSIF_FSL);

	getfsl(retval, OSIF_FSL);
}

int sem_wait (sem_t *__sem){
	uint32_t retval;
	putfsl(OSIF_CMD_SEM_WAIT, OSIF_FSL);
	putfsl(*__sem, OSIF_FSL);
	getfsl(retval, OSIF_FSL);
	return retval;
}

int sem_post (sem_t *__sem){
	uint32_t retval;
	putfsl(OSIF_CMD_SEM_POST, OSIF_FSL);
	putfsl(*__sem, OSIF_FSL);
	getfsl(retval, OSIF_FSL);
	return retval;
}


int pthread_mutex_trylock (pthread_mutex_t *__mutex){
	uint32_t retval;
	putfsl(OSIF_CMD_MUTEX_TRYLOCK, OSIF_FSL);
	putfsl(*__mutex, OSIF_FSL);
	getfsl(retval, OSIF_FSL);
	return retval;
}

int pthread_mutex_lock (pthread_mutex_t *__mutex){
	uint32_t retval;
	putfsl(OSIF_CMD_MUTEX_LOCK, OSIF_FSL);
	putfsl(*__mutex, OSIF_FSL);
	getfsl(retval, OSIF_FSL);
	return retval;
}

int pthread_mutex_unlock (pthread_mutex_t *__mutex){
	uint32_t retval;
	putfsl(OSIF_CMD_MUTEX_UNLOCK, OSIF_FSL);
	putfsl(*__mutex, OSIF_FSL);
	getfsl(retval, OSIF_FSL);
	return retval;
}


int pthread_cond_wait (pthread_cond_t *__restrict __cond,
			      pthread_mutex_t *__restrict __mutex){
	uint32_t retval;
	putfsl(OSIF_CMD_COND_WAIT, OSIF_FSL);
	putfsl(*__cond, OSIF_FSL);
	putfsl(*__mutex, OSIF_FSL);
	getfsl(retval, OSIF_FSL);
	return retval;
}

int pthread_cond_signal (pthread_cond_t *__cond){
	uint32_t retval;
	putfsl(OSIF_CMD_COND_SIGNAL, OSIF_FSL);
	putfsl(*__cond, OSIF_FSL);
	getfsl(retval, OSIF_FSL);
	return retval;
}

int pthread_cond_broadcast (pthread_cond_t *__cond){
	uint32_t retval;
	putfsl(OSIF_CMD_COND_BROADCAST, OSIF_FSL);
	putfsl(*__cond, OSIF_FSL);
	getfsl(retval, OSIF_FSL);
	return retval;
}

/**
 * Exits thread.
 * @note: Return value is ignored; Delegate thread does always return NULL.
 */
void pthread_exit(void *retval){
	putfsl(OSIF_CMD_THREAD_EXIT, OSIF_FSL);
	exit(0);
}

void pthread_yield(){
	uint32_t retval;
	putfsl(OSIF_CMD_THREAD_YIELD, OSIF_FSL);
	getfsl(retval, OSIF_FSL);
}

/**
 * Return pointer into main memory, where init data is stored.
 */
void * reconos_get_init_data(){
	void* retval;
	putfsl(OSIF_CMD_THREAD_GET_INIT_DATA, OSIF_FSL);
	getfsl(retval, OSIF_FSL);
	return retval;
}
