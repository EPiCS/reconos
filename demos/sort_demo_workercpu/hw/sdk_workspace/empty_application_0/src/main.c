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

#define REPETITIONS  14000 //8192

#define BUFFER_SIZE REPETITIONS*sizeof(uint32_t)
uint32_t buffer[BUFFER_SIZE/sizeof(uint32_t)];

bool test_echo(){
	uint32_t temp = 0;
	int i;
	putfsl(0xA2, 0); // Reconos Exit command
	for ( i=0; i< REPETITIONS; i++){
		getfsl(temp, 0);
	}

	for ( i=0; i< REPETITIONS; i++){
		putfsl(temp, 0);
	}

	for ( i=0; i< REPETITIONS; i++){
		getfsl(temp, 0);
		putfsl(temp, 0);
	}
	return true;
}

bool test_echo_block(){
	uint32_t temp = 0;
	int i;
	putfsl(0xA2, 0); // Reconos Exit command
	for ( i=0; i< REPETITIONS; i++){
		getfsl(temp, 0);
	}

	for ( i=0; i< REPETITIONS; i++){
		putfsl(temp, 0);
	}

	for ( i=0; i< REPETITIONS; i++){
		getfsl(buffer[i], 0);
	}
	for ( i=0; i< REPETITIONS; i++){
		putfsl(buffer[i], 0);
	}
	return true;
}

bool test_mbox(){
	uint32_t temp = 0;
	int i;
	for ( i=0; i < REPETITIONS; i++){
		temp = mbox_get(&mb_recv);
	}
	for ( i=0; i < REPETITIONS; i++){
		mbox_put(&mb_send, temp);
	}
	return true;
}

#define RQUEUE_BUFFER_SIZE 1024
bool test_rqueue(){
	/*
	 * No error handling here. Main processor will compare send and
	 * received data and reveal discrepancies.
	 */
	int i;
	for (i=0; i< REPETITIONS; i++){
		(void) rq_receive(&rqueue_recv, buffer, RQUEUE_BUFFER_SIZE);
	}

	for (i=0; i< REPETITIONS; i++){
		rq_send(&rqueue_send, buffer, RQUEUE_BUFFER_SIZE);
	}
	return true;
}

bool test_sem() {
	int i;
	for (i=0; i< REPETITIONS; i++){
		sem_wait(&sem_recv);
/*	}
	for (i=0; i< REPETITIONS; i++){
*/		sem_post(&sem_send);
	}
	return true;
}

bool test_mutex() {
	/*pthread_mutex_trylock(&mutex);*/
	/*pthread_mutex_unlock(&mutex);*/
	int i;
	for (i=0; i< REPETITIONS; i++){
		pthread_mutex_lock(&mutex_recv);
/*	}
	for (i=0; i< REPETITIONS; i++){
*/		pthread_mutex_unlock(&mutex_send);
	}
	return true;
}

bool test_cond() {
	return true;
}

typedef bool (*test_func)();

test_func test_array[] = {
		test_mbox,
		test_rqueue,
		test_sem,
		test_mutex,
		test_cond,
		test_echo,
		test_echo_block,
		NULL
};

/**
 * Worker CPU test programm: test every function in reconos.h
 */
int main(){


	bool passed = true;
	while (1){
		int i = 0;
		while (test_array[i] != NULL && passed == true){
			passed = test_array[i]();
			i++;
		}
	}

	return 0;
}
