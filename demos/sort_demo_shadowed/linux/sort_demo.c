#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#define  _GNU_SOURCE
#include <pthread.h>
#include <assert.h>
#include <signal.h>
//#include <sys/ucontext.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>

#include "cmdline.h"
#include "reconos.h"
#include "mbox.h"
#include "rqueue.h"
#ifdef SHADOWING
#include "thread_shadowing.h"
//#include "thread_shadowing_subs.h"
#endif
#include "config.h"
#include "merge.h"
#include "data.h"
#include "sort8k.h"
#include "timing.h"

#include "sort_mbox.h"
#include "sort_rq.h"
#include "sort_shmem.h"


//! #define PAGE_SIZE 4096 // In bytes, needed for correct memory alignment


#define TO_WORDS(x) ((x)/4)
#define TO_BLOCKS(buffer_size_bytes, block_size_bytes) ((buffer_size_bytes)/(block_size_bytes))

// Thread Interfaces
#define TI_SHMEM  0
#define TI_MBOX   1
#define TI_RQUEUE 2

struct gengetopt_args_info args_info;
int running_threads;
int buffer_size = 0;



#ifdef SHADOWING
// Thread shadowing

shadowedthread_t sh[MAX_THREADS];
#else
// software threads
pthread_t swt[MAX_THREADS];
pthread_attr_t swt_attr[MAX_THREADS];

// hardware threads
struct reconos_hwt hwt[MAX_THREADS];
#endif

// pointers to buffers of unsorted numbers
unsigned int *data, *copy;


/**
 * @brief Versatile function for printing data arrays
 * @param _data		   pointer to data array
 * @param _data_size   is gives size of data array in bytes
 * @param _first_count determines how many bytes at start of data array will be printed
 * @param _last_count  determines how many bytes at end   of data array will be printed
 */
void print_data_first_last(unsigned int* _data, size_t _data_size,
		size_t _first_count, size_t _last_count) {
	int i;
	for (i = 0; i < _first_count; i++) {
		printf("%08X ", _data[i]);
		if ((i % 16) == 15)
			printf("\n");
	}
	if (_last_count > 0) {
		printf("[...]\n");
		for (i = TO_WORDS(_data_size) - _last_count; i < TO_WORDS(_data_size);
				i++) {
			printf("%08X ", _data[i]);
			if ((i % 16) == 15)
				printf("\n");
		}
	}
	if ((i % 16) != 15)
		printf("\n");
}

/*
 * @brief Prints statistics on the memory management unit in the hardware slots path to memory.
 */
void print_mmu_stats() {
	uint32 hits, misses, pgfaults;

	reconos_mmu_stats(&hits, &misses, &pgfaults);

	printf("MMU stats: TLB hits: %d    TLB misses: %d    page faults: %d\n",
			hits, misses, pgfaults);
}

/*
 * Signal handler for SIGSEGV. Used for debugging on a microblaze processor.
 * Get as much information to help in debugging as possible!
 */
void sigsegv_handler(int sig, siginfo_t *siginfo, void * context) {
//!	ucontext_t* uc = (ucontext_t*) context;

	// Yeah, i know using printf in a signal context is not save.
	// But with a SIGSEGV the programm is messed up anyway, so what?
//!	printf(
//!			"SIGSEGV: Programm killed at programm address %p, tried to access %p.\n",
#ifndef HOST_COMPILE
//!			(void*)uc->uc_mcontext.regs.pc,
#else
//!			(void*) uc->uc_mcontext.gregs[14],
#endif
//!			(void*) siginfo->si_addr);

	// Print address of unsorted numbers buffer
	printf("data: %8p \ncopy: %8p\n", data, copy);
#ifdef SHADOWING
	// Print OS call lists for debugging
	int i;
	for (i=0; i < running_threads; i++) {
		shadow_dump(sh + i);
	}
#endif
	exit(32);
}

//extern int pthread_attr_getstack(pthread_attr_t *attr, void **stackaddr, size_t *stacksize);
//extern int pthread_attr_getstack (__const pthread_attr_t *__restrict __attr,
//                                  void **__restrict __stackaddr,
//                                  size_t *__restrict __stacksize);

/**
 * @brief Used to limit the range of a variable: lower <= return value <= upper.
 */
int limit(int var, int lower, int upper) {
	if (var < lower) {
		var = lower;
	}
	if (var > upper) {
		var = upper;
	}
	return var;
}

void install_sighandlers(){
	// Install signal handler for segfaults
	struct sigaction act = { .sa_sigaction = sigsegv_handler, .sa_flags =
			SA_SIGINFO };
	sigaction(SIGSEGV, &act, NULL);

}

void handle_commandline(int argc, char** argv){
	//
	// Parse command line arguments
	//
	if (cmdline_parser(argc, argv, &args_info) != 0) {
		exit(1);
	}
	args_info.hwt_arg = limit(args_info.hwt_arg, 0, MAX_THREADS);
	args_info.swt_arg = limit(args_info.swt_arg, 0, MAX_THREADS);
	args_info.mt_arg = limit(args_info.mt_arg, 0, MAX_THREADS);
	buffer_size = args_info.blocks_arg * args_info.blocksize_arg;

#ifdef SHADOWING
	printf("sort_demo_shadowed build: %s %s\n", __DATE__, __TIME__);
#else
	printf("sort_demo build: %s %s\n", __DATE__, __TIME__);
#endif
	printf(
			"Parameters: hwt: %2i, swt: %2i, blocks: %5i, thread interface: %s, shadowing: %s, schedule: %i, transmodal: %i, main threads: %i, blocksize: %i\n",
			args_info.hwt_arg, args_info.swt_arg, TO_BLOCKS(buffer_size, args_info.blocksize_arg),
			(args_info.thread_interface_arg == TI_SHMEM ?
					"SHMEM" :
					(args_info.thread_interface_arg == TI_MBOX ?
							"MBOX" :
							(args_info.thread_interface_arg == TI_RQUEUE ?
									"RQUEUE" : "unknown"))),
			((args_info.shadow_flag + 1) == 1 ? "off" : "on"),
			args_info.shadow_schedule_arg, args_info.shadow_transmodal_flag,
			args_info.mt_arg, args_info.blocksize_arg);

	running_threads = args_info.hwt_arg + args_info.swt_arg + args_info.mt_arg;
	printf("Main thread is pthread %lu\n", (unsigned long)pthread_self());
}





#ifdef SHADOWING
void prepare_threads_shadowing(shadowedthread_t * sh, const char* worker_progname, void *(*actual_sort_thread)(void* data)){
	//
	// Configure Threads
	//
	printf("Configuring %i shadowed threads: ", args_info.hwt_arg+args_info.swt_arg);
	for (int i = 0; i < args_info.hwt_arg+args_info.swt_arg; i++) {
		shadow_init( sh+i );
		shadow_set_resources( sh+i, res[i], 2 );
		shadow_set_program( sh+i , worker_progname);
		/*
		 for (j=0; j< (args_info.shadow_flag+1); j++)
		 {
		 args_info.shadow_transmodal_flag
		 args_info.shadow_flag
		 shadow_set_hwslots(sh+i, j, actual_slot_map[(i*(args_info.shadow_flag+1))+j]);
		 }
		 */
		shadow_set_swthread( sh+i, actual_sort_thread );
		if(args_info.shadow_schedule_arg==0) {shadow_set_options(sh+i, TS_MANUAL_SCHEDULE);}
	}
}

void start_threads_shadowing_hw(shadowedthread_t * sh, const int * actual_slot_map){
	//
	// create hardware shadowed threads
	//
	reconos_init_autodetect();

	printf("Creating %i shadowed hw-threads: ", args_info.hwt_arg);
	fflush(stdout);
	for (int i = 0; i < args_info.hwt_arg; i++)
	{
		printf(" %i",i);fflush(stdout);
		shadow_set_threadcount(sh+i, (args_info.shadow_flag+1), 0);
		//if(args_info.shadow_transmodal_flag==1) {shadow_set_options(sh+i, TS_HW_LEADS);}
		for (int j=0; j< (args_info.shadow_flag+1); j++)
		{
			if ( j == 1 && args_info.shadow_transmodal_flag == 1) {
				shadow_set_hwslots(sh+i, j, workercpu_slots[(i*(args_info.shadow_flag+1))+j]);
				printf("Set thread %d.%d to slot %d\n", i,j, workercpu_slots[(i*(args_info.shadow_flag+1))+j]);
			} else {
				shadow_set_hwslots(sh+i, j, actual_slot_map[(i*(args_info.shadow_flag+1))+j]);
				printf("Set thread %d.%d to slot %d\n", i,j, actual_slot_map[(i*(args_info.shadow_flag+1))+j]);
			}
		}
		shadow_thread_create(sh+i);
	}
	printf("\n");
}

void start_threads_shadowing_sw(shadowedthread_t * sh, const int * actual_slot_map){
	//
	// create software shadowed threads
	//

	printf("Creating %i shadowed sw-threads: ",args_info.swt_arg);
	fflush(stdout);

	for (int i = args_info.hwt_arg; i < args_info.hwt_arg+args_info.swt_arg; i++)
	{
		printf(" %i",i-args_info.hwt_arg);fflush(stdout);
		shadow_set_threadcount(sh+i, (args_info.shadow_flag+1), 0);
		for (int j=0; j< (args_info.shadow_flag+1); j++)
		{
			if ( j == 1 && args_info.shadow_transmodal_flag == 1) {
				shadow_set_hwslots(sh+i, j, actual_slot_map[((i-args_info.hwt_arg)*(args_info.shadow_flag+1))+j]);
				printf("Set thread %d.%d to slot %d\n", i,j, actual_slot_map[((i-args_info.hwt_arg)*(args_info.shadow_flag+1))+j]);
			} else {
				shadow_set_hwslots(sh+i, j, workercpu_slots[((i-args_info.hwt_arg)*(args_info.shadow_flag+1))+j]);
				printf("Set thread %d.%d to slot %d\n", i,j, workercpu_slots[((i-args_info.hwt_arg)*(args_info.shadow_flag+1))+j]);
			}
		}
		/*		shadow_set_threadcount(sh+i, args_info.shadow_transmodal_flag, (args_info.shadow_flag+1)-args_info.shadow_transmodal_flag);
		 if(args_info.shadow_transmodal_flag==1) {shadow_set_options(sh+i, TS_SW_LEADS);}
		 */
		shadow_thread_create(sh+i);

	}
	printf("\n");
}
#endif //SHADOWING

void start_threads_hw(const char* worker_progname, const int * actual_slot_map){
	// init reconos and communication resources
	reconos_init_autodetect();

	printf("Creating %i hw-threads: ", args_info.hwt_arg);
	fflush(stdout);
	for (int i = 0; i < args_info.hwt_arg; i++)
	{
		printf(" %i",i);fflush(stdout);
		reconos_hwt_setresources(&(hwt[i]),res[i],2);
		reconos_hwt_setprogram( &(hwt[i]), worker_progname);
		reconos_hwt_create(&(hwt[i]), actual_slot_map[i], NULL);
	}
	printf("\n");
}

void start_threads_sw(const char* worker_progname, const int * actual_slot_map){
	// init software threads
	printf("Creating %i sw-threads: ", args_info.swt_arg);
	fflush(stdout);
	for (int i = args_info.hwt_arg; i < args_info.swt_arg + args_info.hwt_arg;
			i++) {
		printf(" %i", i);
		fflush(stdout);
		reconos_hwt_setresources(&(hwt[i]), res[i], 2);
		reconos_hwt_setprogram(&(hwt[i]), worker_progname);
		reconos_hwt_create(&(hwt[i]), workercpu_slots[i - args_info.hwt_arg],
				NULL);
	}
}

void start_threads_host(void *(*actual_sort_thread)(void* data)){
	printf("Creating %i main-threads: ", args_info.mt_arg);
	fflush(stdout);
	for (int i = args_info.hwt_arg+args_info.swt_arg; i < args_info.hwt_arg+args_info.swt_arg+args_info.mt_arg; i++) {
	 printf(" %i", i);
	 fflush(stdout);
	 pthread_attr_init(&swt_attr[i]);
	 pthread_create(&swt[i], &swt_attr[i], actual_sort_thread,
	 (void*) res[i]);
	 }

	printf("\n");
}

void setup_sort_data(){
	printf("malloc page aligned ...\n");
	data = xmalloc_aligned(buffer_size, PAGE_SIZE);
	copy = xmalloc_aligned(buffer_size, PAGE_SIZE);
	printf("generating %i words of data ...\n", TO_WORDS(buffer_size));
	generate_data(data, TO_WORDS(buffer_size));
	memcpy(copy, data, buffer_size);

	// print generated data
#if 0
	printf("\ndumping the first and last 128 words of data:\n");
	print_data_first_last(data, buffer_size, 128, 128);

	printf("\ndumping the first and last 128 words of copy:\n");
	print_data_first_last(copy, buffer_size, 128, 128);
#endif
}

void merge_sort_data(){
	printf("Merging sorted data slices...\n");
	unsigned int * temp = xmalloc_aligned(buffer_size, PAGE_SIZE);
	//printf("Data buffer at address %p \n", (void*)data);
	//printf("Address of temporary merge buffer: %p\n", (void*)temp);
	//printf("Total size of data in bytes: %i\n",buffer_size);
	//printf("Size of a sorting block in bytes: %i\n",args_info.blocksize_arg);
	if (temp == NULL) {
		printf("Buffer allocation failed. Exiting...\n");
		exit(2);
	}
	data = recursive_merge(data, temp, TO_WORDS(buffer_size),
			TO_WORDS(args_info.blocksize_arg), simple_merge);
}

void check_sort_data(){
	printf("Checking sorted data: ... ");
	fflush(stdout);
	int error_idx = check_data(data, copy, TO_WORDS(buffer_size));
	if (error_idx >= 0) {
		printf("failure at word index %i\n", error_idx);
		printf("expected 0x%08X    found 0x%08X\n", copy[error_idx],
				data[error_idx]);
		printf("\ndumping the first and last %i words of data:\n", 16); //TO_WORDS(buffer_size));
		print_data_first_last(data, buffer_size, 16, 16); //TO_WORDS(buffer_size)
		printf("\ndumping the first and last %i words of copy:\n", 16); //TO_WORDS(buffer_size));
		print_data_first_last(copy, buffer_size, 16, 16);
		exit(4);
	} else {
		printf("success\n");
	}

}

#if SHADOWING
void join_threads_shadowing(shadowedthread_t * sh){
	for (int i=0; i<running_threads; i++)
	{
		shadow_join(sh+i, NULL);
	}
	printf("\n");
}
#endif // Shadowing

void join_threads(){
	for (int i = 0; i < args_info.hwt_arg; i++) {
		pthread_join(hwt[i].delegate, NULL);
	}

	for (int i = 0; i < args_info.swt_arg; i++) {
		pthread_join(swt[i], NULL);
	}

/* @BUG: Join commands in non shadowed mode are mixed up!
	for (i = 0; i < args_info.mt_arg; i++) {
		pthread_join(swt[i], NULL);
	}
*/
}

/**
 * @bief Main function
 */
int main(int argc, char ** argv) {
	void *(*actual_sort_thread)(void* data) = NULL;
	const int * actual_slot_map = NULL;
	timing_t t_start = { };
	timing_t t_stop = { };
	timing_t t_generate = { };
	timing_t t_sort = { };
	timing_t t_merge = { };
	timing_t t_check = { };

	//
	// Setup program names for worker cpus
	//
	const char* worker_progname = "sort_demo_workercpu.bin";

	install_sighandlers();

	handle_commandline(argc, argv);

	switch (args_info.thread_interface_arg) {
	case TI_SHMEM:
		sort_shmem_setup_resources(&actual_sort_thread, &actual_slot_map, res);
		break;
	case TI_MBOX:
		sort_mbox_setup_resources(&actual_sort_thread, &actual_slot_map, res);
		break;
	case TI_RQUEUE:
		sort_rq_setup_resources(&actual_sort_thread, &actual_slot_map, res);
		break;
	}

#ifdef SHADOWING
	prepare_threads_shadowing(actual_sort_thread);

#ifndef HOST_COMPILE
	start_threads_shadowing_hw(sh, actual_slot_map);
#endif // HOST_COMPILE
	start_threads_shadowing_sw(sh, actual_slot_map);

#else // not SHADOWING

#ifndef HOST_COMPILE
	start_threads_hw(worker_progname, actual_slot_map);
#endif // HOST_COMPILE
	start_threads_sw(worker_progname, actual_slot_map);

	start_threads_host(actual_sort_thread);
#endif // SHADOWING


	// create pages and generate data
	t_start = gettime();
	setup_sort_data();
	t_stop = gettime();
	timerdiff(&t_stop, &t_start, &t_generate);

	// Start sort threads
	t_start = gettime();
	printf("Putting %i blocks into job queues: ", TO_BLOCKS(buffer_size, args_info.blocksize_arg));
	fflush(stdout);
	//
	// Transfer data to compute threads
	//
	switch (args_info.thread_interface_arg) {
	case TI_SHMEM:
		sort_shmem_put_data();
		break;
	case TI_MBOX:
		sort_mbox_put_data();
		break;
	case TI_RQUEUE:
		sort_rq_put_data();
		break;
	}
	printf("\n");
#ifndef HOST_COMPILE
	//
	// Install permanent error in first Message Based HW Sort Thread
	//
	if (args_info.error_count_arg) {
		// Lowest bit in data signals coming from  sorter will suffer a stuck-at-0 error
		//reconos_faultinject(1, 0x00000001, 0x00000000);

		// Disturb hwt state machine
		reconos_faultinject(0, 0x00000001, 0x00000000);
	}
#endif
	//
	// Wait for results
	//
	printf("Waiting for %i blocks of data: ", TO_BLOCKS(buffer_size, args_info.blocksize_arg));
	fflush(stdout);
	switch (args_info.thread_interface_arg) {
	case TI_SHMEM:
		sort_shmem_get_data();
		break;
	case TI_MBOX:
		sort_mbox_get_data();
		break;
	case TI_RQUEUE:
		sort_rq_get_data();
		break;
	}
	printf("\n");
	t_stop = gettime();
	timerdiff(&t_stop, &t_start, &t_sort);

	// merge data
	t_start = gettime();
	merge_sort_data();
	t_stop = gettime();
	timerdiff(&t_stop, &t_start, &t_merge);

	// check data
	//data[0] = 6666; // manual fault
	t_start = gettime();
	check_sort_data();
	t_stop = gettime();
	timerdiff(&t_stop, &t_start, &t_stop);

	// terminate all threads
	printf("Sending terminate message to %i threads:", running_threads);
	fflush(stdout);
	switch (args_info.thread_interface_arg) {
	case TI_SHMEM:
		sort_shmem_terminate();
		break;
	case TI_MBOX:
		sort_mbox_terminate();
		break;
	case TI_RQUEUE:
		sort_rq_terminate();
		break;
	}
	printf("\n");
	printf("Waiting for termination...\n");

#ifdef SHADOWING
	join_threads_shadowing(sh);

#else
	join_threads();
#endif

#ifndef HOST_COMPILE
	print_mmu_stats();
#endif

	printf("Running times (size: %d words, %d hw-threads, %d sw-threads):\n"
			"\tGenerate data: %lu ms\n"
			"\tSort data    : %lu ms\n"
			"\tMerge data   : %lu ms\n"
			"\tCheck data   : %lu ms\n"
			"Total computation time (sort & merge): %lu ms\n",
			TO_WORDS(buffer_size), args_info.hwt_arg, args_info.swt_arg,
			timer2ms(&t_generate), timer2ms(&t_sort), timer2ms(&t_merge),
			timer2ms(&t_check), timer2ms(&t_sort) + timer2ms(&t_merge));
#ifdef SHADOWING
	shadow_dump_timestats_all();
	shadow_dump_cyclestats_all();
#endif
	free(data);
	free(copy);

	//
	// Deactivate Fault Injection
	//
	if (args_info.error_count_arg) {
		reconos_faultinject(0, 0x00000000, 0x00000000);
		reconos_faultinject(1, 0x00000000, 0x00000000);
	}

	exit(0);
}

