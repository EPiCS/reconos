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

struct parallel_sort_interface sort_rq_interface = {
		.setup_resources = sort_rq_setup_resources,
		.put_data = sort_rq_put_data,
		.get_data = sort_rq_get_data,
		.terminate = sort_rq_terminate,
		.teardown_resources = sort_rq_teardown_resources
};

// reconos queues
rqueue sort_rq_start[MAX_THREADS];
rqueue sort_rq_stop[MAX_THREADS];

// This is a reconos queue based solution.
// Sort data is communicated in 8k blocks via reconos queues.
// Protocol is:
// - First rq message is a single word containing length of data to sort
//   If it is UINT_MAX, thread will exit
// - Second rq message will contain data to sort.
// - thread sends back sorted data via rq message
void *sort_rq_thread(void* data)
{
	static int call_nr = 0;
    unsigned int length_bytes;
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
        error = rq_receive(rq_start,&length_bytes, sizeof(length_bytes));
        SORT_DEBUG1("RQ_RECEIVE 1 returned %i\n", error);
        SORT_DEBUG1("RQ_RECEIVE 1 length_bytes is %i\n", length_bytes);
        if ( error != sizeof(length_bytes) )
        {
        	printf("ERROR: rq_receive 1 returned to few data. Expected: %lu bytes, returned %i bytes", sizeof(length_bytes), error);
        	exit(24);
        }
		//printf("SW Thread %lu: Got address %p from mailbox %p.\n", self, (void*)ret, mb_start);
		if (length_bytes == UINT_MAX)
		{
		  SORT_DEBUG3("SW Thread %lu, call %d: Got exit command from rqueue %p.\n", self, call_nr, rq_start);
		  rq_send(rq_stop, &length_bytes, sizeof(length_bytes));
		  //free(buffer);
		  pthread_exit((void*)0);
		}
		else
		{
		  SORT_DEBUG3("SW Thread %lu, call %d: starting bubblesort with length_bytes %i\n", self, call_nr, (unsigned int)length_bytes);
		  // read into local buffer
		  SORT_DEBUG("Reading Data Words:...\n");
		  // Error injection:
		  // if (leading_thread){length_bytes--;} // Tests parameter checking
		  //
		  error = rq_receive(rq_start, buffer, length_bytes);
		  SORT_DEBUG1("RQ_RECEIVE 2 returned %i\n", error);
		  SORT_DEBUG1("RQ_RECEIVE 2 length_bytes is %i\n", length_bytes);
		  if ( error != length_bytes)
		  {
			printf("ERROR: rq_receive 2 returned to few data. Expected: %i bytes, returned %i bytes", length_bytes, error);
			exit(24);
		  }

		  SORT_DEBUG3("First three data words read: %i %i %i\n", buffer[0],buffer[1],buffer[2]);
		  // sort local buffer
#ifdef BENCHMARK
		  timing_t start, stop;
		  ms_t bubblesort_time;
		  start = gettime();
#endif
		  bubblesort(  buffer, TO_WORDS(length_bytes)); // N is number of (unsigned int*) the buffer consists of
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
		  rq_send(rq_stop, buffer, length_bytes);
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

void sort_rq_setup_resources(const struct parallel_sort_params_in * pin, struct parallel_sort_params_out * pout){
	const int sort_rq_resource_count = 2;
	// set software implementation of sort thread
	pout->sort_thread_main = sort_rq_thread;
	pout->sort_program_worker = NULL;
	pout->sort_program_hwt = "SLOT_SORT_RQ";

	pout->reconos_resources_count = sort_rq_resource_count;
		pout->res = malloc(sort_rq_resource_count * pin->thread_count* sizeof(struct reconos_resource));
	// init reconos queues
	for (int i = 0; i < pin->thread_count; i++) {
		rq_init(&(sort_rq_start[i]), TO_BLOCKS(pin->data_size_bytes, pin->block_size_bytes) * 2);
		rq_init(&(sort_rq_stop[i]), TO_BLOCKS(pin->data_size_bytes, pin->block_size_bytes) * 2);
		pout->res[i*sort_rq_resource_count + 0] = (struct reconos_resource){
			.type = RECONOS_TYPE_RQ,
			.ptr = &(sort_rq_start[i])
		};
		pout->res[i*sort_rq_resource_count + 1] = (struct reconos_resource){
				.type = RECONOS_TYPE_RQ,
				.ptr = &(sort_rq_stop[i])
		};
	}
}

void sort_rq_put_data(const struct parallel_sort_params_in * pin){
	// rq_* calls expect length parameters in bytes
	// the sort thread expects length parameters in words!
	unsigned int length_bytes = pin->block_size_bytes;
	for (int i = 0; i < TO_BLOCKS(pin->data_size_bytes, pin->block_size_bytes); i++) {
		// First send length of data  to sort
		rq_send(&sort_rq_start[i % pin->thread_count], &length_bytes, sizeof(length_bytes));
		// then send actual data
		rq_send(&sort_rq_start[i % pin->thread_count],
				pin->data + i * TO_WORDS(pin->block_size_bytes), length_bytes);
	}
}

void sort_rq_get_data(const struct parallel_sort_params_in * pin){
	unsigned int length_bytes = pin->block_size_bytes;
	for (int i = 0; i < TO_BLOCKS(pin->data_size_bytes,pin->block_size_bytes); i++) {
		// receive results
		rq_receive(&sort_rq_stop[i % pin->thread_count],
				pin->data + i * TO_WORDS(pin->block_size_bytes), length_bytes);
	}
}

void sort_rq_terminate(const struct parallel_sort_params_in * pin){
	unsigned int exit_value = UINT_MAX;
	for (int i = 0; i < pin->thread_count; i++) {
		printf(" %i", i);
		fflush(stdout);
		rq_send(&sort_rq_start[i], &exit_value, sizeof(exit_value));
		//shadow_dump(sh+i);

	}
}

void sort_rq_teardown_resources(const struct parallel_sort_params_in * pin, struct parallel_sort_params_out * pout){
	free(pout->res);
	for (int i = 0; i < MAX_THREADS; i++) {
		rq_close(&(sort_rq_start[i]));
		rq_close(&(sort_rq_stop[i]));
	}
}
