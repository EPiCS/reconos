/*
 * sort_rq.c
 *
 *  Created on: 22.07.2013
 *      Author: meise
 */

#include "sort_rq.h"

#define DEBUG 1

#ifdef DEBUG
	#define SORT_DEBUG(message) printf("SORT_RQ: " message)
    #define SORT_DEBUG1(message, arg1) printf("SORT_RQ: " message, (arg1))
    #define SORT_DEBUG2(message, arg1, arg2) printf("SORT_RQ: " message, (arg1), (arg2))
	#define SORT_DEBUG3(message, arg1, arg2, arg3) printf("SORT_RQ: " message, (arg1), (arg2), (arg3))
	#define SORT_DEBUG4(message, arg1, arg2, arg3, arg4) printf("SORT_RQ: " message, (arg1), (arg2), (arg3), (arg4))
#else
    #define SORT_DEBUG(message)
    #define SORT_DEBUG1(message, arg1)
    #define SORT_DEBUG2(message, arg1, arg2)
	#define SORT_DEBUG3(message, arg1, arg2, arg3)
	#define SORT_DEBUG4(message, arg1, arg2, arg3, arg4)
#endif

// reconos queues
rqueue rq_start[MAX_THREADS];
rqueue rq_stop[MAX_THREADS];

// This is a reconos queue based solution.
// Sort data is communicated in 8k blocks via reconos queues.
// Protocol is:
// - First rq message is a single word containing length of data to sort
//   If it is UINT_MAX, thread will exit
// - Second rq message will contain data to sort.
// - thread sends back sorted data via rq message
void *sort_thread_rqueue(void* data)
{
	static int call_nr = 0;
    unsigned int length;
    unsigned int error=0;
    unsigned int  buffer[MAX_BLOCK_SIZE_WORDS*sizeof(unsigned int)];
    struct reconos_resource *res  = (struct reconos_resource*) data;
    rqueue *rq_start = res[0].ptr;
    rqueue *rq_stop  = res[1].ptr;
#ifdef DEBUG
    pthread_t self = pthread_self();
#endif
    SORT_DEBUG4("SW Thread %lu, call %d: Started with rqueue addresses %p and %p ...\n", self, call_nr,  rq_start, rq_stop);

    // error injection code
//    int leading_thread = false;
//    shadowedthread_t *sh;
//    pthread_t this = pthread_self();
//    if (is_shadowed_in_parent(this, &sh)) {
//    	leading_thread = shadow_leading_thread(sh, this);
//	}
    //


    while ( 1 ) {
    	SORT_DEBUG3("SW Thread %lu, call %d: getting length from rqueue %p\n", self, call_nr, rq_start);
        error = rq_receive(rq_start,&length, sizeof(length));
        SORT_DEBUG1("RQ_RECEIVE 1 returned %i\n", error);
        SORT_DEBUG1("RQ_RECEIVE 1 length is %i\n", length);
        if ( error != sizeof(length) )
        {
        	printf("ERROR: rq_receive 1 returned to few data. Expected: %lu bytes, returned %i bytes", sizeof(length), error);
        	exit(24);
        }
		//printf("SW Thread %lu: Got address %p from mailbox %p.\n", self, (void*)ret, mb_start);
		if (length == UINT_MAX)
		{
		  SORT_DEBUG3("SW Thread %lu, call %d: Got exit command from rqueue %p.\n", self, call_nr, rq_start);
		  rq_send(rq_stop, &length, sizeof(length));
		  //free(buffer);
		  pthread_exit((void*)0);
		}
		else
		{
		  SORT_DEBUG3("SW Thread %lu, call %d: starting bubblesort with length %i\n", self, call_nr, (unsigned int)length);
		  // read into local buffer
		  SORT_DEBUG("Reading Data Words:...\n");
		  // Error injection:
		  // if (leading_thread){length--;} // Tests parameter checking
		  //
		  error = rq_receive(rq_start, buffer, length);
		  SORT_DEBUG1("RQ_RECEIVE 2 returned %i\n", error);
		  SORT_DEBUG1("RQ_RECEIVE 2 length is %i\n", length);
		  if ( error != length )
		  {
			printf("ERROR: rq_receive 2 returned to few data. Expected: %i bytes, returned %i bytes", length, error);
			exit(24);
		  }

		  SORT_DEBUG3("First three data words read: %i %i %i\n", buffer[0],buffer[1],buffer[2]);
		  // sort local buffer
#ifdef BENCHMARK
		  timing_t start, stop;
		  ms_t bubblesort_time;
		  start = gettime();
#endif
		  bubblesort(  buffer, length); // N is number of (unsigned int*) the buffer consists of
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
		  rq_send(rq_stop, buffer, length);
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

void sort_rq_setup_resources(void *(**actual_sort_thread)(void* data), const int ** actual_slot_map, struct reconos_resource res[MAX_THREADS][2], int buffer_size, struct gengetopt_args_info args_info){
	// set software implementation of sort thread
	*actual_sort_thread = sort_thread_rqueue;

	// set slot assignments
	*actual_slot_map = rqueue_slots;

	// init reconos queues
	for (int i = 0; i < MAX_THREADS; i++) {
		rq_init(&(rq_start[i]), TO_BLOCKS(buffer_size, args_info.blocksize_arg) * 2);
		rq_init(&(rq_stop[i]), TO_BLOCKS(buffer_size, args_info.blocksize_arg) * 2);
		res[i][0].type = RECONOS_TYPE_RQ;
		res[i][0].ptr = &(rq_start[i]);
		res[i][1].type = RECONOS_TYPE_RQ;
		res[i][1].ptr = &(rq_stop[i]);
	}
}

void sort_rq_put_data(int buffer_size){
	//
	// rq solution
	//
	unsigned int length = TO_WORDS(args_info.blocksize_arg) * 4;
	for (int i = 0; i < TO_BLOCKS(buffer_size, args_info.blocksize_arg); i++) {
		// First send length of data  to sort
		rq_send(&rq_start[i % running_threads], &length, sizeof(length));
		// then send actual data
		rq_send(&rq_start[i % running_threads],
				data + i * TO_WORDS(args_info.blocksize_arg), length);
	}
}

void sort_rq_get_data(int buffer_size){
	//
	// rq solution
	//
	unsigned int length = TO_WORDS(args_info.blocksize_arg) * 4;
	for (int i = 0; i < TO_BLOCKS(buffer_size, args_info.blocksize_arg); i++) {
		// receive results
		rq_receive(&rq_stop[i % running_threads],
				data + i * TO_WORDS(args_info.blocksize_arg), length);
	}
}

void sort_rq_terminate(){
	//
	// rq solution
	//
	{
	unsigned int exit_value = UINT_MAX;
	for (int i = 0; i < running_threads; i++) {
		printf(" %i", i);
		fflush(stdout);
		rq_send(&rq_start[i], &exit_value, sizeof(exit_value));
		//shadow_dump(sh+i);

	}
}
}
