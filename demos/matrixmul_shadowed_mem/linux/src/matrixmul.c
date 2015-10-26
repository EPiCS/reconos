/* matrixmul.c */
#define  _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>
#include <math.h>

#include <signal.h>
#include <sys/ucontext.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>


#include "reconos.h"
#include "mbox.h"
#include "cpuusage.h"

#ifdef SHADOWING
#include "thread_shadowing.h"
//#include "thread_shadowing_subs.h"
#endif

#include "mmp.h"
#include "common.h"
#include "logging.h"
#include "cmdline.h"
#include "matrixmul.h"

#define NUM_MAX_HWTS 14
#define NUM_MAX_SWTS 0
#define NUM_MAX_MTS 8

// Thread Interfaces
#define TI_SHMEM  0
#define TI_MBOX   1 // currently not implemented
#define TI_RQUEUE 2 // currently not implemented

// command line arguments
struct gengetopt_args_info args_info;

// Total number of compute threads running
int running_threads;

#ifdef SHADOWING
// Thread shadowing
#define MAX_THREADS  32
shadowedthread_t sh[MAX_THREADS];
unsigned int sh_free_idx=0;

#else // not SHADOWING



// main threads
pthread_t mt[NUM_MAX_MTS];
pthread_attr_t mt_attr[NUM_MAX_MTS];

// hardware threads
struct reconos_hwt hwt[NUM_MAX_HWTS];
#endif

// ReconOS resources are always needed
struct reconos_resource res[2];

char * actual_slot_map[] = {
		"SLOT_MATRIX", "SLOT_MATRIX",
		NULL};

// mailboxes
struct mbox mb_start;
struct mbox mb_stop;

void *matrixmul_thread(void *data) {
	struct reconos_resource *res  = (struct reconos_resource*) data;
	struct mbox *mb_start = res[0].ptr;
	struct mbox *mb_stop  = res[1].ptr;
	unsigned int ret;
	int **ret2;
	//printf("### Matrixmul Thread Start\n");
	while (1) {
		//printf("### Matrixmul Thread mbox_get(), mb_start: %p\n", mb_start);
		ret = mbox_get(mb_start);
		//printf("### Matrixmul Thread mbox_get() finished\n");
		if (ret == UINT_MAX) {
			pthread_exit((void *)0);
		}
		//printf("### Matrixmul Thread checked for exit value.\n");
		ret2 = (int **)ret;
		//printf("### Matrixmul Thread std_matrix_mul call\n");
		std_matrix_mul(ret2[0], ret2[1], ret2[2], STD_MMP_MATRIX_SIZE);
		//printf("### Matrixmul Thread std_matrix_mul finish\n");
		mbox_put(mb_stop, (int)ret2[2]);
	}
	return NULL;
}

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


/*
 * Signal handler for SIGSEGV. Used for debugging on a microblaze processor.
 * Get as much information to help in debugging as possible!
 */
void sigsegv_handler(int sig, siginfo_t *siginfo, void * context) {
	ucontext_t* uc = (ucontext_t*) context;

	// Yeah, i know using printf in a signal context is not save.
	// But with a SIGSEGV the programm is messed up anyway, so what?
	printf(
			"%s: Programm killed at programm address %p, tried to access %p.\n",
						(sig == SIGSEGV ? "SIGSEGV":(
						sig == SIGFPE  ? "SIGFPE": (
						sig == SIGILL  ? "SIGILL": "Unkown Signal"))),
#ifndef HOST_COMPILE
			(void*)uc->uc_mcontext.regs.pc,
#else
			(void*) uc->uc_mcontext.gregs[14],
#endif
			(void*) siginfo->si_addr);

#ifdef SHADOWING
	// Print OS call lists for debugging
	int i;
	for (i=0; i < running_threads; i++) {
		//shadow_dump(sh + i);
	}
#endif
	exit(sig);
}

/*
 * Install signal handler for segfaults, so that debug information can be printed
 * from the sigsegv_handler().
 */
void install_sighandlers(){
	struct sigaction act;
	act.sa_sigaction = sigsegv_handler;
	sigemptyset (&act.sa_mask);
	act.sa_flags = SA_SIGINFO;
	sigaction(SIGSEGV, &act, NULL);
	sigaction(SIGFPE, &act, NULL);
	sigaction(SIGILL, &act, NULL);
}

/**
 * @brief Parses the command line arguments and checks for errors and limits parameters.
 */
void handle_commandline(int argc, char** argv){
	//
	// Parse command line arguments
	//
	if (cmdline_parser(argc, argv, &args_info) != 0) {
		exit(1);
	}
	args_info.hwt_arg = limit(args_info.hwt_arg, 0, NUM_MAX_HWTS);
	args_info.swt_arg = limit(args_info.swt_arg, 0, NUM_MAX_SWTS);
	args_info.mt_arg = limit(args_info.mt_arg, 0, NUM_MAX_MTS);
	running_threads = args_info.hwt_arg + args_info.swt_arg + args_info.mt_arg;

	uint16_t arb_options = 0;
	if (args_info.shadow_arb_err_det_given || args_info.shadow_arb_buf_size_given || args_info.level_arg >2 )  {
		printf("Activating arbiter error detection...\n");
		arb_options = ARB_ERROR_DETECTION_ON | ((args_info.shadow_arb_buf_size_arg<<1) & ARB_SHADOW_BUFFER_MASK );
	}
#ifndef HOST_COMPILE
	reconos_set_arb_runtime_opts(arb_options);
#endif

#ifdef SHADOWING
	printf("matrixmul_shadowed build: %s %s\n", __DATE__, __TIME__);
#else
	printf("matrixmul build: %s %s\n", __DATE__, __TIME__);
#endif
	printf(
			"Parameters: hwt: %2i, swt: %2i, matrix size: %i, thread interface: %s, shadowing: %s, schedule: %i, transmodal: %i, main threads: %i,"
			"arb_error_det: %i, arb_buf_size: %i, level: %d\n",
			args_info.hwt_arg, args_info.swt_arg, args_info.matrix_size_arg,
			(args_info.thread_interface_arg == TI_SHMEM ?
					"SHMEM" :
					(args_info.thread_interface_arg == TI_MBOX ?
							"MBOX" :
							(args_info.thread_interface_arg == TI_RQUEUE ?
									"RQUEUE" : "unknown"))),
			((args_info.shadow_flag + 1) == 1 ? "off" : "on"),
			args_info.shadow_schedule_arg, args_info.shadow_transmodal_flag,
			args_info.mt_arg,
			args_info.shadow_arb_err_det_flag, args_info.shadow_arb_buf_size_arg, args_info.level_arg);
	printf("Reading matrice data from file: %s, writing matrice data to file: %s\n",
			args_info.read_matrices_given ? "yes" : "no", args_info.write_matrices_given ? "yes" : "no");
	printf("Main thread is pthread %lu\n", (unsigned long)pthread_self());
}


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
		shadow_init( sh+i );
		shadow_set_level(sh+i, args_info.level_arg);
		shadow_set_resources( sh+i, res+i*reconos_resource_count, reconos_resource_count );
		shadow_set_program( sh+i , worker_progname);
		shadow_set_swthread( sh+i, actual_sort_thread );
		if(args_info.shadow_schedule_arg==0) {shadow_set_options(sh+i, TS_MANUAL_SCHEDULE);}
	}
}

void start_threads_shadowing_hw(int hwt_count,
								shadowedthread_t * sh,
								unsigned int * sh_free_idx,
								char * const actual_slot_map[],
								char * hwt_type,
								int shadow_flag,
								int shadow_transmodal_flag)
{

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

	for (int i = 0; i < args_info.mt_arg; i++) {
		pthread_join(mt[i], NULL);
	}

/* @BUG: Join commands in non shadowed mode are mixed up!
	for (i = 0; i < args_info.mt_arg; i++) {
		pthread_join(swt[i], NULL);
	}
*/
}
#endif

int main(int argc, char **argv) {
	cpuusage_init();
	logging_init();

	int i;

	unsigned generate_data_time;
	unsigned generate_check_result_time;
	unsigned init_hwt_time;
	unsigned init_mt_time;
	unsigned str_mmp_split;
	unsigned std_mmp_time;
	unsigned str_mmp_combine;
	unsigned terminate_hwt_time;
	unsigned terminate_mt_time;
	unsigned comparision_time;
	unsigned calculation_time_std;
	unsigned calculation_time_str;

	install_sighandlers();
	handle_commandline(argc, argv);

	int hw_threads = args_info.hwt_arg;
	int sw_threads = args_info.swt_arg;
	int main_threads = args_info.mt_arg;

	int std_matrix_size	= STD_MMP_MATRIX_SIZE; // Fixed by hardware thread
	int str_matrix_size = args_info.matrix_size_arg; //STR_MMP_INPUT_MATRIX_SIZE;

	int mbox_size = (int) pow(7, ((int)log2(args_info.matrix_size_arg)) - ((int)log2(STD_MMP_MATRIX_SIZE)));
	printf("Size of mailboxes: %i\n", mbox_size);
	printf("Address of mb_start: %p\n", &mb_start);

	int *i_matrixes[2]	= {NULL, NULL};
	int *o_matrix		= NULL;
	int *compare		= NULL;

	MATRIXES* std_mmp_matrixes = NULL;

	mbox_init(&mb_start, mbox_size);
	mbox_init(&mb_stop,  mbox_size);

#ifndef HOST_COMPILE
	printf("Initializing reconos...\n");
	reconos_init_autodetect();
#endif

	res[0].type = RECONOS_TYPE_MBOX;
	res[0].ptr  = &mb_start;
	res[1].type = RECONOS_TYPE_MBOX;
	res[1].ptr  = &mb_stop;

	// If command line argument given, read matrices from file

	// generate or read in data and result matrix
	if (args_info.read_matrices_given){
		generate_data_time = 0;
		generate_check_result_time = 0;

		INFO("Reading in input data.\n");
		read_data(i_matrixes, &o_matrix, str_matrix_size);
		INFO("Reading in check results.\n");
		read_result(&compare, str_matrix_size);
	} else {
		INFO("Generating input data.\n");
		generate_data_time = time_ms();
		generate_data(i_matrixes, &o_matrix, str_matrix_size);
		generate_data_time = time_ms() - generate_data_time;

		INFO("Generating check results.\n");
		generate_check_result_time = time_ms();
		generate_result(i_matrixes, &compare, str_matrix_size);
		generate_check_result_time = time_ms() - generate_check_result_time;
	}
	if (args_info.write_matrices_given){
		INFO("Writing out input data.\n");
		write_data(i_matrixes, &o_matrix, str_matrix_size);
		INFO("Writing out check results.\n");
		write_result(&compare, str_matrix_size);
	}
#ifdef SHADOWING

	prepare_threads_shadowing(args_info.hwt_arg + args_info.swt_arg + args_info.mt_arg,
								res,
								2,
								sh,
								"SLOT_MATRIX",
								matrixmul_thread);
	init_hwt_time = time_ms();
#ifndef HOST_COMPILE
	start_threads_shadowing_hw(args_info.hwt_arg,
								sh,
								&sh_free_idx,
								actual_slot_map,
								"SLOT_MATRIX",
								args_info.shadow_flag,
								args_info.shadow_transmodal_flag);
	init_hwt_time = time_ms() - init_hwt_time;
#endif // HOST_COMPILE
	init_mt_time = time_ms();
	start_threads_shadowing_host(args_info.mt_arg,
									sh,
									&sh_free_idx,
									actual_slot_map,
									"SLOT_MATRIX",
									args_info.shadow_flag,
									args_info.shadow_transmodal_flag);
	init_mt_time = time_ms() - init_mt_time;
#else // not SHADOWING

	init_hwt_time = time_ms();
#ifndef HOST_COMPILE
	// init hw-threads
	INFO("Creating %i hw-thread(s).\n", hw_threads);

	start_threads_hw(args_info.hwt_arg,
						res,
						2,
						hwt,
						"SLOT_MATRIX",
						actual_slot_map);
#endif
	init_hwt_time = time_ms() - init_hwt_time;

	// init sw-threads
	INFO("Creating %i main threads.\n", main_threads);
	init_mt_time = time_ms();
	start_threads_host(args_info.mt_arg,
						res,
						2,
						mt,
						mt_attr,
						matrixmul_thread);
	init_mt_time = time_ms() - init_mt_time;


#endif

#ifndef HOST_COMPILE
	// fault injection has to be here, because we need to first call reconos_init() ...
	printf(" Activating fault injection: %x\n", 0); //args_info.error_type_arg);
	//reconos_faultinject(0,args_info.error_type_arg,args_info.error_type_arg); // set  error injection
	reconos_faultinject(0,0,0); // set  error injection
#endif

	// split input matrixes recursively (strassen algorithm part 1)
	INFO("Running Strassen algorithm part 1 - split.\n");
	str_mmp_split = time_ms();
	str_matrix_split(i_matrixes[0], i_matrixes[1], &std_mmp_matrixes, str_matrix_size);
	str_mmp_split = time_ms() - str_mmp_split;

	// calculate matrixes with standard mmp algorithm (in hw and/or sw)
	INFO("Putting matrix pointers in mbox.\n");
	std_mmp_time = time_ms();
	MATRIXES *ptr = std_mmp_matrixes;

	//print_matrix(i_matrixes[0], 'a', str_matrix_size);
	//print_matrix(i_matrixes[1], 'b', str_matrix_size);
	//print_matrixes(&std_mmp_matrixes, STD_MMP_MATRIX_SIZE);


	for (i=0; i<mbox_size; ++i) {
		printf("Putting pointer to matrixes into mbox: %p, %p, %p\n", ptr->matrixes[0],ptr->matrixes[1],ptr->matrixes[2]);
		mbox_put(&mb_start,(unsigned int)(ptr->matrixes));
		ptr = ptr->next;
	}
	INFO("Waiting for acknowledgements...\n");
	for (i=0; i<mbox_size; ++i) {
		printf("Getting pointer to matrixes from mbox: %p\n", (void*)mbox_get(&mb_stop));
	}
	std_mmp_time = time_ms() - std_mmp_time;
	INFO("Got acknowledgments.\n");

	// terminate threads
	INFO("Sending terminate message to %i thread(s).\n", hw_threads + sw_threads + main_threads);
	terminate_hwt_time = time_ms();
	terminate_mt_time = terminate_hwt_time;
	for (i = 0; i < hw_threads + sw_threads + main_threads; i++) {
		INFO("Putting a stop message into MBOX...\n");
		mbox_put(&mb_start,UINT_MAX);
	}


#ifdef SHADOWING
	INFO("Joining all shadowed threads...\n");
	join_threads_shadowing(sh);
#else
	INFO("Joining all threads...\n");
	join_threads();
#endif
	// well, this will now measure termination time of all threads....
	terminate_hwt_time = time_ms() - terminate_hwt_time;
	terminate_mt_time = time_ms() - terminate_mt_time;

	INFO("Threads have been terminated.\n");

	//print_matrixes(&std_mmp_matrixes, STD_MMP_MATRIX_SIZE);

	// combine results (strassen algorithm part 2)
	INFO("Running Strassen algorithm part 2 - combine.\n");
	str_mmp_combine = time_ms();
	o_matrix = str_matrix_combine(&std_mmp_matrixes, std_matrix_size, str_matrix_size);
	str_mmp_combine = time_ms() - str_mmp_combine;

	// check, if results are correct
	comparision_time = time_ms();
	int correct_result =  compare_result(o_matrix, compare, str_matrix_size);
	comparision_time = time_ms() - comparision_time;


	//print_matrix(i_matrixes[0], 'A', str_matrix_size);
	//print_matrix(i_matrixes[1], 'B', str_matrix_size);
	//print_matrix(o_matrix    , 'C', str_matrix_size);
	//print_matrix(compare          , 'Z', str_matrix_size);
	if (correct_result == -1) {
		INFO("\nResult is correct.\n\n");
	} else {
		INFO("\nBad result.\n");
		printf("Comparison failed at index %i.Correct: %i, Actual result: %i.\n", correct_result, compare[correct_result], o_matrix[correct_result] );
#if 0
		print_matrix(i_matrixes[0], 'A', str_matrix_size);
		print_matrix(i_matrixes[1], 'B', str_matrix_size);
		print_matrix(o_matrix    , 'C', str_matrix_size);
		print_matrix(compare          , 'Z', str_matrix_size);
#endif
		INFO("\n");
	}

	calculation_time_std = generate_check_result_time;
	calculation_time_str = init_hwt_time + init_mt_time + str_mmp_split + std_mmp_time + terminate_mt_time + str_mmp_combine;

	INFO("Timing information\n");
	INFO("==================\n");
	INFO("Generate input data:   %u ms\n", generate_data_time);
	INFO("Generate check result: %u ms\n", generate_check_result_time);
	INFO("Initializing HWT:      %u ms\n", init_hwt_time);
	INFO("Initializing MT:       %u ms\n", init_mt_time);
	INFO("Str. split (part 1):   %u ms\n", str_mmp_split);
	INFO("Std. MMP:              %u ms\n", std_mmp_time);
	INFO("Str. combine (part 2): %u ms\n", str_mmp_combine);
	INFO("~Thread term. HWT:     %u ms\n", terminate_hwt_time);
	INFO("~Thread term. MT:      %u ms\n", terminate_mt_time);
	INFO("Check HWT result:      %u ms\n\n", comparision_time);
	INFO("Important timing results\n");
	INFO("========================\n");
	INFO("Runtime Std. MMP:      %u ms\n", calculation_time_std);
	INFO("Runtime Str. MMP:      %u ms\n", calculation_time_str);

#ifdef SHADOWING
	shadow_dump_timestats_all();
	shadow_dump_cyclestats_all();
	shadow_dump_func_stats();
#endif
	printf("CPU usage average: %f\n", cpuusage_average());
	return 0;
}
