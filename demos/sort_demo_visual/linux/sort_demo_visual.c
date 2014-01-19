#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>

#include "sort_demo_visual.h"
#include "display.h"

uint32_t *generate_data() {
	uint32_t *data;
	int i;

	data = (uint32_t *)malloc(sizeof(uint32_t) * SORT_SIZE);
	if (!data)
		return 0;

	for (i = 0; i < SORT_SIZE; i++)
		data[i] = (uint32_t)rand();

	return data;
}

void *thread_control(void *arg) {
	struct sort_demo_visual *demo;
	uint32_t *data;

	demo = (struct sort_demo_visual *)arg;

	while(1) {
		sem_wait(&demo->thread_control_wait);

		while (demo->num_hwts_running < demo->conf.num_hwts) {
			//printf("[thread-control] generating new data for hardware thread\n");
			data = generate_data();
			mbox_put(&demo->mb_hwt_recv, (uint32_t)data);

			sem_wait(&demo->num_hwts_running_sem);
			demo->num_hwts_running++;
			sem_post(&demo->num_hwts_running_sem);
		}

		while (demo->num_swts_running < demo->conf.num_swts) {
			//printf("[thread-control] generating new data for software thread\n");
			data = generate_data();
			mbox_put(&demo->mb_swt_recv, (uint32_t)data);

			sem_wait(&demo->num_swts_running_sem);
			demo->num_swts_running++;
			sem_post(&demo->num_swts_running_sem);
		}
	}
}

void *hwt_response(void *arg) {
	struct sort_demo_visual *demo;
	uint32_t *data;

	demo = (struct sort_demo_visual *)arg;

	while (1) {
		data = (uint32_t *)mbox_get(&demo->mb_hwt_send);
		free(data);

		sem_wait(&demo->num_hwts_running_sem);
		demo->num_hwts_running--;
		sem_post(&demo->num_hwts_running_sem);

		sem_wait(&demo->stats.sem);
		demo->stats.block_count++;
		sem_post(&demo->stats.sem);

		sem_post(&demo->thread_control_wait);
	}
}

void *swt_response(void *arg) {
	struct sort_demo_visual *demo;
	uint32_t *data;

	demo = (struct sort_demo_visual *)arg;

	while (1) {
		data = (uint32_t *)mbox_get(&demo->mb_swt_send);
		free(data);

		sem_wait(&demo->num_swts_running_sem);
		demo->num_swts_running--;
		sem_post(&demo->num_swts_running_sem);

		sem_wait(&demo->stats.sem);
		demo->stats.block_count++;
		sem_post(&demo->stats.sem);

		sem_post(&demo->thread_control_wait);
	}
}

void bubblesort (uint32_t *data) {
    int swapped = 1;
    unsigned int i, n, n_new, temp;
    n = SORT_SIZE - 1;
    n_new = n;

    while (swapped) {
        swapped = 0;
        for (i = 0; i < n; i++) {
            if (data[i] > data[i + 1] ) {
                temp = data[i];
                data[i] = data[i + 1];
                data[i + 1] = temp;
                n_new = i;
                swapped = 1;
            }
        }
        n = n_new;
    }
}

void *sort_thread(void *arg) {
	struct reconos_resource *res;
	uint32_t ret;

	res = (struct reconos_resource *)arg;

	while (1) {
		ret = mbox_get(res[0].ptr);
		if (ret == 0xFFFFFFFF)
			pthread_exit(NULL);

		bubblesort((uint32_t *)ret);

		mbox_put(res[1].ptr, ret);
	}
}

int init_sort_demo(struct sort_demo_visual *demo) {
	mbox_init(&demo->mb_hwt_recv, NUM_HWTS);
	mbox_init(&demo->mb_hwt_send, NUM_HWTS);
	demo->hwt_res[0].ptr = &demo->mb_hwt_recv;
	demo->hwt_res[0].type = RECONOS_RESOURCE_TYPE_MBOX;
	demo->hwt_res[1].ptr = &demo->mb_hwt_send;
	demo->hwt_res[1].type = RECONOS_RESOURCE_TYPE_MBOX;

	mbox_init(&demo->mb_swt_recv, NUM_SWTS);
	mbox_init(&demo->mb_swt_send, NUM_SWTS);
	demo->swt_res[0].ptr = &demo->mb_swt_recv;
	demo->hwt_res[0].type = RECONOS_RESOURCE_TYPE_MBOX;
	demo->swt_res[1].ptr = &demo->mb_swt_send;
	demo->hwt_res[1].type = RECONOS_RESOURCE_TYPE_MBOX;

	demo->conf.num_swts = 1;
	demo->conf.num_hwts = 0;
	demo->conf.thread_control_wait = &demo->thread_control_wait;

	demo->num_hwts_running = 0;
	sem_init(&demo->num_hwts_running_sem, 0, 1);
	demo->num_swts_running = 0;
	sem_init(&demo->num_swts_running_sem, 0, 1);

	sem_init(&demo->thread_control_wait, 0, 0);

	sem_init(&demo->stats.sem, 0, 1);
	demo->stats.block_count = 0;

	return 0;
}

void signalhandler(int sig) {
	reconos_cleanup();
	clean_display();

	printf("[sort-demo-visual] aborted\n");

	exit(0);
}


int main(int argc, char **argv) {
	int i;
	struct sort_demo_visual demo;
	struct display display;

	unsigned int rate;

	reconos_init();

	// override reconos signal handlers
	signal(SIGINT, signalhandler);
	signal(SIGTERM, signalhandler);
	signal(SIGABRT, signalhandler);

	init_sort_demo(&demo);
	init_display(&display, &demo.stats, &demo.conf);

	pthread_create(&demo.hwt_response, NULL, hwt_response, &demo);
	pthread_create(&demo.swt_response, NULL, swt_response, &demo);
	pthread_create(&demo.thread_control, NULL, thread_control, &demo);

	for (i = 0; i < NUM_HWTS; i++) {
		reconos_hwt_setresources(&demo.hwt[i], demo.hwt_res, 2);
		reconos_hwt_create(&demo.hwt[i], i, NULL);
	}

	for (i = 0; i < NUM_SWTS; i++) {
		pthread_create(&demo.swt[i], NULL, sort_thread, &demo.swt_res);
	}

	sem_post(&demo.thread_control_wait);

#if 0
	while (1) {
		sem_wait(&demo.stats.sem);
		rate = demo.stats.block_count;
		demo.stats.block_count = 0;
		sem_post(&demo.stats.sem);
		printf("%d blocks/s\n", rate * 2);

		usleep(500000);
	}
#endif

	pthread_join(demo.thread_control, NULL);

	reconos_cleanup();
	clean_display();

	return 0;
}
