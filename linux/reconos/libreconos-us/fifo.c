/*
 * fifo.c
 *
 *  Created on: 19.09.2012
 *      Author: meise
 */

#include "fifo.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

//
// Debugging
//
//#define DEBUG 1

#ifdef DEBUG
    #define FIFO_DEBUG(message) printf("FIFO: " message)
    #define FIFO_DEBUG1(message, arg1) printf("FIFO: " message, (arg1))
    #define FIFO_DEBUG2(message, arg1, arg2) printf("FIFO: " message, (arg1), (arg2))
    #define FIFO_DEBUG3(message, arg1, arg2, arg3) printf("FIFO: " message, (arg1), (arg2), (arg3))
    #define FIFO_DEBUG4(message, arg1, arg2, arg3, arg4) printf("FIFO: " message, (arg1), (arg2), (arg3), (arg4))
#else
    #define FIFO_DEBUG(message)
    #define FIFO_DEBUG1(message, arg1)
    #define FIFO_DEBUG2(message, arg1, arg2)
    #define FIFO_DEBUG3(message, arg1, arg2, arg3)
    #define FIFO_DEBUG4(message, arg1, arg2, arg3, arg4)
#endif

//
// \param f			Pointer to the fifo you want to initialize
// \param obj_count	How many objects should fit initially into the fifo?
// \param obj_size 	What size do the objects have you want to put into the fifo?
// \return	0 on success, -1 on failure due to failing memory allocation.
int fifo_init( fifo_t * f, unsigned int obj_count, unsigned int obj_size){

	int error;

	f->obj_cnt   = obj_count;
	f->obj_size  = obj_size;
	f->data_size = obj_count * obj_size;

	f->wr_idx = 0; // byte offset into data
	f->re_idx = 0; // byte offset into data

	f->data = malloc(obj_count * obj_size);
	if (! f-> data){ return -1; }

	error = sem_init(&f->sem_read,0,0);
	if(error){
		perror("sem_init: sem_read");
		return -1;
	}

	error = sem_init(&f->sem_write,0,obj_count);
	if(error){
		perror("sem_init: sem_write");
		return -1;
	}

	error = pthread_mutex_init(&f->mutex_read,NULL);
	if(error){
		perror("mutex_init: mutex_read");
		return -1;
	}

	error = pthread_mutex_init(&f->mutex_write,NULL);
	if(error){
		perror("mutex_init: mutex_write");
		return -1;
	}
	FIFO_DEBUG3("FIFO at %p initialized with %i objects of size %u\n",f, obj_count, obj_size );
	return 0;
}

// Frees all resources used by fifo.
// All data in the fifo will be lost!
void fifo_destroy (fifo_t * f){
	free(f->messages);
	sem_destroy(&f->sem_write);
	sem_destroy(&f->sem_read);
	pthread_mutex_destroy(&f->mutex_read);
	pthread_mutex_destroy(&f->mutex_write);
}

//#define SEM_DEBUG(where) do{int a,b; sem_getvalue(&mb->sem_read,&a); sem_getvalue(&mb->sem_write,&b); fprintf(stderr,where "R %d W %d\n",a,b); }while(0)
#define SEM_DEBUG(where)

// copies into fifo, no references kept
// Blocks on full FIFO until someone pops data from it.
void fifo_push( fifo_t * f, void* obj ){
	sem_wait(&f->sem_write);
	pthread_mutex_lock(&f->mutex_write);
	SEM_DEBUG("put entry");

	memcpy(f->data+f->wr_idx, obj, f->obj_size);
	f->wr_idx = (f->wr_idx + f->obj_size) % f->data_size;

	pthread_mutex_unlock(&f->mutex_write);
	sem_post(&f->sem_read);
	SEM_DEBUG("put exit");
	FIFO_DEBUG2("FIFO pushed data to FIFO at %p from %p\n",f, obj);
}

// Copies into obj, object deleted afterwards from fifo.
// Blocks on empty FIFO until someone pushes data into it.
// If obj is NULL, nothing happens and function returns immediately.
void fifo_pop ( fifo_t * f, void* obj ){
	if (obj == NULL){return;}

	sem_wait(&f->sem_read);
	pthread_mutex_lock(&f->mutex_read);
	SEM_DEBUG("get entry");
	memcpy(obj,f->data+f->re_idx, f->obj_size);
	f->re_idx = (f->re_idx + f->obj_size) % f->data_size;
	pthread_mutex_unlock(&f->mutex_read);
	sem_post(&f->sem_write);
	SEM_DEBUG("get exit");
	FIFO_DEBUG2("FIFO popped data from FIFO at %p to %p\n",f, obj);
}

// Lets you take a look at the first element in the fifo, without popping it.
// Additionally can be used to determine is fifo is empty.
// return value = 0 -> FIFO empty, >0 -> amount of objects in FIFO
// Does not block on empty fifo.
int fifo_peek ( fifo_t * f, void* obj ){
	int retval;

	pthread_mutex_lock(&f->mutex_read);
	sem_getvalue(&f->sem_read, &retval);
	if ( retval > 0 && obj != NULL) {
		memcpy(obj,f->data+f->re_idx, f->obj_size);
	}
	pthread_mutex_unlock(&f->mutex_read);
	FIFO_DEBUG2("FIFO peeked data from FIFO at %p to %p\n",f, obj);
	return retval;
}
