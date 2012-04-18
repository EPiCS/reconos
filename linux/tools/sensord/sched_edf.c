/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <unistd.h>
#include "plugin.h"

static void sched_edf_fetch(struct plugin_instance *p)
{
	p->fetch(p);
}

void sched_edf_main(void)
{
	while (1) {
		for_each_plugin(sched_edf_fetch);
		sleep(1);
	}
}
