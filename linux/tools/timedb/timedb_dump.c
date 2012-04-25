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
#include <assert.h>

#include "timedb.h"

#define US_TO_MIN(x)	(1.0 * (((x) / (1000 * 1000)) / 60))
#define US_TO_DAY(x)	(1.0 * ((((x) / (1000 * 1000)) / 60) / 1440))

int main(int argc, char **argv)
{
	int fd;
	ssize_t ret;
	size_t block_len, idx, j;
	struct timedb_hdr th;
	time_t nowtime;
	struct tm *nowtm;
	char tmbuf[128], buf[256];
	uint8_t *block;

	if (argc != 2) {
		printf("Usage: timedb_dump <file>\n");
		exit(1);
	}

	fd = open(argv[1], O_RDWR);
	if (fd < 0) {
		printf("Cannot open file: %s!\n", strerror(errno));
		exit(1);
	}

	ret = read(fd, &th, sizeof(th));
	if (ret != sizeof(th)) {
		printf("Cannot read from file: %s!\n", strerror(errno));
		exit(1);
	}

	nowtime = th.start.tv_sec;
	nowtm = localtime(&nowtime);

	memset(tmbuf, 0, sizeof(tmbuf));
	memset(buf, 0, sizeof(buf));

	strftime(tmbuf, sizeof(tmbuf), "%Y-%m-%d %H:%M:%S", nowtm);
	snprintf(buf, sizeof(buf), "%s.%06d", tmbuf, th.start.tv_usec);

	printf("meta information:\n");
	printf("canary: 0x%x\n", th.canary);
	printf("version_major: %u\n", th.version_major);
	printf("version_minor: %u\n", th.version_minor);
	printf("start.tv_sec: %u\n", th.start.tv_sec);
	printf("start.tv_usec: %u\n", th.start.tv_usec);
	printf("start: %s\n", buf);
	printf("interval: %lu us\n", th.interval);
	printf("storage window: %lu us [%lf min] [%lf days]\n",
	       th.interval * th.block_entries,
	       US_TO_MIN(th.interval * th.block_entries),
	       US_TO_DAY(th.interval * th.block_entries));
	printf("block_entries: %lu\n", th.block_entries);
	printf("cells_per_block: %u\n", th.cells_per_block);
	printf("data_cells_per_block: %u\n", th.cells_per_block - 1);
	printf("offset_next: %lu\n", th.offset_next);
	printf("seq_next: %lu\n", th.seq_next);
	printf("payload:\n");

	block_len = th.cells_per_block * sizeof(uint64_t);
	block = malloc(block_len);
	assert(block);

	for (idx = 0; idx < th.block_entries; idx++) {
		ret = read(fd, block, block_len);
		if (ret != block_len)
			break;
		printf("%zu: seq:%lu ", idx, block_to_seq(block));
		for (j = 0; j < th.cells_per_block - 1; ++j) {
			printf("%lf ", block_to_data_off(block, j));
		}
		printf("\n");
	}

	free(block);
	close(fd);

	return 0;
}
