#ifndef SORT_DEMO_VISUAL_H
#define SORT_DEMO_VISUAL_H

#include <stdint.h>
#include <pthread.h>
#include <semaphore.h>

#include "reconos.h"
#include "mbox.h"

#define NUM_HWTS 16
#define NUM_SWTS 4
#define SORT_SIZE 2048

struct configuration {
	int num_hwts;
	int num_swts;
	sem_t *thread_control_wait;
};

struct statistics {
	sem_t sem;
	unsigned int block_count;
};

struct sort_demo_visual {
	struct reconos_hwt hwt[NUM_HWTS];
	struct reconos_resource hwt_res[2];

	pthread_t swt[NUM_SWTS];
	struct reconos_resource swt_res[2];

	struct mbox mb_hwt_recv, mb_hwt_send;
	struct mbox mb_swt_recv, mb_swt_send;

	struct configuration conf;
	struct statistics stats;

	pthread_t thread_control;
	sem_t thread_control_wait;

	pthread_t hwt_response;
	pthread_t swt_response;

	int num_hwts_running;
	sem_t num_hwts_running_sem;
	int num_swts_running;
	sem_t num_swts_running_sem;
};

#endif /* SORT_DEMO_VISUAL */
