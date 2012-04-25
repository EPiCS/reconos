/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include "sensord.h"

#define MODULE	"dummy"

static void dummy_fetch(struct plugin_instance *self)
{
	int i;
	double *cells = self->private_data;
	size_t len = self->cells_per_block;

	printp("Hello Fetch!\n");

	for (i = 0; i < len; ++i) {
		cells[i] = 1.0;
	}
}

struct plugin_instance dummy_plugin = {
	.name			=	MODULE "-1",
	.basename		=	MODULE,
	.fetch			=	dummy_fetch,
	.type			=	TYPE_FLOAT,
	/* schedule_int and block_entries describe your window size, so
	   one of the two should at least be large enough */
	.schedule_int		=	TIME_IN_SEC(1),
	.block_entries		=	10,
	.cells_per_block	=	2,
};

static __init int dummy_init(void)
{
	struct plugin_instance *pi = &dummy_plugin;

	printp("Hello World!\n");

	pi->private_data = malloc(pi->cells_per_block * sizeof(double));
	assert(pi->private_data);

	return register_plugin_instance(pi);
}

static __exit void dummy_exit(void)
{
	struct plugin_instance *pi = &dummy_plugin;

	free(pi->private_data);

	unregister_plugin_instance(pi);

	printp("Goodbye World!\n");
}

plugin_init(dummy_init);
plugin_exit(dummy_exit);

PLUGIN_LICENSE("GPL");
PLUGIN_AUTHOR("Daniel Borkmann <daniel.borkmann@tik.ee.ethz.ch>");
PLUGIN_DESC("A simple dummy sensord plugin");
