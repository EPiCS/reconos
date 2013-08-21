/*
 * main.c
 *
 *  Created on: Apr 22, 2013
 *      Author: meise
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
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



#define BUFFER_SIZE_BYTES 56000
#define REPETITIONS  BUFFER_SIZE_BYTES/sizeof(uint32_t)
uint32_t buffer[BUFFER_SIZE_BYTES/sizeof(uint32_t)];

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

bool test_mem_read() {
	int i;
	void * src;
	bool passed = true;

	memset(buffer, 0x0, BUFFER_SIZE_BYTES);
	src = (void *) mbox_get(&mb_recv);
	mbox_put(&mb_send,(uint32_t) src); // acknowledge receiving of address

	//memif_read(src, buffer, BUFFER_SIZE_BYTES);
	memif_read(src, buffer, 512);
	//memif_read((void*)0xFFFFFFFF, buffer, BUFFER_SIZE_BYTES); // provokes segfault

	mbox_put(&mb_send,(uint32_t) src); // acknowledge memory read
	// Check for correct contents: all bytes should be 0x42, which means a word of data should be 0x42424242
	for (i = 0; i< BUFFER_SIZE_BYTES/sizeof(uint32_t); i++){
		if (buffer[i] != 0x42424242 ){
			passed = false;
			break;
		}
	}

	mbox_put(&mb_send,(uint32_t) passed);

	return passed;
}

bool test_mem_write() {
	//void * dst;
	//dst = (void *)mbox_get(&mb_recv);
	//memif_write(buffer, dst, BUFFER_SIZE_BYTES);
	return true;
}

typedef bool (*test_func)();

test_func test_array[] = {
//		test_mbox,
//		test_rqueue,
//		test_sem,
//		test_mutex,
//		test_cond,
//		test_echo,
//		test_echo_block,
		test_mem_read,
		test_mem_write,
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
