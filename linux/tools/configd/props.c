/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <pthread.h>
#include <stdint.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <linux/types.h>
#include <linux/netlink.h>
#include <linux/if.h>

#include "xt_vlink.h"
#include "xt_fblock.h"
#include "props.h"
#include "xutils.h"

static pthread_t thread;

extern sig_atomic_t sigint;

struct prop_type {
	char name[FBNAMSIZ];
	enum fblock_props props[MAX_PROPS];
};

#define MAX_ELEMS	1024

static struct prop_type table[MAX_ELEMS];
static size_t elems;

static void *property_fetcher(void *null)
{
	while (!sigint) {
		sleep(1);
	}

	pthread_exit(NULL);
}

void start_property_fetcher(void)
{
	int ret = pthread_create(&thread, NULL, property_fetcher, NULL);
	if (ret < 0)
		panic("Cannot create thread!\n");

	printd("Start property collector!\n");
}

void stop_property_fetcher(void)
{
	pthread_join(thread, NULL);

	printd("Stop property collector!\n");
}
