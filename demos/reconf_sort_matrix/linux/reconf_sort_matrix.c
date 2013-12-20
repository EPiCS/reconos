#include "reconos.h"

#include <pthread.h>
#include "mbox.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <string.h>
#include <signal.h>

#define NUM_HWT 11

#define NUM_SORT 16
#define SORT_SIZE 2048

#define NUM_MATRICES 16
#define MATRIX_SIZE 64

struct mbox mbox_sort_recv, mbox_sort_send;
struct mbox mbox_mmul_recv, mbox_mmul_send;

struct reconos_hwt hwt[NUM_HWT];
struct reconos_resource sort_res[2];
struct reconos_resource mmul_res[2];

struct reconos_configuration sort_cfg[NUM_HWT];
struct reconos_configuration mmul_cfg[NUM_HWT];

pthread_t ctrl_sort, ctrl_mmul;
pthread_t generate;
pthread_t monitor;
pthread_mutex_t sched_mutex;

int sort_data[NUM_SORT][SORT_SIZE];
int sort_request_count, sort_request_count_active;;
int sort_thread_count;
int sort_done_count;

int matrix_data[3 * NUM_MATRICES][MATRIX_SIZE][MATRIX_SIZE];
int *matrix_ptr[3 * NUM_MATRICES];
int matrix_done_count;

struct reconos_configuration *schedule(struct reconos_hwt *hwt) {
	pthread_mutex_lock(&sched_mutex);

	if (sort_request_count > 0) {
		sort_request_count--;

		if (!strcmp("mmul", hwt->cfg->name)) {
			sort_thread_count++;
			//printf("Replacing mmul thread by sort thread now\n");
		}

		pthread_mutex_unlock(&sched_mutex);
		return &sort_cfg[hwt->slot];

	} else {
		if (!strcmp("sort", hwt->cfg->name)) {
			sort_thread_count--;
			//printf("Replacing sort thread by mmul thread now\n");
		}

		pthread_mutex_unlock(&sched_mutex);
		return &mmul_cfg[hwt->slot];
	}
}

void *ctrl_sort_thread(void *data) {
	int i;
	int m;

	for (i = 0; i < NUM_HWT; i++) {
		printf("putting into sort mbox: %x\n", (unsigned int)&sort_data[i][0]);
		mbox_put(&mbox_sort_recv, (unsigned int)&sort_data[i][0]);
	}

	while (1) {
		m = mbox_get(&mbox_sort_send);
		sort_request_count_active--;
		sort_done_count++;
		m = (m - (int)&sort_data) / (4 * SORT_SIZE);
		//printf("putting into sort mbox: %x\n", (unsigned int)&sort_data[m][0]);
		mbox_put(&mbox_sort_recv, (unsigned int)&sort_data[m][0]);
	}
}

void *ctrl_mmul_thread(void *data) {
	int i;
	int m;

	for (i = 0; i < NUM_HWT; i++) {
		printf("putting into mmul mbox: %x\n", (unsigned int)&matrix_ptr[3 * i]);
		mbox_put(&mbox_mmul_recv, (unsigned int)&matrix_ptr[3 * i]);
	}

	while (1) {
		m = mbox_get(&mbox_mmul_send);
		matrix_done_count++;
		m = (m - (int)&matrix_data[0][0][0]) / (4 * MATRIX_SIZE * MATRIX_SIZE);
		//printf("putting into mmul mbox: %x\n", (unsigned int)&matrix_ptr[m % 2]);
		mbox_put(&mbox_mmul_recv, (unsigned int)&matrix_ptr[m % 2]);
	}
}

void *generate_thread(void *data) {
	int wait, count;

	while (1) {
		wait = rand() % 10000 + 60000;
		count = rand() % 20 + 1;
		usleep(wait);

		//printf("Generating %d new sort requests (in total now %d)\n", count, sort_request_count + count);

		pthread_mutex_lock(&sched_mutex);
		sort_request_count += count;
		sort_request_count_active += count;
		pthread_mutex_unlock(&sched_mutex);
	}
}

void *monitor_thread(void *data) {
	unsigned int time = 0;

	printf("#MONITOR OUTPUT: time	#sort_threads	#mmul_threads	#sorts_done	#matrix_done	#sort_requests\n");

	while (1) {
		time++;
		printf("%d	%d	%d	%d	%d	%d\n",
		         time,
		         sort_thread_count,
		         NUM_HWT - sort_thread_count,
		         sort_done_count,
		         matrix_done_count,
		         sort_request_count_active);

		//printf("MONITOR: %d sort threads, %d mmul threads\n", sort_thread_count, NUM_HWT - sort_thread_count);
		//printf("MONITOR: %d sorts done, %d matrix done\n", sort_done_count, matrix_done_count);
		//printf("MONITOR: %d sort requests\n", sort_request_count);
		//printf("------------------------------------------------------\n");
		usleep(10000);
	}
}

void init_sort_data() {
	int i, j;
	int data;

	sort_request_count = 0;
	sort_request_count_active = 0;
	sort_thread_count = 0;

	sort_done_count = 0;

	data = 0xFFFFFFFF;
	for (i = 0; i < NUM_SORT; i ++) {
		for (j = 0; j < SORT_SIZE; j++) {
			sort_data[i][j] = data;
			data--;
		}
	}
}

void init_mmul_data() {
	int m, i, j;

	matrix_done_count = 0;

	for (m = 0; m < 3 * NUM_MATRICES; m++) {
		matrix_ptr[m] = (int *)&matrix_data[m][0][0];

		for (i = 0; i < MATRIX_SIZE; i++) {
			for (j = 0; j < MATRIX_SIZE; j++) {
				matrix_data[m][i][j] = rand() % 128;
			}
		}
	}
}

int main(int argc, char **argv) {
	int i;
	char filename[256];

	// initialize mboxes
	mbox_init(&mbox_sort_recv, 16);
	mbox_init(&mbox_sort_send, 16);

	mbox_init(&mbox_mmul_recv, 16);
	mbox_init(&mbox_mmul_send, 16);

	pthread_mutex_init(&sched_mutex, NULL);

	init_sort_data();
	init_mmul_data();

	// initialize resources
	sort_res[0].type = RECONOS_RESOURCE_TYPE_MBOX;
	sort_res[0].ptr = &mbox_sort_recv;
	sort_res[1].type = RECONOS_RESOURCE_TYPE_MBOX;
	sort_res[1].ptr = &mbox_sort_send;

	mmul_res[0].type = RECONOS_RESOURCE_TYPE_MBOX;
	mmul_res[0].ptr = &mbox_mmul_recv;
	mmul_res[1].type = RECONOS_RESOURCE_TYPE_MBOX;
	mmul_res[1].ptr = &mbox_mmul_send;

	for (i = 0; i < NUM_HWT; i++) {
		reconos_configuration_init(&sort_cfg[i], "sort", i);
		reconos_configuration_setresources(&sort_cfg[i], sort_res, 2);
		snprintf(filename, sizeof(filename), "system_hwt_reconf_%d_hwt_sort_demo_partial.bin", i);
		reconos_configuration_loadbitstream(&sort_cfg[i], filename);

		reconos_configuration_init(&mmul_cfg[i], "mmul", i);
		reconos_configuration_setresources(&mmul_cfg[i], mmul_res, 2);
		snprintf(filename, sizeof(filename), "system_hwt_reconf_%d_hwt_matrixmul_partial.bin", i);
		reconos_configuration_loadbitstream(&mmul_cfg[i], filename);
	}

	reconos_init();
	reconos_set_scheduler(schedule);

	pthread_create(&ctrl_sort, NULL, ctrl_sort_thread, NULL);
	pthread_create(&ctrl_mmul, NULL, ctrl_mmul_thread, NULL);
	pthread_create(&monitor, NULL, monitor_thread, NULL);
	pthread_create(&generate, NULL, generate_thread, NULL);

	for (i = 0; i < NUM_HWT; i++) {
		reconos_hwt_create_reconf(&hwt[i], i, &mmul_cfg[i], NULL);
		//reconos_hwt_setresources(&hwt[i], mmul_res, 2);
		//reconos_hwt_create(&hwt[i], i, NULL);
	}

	while(1) {
#if 0
		fgetc(stdin);
		sort_request_count++;
#endif
	}

	//pthread_join(ctrl_sort, NULL);
	//pthread_join(ctrl_mmul, NULL);

	return 0;
}
