/*
 * main.c
 *
 *  Created on: Apr 22, 2013
 *      Author: meise
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <mb_interface.h>
#include "reconos.h"

#define RES_MBOX   0
#define RES_RQUEUE 1
#define RES_SEM    2
#define RES_MUTEX  3
#define RES_COND   4

struct mbox mb_recv = {0};
struct mbox mb_send = {1};
rqueue rqueue_recv = 2;
rqueue rqueue_send = 3;
sem_t sem_recv = 4;
sem_t sem_send = 5;
pthread_mutex_t mutex_recv = 6;
pthread_mutex_t mutex_send = 7;
pthread_cond_t cond_recv = 8;
pthread_cond_t cond_send = 9;

#define REPETITIONS 1000

#define BUFFER_SIZE 16384
uint32_t buffer[BUFFER_SIZE/sizeof(uint32_t)];

bool test_echo(){
	uint32_t temp = 0;
	getfsl(temp, 0);
	putfsl(temp, 0);
	return true;
}

bool test_mbox(){
	uint32_t temp = 0;
	int i;
	for ( i=0; i< REPETITIONS; i++){
		temp = mbox_get(&mb_recv);
		mbox_put(&mb_send, temp);
	}
	return true;
}

bool test_rqueue(){
	/*
	 * No error handling here. Main processor will compare send and
	 * received data and reveal discrepancies.
	 */
	(void) rq_receive(&rqueue_recv, buffer, BUFFER_SIZE);
	rq_send(&rqueue_send, buffer, BUFFER_SIZE);
	return true;
}

bool test_sem() {
	sem_wait(&sem_recv);
	sem_post(&sem_send);
	return true;
}

bool test_mutex() {
	/*pthread_mutex_trylock(&mutex);*/
	/*pthread_mutex_unlock(&mutex);*/
	pthread_mutex_lock(&mutex_recv);
	pthread_mutex_unlock(&mutex_send);
	return true;
}

bool test_cond() {
	return true;
}

typedef bool (*test_func)();

test_func test_array[] = {
		test_echo,
		test_mbox,
		test_rqueue,
		test_sem,
		test_mutex,
		test_cond,
		NULL
};

/**
 * Worker CPU test programm: test every function in reconos.h
 */
int main(){

	int i = 0;
	bool passed = true;
	while (1){
		while (test_array[i] != NULL && passed == true){
			passed = test_array[i]();
			i++;
		}
	}

	return 0;
}

#if 0

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

#endif
