/* matrixmul.c */

#include "xmk.h"
#include "sys/init.h"
#include "platform.h"
#include "mb_interface.h"

#include <stdio.h>
#include <stdlib.h>

#include "reconos.h"
#include "mbox.h"

#include "reconos.h"
#include "mbox.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>
#include "mmp.h"
#include "common.h"
#include "logging.h"

#if 0
#define TEST
#endif

#define NUM_HWTS 1
//#define NUM_SWTS 0 // no sw thread support!

// software threads
//pthread_t swt[NUM_SWTS]; // no sw thread support!
//pthread_attr_t swt_attr[NUM_SWTS]; // no sw thread support!

// hardware threads
struct reconos_resource res[NUM_HWTS][2];
struct reconos_hwt hwt[NUM_HWTS];
// How many parallel matrix multiplications can a hwt do?
unsigned int reconos_hwt_engines[NUM_HWTS] = {1,1,1}; //{5,5,5} // maximum

// mailboxes - individual inputs, but commmon outputs mailboxes
struct mbox mb_start[NUM_HWTS];
struct mbox mb_stop;

#if 0 // no sw thread support!
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
#endif



extern int _STACK_SIZE;
extern int _HEAP_SIZE;

void *matrixmul_main(void *args) {
	logging_init();
	INFO("HeapSize: 0x%X StackSize: 0x%X\n", &_HEAP_SIZE, &_STACK_SIZE);
	INFO("sort_demo build: %s %s\n", __DATE__, __TIME__);

	int i,j, k;

	unsigned generate_data_time;
	unsigned generate_check_result_time;
	unsigned init_hwt_time;
	//unsigned init_swt_time;
	unsigned str_mmp_split;
	unsigned std_mmp_time;
	unsigned str_mmp_combine;
	unsigned terminate_hwt_time;
	//unsigned terminate_swt_time;
	unsigned comparision_time;
	unsigned calculation_time_std;
	unsigned calculation_time_str;

	int hw_threads = NUM_HWTS;
	//int sw_threads = NUM_SWTS;

	int std_matrix_size	= STD_MMP_MATRIX_SIZE;
	int str_matrix_size = STR_MMP_INPUT_MATRIX_SIZE;

	int *i_matrixes[2]	= {NULL, NULL};
	int *o_matrix		= NULL;
	int *compare		= NULL;

	MATRIXES* std_mmp_matrixes = NULL;

	for (k=0; k< NUM_HWTS; k++){
		mbox_init(&mb_start[k], MBOX_SIZE);
	}
	mbox_init(&mb_stop,  MBOX_SIZE);

	reconos_init(3, 4);

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
	for (k = 0; k < hw_threads; k++) {
		res[k][0].type = RECONOS_TYPE_MBOX;
		res[k][0].ptr  = &mb_start[k];
		res[k][1].type = RECONOS_TYPE_MBOX;
		res[k][1].ptr  = &mb_stop;
		reconos_hwt_setresources(&(hwt[k]),res[k],2);
		reconos_hwt_create(&(hwt[k]),k,NULL);
	}
	init_hwt_time = time_ms() - init_hwt_time;

#if 0  // No software thread support!
	// init sw-threads
	INFO("Creating %i sw-threads.\n", sw_threads);
	init_swt_time = time_ms();
	for (i = 0; i < sw_threads; i++) {
		pthread_attr_init(&swt_attr[i]);
		pthread_create(&swt[i], &swt_attr[i], matrixmul_thread, (void*)res);
	}
	init_swt_time = time_ms() - init_swt_time;
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

	i=0; // no work packages assigned yet.
	j=0; // current hwt to assign work to.
	INFO("Work packages assigned: %d \n", i);
	while(MBOX_SIZE-i > 0) {
		/* Distribution algorithm:
		 * reconos_hwt_engines stores how many matrices each hwt can take.
		 * We implement a round-robin scheme: we fill up the first thread with its maximum work capacity,
		 * then we fill up the second thread, and so on.
		 *
		 * i = current matrix multiplication to assign
		 * MBOX_SIZE - i = remaining  matrix multiplications
		 *
		 */
		int work_package_size = reconos_hwt_engines[j] < MBOX_SIZE-i ? reconos_hwt_engines[j] : MBOX_SIZE-i;

		// Put number of work packages into mbox
		mbox_put(&mb_start[j],work_package_size);
		// Put work packages into mbox
		for(k=0; k<work_package_size; k++ ){
			mbox_put(&mb_start[j],(unsigned int)(ptr->matrixes));
			ptr = ptr->next;
		}
		i += work_package_size;
		j = (j+1)%NUM_HWTS;
		//INFO("Work packages assigned: %d ; Assigned %d to mbox %d \n", i, work_package_size, j);
	}


	for (k=0; k<MBOX_SIZE; ++k) {
		mbox_get(&mb_stop);
	}
	std_mmp_time = time_ms() - std_mmp_time;
	INFO("Got acknowledgments.\n");

	// terminate threads
	INFO("Sending terminate message to %i thread(s).\n", hw_threads ); // + sw_threads
	terminate_hwt_time = time_ms();
	//terminate_swt_time = terminate_hwt_time;
	for (k = 0; k < hw_threads ; k++) { // + sw_threads
		mbox_put(&mb_start[k],1);  // 1 Task to do:
		mbox_put(&mb_start[k],UINT_MAX); // terminate yourself!
	}

	for (k=0; k<hw_threads; k++) {
		pthread_join(hwt[k].delegate,NULL);
	}
	terminate_hwt_time = time_ms() - terminate_hwt_time;
	//for (k=0; k<sw_threads; k++) {
	//	pthread_join(swt[k],NULL);
	//}
	//terminate_swt_time = time_ms() - terminate_swt_time;
	INFO("Threads have been terminated.\n");

	// combine results (strassen algorithm part 2)
	INFO("Running Strassen algorithm part 2 - combine.\n");
	str_mmp_combine = time_ms();
	o_matrix = str_matrix_combine(&std_mmp_matrixes, std_matrix_size);
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
	calculation_time_str = init_hwt_time + str_mmp_split + std_mmp_time + str_mmp_combine; // + terminate_swt_time  init_swt_time +

	INFO("Timing information\n");
	INFO("==================\n");
	INFO("Generate input data:   %u ms\n", generate_data_time);
	INFO("Generate check result: %u ms\n", generate_check_result_time);
	INFO("Initializing HWT:      %u ms\n", init_hwt_time);
	//INFO("Initializing SWT:      %u ms\n", init_swt_time);
	INFO("Str. split (part 1):   %u ms\n", str_mmp_split);
	INFO("Std. MMP:              %u ms\n", std_mmp_time);
	INFO("Str. combine (part 2): %u ms\n", str_mmp_combine);
	INFO("~Thread term. HWT:     %u ms\n", terminate_hwt_time);
	//INFO("~Thread term. SWT:     %u ms\n", terminate_swt_time);
	INFO("Check HWT result:      %u ms\n\n", comparision_time);
	INFO("Important timing results\n");
	INFO("========================\n");
	INFO("Runtime Std. MMP:      %u ms\n", calculation_time_std);
	INFO("Runtime Str. MMP:      %u ms\n", calculation_time_str);

	while(1);
	return NULL;
}


int main() {
	init_platform();

	/* Initialize xilkernel */
	xilkernel_init();

	/* add a thread to be launched once xilkernel starts */
#ifdef TEST
	xmk_add_static_thread(matrixmul_test, 0);
#else
	xmk_add_static_thread(matrixmul_main, 0);
#endif

	/* start xilkernel - does not return control */
	xilkernel_start();

	/* Never reached */
	cleanup_platform();

	return 0;
}
