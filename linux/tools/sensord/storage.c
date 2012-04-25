/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>

#include "timedb.h"
#include "xutils.h"
#include "storage.h"
#include "plugin.h"
#include "sensord.h"

static int storage_create_db(char *path, uint64_t interval, uint64_t tot_blocks,
			     uint16_t cells)
{
	int fd, dummy = 0;
	ssize_t ret;
	struct timedb_hdr th;

	if (interval == 0 || tot_blocks == 0 || cells == 0) {
		printd("Invalid argument for creating timedb!\n");
		return -EINVAL;
	}

	timedb_fill_hdr(&th, interval, tot_blocks, cells);

	fd = open(path, O_CREAT | O_WRONLY | O_TRUNC, S_IRUSR | S_IWUSR);
	if (fd < 0) {
		printf("Cannot open file: %s!\n", strerror(errno));
		return -EINVAL;
	}

	ret = write(fd, &th, sizeof(th));
	if (ret != sizeof(th)) {
		printf("Cannot write to file: %s!\n", strerror(errno));
		return -EINVAL;
	}

	lseek(fd, th.block_entries * th.cells_per_block * sizeof(uint64_t) - 1,
	      SEEK_CUR);

	ret = write(fd, &dummy, 1);
	if (ret != 1) {
		printf("Cannot write to file: %s!\n", strerror(errno));
		return -EINVAL;
	}

	return fd;
}

void storage_register_task(struct plugin_instance *p)
{
	int fd;
	char name[256];

	memset(name, 0, sizeof(name));
	snprintf(name, sizeof(name), "%s%s", DATABASE_DIR, p->name);

	fd = open(name, O_RDONLY);
	if (fd < 0) {
		fd = storage_create_db(name, p->schedule_int, p->block_entries,
				       p->cells_per_block);
		if (fd < 0)
			panic("Cannot create database!\n");
		printd("timedb database %s created!\n", name);
	}

	p->timedb_fd = fd;
}

void storage_unregister_task(struct plugin_instance *p)
{
	close(p->timedb_fd);
}

void storage_update_task(struct plugin_instance *p, double *cells, size_t len)
{
	/* stub */
}
