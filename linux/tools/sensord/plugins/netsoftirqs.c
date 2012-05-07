/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 * Subject to the GNU GPL, version 2.0.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#include <unistd.h>
#include <errno.h>

#include "sensord.h"

#define MODULE	"netsoftirqs"

static FILE *fp;
static double rx_last = 0.0, tx_last = 0.0;
static int first = 1;

static inline int get_number_cpus(void)
{
	return sysconf(_SC_NPROCESSORS_CONF);
}

static void netsoftirqs_fetch(struct plugin_instance *self)
{
	int i, rxf = 0;
	char *ptr, *ptr2;
	char buff[256];
	double rx = 0.0, tx = 0.0;
	size_t irqs_len = get_number_cpus();

	rewind(fp);

	memset(buff, 0, sizeof(buff));
	while (fgets(buff, sizeof(buff), fp) != NULL) {
		buff[sizeof(buff) - 1] = 0;

		if ((ptr = strstr(buff, "NET_TX:")) == NULL) {
			ptr = strstr(buff, "NET_RX:");

			if (ptr == NULL)
				continue;
			rxf = 1;
		} else {
			rxf = 0;
		}

		ptr += strlen("NET_TX:");

		for (i = 0; i < irqs_len; ++i) {
			ptr++;
			while (*ptr == ' ')
				ptr++;
			ptr2 = ptr;
			while (*ptr != ' ' && *ptr != 0)
				ptr++;
			*ptr = 0;
			if (rxf)
				rx += 1.0 * atoi(ptr2);
			else
				tx += 1.0 * atoi(ptr2);
		}

		memset(buff, 0, sizeof(buff));
	}

	if (first) {
		self->cells[0] = 0.0;
		self->cells[1] = 0.0;
		first = 0;
	} else {
		self->cells[0] = rx - rx_last;
		self->cells[1] = tx - tx_last;
	}

	rx_last = rx;
	tx_last = tx;
}

struct plugin_instance netsoftirqs_plugin = {
	.name			=	MODULE "-1",
	.basename		=	MODULE,
	.fetch			=	netsoftirqs_fetch,
	.schedule_int		=	TIME_IN_MSEC(500),
	.block_entries		=	1000000,
	.cells_per_block	=	2, /* rx, tx */
};

static __init int netsoftirqs_init(void)
{
	struct plugin_instance *pi = &netsoftirqs_plugin;

	pi->cells = malloc(pi->cells_per_block * sizeof(double));
	assert(pi->cells);

	fp = fopen("/proc/softirqs", "r");
	if (fp == NULL) {
		free(pi->cells);
		return -EIO;
	}

	return register_plugin_instance(pi);
}

static __exit void netsoftirqs_exit(void)
{
	struct plugin_instance *pi = &netsoftirqs_plugin;

	free(pi->cells);
	unregister_plugin_instance(pi);

	fclose(fp);
}

plugin_init(netsoftirqs_init);
plugin_exit(netsoftirqs_exit);

PLUGIN_LICENSE("GPL");
PLUGIN_AUTHOR("Daniel Borkmann <daniel.borkmann@tik.ee.ethz.ch>");
PLUGIN_DESC("A network softirqs sensord plugin");
