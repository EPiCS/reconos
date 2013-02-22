/*
 * eif.c
 *
 *  Created on: 07.12.2012
 *      Author: meise
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/mman.h>

#include "eif.h"


#define DEBUG 1

#ifdef DEBUG
#define EIF_DEBUG(message) printf("EIF: " message)
#define EIF_DEBUG1(message, arg1) printf("EIF: " message, (arg1))
#define EIF_DEBUG2(message, arg1, arg2) printf("EIF: " message, (arg1), (arg2))
#else
#define EIF_DEBUG(message)
#define EIF_DEBUG1(message, arg1)
#define EIF_DEBUG2(message, arg1, arg2)
#endif


typedef struct error2inject {
	void* mem;
	unsigned int time;
	error_t et;
	unsigned char ep;
	struct error2inject* next;
} error2inject_t;

static error2inject_t * eif_error_list;
static pthread_attr_t eif_thread_attr;
static pthread_t eif_thread;
static unsigned int eif_seed = 1;

static unsigned int rand_between(unsigned int min, unsigned int max){
	return min + rand_r(&eif_seed) % (max-min+1);
}

static void eif_insert_time_ordered(error2inject_t ** eif_error_list, error2inject_t * e2i){
	error2inject_t** current = eif_error_list;
	error2inject_t* temp;

	// Search for right place to insert
	while( (*current) && ((*current)->time < e2i->time) ){
		current = &((*current)->next);
	}

	//insert
	temp      = *current;
	*current  = e2i;
	e2i->next = temp;

	return;
}

static void eif_inject_error(error2inject_t * e){
	unsigned int i;
	unsigned int random;
	unsigned char mask;

	switch (e->et){
	case SINGLE_BIT_FLIP:
		random = rand()%8; //choose which bit to flip
		mask = 1<<random;
		*((unsigned char*)e->mem) ^= mask;
		break;

	case MULTIPLE_BIT_FLIP:
		for ( i=0; i<e->ep; i++){
			random = rand()%8; //choose which bit to flip
			mask = 1<<random;
			*((unsigned char*)e->mem) ^= mask;
		}
		break;

	case SET_VALUE:
		*((unsigned char*)e->mem) = e->ep;
		break;

	case OR_VALUE:
		*((unsigned char*)e->mem) |= e->ep;
		break;

	case AND_VALUE:
		*((unsigned char*)e->mem) &= e->ep;
		break;

	}
}

static void* eif_injector(void* input){
	unsigned int now = 0;
	error2inject_t *e2i_list = (error2inject_t *)input;
	error2inject_t * current = e2i_list;

	while(current){
		usleep((current->time-now)*1000);
		EIF_DEBUG2("Injecting Error at memory position %8p at time %8i ms.\n", current->mem, current->time);
		eif_inject_error(current);
		now=current->time;
		current = current->next;
	}
	return 0 ;
}

/**
 * Add one or multiple _transient_ errors to the error injection system.
 * @param mem_start Start address of the memory region where an error shall be injected.
 * @param mem_len   Length of the memory region where an error shall be injected.
 * @param error_cnt How many errors do want to be inserted?
 * @param start_time When do you want the error to be inserted? Counts in ms from eif_start().
 * @param end_time   When do you want the error to be inserted? Counts in ms from eif_start().
 * @param et 		 Which kind of error do you want to be inserted? Have a look at the Enum error_t for options.
 * @param ep		 Parameter to the error type, i.e., number of bits to flip or masks.
 * @return 0 on success, -1 on error
 */
int  eif_add_trans(void* mem_start, unsigned int mem_len, unsigned int error_cnt, unsigned int start_time, unsigned int end_time, error_t et, unsigned char ep){
	int i;
	error2inject_t* e2i;

	// Change permission to this memory are, so we can write to it!
	int pagesize = sysconf(_SC_PAGE_SIZE);
	void* page_start = (void*) ( ( ((unsigned int)mem_start) / pagesize ) * pagesize );
	unsigned int addr_diff = mem_start - page_start;
	if (mprotect(page_start, mem_len+addr_diff, PROT_READ | PROT_WRITE | PROT_EXEC) != 0) {
		/* Could not set permissions to write to that page */
	    return -1;
	}

	// Create every single error
	for ( i = 0; i < error_cnt; i++){
		// create new error
		e2i = malloc(sizeof(error2inject_t));
		if ( !e2i ) { return -1; }

		// fill error data
		e2i->mem	= (void*)rand_between((unsigned int)mem_start, (unsigned int)mem_start + mem_len);
		e2i->time	= rand_between(start_time, end_time);
		e2i->et		= et;
		e2i->ep		= ep;
		e2i->next	= NULL;

		// insert into list
		eif_insert_time_ordered(&eif_error_list, e2i);
	}
	return 0;

}

/**
 * Add one or multiple _permanent_ errors to the error injection system.
 * @param mem_start Start address of the memory region where an error shall be injected.
 * @param mem_len   Length of the memory region where an error shall be injected.
 * @param error_cnt How many errors do want to be inserted?
 * @param start_time When do you want the permanent error to appear? Counts in ms from eif_start().
 * @param end_time   When do you want the permanent error to diappear? Counts in ms from eif_start(). Zero means never.
 * @param et 		 Which kind of error do you want to be inserted? Have a look at the Enum error_t for options.
 * @param ep		 Parameter to the error type, i.e., number of bits to flip or masks.
 * @return 0 on success, -1 on error
 */
int  eif_add_perma(void* mem, unsigned int len, unsigned int error_cnt, unsigned int start_time, unsigned int end_time, error_t et, unsigned char ep){

	return 0;

}

/**
 * Set the internally used seed for random number generation
 * @param s Seed value to use.
 */
void eif_set_seed(unsigned int s){
	eif_seed = s;
}

/**
 * Start the error injection thread.
 * @return 0 on success, else error number
 */
int eif_start(){
	int ret;
	pthread_attr_init(&(eif_thread_attr));
	ret = pthread_create(
			&(eif_thread), //handle
			&(eif_thread_attr),
			eif_injector, //start function
			(void*)eif_error_list);
	return ret;
}

/**
 * Stops the error injection thread.
 */
void eif_stop() {

}


/**
 * Wait until the error injection thread ends.
 */
void eif_join() {
	void* retval;
	pthread_join(eif_thread,&retval);
}
