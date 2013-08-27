/*
 * sort_shmem.c
 *
 *  Created on: 22.07.2013
 *      Author: meise
 */
#include "sort_shmem.h"

#define DEBUG 1

#ifdef DEBUG
    #define SORT_DEBUG(message) printf("SORT_SHMEM: " message)
    #define SORT_DEBUG1(message, arg1) printf("SORT_SHMEM: " message, (arg1))
    #define SORT_DEBUG2(message, arg1, arg2) printf("SORT_SHMEM: " message, (arg1), (arg2))
	#define SORT_DEBUG3(message, arg1, arg2, arg3) printf("SORT_SHMEM: " message, (arg1), (arg2), (arg3))
	#define SORT_DEBUG4(message, arg1, arg2, arg3, arg4) printf("SORT_SHMEM: " message, (arg1), (arg2), (arg3), (arg4))
#else
    #define SORT_DEBUG(message)
    #define SORT_DEBUG1(message, arg1)
    #define SORT_DEBUG2(message, arg1, arg2)
	#define SORT_DEBUG3(message, arg1, arg2, arg3)
	#define SORT_DEBUG4(message, arg1, arg2, arg3, arg4)
#endif

// mailboxes
struct mbox mb_start[MAX_THREADS];
struct mbox mb_stop[MAX_THREADS];

// sort thread shall behave the same as hw thread:
// - get pointer to data buffer
// - if valid address: sort data and post answer
// - if exit command: issue thread exit os call
void *sort_thread_shmem(void* data)
{
	static int call_nr = 0;
	unsigned int length; // number of words to sort
    unsigned int address;
    unsigned int dummy = 23;
    struct reconos_resource *res  = (struct reconos_resource*) data;
    struct mbox *mb_start = res[0].ptr;
    struct mbox *mb_stop  = res[1].ptr;
#ifdef DEBUG
    pthread_t self = pthread_self();
#endif
    SORT_DEBUG4("SW Thread %lu, call %d: Started with mailbox addresses %p and %p ...\n", self, call_nr,  mb_start, mb_stop);
    while ( 1 ) {
    	SORT_DEBUG3("SW Thread %lu, call %d: getting buffer address from mailbox %p\n", self, call_nr, mb_start);
        length = mbox_get(mb_start);
		//printf("SW Thread %lu: Got address %p from mailbox %p.\n", self, (void*)ret, mb_start);
		if (length == UINT_MAX)
		{
		  SORT_DEBUG3("SW Thread %lu, call %d: Got exit command from mailbox %p.\n", self, call_nr, mb_start);
		  mbox_put(mb_stop, dummy);
		  pthread_exit((void*)0);
		}

		address = mbox_get(mb_start);

		SORT_DEBUG3("SW Thread %lu, call %d: starting bubblesort on pointer %p\n", self, call_nr, (unsigned int*)address);
#ifdef BENCHMARK
		timing_t start, stop;
		ms_t bubblesort_time;
		start = gettime();
#endif
		bubblesort( (unsigned int*) address, length);
#ifdef BENCHMARK
		stop = gettime();
		bubblesort_time = calc_timediff_ms(start, stop);
		printf("bubblesort time: %lu ms\n", bubblesort_time);
#endif
		mbox_put(mb_stop, dummy);

		SORT_DEBUG3("SW Thread %lu, call %d: putting acknowledgement into mailbox %p\n", self, call_nr, mb_stop);
        call_nr++;
    }

    return (void*)0;
}


void sort_shmem_setup_resources(void *(**actual_sort_thread)(void* data), const int ** actual_slot_map, struct reconos_resource res[MAX_THREADS][2], int buffer_size,struct gengetopt_args_info args_info){
	// set software implementation of sort thread
	*actual_sort_thread = sort_thread_shmem;

	// set slot assignments
	*actual_slot_map = shmem_slots;

	// init mailboxes for shared memory solution
	for (int i = 0; i < MAX_THREADS; i++) {
		mbox_init(&mb_start[i], TO_BLOCKS(buffer_size, args_info.blocksize_arg));
		mbox_init(&mb_stop[i], TO_BLOCKS(buffer_size, args_info.blocksize_arg));
		res[i][0].type = RECONOS_TYPE_MBOX;
		res[i][0].ptr = &(mb_start[i]);
		res[i][1].type = RECONOS_TYPE_MBOX;
		res[i][1].ptr = &(mb_stop[i]);
	}
}

void sort_shmem_put_data(int buffer_size){
	//
	// shared memory solution
	//
	for (int i = 0; i < TO_BLOCKS(buffer_size, args_info.blocksize_arg); i++) {
		mbox_put(&mb_start[i % running_threads], TO_WORDS(args_info.blocksize_arg));
		mbox_put(&mb_start[i % running_threads], (unsigned int) data + (i * args_info.blocksize_arg));
		//printf(" %i",i);fflush(stdout);
	}
}

void sort_shmem_get_data(int buffer_size){
	//
	// shared memory solution
	//
	for (int i = 0; i < TO_BLOCKS(buffer_size, args_info.blocksize_arg); i++) {
		(void) mbox_get(&mb_stop[i % running_threads]); // we discard return value as it does not matter
	}
}

void sort_shmem_terminate(){
	for (int i = 0; i < running_threads; i++) {
		printf(" %i", i);
		fflush(stdout);
		mbox_put(&mb_start[i], UINT_MAX);
	}
}
