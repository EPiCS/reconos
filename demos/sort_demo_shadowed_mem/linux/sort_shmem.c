/*
 * sort_shmem.c
 *
 *  Created on: 22.07.2013
 *      Author: meise
 */
#include "sort_shmem.h"

//#include "thread_shadowing_subs.h"

//#define DEBUG 1

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

struct parallel_sort_interface sort_shmem_interface = {
		.setup_resources = sort_shmem_setup_resources,
		.put_data = sort_shmem_put_data,
		.get_data = sort_shmem_get_data,
		.terminate = sort_shmem_terminate,
		.teardown_resources = sort_shmem_teardown_resources
};

// mailboxes
static struct mbox sort_shmem_mb_start[MAX_THREADS];
static struct mbox sort_shmem_mb_stop[MAX_THREADS];

// sort thread shall behave the same as hw thread:
// - get pointer to data buffer
// - if valid address: sort data and post answer
// - if exit command: issue thread exit os call
void *sort_shmem_thread(void* data)
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


void sort_shmem_setup_resources(const struct parallel_sort_params_in * pin, struct parallel_sort_params_out * pout){
	const int sort_shmem_resource_count = 2;
	// set implementations of sort thread
	pout->sort_thread_main = sort_shmem_thread;
	pout->sort_program_worker = "sort_demo_shmem_workercpu.bin";
	pout->sort_program_hwt = "SLOT_SORT_SHMEM";

	pout->reconos_resources_count = sort_shmem_resource_count;
	pout->res = malloc(sort_shmem_resource_count * pin->thread_count* sizeof(struct reconos_resource));
	// init mailboxes for shared memory solution
	for (int i = 0; i < pin->thread_count; i++) {
		mbox_init(&sort_shmem_mb_start[i], TO_BLOCKS(pin->data_size_bytes, pin->block_size_bytes));
		mbox_init(&sort_shmem_mb_stop[i], TO_BLOCKS(pin->data_size_bytes, pin->block_size_bytes));
		pout->res[i*sort_shmem_resource_count + 0] = (struct reconos_resource){
				.type = RECONOS_TYPE_MBOX,
				.ptr = &(sort_shmem_mb_start[i])
		};
		pout->res[i*sort_shmem_resource_count + 1] = (struct reconos_resource){
				.type = RECONOS_TYPE_MBOX,
				.ptr = &(sort_shmem_mb_stop[i])
		};

	}
}

void sort_shmem_put_data(const struct parallel_sort_params_in * pin){
	for (int i = 0; i < TO_BLOCKS(pin->data_size_bytes, pin->block_size_bytes); i++) {
		//printf("SORT_SHMEM: 0x%p\n",  pin->data + (i * pin->block_size_bytes));
		mbox_put(&sort_shmem_mb_start[i % pin->thread_count], TO_WORDS(pin->block_size_bytes));
		mbox_put(&sort_shmem_mb_start[i % pin->thread_count], (unsigned int) pin->data + (i * pin->block_size_bytes));
		//printf(" %i",i);fflush(stdout);
	}
}

void sort_shmem_get_data(const struct parallel_sort_params_in * pin){
	for (int i = 0; i < TO_BLOCKS(pin->data_size_bytes, pin->block_size_bytes); i++) {
		(void) mbox_get(&sort_shmem_mb_stop[i % pin->thread_count]); // we discard return value as it does not matter
	}
}

void sort_shmem_terminate(const struct parallel_sort_params_in * pin){
	for (int i = 0; i < pin->thread_count; i++) {
		printf(" %i", i);
		fflush(stdout);
		mbox_put(&sort_shmem_mb_start[i], UINT_MAX);
	}
}

void sort_shmem_teardown_resources(const struct parallel_sort_params_in * pin, struct parallel_sort_params_out * pout){
	free(pout->res);
	for (int i = 0; i < MAX_THREADS; i++) {
		mbox_destroy(&sort_shmem_mb_start[i]);
		mbox_destroy(&sort_shmem_mb_stop[i]);
	}
}
