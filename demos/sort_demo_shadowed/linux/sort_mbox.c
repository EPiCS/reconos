/*
 * sort_mbox.c
 *
 *  Created on: 22.07.2013
 *      Author: meise
 */

#include "sort_mbox.h"

#define DEBUG 1

#ifdef DEBUG
    #define SORT_DEBUG(message) printf("SORT_MBOX: " message)
    #define SORT_DEBUG1(message, arg1) printf("SORT_MBOX: " message, (arg1))
    #define SORT_DEBUG2(message, arg1, arg2) printf("SORT_MBOX: " message, (arg1), (arg2))
	#define SORT_DEBUG3(message, arg1, arg2, arg3) printf("SORT_MBOX: " message, (arg1), (arg2), (arg3))
	#define SORT_DEBUG4(message, arg1, arg2, arg3, arg4) printf("SORT_MBOX: " message, (arg1), (arg2), (arg3), (arg4))
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

// This is a messsage based sort thread:
// - gets length of data and every data word via a message box
// - if length > 0: copy data into private buffer and start sorting it; afterwards pass data back via message box
// - if length = UINT_MAX : exit command -> issue thread exit os call
void *sort_thread_mbox(void* data)
{
	static int call_nr = 0;
	unsigned int i;
    unsigned int length;
    unsigned int  buffer[MAX_BLOCK_SIZE_WORDS*sizeof(unsigned int)];
    struct reconos_resource *res  = (struct reconos_resource*) data;
    struct mbox *mb_start = res[0].ptr;
    struct mbox *mb_stop  = res[1].ptr;
#ifdef DEBUG
    pthread_t self = pthread_self();
#endif
    SORT_DEBUG4("SW Thread %lu, call %d: Started with mailbox addresses %p and %p ...\n", self, call_nr,  mb_start, mb_stop);

    // error injection code
//    int leading_thread = false;
//    shadowedthread_t *sh;
//    pthread_t this = pthread_self();
//    if (is_shadowed_in_parent(this, &sh)) {
//    	leading_thread = shadow_leading_thread(sh, this);
//	}
    //

    SORT_DEBUG2("SORT8K: Address of buffer: %8p, size of buffer %lu\n", buffer, sizeof(buffer));
    while ( 1 ) {
    	SORT_DEBUG3("SW Thread %lu, call %d: getting length from mailbox %p\n", self, call_nr, mb_start);
        length = mbox_get(mb_start);

		//printf("SW Thread %lu: Got address %p from mailbox %p.\n", self, (void*)ret, mb_start);
		if (length == UINT_MAX)
		{
		  SORT_DEBUG3("SW Thread %lu, call %d: Got exit command from mailbox %p.\n", self, call_nr, mb_start);
		  mbox_put(mb_stop, UINT_MAX);
		  //free(buffer);
		  pthread_exit((void*)0);
		}
		else
		{
		  SORT_DEBUG3("SW Thread %lu, call %d: starting bubblesort with length %i\n", self, call_nr, (unsigned int)length);
		  // read into local buffer
		  SORT_DEBUG("Reading Data Words:...\n");
		  for (i = 0; i< length; i++){
			  // Error injection:
			  //if (leading_thread && (i == 42) ){continue;}
			  //if (leading_thread && (i == 42) ){mbox_put(mb_stop, buffer[i]);}
			  //
			  buffer[i] = mbox_get(mb_start);
		  }
		  SORT_DEBUG3("First three data words read: %i %i %i\n", buffer[0],buffer[1],buffer[2]);
		  // sort local buffer
#ifdef BENCHMARK
		  timing_t start, stop;
		  ms_t bubblesort_time;
		  start = gettime();
#endif
		  bubblesort(  buffer, length); // length is number of (unsigned int*) the buffer consists of
#ifdef BENCHMARK
		  stop = gettime();
		  bubblesort_time = calc_timediff_ms(start, stop);
		  printf("bubblesort time: %lu ms\n", bubblesort_time);
#endif
		  // Error injection
		  //if (leading_thread){buffer[42]= 0x1337;}
		  //

		  // write sorted buffer into output queue
		  SORT_DEBUG("Writing Data Words...\n");
		  for (i = 0; i< length; i++){
		  	  mbox_put(mb_stop, buffer[i]);
		  }
		  SORT_DEBUG3("First three data words written: %i %i %i\n", buffer[0],buffer[1],buffer[2]);

		}
		//SORT_DEBUG3("SW Thread %lu, call %d: put acknowledgement into mailbox %p\n", self, call_nr, mb_stop);
        call_nr++;
#ifdef SHADOWING
        SORT_DEBUG("Calling pthread_yield() ...\n");
        pthread_yield();
#endif
    }

    return (void*)0;
}

void sort_mbox_setup_resources(void *(**actual_sort_thread)(void* data), const int ** actual_slot_map, struct reconos_resource res[MAX_THREADS][2],int buffer_size,struct gengetopt_args_info args_info){
	// set software implementation of sort thread
	*actual_sort_thread = sort_thread_mbox;

	// set slot assignments
	*actual_slot_map = mbox_slots;

	// init mailboxes for mbox solution
	for (int i = 0; i < MAX_THREADS; i++) {
		mbox_init(&(mb_start[i]), TO_WORDS(buffer_size) + MAX_THREADS);
		mbox_init(&(mb_stop[i]), TO_WORDS(buffer_size) + MAX_THREADS);
		res[i][0].type = RECONOS_TYPE_MBOX;
		res[i][0].ptr = &(mb_start[i]);
		res[i][1].type = RECONOS_TYPE_MBOX;
		res[i][1].ptr = &(mb_stop[i]);
	}

}

void sort_mbox_put_data(int buffer_size){
	//
	// mbox solution
	//
	for (int i = 0; i < TO_BLOCKS(buffer_size, args_info.blocksize_arg); i++) {
		mbox_put(&mb_start[i % running_threads],
				(unsigned int) TO_WORDS(args_info.blocksize_arg));
		//printf(" %i",i);fflush(stdout);
		for (int j = 0; j < TO_WORDS(args_info.blocksize_arg); j++) {
			mbox_put(&mb_start[i % running_threads],
					(unsigned int) data[i * TO_WORDS(args_info.blocksize_arg) + j]);
		}
	}
}

void sort_mbox_get_data(int buffer_size){
	//
	// mbox solution
	//
	for (int i = 0; i < TO_BLOCKS(buffer_size, args_info.blocksize_arg); i++) {
		for (int j = 0; j < TO_WORDS(args_info.blocksize_arg); j++) {
			data[i * TO_WORDS(args_info.blocksize_arg) + j] = mbox_get(
					&mb_stop[i % running_threads]);
		}
		//printf(" %i",i);fflush(stdout);
	}
}

void sort_mbox_terminate(){
	//
	// mbox_solution
	//
	for (int i = 0; i < running_threads; i++) {
		printf(" %i", i);
		fflush(stdout);
		mbox_put(&mb_start[i], UINT_MAX);
	}
}

