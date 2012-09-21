/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include "sensord.h"
#define MODULE	"file"

static void file_fetch(struct plugin_instance *self)
{
	int fd;
	char buff[256];
	float val = 0.0;

	fd = open("/tmp/sensor", O_RDONLY);
	if (fd >= 0) {
		memset(buff, 0, sizeof(buff));
		read(fd, buff, sizeof(buff));
		close(fd);
		sscanf(buff, "%f", &val);
	}

	self->cells[0] = (double) val;
}

struct plugin_instance file_plugin = {
	.name			=	MODULE "-1",
	.basename		=	MODULE,
	.fetch			=	file_fetch,
	.schedule_int		=	TIME_IN_SEC(1),
	.block_entries		=	1000000,
	.cells_per_block	=	1,
};

static __init int file_init(void)
{
	struct plugin_instance *pi = &file_plugin;

	printp("Hello World!\n");

	srand(time(NULL));

	pi->cells = malloc(pi->cells_per_block * sizeof(double));
	assert(pi->cells);

	return register_plugin_instance(pi);
}

static __exit void file_exit(void)
{
	struct plugin_instance *pi = &file_plugin;

	free(pi->cells);
	unregister_plugin_instance(pi);

	printp("Goodbye World!\n");
}

plugin_init(file_init);
plugin_exit(file_exit);

PLUGIN_LICENSE("GPL");
PLUGIN_AUTHOR("Daniel Borkmann <daniel.borkmann@tik.ee.ethz.ch>");
PLUGIN_DESC("A simple file sensord plugin");
