/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <unistd.h>

#include "plugin.h"
#include "locking.h"
#include "xutils.h"
#include "sched_edf.h"

struct task {
	unsigned long interval;		/* in us */
	unsigned long interval_left;	/* in us */
	struct plugin_instance *plugin;
	struct task *next;
};

static struct task *list = NULL;
static struct mutexlock lock;

void sched_edf_register_task(struct plugin_instance *p)
{
}

void sched_edf_unregister_task(struct plugin_instance *p)
{
}

void sched_edf_main(void)
{
	while (1) {
		sleep(1);
	}
}
