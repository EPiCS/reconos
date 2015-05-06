#define  _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
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

#include "parallel_sort_interface.h"
#include "sort_mbox.h"
#include "sort_rq.h"
#include "sort_shmem.h"


// Thread Interfaces
#define TI_SHMEM  0
#define TI_MBOX   1
#define TI_RQUEUE 2

struct gengetopt_args_info args_info;
int running_threads;
int buffer_size = 0;

#if 0
char * actual_slot_map[] = {
		"SLOT_SORT_SHMEM", "SLOT_SORT_SHMEM", "SLOT_SORT_SHMEM", "SLOT_SORT_SHMEM",
		"SLOT_SORT_SHMEM", "SLOT_SORT_SHMEM", "SLOT_SORT_SHMEM", "SLOT_SORT_SHMEM",
		"SLOT_SORT_SHMEM", "SLOT_SORT_SHMEM", "SLOT_SORT_SHMEM", "SLOT_SORT_SHMEM",
		"SLOT_SORT_SHMEM", "SLOT_SORT_SHMEM",
		NULL};
char * actual_slot_map[] = {
		"SLOT_WORKERCPU", "SLOT_WORKERCPU", "SLOT_WORKERCPU", "SLOT_WORKERCPU",
		"SLOT_WORKERCPU", "SLOT_WORKERCPU", "SLOT_WORKERCPU",
		"SLOT_SORT_RQ", "SLOT_SORT_RQ", "SLOT_SORT_RQ", "SLOT_SORT_RQ",
		"SLOT_SORT_RQ", "SLOT_SORT_RQ", "SLOT_SORT_RQ",
		NULL};

char * actual_slot_map[] = {
		"SLOT_SORT_RQ", "SLOT_SORT_RQ", "SLOT_SORT_RQ", "SLOT_SORT_RQ",
		"SLOT_SORT_RQ", "SLOT_SORT_RQ", "SLOT_SORT_RQ",
		"SLOT_SORT_RQ", "SLOT_SORT_RQ", "SLOT_SORT_RQ", "SLOT_SORT_RQ",
		"SLOT_SORT_RQ", "SLOT_SORT_RQ", "SLOT_SORT_RQ",
		NULL};
#endif

char * actual_slot_map[] = {
		"SLOT_SORT_SHMEM", "SLOT_SORT_SHMEM",
		NULL};

#ifdef SHADOWING
// Thread shadowing
shadowedthread_t sh[MAX_THREADS];
unsigned int sh_free_idx=0;
#else
// software threads
pthread_t swt[MAX_THREADS];
pthread_attr_t swt_attr[MAX_THREADS];

// hardware threads
struct reconos_hwt hwt[MAX_THREADS];

// workercpu threads
struct reconos_hwt hwt_worker[MAX_THREADS];
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
/*
data
copy
running_threads
sh
 */
void sigsegv_handler(int sig, siginfo_t *siginfo, void * context) {
	ucontext_t* uc = (ucontext_t*) context;

	// Yeah, i know using printf in a signal context is not save.
	// But with a SIGSEGV the programm is messed up anyway, so what?
	printf(
			"SIGSEGV: Programm killed at programm address %p, tried to access %p.\n",
#ifndef HOST_COMPILE
			(void*)uc->uc_mcontext.regs.pc,
#else
			(void*) uc->uc_mcontext.gregs[14],
#endif
			(void*) siginfo->si_addr);

	// Print address of unsorted numbers buffer
	printf("data: %8p \ncopy: %8p\n", data, copy);
#ifdef SHADOWING
	// Print OS call lists for debugging
	int i;
	for (i=0; i < running_threads; i++) {
		shadow_dump(sh + i);
	}
#endif
	exit(EXIT_SEGFAULT);
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

// nth starts with 0!
int slot_map_find(char * const  map[], const char * hwt_type, int nth){
	int found_at_index=-1;
	for (int i = 0; map[i] != NULL ; i++){
		if (strcmp(map[i],hwt_type) == 0){nth--;}
		if (nth == -1){found_at_index = i; break;}
	}
	return found_at_index;
}

void slot_map_print(char * const  map[]){
	printf("Slot Map:");
	for (int i = 0; map[i] != NULL ; i++){
		printf(" %s", map[i]);
	}
	printf("\n");
}

void install_sighandlers(){
	// Install signal handler for segfaults
	struct sigaction act;
	act.sa_sigaction = sigsegv_handler;
	sigemptyset (&act.sa_mask);
	act.sa_flags = SA_SIGINFO;
	sigaction(SIGSEGV, &act, NULL);
	sigaction(SIGFPE, &act, NULL);
}

/**
 * @brief Parses the command line arguments and checks for errors and limits parameters.
 */
void handle_commandline(int argc, char** argv){
	//
	// Parse command line arguments
	//
	if (cmdline_parser(argc, argv, &args_info) != 0) {
		exit(EXIT_CMD_LINE_PARSE);
	}
	args_info.hwt_arg = limit(args_info.hwt_arg, 0, MAX_THREADS);
	args_info.swt_arg = limit(args_info.swt_arg, 0, MAX_THREADS);
	args_info.mt_arg = limit(args_info.mt_arg, 0, MAX_THREADS);
	buffer_size = args_info.blocks_arg * args_info.blocksize_arg;
	running_threads = args_info.hwt_arg + args_info.swt_arg + args_info.mt_arg;

	uint16_t arb_options = 0;
	if (args_info.shadow_arb_err_det_given || args_info.shadow_arb_buf_size_given)  {
		arb_options = ARB_ERROR_DETECTION_ON | ((args_info.shadow_arb_buf_size_arg<<1) & ARB_SHADOW_BUFFER_MASK );
	}
	reconos_set_arb_runtime_opts(arb_options);

#ifdef SHADOWING
	printf("sort_demo_shadowed build: %s %s\n", __DATE__, __TIME__);
#else
	printf("sort_demo build: %s %s\n", __DATE__, __TIME__);
#endif
	printf(
			"Parameters: hwt: %2i, swt: %2i, blocks: %5i, thread interface: %s, shadowing: %s, schedule: %i, transmodal: %i, main threads: %i, blocksize: %i,"
			"arb_error_det: %i, arb_buf_size: %i\n",
			args_info.hwt_arg, args_info.swt_arg, TO_BLOCKS(buffer_size, args_info.blocksize_arg),
			(args_info.thread_interface_arg == TI_SHMEM ?
					"SHMEM" :
					(args_info.thread_interface_arg == TI_MBOX ?
							"MBOX" :
							(args_info.thread_interface_arg == TI_RQUEUE ?
									"RQUEUE" : "unknown"))),
			((args_info.shadow_flag + 1) == 1 ? "off" : "on"),
			args_info.shadow_schedule_arg, args_info.shadow_transmodal_flag,
			args_info.mt_arg, args_info.blocksize_arg,
			args_info.shadow_arb_err_det_flag, args_info.shadow_arb_buf_size_arg);

	printf("Main thread is pthread %lu\n", (unsigned long)pthread_self());
}


struct parallel_sort_interface choose_implementation (int interface){
	struct parallel_sort_interface pint;
	switch (interface){
		case TI_SHMEM:
			pint = sort_shmem_interface;
			break;
		case TI_MBOX:
			pint = sort_mbox_interface;
			break;
		case TI_RQUEUE:
			pint = sort_rq_interface;
			break;
	}
	return pint;
}

//#define SHADOWING 1
#ifdef SHADOWING
/*
args_info.hwt_arg
args_info.swt_arg
args_info.shadow_schedule_arg
sh
res
worker_progname
actual_sort_thread
*/
void prepare_threads_shadowing(int thread_count,
								struct reconos_resource * res,
								int reconos_resource_count,
								shadowedthread_t * sh,
								const char* worker_progname,
								void *(*actual_sort_thread)(void* data))
{
	//
	// Configure Threads
	//
	printf("Configuring %i shadowed threads: ", thread_count);
	for (int i = 0; i < thread_count; i++) {
		printf(" %i",i);fflush(stdout);
		shadow_init( sh+i );
		shadow_set_resources( sh+i, res+i*reconos_resource_count, reconos_resource_count );
		shadow_set_program( sh+i , worker_progname);
		shadow_set_swthread( sh+i, actual_sort_thread );
		if(args_info.shadow_schedule_arg==0) {shadow_set_options(sh+i, TS_MANUAL_SCHEDULE);}
	}
	printf("\n");
}

void start_threads_shadowing_hw(int hwt_count,
								shadowedthread_t * sh,
								unsigned int * sh_free_idx,
								char * const actual_slot_map[],
								char * hwt_type,
								int shadow_flag,
								int shadow_transmodal_flag)
{
	reconos_init_autodetect();

	printf("Creating %i shadowed hw-threads: ", hwt_count);
	fflush(stdout);
	for (int i = *sh_free_idx; i < hwt_count+*sh_free_idx; i++)
	{
		printf(" %i",i);fflush(stdout);
		shadow_set_threadcount(sh+i, (shadow_flag+1), 0);
		for (int j=0; j< (shadow_flag+1); j++)
		{
			int slot_number;
			char * hardware;
			if ( j == 1 && shadow_transmodal_flag == 1) {
				hardware = "SLOT_WORKERCPU";
			} else {
				hardware = hwt_type;
			}
			slot_number = slot_map_find(actual_slot_map, hardware , (i*(shadow_flag+1))+j);
			if(slot_number == -1){printf("Warning: Requested HWT Type not found: %s\n", hardware);}
			shadow_set_hwslots(sh+i, j, slot_number);
			printf("Set thread %d.%d to slot %d\n", i,j, slot_number);
		}
		shadow_thread_create(sh+i);
	}
	*sh_free_idx += hwt_count;
	printf("\n");
}

void start_threads_shadowing_sw(int swt_count,
								shadowedthread_t * sh,
								unsigned int * sh_free_idx,
								char * const actual_slot_map[],
								char * hwt_type,
								int shadow_flag,
								int shadow_transmodal_flag)
{
	printf("Creating %i shadowed sw-threads: ",swt_count);
	fflush(stdout);

	for (int i = *sh_free_idx; i < *sh_free_idx+swt_count; i++)
	{
		printf(" %i",i-*sh_free_idx);fflush(stdout);
		shadow_set_threadcount(sh+i, (shadow_flag+1), 0);
		for (int j=0; j< (shadow_flag+1); j++)
		{
			int slot_number;
			char * hardware;
			if ( j == 1 && shadow_transmodal_flag == 1) {
				hardware = hwt_type;
			} else {
				hardware = "SLOT_WORKERCPU";
			}
			slot_number = slot_map_find(actual_slot_map, hardware , ((i-*sh_free_idx)*(shadow_flag+1))+j);
			if(slot_number == -1){printf("Warning: Requested HWT Type not found: %s\n", hardware);}
			shadow_set_hwslots(sh+i, j, slot_number);
			printf("Set thread %d.%d to slot %d\n", i,j, slot_number);
		}
		shadow_thread_create(sh+i);

	}
	*sh_free_idx += swt_count;
	printf("\n");
}

void start_threads_shadowing_host(int mt_count,
								shadowedthread_t * sh,
								unsigned int * sh_free_idx,
								char * const actual_slot_map[],
								char * hwt_type,
								int shadow_flag,
								int shadow_transmodal_flag)
{
	printf("Creating %i shadowed host-threads: ",mt_count);
	fflush(stdout);

	for (int i = *sh_free_idx; i < *sh_free_idx+mt_count; i++)
	{
		printf(" %i",i-*sh_free_idx);fflush(stdout);
		shadow_set_threadcount(sh+i,  0, (shadow_flag+1));
		for (int j=0; j< (shadow_flag+1); j++)
		{
			int slot_number;
			char * hardware;
			if ( j == 1 && shadow_transmodal_flag == 1) {
				hardware = hwt_type;
			} else {
				hardware = "SLOT_WORKERCPU";
			}
			slot_number = slot_map_find(actual_slot_map, hardware , ((i-*sh_free_idx)*(shadow_flag+1))+j);
			if(slot_number == -1){printf("Warning: Requested HWT Type not found: %s\n", hardware);}
			shadow_set_hwslots(sh+i, j, slot_number);
			printf("Set thread %d.%d to slot %d\n", i,j, slot_number);
		}
		shadow_thread_create(sh+i);

	}
	*sh_free_idx += mt_count;
	printf("\n");
}

#endif //SHADOWING

/*
args_info.hwt_arg
res
hwt
worker_progname
actual_slot_map
 */
void start_threads_hw(int hwt_count,
						struct reconos_resource * res,
						int reconos_resource_count,
						struct reconos_hwt * hwt,
						char * hwt_type,
						char * const actual_slot_map[])
{
	// init reconos and communication resources
	reconos_init_autodetect();

	printf("Creating %i hw-threads: ", hwt_count);
	fflush(stdout);
	for (int i = 0; i < hwt_count; i++)
	{
		printf(" %i",i);fflush(stdout);
		reconos_hwt_setresources(&(hwt[i]),res+i*reconos_resource_count, reconos_resource_count);
		int slot_number = slot_map_find(actual_slot_map, hwt_type, i);
		if(slot_number == -1){
			printf("Warning: Requested HWT Type not found: %s\n", hwt_type);
			slot_map_print(actual_slot_map);
		}
		reconos_hwt_create(&(hwt[i]),
				slot_number,
				NULL);
	}
	printf("\n");
}

/*
args_info.swt_arg
res
hwt
worker_progname
workercpu_slots
 */
void start_threads_sw(int swt_count,
						struct reconos_resource * res,
						int reconos_resource_count,
						struct reconos_hwt * hwt_worker,
						const char* worker_progname,
						char * const actual_slot_map[])
{
	// init software threads
	printf("Creating %i sw-threads: ", swt_count);
	fflush(stdout);
	for (int i = 0; i < swt_count;i++) {
		printf(" %i", i);
		fflush(stdout);
		reconos_hwt_setresources(&(hwt_worker[i]), res+i*reconos_resource_count, reconos_resource_count);
		reconos_hwt_setprogram(&(hwt_worker[i]), worker_progname);
		int slot_number = slot_map_find(actual_slot_map, "SLOT_WORKERCPU", i);
		if(slot_number == -1){printf("Warning: Requested HWT Type not found: %s\n", "SLOT_WORKERCPU");}
		reconos_hwt_create(&(hwt_worker[i]),
				slot_number,
				NULL);
	}
}

void start_threads_host(int mt_count,
						struct reconos_resource * res,
						int reconos_resource_count,
						pthread_t * swt,
						pthread_attr_t * swt_attr,
						void *(*actual_sort_thread)(void* data))
{
	printf("Creating %i main-threads: ", mt_count);
	fflush(stdout);
	for (int i = 0; i < mt_count; i++) {
	 printf(" %i", i);
	 fflush(stdout);
	 pthread_attr_init(&swt_attr[i]);
	 pthread_create(&swt[i], &swt_attr[i], actual_sort_thread,(void*) (res+i*reconos_resource_count));
	 }
	printf("\n");
}

void setup_sort_data(unsigned int ** data, unsigned int ** copy, int buffer_size){
	printf("malloc page aligned ...\n");
	*data = xmalloc_aligned(buffer_size, PAGE_SIZE);
	*copy = xmalloc_aligned(buffer_size, PAGE_SIZE);
	printf("generating %i words of data ...\n", TO_WORDS(buffer_size));
	generate_data(*data, TO_WORDS(buffer_size));
	memcpy(*copy, *data, buffer_size);

	// print generated data
#if 0
	printf("\ndumping the first and last 128 words of data:\n");
	print_data_first_last(*data, buffer_size, 128, 128);

	printf("\ndumping the first and last 128 words of copy:\n");
	print_data_first_last(*copy, buffer_size, 128, 128);
#endif
}

unsigned int * merge_sort_data(unsigned int * data, int buffer_size, int blocksize){
	printf("Merging sorted data slices...\n");
	unsigned int * merged_buffer;
	unsigned int * scratchpad_buffer = xmalloc_aligned(buffer_size, PAGE_SIZE);
	//printf("Data buffer at address %p \n", (void*)data);
	//printf("Address of temporary merge buffer: %p\n", (void*)temp);
	//printf("Total size of data in bytes: %i\n",buffer_size);
	//printf("Size of a sorting block in bytes: %i\n",args_info.blocksize_arg);
	if (scratchpad_buffer == NULL) {
		printf("Buffer allocation failed. Exiting...\n");
		exit(EXIT_MALLOC);
	}
	merged_buffer = recursive_merge(data, scratchpad_buffer, TO_WORDS(buffer_size),
			TO_WORDS(blocksize), simple_merge);

	if (merged_buffer == data				){free(scratchpad_buffer);}
	if (merged_buffer == scratchpad_buffer	){free(data);}
	return merged_buffer;
}

void check_sort_data(unsigned int * data, unsigned int * copy, int buffer_size){
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
		exit(EXIT_FAULTY_RESULT);
	} else {
		printf("success\n");
	}
}

#if SHADOWING
/*
running_threads
 */
void join_threads_shadowing(shadowedthread_t * sh){
	for (int i=0; i<running_threads; i++)
	{
		shadow_join(sh+i, NULL);
	}
	printf("\n");
}
#else

/*
args_info.hwt_arg
args_info.swt_arg
args_info.mt_arg
hwt[i].delegate
swt
 */
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
#endif

/**
 * @brief Main function
 */
int main(int argc, char ** argv) {
	struct parallel_sort_params_in pin;
	struct parallel_sort_params_out pout;
	struct parallel_sort_interface pinterface;

	INIT_THE_CLOCK()
	install_sighandlers();
	handle_commandline(argc, argv);
	STOP_THE_CLOCK(t_generate,
		setup_sort_data(&data, &copy, buffer_size);
	)

	pin.actual_slot_map = actual_slot_map;
	pin.data = data;
	pin.block_size_bytes = args_info.blocksize_arg;
	pin.data_size_bytes = buffer_size;
	pin.thread_count = args_info.hwt_arg + args_info.swt_arg + args_info.mt_arg;

	pinterface = choose_implementation(args_info.thread_interface_arg);
	pinterface.setup_resources(&pin, &pout);

#ifdef SHADOWING
	prepare_threads_shadowing(pin.thread_count,
								pout.res,
								pout.reconos_resources_count,
								sh,
								pout.sort_program_worker,
								pout.sort_thread_main);
#ifndef HOST_COMPILE
	// Calls reconos_init()!
	start_threads_shadowing_hw(args_info.hwt_arg,
								sh,
								&sh_free_idx,
								actual_slot_map,
								pout.sort_program_hwt,
								args_info.shadow_flag,
								args_info.shadow_transmodal_flag);

	start_threads_shadowing_sw(args_info.swt_arg,
								sh,
								&sh_free_idx,
								actual_slot_map,
								pout.sort_program_hwt,
								args_info.shadow_flag,
								args_info.shadow_transmodal_flag);
#endif // HOST_COMPILE
	start_threads_shadowing_host(args_info.mt_arg,
									sh,
									&sh_free_idx,
									actual_slot_map,
									pout.sort_program_hwt,
									args_info.shadow_flag,
									args_info.shadow_transmodal_flag);
#else // not SHADOWING

#ifndef HOST_COMPILE
	start_threads_hw(args_info.hwt_arg,
						pout.res,
						pout.reconos_resources_count,
						hwt,
						pout.sort_program_hwt,
						actual_slot_map);

	start_threads_sw(args_info.swt_arg,
						pout.res,
						pout.reconos_resources_count,
						hwt_worker,
						pout.sort_program_worker,
						actual_slot_map);
#endif // HOST_COMPILE
	start_threads_host(args_info.mt_arg,
						pout.res,
						pout.reconos_resources_count,
						swt,
						swt_attr,
						pout.sort_thread_main);
#endif // SHADOWING

#ifndef HOST_COMPILE
	// fault injection has to be here, because we need to first call reconos_init() ...
	printf(" Activating fault injection: %x\n", args_info.error_type_arg);
	reconos_faultinject(0,args_info.error_type_arg,args_info.error_type_arg); // set  error injection
#endif


	//
	// Transfer data to compute threads
	//
	STOP_THE_CLOCK(t_sort,
				printf("Putting %i blocks into job queues...\n", TO_BLOCKS(buffer_size, args_info.blocksize_arg));
				pinterface.put_data(&pin);

#ifndef HOST_COMPILE
	// fault injection has to be here, because we need to first call reconos_init() ...
if (args_info.error_type_arg == 2){
	printf(" Activating fault injection: %x\n", args_info.error_type_arg);
	reconos_faultinject(0,0,0); // set  error injection
	reconos_faultinject(0,args_info.error_type_arg,args_info.error_type_arg); // set  error injection
}
#endif

				printf("Waiting for %i blocks of data...\n", TO_BLOCKS(buffer_size, args_info.blocksize_arg));
				pinterface.get_data(&pin);
	)

	STOP_THE_CLOCK(t_merge,
		data = merge_sort_data(data, buffer_size, args_info.blocksize_arg);
	)

	STOP_THE_CLOCK(t_check,
		check_sort_data(data, copy, buffer_size);
	)

	// terminate all threads
	printf("Sending terminate message to %i threads:", running_threads);
	fflush(stdout);
	pinterface.terminate(&pin);
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

	pinterface.teardown_resources(&pin, &pout);

	reconos_faultinject(0,0,0); // deactivate all errors on exit
	exit(EXIT_SUCCESS);
}

