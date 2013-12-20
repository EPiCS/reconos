#include "reconos.h"

#include <pthread.h>
#include "mbox.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#define NUM_HWT 8

#define ARGUMENT (rand() % 10000000 + 8000000)

struct mbox mbox_on_recv, mbox_on_send;
struct mbox mbox_off_recv, mbox_off_send;

struct reconos_hwt hwt[NUM_HWT];
struct reconos_resource led_on_res[2];
struct reconos_resource led_off_res[2];

struct reconos_configuration led_on_conf[NUM_HWT];
struct reconos_configuration led_off_conf[NUM_HWT];

pthread_t ctrl_on, ctrl_off;

struct reconos_configuration *schedule(struct reconos_hwt *hwt) {
	//printf("... Scheduler called with hwt %d currently running configuration '%s'\n", hwt->slot, hwt->cfg->name);

	if(!strcmp("on", hwt->cfg->name)) {
		//printf("... Scheduler reschedules to configuration '%s' (should be off)\n", led_off_conf[hwt->slot].name);
		// inverting to off thread
		return &led_off_conf[hwt->slot];
	} else {
		//printf("... Scheduler reschedules to configuration '%s' (should be on)\n", led_on_conf[hwt->slot].name);
		// inverting to on thread
		return &led_on_conf[hwt->slot];
	}
}

void *ctrl_on_thread(void *data) {
	int i;

	//printf("..... control thread 'on' started\n");

	for (i = 0; i < NUM_HWT; i++) {
		mbox_put(&mbox_on_recv, ARGUMENT);
	}

	while (1) {
		mbox_get(&mbox_on_send);
		//printf("..... control thread 'on' received ack, generate new data\n");
		mbox_put(&mbox_on_recv, ARGUMENT);
	}
}

void *ctrl_off_thread(void *data) {
	int i;

	//printf("..... control thread 'off' started\n");

	for (i = 0; i < NUM_HWT; i++) {
		mbox_put(&mbox_off_recv, ARGUMENT);
	}

	while (1) {
		mbox_get(&mbox_off_send);
		//printf("..... control thread 'off' received ack, generate new data\n");
		mbox_put(&mbox_off_recv, ARGUMENT);
	}
}

int main(int argc, char **argv) {
	int i;
	char filename[256];

	// initialize mboxes
	mbox_init(&mbox_on_recv, 16);
	mbox_init(&mbox_on_send, 16);

	mbox_init(&mbox_off_recv, 16);
	mbox_init(&mbox_off_send, 16);


	// intialize resources
	led_on_res[0].type = RECONOS_RESOURCE_TYPE_MBOX;
	led_on_res[0].res = &mbox_on_recv;
	led_on_res[1].type = RECONOS_RESOURCE_TYPE_MBOX;
	led_on_res[1].res = &mbox_on_send;

	led_off_res[0].type = RECONOS_RESOURCE_TYPE_MBOX;
	led_off_res[0].res = &mbox_off_recv;
	led_off_res[1].type = RECONOS_RESOURCE_TYPE_MBOX;
	led_off_res[1].res = &mbox_off_send;

	// initialize configurations
	for (i = 0; i < NUM_HWT; i++) {
		reconos_configuration_init(&led_on_conf[i], "on", i);
		reconos_configuration_setresources(&led_on_conf[i], led_on_res, 2);
		snprintf(filename, sizeof(filename), "system_hwt_reconf_%d_hwt_led_on_partial.bin", i);
		reconos_configuration_loadbitstream(&led_on_conf[i], filename);

		reconos_configuration_init(&led_off_conf[i], "off", i);
		reconos_configuration_setresources(&led_off_conf[i], led_off_res, 2);
		snprintf(filename, sizeof(filename), "system_hwt_reconf_%d_hwt_led_off_partial.bin", i);
		reconos_configuration_loadbitstream(&led_off_conf[i], filename);
	}

	reconos_init();
	reconos_set_scheduler(schedule);

	pthread_create(&ctrl_on, NULL, ctrl_on_thread, NULL);
	pthread_create(&ctrl_off, NULL, ctrl_off_thread, NULL);

	for (i = 0; i < NUM_HWT; i++) {
		reconos_hwt_create_reconf(&hwt[i], i, &led_on_conf[i], NULL);
	}

	pthread_join(ctrl_on, NULL);
	pthread_join(ctrl_off, NULL);

	return 0;
}
