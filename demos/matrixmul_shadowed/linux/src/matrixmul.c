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
#include "mmp.h"
#include "common.h"
#include "logging.h"
#include "cmdline.h"


#define NUM_MAX_HWTS 14
#define NUM_MAX_SWTS 0
#define NUM_MAX_MTS 1

// Thread Interfaces
#define TI_SHMEM  0
#define TI_MBOX   1 // currently not implemented
#define TI_RQUEUE 2 // currently not implemented

// command line arguments
struct gengetopt_args_info args_info;

// Total number of compute threads running
int running_threads;

// software threads
pthread_t swt[NUM_MAX_SWTS];
pthread_attr_t swt_attr[NUM_MAX_SWTS];

// hardware threads
struct reconos_resource res[2];
struct reconos_hwt hwt[NUM_MAX_HWTS];

// mailboxes
struct mbox mb_start;
struct mbox mb_stop;

void *matrixmul_thread(void *data) {
	struct reconos_resource *res  = (struct reconos_resource*) data;
	struct mbox *mb_start = res[0].ptr;
	struct mbox *mb_stop  = res[1].ptr;
	unsigned int ret;
	int **ret2;

	while (1) {
		ret = mbox_get(mb_start);
		if (ret == UINT_MAX) {
			pthread_exit((void *)0);
		}

		ret2 = (int **)ret;

		std_matrix_mul(ret2[0], ret2[1], ret2[2], STD_MMP_MATRIX_SIZE);

		mbox_put(mb_stop, 23);
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

/*
 * Signal handler for SIGSEGV. Used for debugging on a microblaze processor.
 * Get as much information to help in debugging as possible!
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

#ifdef SHADOWING
	// Print OS call lists for debugging
	int i;
	for (i=0; i < running_threads; i++) {
		//shadow_dump(sh + i);
	}
#endif
	exit(32);
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

#ifdef SHADOWING
	printf("matrixmul_shadowed build: %s %s\n", __DATE__, __TIME__);
#else
	printf("matrixmul build: %s %s\n", __DATE__, __TIME__);
#endif
	printf(
			"Parameters: hwt: %2i, swt: %2i, matrix size: %i, thread interface: %s, shadowing: %s, schedule: %i, transmodal: %i, main threads: %i\n",
			args_info.hwt_arg, args_info.swt_arg, args_info.matrix_size_arg,
			(args_info.thread_interface_arg == TI_SHMEM ?
					"SHMEM" :
					(args_info.thread_interface_arg == TI_MBOX ?
							"MBOX" :
							(args_info.thread_interface_arg == TI_RQUEUE ?
									"RQUEUE" : "unknown"))),
			((args_info.shadow_flag + 1) == 1 ? "off" : "on"),
			args_info.shadow_schedule_arg, args_info.shadow_transmodal_flag,
			args_info.mt_arg);

	printf("Main thread is pthread %lu\n", (unsigned long)pthread_self());
}

int main(int argc, char **argv) {
	logging_init();

	int i;

	unsigned generate_data_time;
	unsigned generate_check_result_time;
	unsigned init_hwt_time;
	unsigned init_swt_time;
	unsigned str_mmp_split;
	unsigned std_mmp_time;
	unsigned str_mmp_combine;
	unsigned terminate_hwt_time;
	unsigned terminate_swt_time;
	unsigned comparision_time;
	unsigned calculation_time_std;
	unsigned calculation_time_str;

	install_sighandlers();
	handle_commandline(argc, argv);

	int hw_threads = args_info.hwt_arg;
	int sw_threads = args_info.swt_arg;

	int std_matrix_size	= STD_MMP_MATRIX_SIZE; // Fixed by hardware thread
	int str_matrix_size = args_info.matrix_size_arg; //STR_MMP_INPUT_MATRIX_SIZE;

	int mbox_size = (int) pow(7, ((int)log2(args_info.matrix_size_arg)) - ((int)log2(STD_MMP_MATRIX_SIZE)));
	printf("Size of mailboxes: %i\n", mbox_size);

	int *i_matrixes[2]	= {NULL, NULL};
	int *o_matrix		= NULL;
	int *compare		= NULL;

	MATRIXES* std_mmp_matrixes = NULL;

	mbox_init(&mb_start, mbox_size);
	mbox_init(&mb_stop,  mbox_size);

	reconos_init(14, 15);

	res[0].type = RECONOS_TYPE_MBOX;
	res[0].ptr  = &mb_start;
	res[1].type = RECONOS_TYPE_MBOX;
	res[1].ptr  = &mb_stop;

	// generate data and result matrix
	INFO("Generating input data.\n");
	generate_data_time = time_ms();
	generate_data(i_matrixes, &o_matrix, str_matrix_size);
	generate_data_time = time_ms() - generate_data_time;

	INFO("Generating check results.\n");
	generate_check_result_time = time_ms();
	generate_result(i_matrixes, &compare, str_matrix_size);
	generate_check_result_time = time_ms() - generate_check_result_time;

	// init hw-threads
	INFO("Creating %i hw-thread(s).\n", hw_threads);
	init_hwt_time = time_ms();
	for (i = 0; i < hw_threads; i++) {
		reconos_hwt_setresources(&(hwt[i]),res,2);
		reconos_hwt_create(&(hwt[i]),i,NULL);
	}
	init_hwt_time = time_ms() - init_hwt_time;

	// init sw-threads
	INFO("Creating %i sw-threads.\n", sw_threads);
	init_swt_time = time_ms();
	for (i = 0; i < sw_threads; i++) {
		pthread_attr_init(&swt_attr[i]);
		pthread_create(&swt[i], &swt_attr[i], matrixmul_thread, (void*)res);
	}
	init_swt_time = time_ms() - init_swt_time;

	// split input matrixes recursively (strassen algorithm part 1)
	INFO("Running Strassen algorithm part 1 - split.\n");
	str_mmp_split = time_ms();
	str_matrix_split(i_matrixes[0], i_matrixes[1], &std_mmp_matrixes, str_matrix_size);
	str_mmp_split = time_ms() - str_mmp_split;

	// calculate matrixes with standard mmp algorithm (in hw and/or sw)
	INFO("Putting matrix pointers in mbox.\n");
	std_mmp_time = time_ms();
	MATRIXES *ptr = std_mmp_matrixes;
	for (i=0; i<mbox_size; ++i) {
		mbox_put(&mb_start,(unsigned int)(ptr->matrixes));
		ptr = ptr->next;
	}
	INFO("Waiting for acknowledgements...\n");
	for (i=0; i<mbox_size; ++i) {
		mbox_get(&mb_stop);
	}
	std_mmp_time = time_ms() - std_mmp_time;
	INFO("Got acknowledgments.\n");

	// terminate threads
	INFO("Sending terminate message to %i thread(s).\n", hw_threads + sw_threads);
	terminate_hwt_time = time_ms();
	terminate_swt_time = terminate_hwt_time;
	for (i = 0; i < hw_threads + sw_threads; i++) {
		mbox_put(&mb_start,UINT_MAX);
	}

	for (i=0; i<hw_threads; i++) {
		pthread_join(hwt[i].delegate,NULL);
	}
	terminate_hwt_time = time_ms() - terminate_hwt_time;
	for (i=0; i<sw_threads; i++) {
		pthread_join(swt[i],NULL);
	}
	terminate_swt_time = time_ms() - terminate_swt_time;
	INFO("Threads have been terminated.\n");

	// combine results (strassen algorithm part 2)
	INFO("Running Strassen algorithm part 2 - combine.\n");
	str_mmp_combine = time_ms();
	o_matrix = str_matrix_combine(&std_mmp_matrixes, std_matrix_size, str_matrix_size);
	str_mmp_combine = time_ms() - str_mmp_combine;

	// check, if results are correct
	comparision_time = time_ms();
	int correct_result =  compare_result(o_matrix, compare, str_matrix_size);
	comparision_time = time_ms() - comparision_time;

	if (correct_result) {
		INFO("\nResult is correct.\n\n");
	} else {
		INFO("\nBad result.\n");
#if 0
		print_matrix(input_matrixes[0], 'A', NUM_INPUT_MATRIXLINE_LEN);
		print_matrix(input_matrixes[1], 'B', NUM_INPUT_MATRIXLINE_LEN);
		print_matrix(output_matrix    , 'C', NUM_INPUT_MATRIXLINE_LEN);
		print_matrix(compare          , 'Z', NUM_INPUT_MATRIXLINE_LEN);
#endif
		INFO("\n");
	}

	calculation_time_std = generate_check_result_time;
	calculation_time_str = init_hwt_time + init_swt_time + str_mmp_split + std_mmp_time + terminate_swt_time + str_mmp_combine;

	INFO("Timing information\n");
	INFO("==================\n");
	INFO("Generate input data:   %u ms\n", generate_data_time);
	INFO("Generate check result: %u ms\n", generate_check_result_time);
	INFO("Initializing HWT:      %u ms\n", init_hwt_time);
	INFO("Initializing SWT:      %u ms\n", init_swt_time);
	INFO("Str. split (part 1):   %u ms\n", str_mmp_split);
	INFO("Std. MMP:              %u ms\n", std_mmp_time);
	INFO("Str. combine (part 2): %u ms\n", str_mmp_combine);
	INFO("~Thread term. HWT:     %u ms\n", terminate_hwt_time);
	INFO("~Thread term. SWT:     %u ms\n", terminate_swt_time);
	INFO("Check HWT result:      %u ms\n\n", comparision_time);
	INFO("Important timing results\n");
	INFO("========================\n");
	INFO("Runtime Std. MMP:      %u ms\n", calculation_time_std);
	INFO("Runtime Str. MMP:      %u ms\n", calculation_time_str);

	return 0;
}
