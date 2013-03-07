/*
 * fifo.h
 *
 *  Created on: 19.09.2012
 *      Author: meise
 */

#ifndef FIFO_H_
#define FIFO_H_

#include <semaphore.h>
#include <pthread.h>

struct fifo {
	sem_t sem_read;
	sem_t sem_write;
	pthread_mutex_t mutex_read;
	pthread_mutex_t mutex_write;
	char *messages;
	unsigned int obj_cnt;
	unsigned int obj_size;
	unsigned int data_size; // internally computed once from obj_cnt and obj_size to save computation time
	unsigned int wr_idx; // byte offset into data array
	unsigned int re_idx; // byte offset into data array
	char * data;
};

typedef struct fifo fifo_t;

int  fifo_init( fifo_t * f, unsigned int obj_count, unsigned int obj_size);
void fifo_destroy (fifo_t * f);
void fifo_push( fifo_t * f, void* obj ); // copies into fifo, no references kept
void fifo_pop ( fifo_t * f, void* obj ); // copies into obj, object deleted afterwards
int  fifo_peek( fifo_t * f, void* obj ); // copies into obj, return amount of objects in fifo

#endif /* FIFO_H_ */
