/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>

#include "timedb.h"

int main(int argc, char **argv)
{
	int fd, fdn, pfd[2], dummy = 0;
	ssize_t ret;
	struct timedb_hdr th;
	uint64_t interval, tot_blocks;
	uint16_t cells;

	if (argc != 5) {
		printf("Usage: timedb_create <file> <interval-in-us> "
		       "<total-blocks> <data-cells-per-block>\n");
		exit(1);
	}

	interval = atol(argv[2]);
	tot_blocks = atol(argv[3]);
	cells = atoi(argv[4]);

	timedb_fill_hdr(&th, interval, tot_blocks, cells);

	fd = open(argv[1], O_CREAT | O_WRONLY | O_TRUNC, S_IRUSR | S_IWUSR);
	if (fd < 0) {
		printf("Cannot open file: %s!\n", strerror(errno));
		exit(1);
	}

	fdn = open("/dev/zero", O_RDONLY);
	if (fdn < 0) {
		printf("Cannot open file: %s!\n", strerror(errno));
		exit(1);
	}

	ret = pipe(pfd);
	if (ret < 0) {
		printf("Cannot create pipe: %s!\n", strerror(errno));
		exit(1);
	}

	ret = write(fd, &th, sizeof(th));
	if (ret != sizeof(th)) {
		printf("Cannot write to file: %s!\n", strerror(errno));
		exit(1);
	}

	lseek(fd, th.block_entries * th.cells_per_block * sizeof(uint64_t) - 1,
	      SEEK_CUR);

	ret = write(fd, &dummy, 1);
	if (ret != 1) {
		printf("Cannot write to file: %s!\n", strerror(errno));
		exit(1);
	}

	close(fdn);
	close(fd);

	return 0;
}
