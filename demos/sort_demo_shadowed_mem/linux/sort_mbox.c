/*
 * sort_mbox.c
 *
 *  Created on: 22.07.2013
 *      Author: meise
 */

#include "sort_mbox.h"

#include "thread_shadowing_subs.h"

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

struct parallel_sort_interface sort_mbox_interface = {
		.setup_resources = sort_mbox_setup_resources,
		.put_data = sort_mbox_put_data,
		.get_data = sort_mbox_get_data,
		.terminate = sort_mbox_terminate,
		.teardown_resources = sort_mbox_teardown_resources
};

// mailboxes
struct mbox sort_mbox_start[MAX_THREADS];
struct mbox sort_mbox_stop[MAX_THREADS];

// This is a messsage based sort thread:
// - gets length of data and every data word via a message box
// - if length > 0: copy data into private buffer and start sorting it; afterwards pass data back via message box
// - if length = UINT_MAX : exit command -> issue thread exit os call
void *sort_mbox_thread(void* data)
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

void sort_mbox_setup_resources(const struct parallel_sort_params_in * pin, struct parallel_sort_params_out * pout){
	const int sort_mbox_resource_count = 2;
	// set implementations of sort thread
	pout->sort_thread_main = sort_mbox_thread;
	pout->sort_program_worker = NULL;
	pout->sort_program_hwt = "SLOT_SORT_MBOX";

	pout->reconos_resources_count = sort_mbox_resource_count;
	pout->res = malloc(sort_mbox_resource_count * pin->thread_count* sizeof(struct reconos_resource));
	// init mailboxes for mbox solution
	for (int i = 0; i < pin->thread_count; i++) {
		mbox_init(&(sort_mbox_start[i]), TO_WORDS(pin->data_size_bytes) + MAX_THREADS);
		mbox_init(&(sort_mbox_stop[i]), TO_WORDS(pin->data_size_bytes) + MAX_THREADS);
		pout->res[i*sort_mbox_resource_count + 0] = (struct reconos_resource){
		       .type = RECONOS_TYPE_MBOX,
		       .ptr = &(sort_mbox_start[i])
		};
		pout->res[i*sort_mbox_resource_count + 1] = (struct reconos_resource){
			.type = RECONOS_TYPE_MBOX,
			.ptr = &(sort_mbox_stop[i])
		};
	}

}

void sort_mbox_put_data(const struct parallel_sort_params_in * pin){
	for (int i = 0; i < TO_BLOCKS(pin->data_size_bytes, pin->block_size_bytes); i++) {
		mbox_put(&sort_mbox_start[i % pin->thread_count],
				(unsigned int) TO_WORDS(pin->block_size_bytes));
		//printf(" %i",i);fflush(stdout);
		for (int j = 0; j < TO_WORDS(pin->block_size_bytes); j++) {
			mbox_put(&sort_mbox_start[i % pin->thread_count],
					(unsigned int) pin->data[i * TO_WORDS(pin->block_size_bytes) + j]);
		}
	}
}

void sort_mbox_get_data(const struct parallel_sort_params_in * pin){
	for (int i = 0; i < TO_BLOCKS(pin->data_size_bytes, pin->block_size_bytes); i++) {
		for (int j = 0; j < TO_WORDS(pin->block_size_bytes); j++) {
			pin->data[i * TO_WORDS(pin->block_size_bytes) + j] = mbox_get(
					&sort_mbox_stop[i % pin->thread_count]);
		}
		//printf(" %i",i);fflush(stdout);
	}
}

void sort_mbox_terminate(const struct parallel_sort_params_in * pin){
	for (int i = 0; i < pin->thread_count; i++) {
		printf(" %i", i);
		fflush(stdout);
		mbox_put(&sort_mbox_start[i], UINT_MAX);
	}
}

void sort_mbox_teardown_resources(const struct parallel_sort_params_in * pin, struct parallel_sort_params_out * pout){
	free(pout->res);
	for (int i = 0; i < MAX_THREADS; i++) {
		mbox_destroy(&(sort_mbox_start[i]));
		mbox_destroy(&(sort_mbox_stop[i]));
	}
}
