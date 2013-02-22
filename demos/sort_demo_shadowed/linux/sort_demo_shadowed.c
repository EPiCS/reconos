#include "reconos.h"
#include "mbox.h"
#include "rqueue.h"

#include "thread_shadowing.h"
//#include "thread_shadowing_subs.h"

#include "eif.h"

#include <stdio.h>
#include <stdlib.h>
#define  _GNU_SOURCE
#include <pthread.h>
#include <assert.h>
#include <signal.h>
#include <sys/ucontext.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>
#include "config.h"
#include "merge.h"
#include "data.h"
//#include "bubblesort.h"
#include "sort8k.h"
#include "timing.h"
#include "eif.h"


#define PAGE_SIZE 4096 //Bytes
#define PAGE_WORDS 1024
#define PAGE_MASK 0xFFFFF000
#define PAGES_PER_THREAD 2

#define BLOCK_SIZE PAGE_SIZE*PAGES_PER_THREAD

#define MAX_BURST_SIZE 1023
#define MAX_THREADS 32

#define TO_WORDS(x) ((x)/4)
#define TO_PAGES(x) ((x)/PAGE_SIZE)
#define TO_BLOCKS(x) ((x)/(PAGE_SIZE*PAGES_PER_THREAD))

// Thread Interfaces
#define TI_SHMEM  0
#define TI_MBOX   1
#define TI_RQUEUE 2

// Thread shadowing
int hw_threads;
int sw_threads;
int sh_threadcount = 2;
int running_threads;
shadowedthread_t sh[MAX_THREADS];

// pointers to buffers of unsorted numbers
unsigned int *data, *copy;

// mailboxes
struct mbox mb_start[MAX_THREADS];
struct mbox mb_stop[MAX_THREADS];

// reconos queues
rqueue rq_start[MAX_THREADS];
rqueue rq_stop[MAX_THREADS];


/**
 * @brief Versatile function for printing data arrays
 * @param _data		   pointer to data array
 * @param _data_size   is gives size of data array in bytes
 * @param _first_count determines how many bytes at start of data array will be printed
 * @param _last_count  determines how many bytes at end   of data array will be printed
 */
void print_data_first_last(unsigned int* _data, size_t _data_size, size_t _first_count, size_t _last_count)
{
	int i;
	for(i = 0; i < _first_count; i++){
	  printf("%08X ",_data[i]);
	  if((i % 16) == 15) printf("\n");
	}
	if (_last_count > 0)
	{
		printf("[...]\n");
		for(i = TO_WORDS(_data_size)-_last_count; i < TO_WORDS(_data_size); i++){
				  printf("%08X ",_data[i]);
				  if((i % 16) == 15) printf("\n");
			}
	}
	if((i % 16) != 15) printf("\n");
}

/**
 * @brief Copies 8kBytes from given pointer to newly allocated block of memory and returns a pointer to it.
 *
 */
void *buffer_copy (void *ptr)
{
  void *cpy;
  cpy = malloc (SIZE);
  if (ptr != NULL)
    {
      memcpy (cpy, ptr, SIZE);
    }
  return cpy;
}

/**
 * @brief Compares two 8 kBytes buffers.
 * \param pos Optional Parameter. If not null, the index of the found difference will be stored.
 */
int buffer_compare_report (unsigned int *a, unsigned int *b, unsigned int *idx)
{
  unsigned int index = 0;
  while ((*a == *b) && (index < N))
    {
      a++, b++, index++;
    }
  if (index < N)
    {
      if (idx != NULL)
	{
	  *idx = index;
	}
      return false;
    }
  else
    {
      return true;
    }
}

int buffer_compare( void *a, void *b){
    return buffer_compare_report( (unsigned int*) a, (unsigned int*) b, NULL);
}

/*
 * @brief Prints statistics on the memory management unit in the hardware slots path to memory.
 */
void print_mmu_stats()
{
	uint32 hits,misses,pgfaults;

	reconos_mmu_stats(&hits,&misses,&pgfaults);

	printf("MMU stats: TLB hits: %d    TLB misses: %d    page faults: %d\n",hits,misses,pgfaults);
}

/*
 * @brief On invalind command line syntax, this function will output a help on correct syntax.
 */
void print_help()
{
  printf(
"ReconOS v3 extended sort demo application.\n"
"Sorts a buffer full of data with a variable number of sw and hw threads.\n"
"Supports thread shadowing and different thread interfaces and error injection."
"\n"
"Usage:\n"
"\tsort_demo <-h|--help>\n"
"\tsort_demo <num_hw_threads> <num_sw_threads> <num_of_blocks> [thread interface] [redundant threads] [#injected errors] [seed]\n"
"\n"
"Size of a block in bytes: %i\n"
"\n"
"Implemented Thread Interfaces:\n"
"\t0: data via shared memory, address via message box (Default),\n"
"\t1: all data via message box,\n"
"\t2: all data via reconos queue\n",
PAGE_SIZE*PAGES_PER_THREAD
);
}

/*
 * Signal handler for SIGSEGV. Used for debugging on a microblaze processor.
 * Get as much information to help in debugging as possible!
 */
void sigsegv_handler(int sig, siginfo_t *siginfo, void * context){
	int i;
	ucontext_t* uc = (ucontext_t*) context;

    // Yeah, i know using printf in a signal context is not save.
    // But with a SIGSEGV the programm is messed up anyway, so what?
    printf("SIGSEGV: Programm killed at programm address %p, tried to access %p.\n",
#ifndef HOST_COMPILE
    		(void*)uc->uc_mcontext.regs.pc,
#else
    		(void*)uc->uc_mcontext.gregs[14],
#endif
    		(void*) siginfo->si_addr);

    // Print address of unsorted numbers buffer
    printf("data: %8p \ncopy: %8p\n", data, copy);
    // Print OS call lists for debugging
    for (i=0; i < running_threads; i++){
    	shadow_dump(sh + i);
    }
    exit(32);
}

/*
 * @brief Sets up the error injection in compute threads stack.
 */
void eif_setup( shadowedthread_t* shadows, unsigned int error_count, unsigned int seed)
{
	void* stack_address;
	size_t stack_size;
	extern int pthread_getattr_np(pthread_t thread, pthread_attr_t *attr);


//	for(i=0; i< running_threads; i++){
//		shadow_get_stack(shadows+i, 0, &stack_address, &stack_size);
//		printf ("Shadowed Thread %i: stack address: %p stack size: %i\n",i, stack_address, stack_size);
//	}
//	exit(0);

	pthread_attr_t main_attr;
	pthread_getattr_np(pthread_self(),&main_attr);
	pthread_attr_getstack(&main_attr, &stack_address, &stack_size);
	printf("Main Thread Stack address: %8p  Stack size: %8zi\n", stack_address, stack_size);

	shadow_get_stack(shadows+0, 0, &stack_address, &stack_size);
	printf("Sort Thread Stack address: %8p  Stack size: %8zi\n", stack_address, stack_size);

	eif_set_seed(seed);
	eif_add_trans(stack_address+stack_size- 1024*1024, 1024*1024 , error_count, 0, 20, SINGLE_BIT_FLIP, 0);
	//eif_add_trans(stack_address, stack_size , error_count, 0, 20, SINGLE_BIT_FLIP, 0);
	eif_start();
}

/**
 * @bief Main function
 */
int main(int argc, char ** argv)
{
	int i = 0;
	int j = 0;
	int error_idx, from, to = 0;
	int buffer_size = 0;
	int thread_interface = 0;
	unsigned int error_count=0;
	unsigned int seed=1;

	timing_t t_start;
    timing_t t_stop;
	ms_t t_generate = 0;
	ms_t t_sort = 0;
	ms_t t_merge = 0;
	ms_t t_check = 0;

	//
	// Install signal handler for segfaults
	//
	struct sigaction act={
			.sa_sigaction = sigsegv_handler,
			.sa_flags =  SA_SIGINFO
	};
	sigaction(SIGSEGV, &act, NULL);

	//
	// Parse command line arguments
	//
	if ((argc < 4) || (argc > 8))
	{
	  print_help();
	  exit(1);
	}
	// we have 3 or 4 arguments now...
	hw_threads = atoi(argv[1]);
	if ( hw_threads < 0 ) { hw_threads = 0; }
	if ( hw_threads > MAX_THREADS ) { hw_threads = MAX_THREADS; }
	sw_threads = atoi(argv[2]);
	if ( sw_threads < 0 ) { sw_threads = 0; }
	if ( sw_threads > MAX_THREADS ) { sw_threads = MAX_THREADS; }
	// Base unit is bytes. Use macros TO_WORDS, TO_PAGES and TO_BLOCKS for conversion.
	buffer_size = atoi(argv[3])*PAGE_SIZE*PAGES_PER_THREAD;
	if ( argc >= 5) {
		thread_interface = atoi(argv[4]);
		if ( thread_interface < TI_SHMEM ) { thread_interface = TI_SHMEM; }
		if ( thread_interface > TI_RQUEUE ) { thread_interface = TI_RQUEUE; }
	}
	if ( argc >= 6) {
		sh_threadcount = atoi(argv[5]);
		if ( sh_threadcount < 1 ){sh_threadcount = 1;}
		if ( sh_threadcount > 2 ){sh_threadcount = 2;}
	}
	if ( argc >= 7) {
		error_count = atoi(argv[6]);
	}
	if ( argc >= 8) {
		seed = atoi(argv[7]);
	}
	printf("Parameters: hwt: %2i, swt: %2i, blocks: %5i, thread interface: %s, shadowing: %s\n",
			hw_threads, sw_threads, TO_BLOCKS(buffer_size),
			(thread_interface == TI_SHMEM? "SHMEM":(thread_interface == TI_MBOX? "MBOX":(thread_interface == TI_RQUEUE? "RQUEUE":"unknown"))),
			(sh_threadcount == 1 ? "off": "on"));

	running_threads = hw_threads + sw_threads;
    printf("Main thread is pthread %lu\n", pthread_self());

    //
    // Setup resources for communication with compute threads
    //
    struct reconos_resource res[MAX_THREADS][2];
    switch( thread_interface )
    {
    case TI_SHMEM:
    	// init one mailbox for shared memory solution
    	mbox_init(&mb_start[0],TO_BLOCKS(buffer_size));
        mbox_init(&mb_stop[0] ,TO_BLOCKS(buffer_size));

    	res[0][0].type = RECONOS_TYPE_MBOX;
    	res[0][0].ptr  = &(mb_start[0]);
        res[0][1].type = RECONOS_TYPE_MBOX;
    	res[0][1].ptr  = &(mb_stop[0]);
    case TI_MBOX:
		// init mailboxes for mbox solution
		for (i=0; i< MAX_THREADS; i++){
			mbox_init(&(mb_start[i]),TO_WORDS(buffer_size)+MAX_THREADS);
			mbox_init(&(mb_stop[i]) ,TO_WORDS(buffer_size)+MAX_THREADS);
			res[i][0].type = RECONOS_TYPE_MBOX;
			res[i][0].ptr  = &(mb_start[i]);
			res[i][1].type = RECONOS_TYPE_MBOX;
			res[i][1].ptr  = &(mb_stop[i]);
		}
		break;
    case TI_RQUEUE:
    	// init reconos queues
		for (i=0; i< MAX_THREADS; i++){
			rq_init(&(rq_start[i]),TO_BLOCKS(buffer_size)*2);
			rq_init(&(rq_stop[i]) ,TO_BLOCKS(buffer_size)*2);
			res[i][0].type = RECONOS_TYPE_RQ;
			res[i][0].ptr  = &(rq_start[i]);
			res[i][1].type = RECONOS_TYPE_RQ;
			res[i][1].ptr  = &(rq_stop[i]);
		}
		break;
    }


#ifndef HOST_COMPILE
    //
	// create hardware shadowed threads
    //
	reconos_init_autodetect();

	printf("Creating %i shadowed hw-threads: ", hw_threads);
	fflush(stdout);
	for (i = 0; i < hw_threads; i++)
	{
		printf(" %i",i);fflush(stdout);

		shadow_init( sh+i );
		shadow_set_reliability( sh+i, TS_REL_DEFAULT );
		shadow_set_copycompare( sh+i, buffer_copy, buffer_compare );
		switch( thread_interface )
		{
			case TI_SHMEM:
				shadow_set_resources( sh+i, res[0], 2 );
				for (j=0; j< sh_threadcount; j++)
				{
					shadow_set_hwslots(sh+i, j, 0+j+sh_threadcount*i);
				}
				break;
			case TI_MBOX:
				shadow_set_resources( sh+i, res[i], 2 );
				for (j=0; j< sh_threadcount; j++)
				{
					shadow_set_hwslots(sh+i, j, 4+j+sh_threadcount*i);
				}
				break;
			case TI_RQUEUE:
				shadow_set_resources( sh+i, res[i], 2 );
				for (j=0; j< sh_threadcount; j++)
				{
					shadow_set_hwslots(sh+i, j, 8+j+sh_threadcount*i);
				}
				break;
		}
		shadow_set_options(sh+i, TS_MANUAL_SCHEDULE);
		shadow_set_threadcount(sh+i, sh_threadcount, 0);
		shadow_thread_create(sh+i);
	}
	printf("\n");
#endif
	// create software shadowed threads
	printf("Creating %i shadowed sw-threads: ",sw_threads);
	fflush(stdout);
	for (i = hw_threads; i < hw_threads+sw_threads; i++)
	{
		printf(" %i",i-hw_threads);fflush(stdout);

		shadow_init( sh+i );
		shadow_set_reliability( sh+i, TS_REL_DEFAULT );
		shadow_set_copycompare( sh+i, buffer_copy, buffer_compare );

		switch( thread_interface )
		{
		    case TI_SHMEM:
		    	shadow_set_swthread( sh+i, sort_thread_shmem );
		    	shadow_set_resources( sh+i, res[0], 2 );
		    	break;
		    case TI_MBOX:
		    	shadow_set_swthread( sh+i, sort_thread_mbox );
		    	shadow_set_resources( sh+i, res[i], 2 );
		    	break;
		    case TI_RQUEUE:
		    	shadow_set_swthread( sh+i, sort_thread_rqueue );
		    	shadow_set_resources( sh+i, res[i], 2 );
		    	break;
		}
		shadow_set_options(sh+i, TS_MANUAL_SCHEDULE);
		shadow_set_threadcount( sh+i, 0, sh_threadcount);
		shadow_thread_create( sh+i );
	}
	printf("\n");


	// Setup error injection; no error injection if error count is 0 :-)
	eif_setup(sh, error_count, seed);

	//print_mmu_stats();

	// create pages and generate data
	t_start = gettime();

	printf("malloc page aligned ...\n");
	data = xmalloc_aligned(buffer_size,PAGE_SIZE);
	copy = xmalloc_aligned(buffer_size,PAGE_SIZE);
	printf("generating %i words of data ...\n", TO_WORDS(buffer_size));
	generate_data( data, TO_WORDS(buffer_size));
	memcpy(copy,data,buffer_size);

	// print generated data
#if 0
	printf("\ndumping the first and last 128 words of data:\n");
	print_data_first_last(data, buffer_size, 128, 128);

	printf("\ndumping the first and last 128 words of copy:\n");
	print_data_first_last(copy, buffer_size, 128, 128);
#endif

	t_stop = gettime();
	t_generate = calc_timediff_ms(t_start,t_stop);

	// Start sort threads
	t_start = gettime();

	printf("Putting %i blocks into job queues: ", TO_BLOCKS(buffer_size));
	fflush(stdout);

	//
	// Transfer data to compute threads
	//
	unsigned int length = TO_WORDS(BLOCK_SIZE)*4;
	switch ( thread_interface )
	{
	case TI_SHMEM:
		//
		// shared memory solution
		//
		for (i=0; i<TO_BLOCKS(buffer_size); i++)
		{
		  mbox_put(&mb_start[0],(unsigned int)data+(i*BLOCK_SIZE));
		  //printf(" %i",i);fflush(stdout);
		}
		break;
	case TI_MBOX:
		//
		// mbox solution
		//
		for (i=0; i<TO_BLOCKS(buffer_size); i++)
		{
		  mbox_put( &mb_start[i%running_threads],(unsigned int)TO_WORDS(BLOCK_SIZE) );
		  //printf(" %i",i);fflush(stdout);
		  for(j = 0; j < TO_WORDS(BLOCK_SIZE); j++)
		  {
			  mbox_put( &mb_start[i%running_threads],(unsigned int)data[i*TO_WORDS(BLOCK_SIZE)+j] );
		  }
		}
		break;
	case TI_RQUEUE:
		//
		// rq solution
		//
		for (i=0; i<TO_BLOCKS(buffer_size); i++)
		{
			// First send length of data  to sort
			rq_send(&rq_start[i%running_threads], &length, sizeof(length));
			// then send actual data
			rq_send(&rq_start[i%running_threads], data+i*TO_WORDS(BLOCK_SIZE), length);
		}
		break;
	}
	printf("\n");

	//
	// Wait for results
	//
	printf("Waiting for %i blocks of data: ", TO_BLOCKS(buffer_size));
	fflush(stdout);

	switch ( thread_interface )
	{
	case TI_SHMEM:
		//
		// shared memory solution
		//
		for (i=0; i<TO_BLOCKS(buffer_size); i++)
		{
		  (void) mbox_get(&mb_stop[0]); // we discard return value as it does not matter
		}
		break;
	case TI_MBOX:
		//
		// mbox solution
		//
		for (i=0; i<TO_BLOCKS(buffer_size); i++)
		{
		  for ( j=0; j<TO_WORDS(BLOCK_SIZE) ; j++ ){
			  data[i*TO_WORDS(BLOCK_SIZE)+j] = mbox_get(&mb_stop[i%running_threads]);
		  }
		  //printf(" %i",i);fflush(stdout);
		}
		break;
	case TI_RQUEUE:
		//
		// rq solution
		//
		for (i=0; i<TO_BLOCKS(buffer_size); i++)
		{
			// receive results
			rq_receive(&rq_stop[i%running_threads], data+i*TO_WORDS(BLOCK_SIZE), length);
		}
		break;
	}
	printf("\n");

	t_stop = gettime();
	t_sort = calc_timediff_ms(t_start,t_stop);

	// merge data
	t_start = gettime();	

	printf("Merging sorted data slices...\n");
	unsigned int * temp = xmalloc_aligned(buffer_size, PAGE_SIZE);
	//printf("Data buffer at address %p \n", (void*)data);
	//printf("Address of temporary merge buffer: %p\n", (void*)temp);
	//printf("Total size of data in bytes: %i\n",buffer_size);
	//printf("Size of a sorting block in bytes: %i\n",BLOCK_SIZE);
	if (temp == NULL){
		printf ("Buffer allocation failed. Exiting...\n");
		exit(2);
	}
	data = recursive_merge( data, 
				temp,
				TO_WORDS(buffer_size), 
				TO_WORDS(BLOCK_SIZE), 
				simple_merge 
				);

	t_stop = gettime();
	t_merge = calc_timediff_ms(t_start,t_stop);
	
	// check data
	//data[0] = 6666; // manual fault
	t_start = gettime();

	printf("Checking sorted data: ... ");
	fflush(stdout);
	error_idx = check_data( data, copy, TO_WORDS(buffer_size));
	if (error_idx >= 0)
	  {
	    printf("failure at word index %i\n", error_idx);
	    printf("expected 0x%08X    found 0x%08X\n",copy[error_idx],data[error_idx]);
		printf("\ndumping the last %i words of data:\n", TO_WORDS(buffer_size));

		from = error_idx;
		to	 = error_idx+16; // error_idx + TO_WORDS(buffer_size)
		for(i = from; i < to; i++){
		  printf("%08X ",data[i]);
		  if((i % 16) == 15) printf("\n");
		}

		printf("\ndumping the last %i words of copy:\n", TO_WORDS(buffer_size));
		for(i = from; i < to; i++){
		  printf("%08X ",copy[i]);
		  if((i % 16) == 15) printf("\n");
		}
		exit(4);
	  }
	else
	  {
	    printf("success\n");
	    //print_data_first_last(data, buffer_size, buffer_size, 0);
	  }

	t_stop = gettime();
	t_check = calc_timediff_ms(t_start,t_stop);

	// terminate all threads
	printf("Sending terminate message to %i threads:", running_threads);
	fflush(stdout);

//	printf("\n");
	switch ( thread_interface )
	{
	case TI_SHMEM:
		for (i=0; i<running_threads; i++)
		{
		  printf(" %i",i);fflush(stdout);
		  mbox_put(&mb_start[0],UINT_MAX);
		}
		break;
	case TI_MBOX:
		//
		// mbox_solution
		//
		for (i=0; i<running_threads; i++)
		{
		  printf(" %i",i);fflush(stdout);
		  mbox_put(&mb_start[i],UINT_MAX);
		}
		break;
	case TI_RQUEUE:
		//
		// rq solution
		//
		{
			unsigned int exit_value = UINT_MAX;
			for (i=0; i<running_threads; i++)
			{
			  printf(" %i",i);fflush(stdout);
			  rq_send(&rq_start[i],&exit_value, sizeof(exit_value));
			  //shadow_dump(sh+i);

			}
		}
		break;
	}
	printf("\n");

	printf("Waiting for termination...\n");
	for (i=0; i<running_threads; i++)
	{
	  shadow_join(sh+i, NULL);
	}
	printf("\n");

	printf("Waiting for error injection to finish...\n");
	eif_join();

#ifndef HOST_COMPILE
	print_mmu_stats();
#endif

	printf( "Running times (size: %d words, %d hw-threads, %d sw-threads):\n"
            "\tGenerate data: %lu ms\n"
            "\tSort data    : %lu ms\n"
            "\tMerge data   : %lu ms\n"
            "\tCheck data   : %lu ms\n"
            "Total computation time (sort & merge): %lu ms\n",
		TO_WORDS(buffer_size), hw_threads, sw_threads,
		t_generate, t_sort, t_merge, t_check, t_sort + t_merge );
	
	free(data);
	free(copy);
	
	exit(0);
}

