/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

/* export for gnuplot et. al. */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <assert.h>
#include <string.h>
#include <sys/mman.h>

#include "timedb.h"

static void print_block(struct timedb_hdr *th, uint8_t *binary, uint64_t offset)
{
	int j;
	uint8_t *block = binary + offset;
	seq64_t s = block_to_seq(block);

	if (s >= th->seq_next || s == 0) {
		s = 0;
		printf("%lu ", s);
		for (j = 0; j < th->cells_per_block - 1; ++j)
			printf("%.16lf ", 0.0);
	} else {
		printf("%lu ", s);
		for (j = 0; j < th->cells_per_block - 1; ++j)
			printf("%.16lf ", block_to_data_off(block, j));
	}
	printf("\n");
}

static uint64_t next_block(struct timedb_hdr *th, uint8_t *binary, size_t max,
			   uint64_t curr)
{
	uint64_t next;

	if (curr == max - sizeof(uint64_t) * th->cells_per_block) {
		next = sizeof(*th);
	} else {
		next = curr + sizeof(uint64_t) * th->cells_per_block;
	}

	return next;
}

int main(int argc, char **argv)
{
	int fd, ret;
	struct stat sb;
	uint8_t *binary;
	struct timedb_hdr *th;
	struct timedb_block *tb;
	uint64_t off, start = 0, i;
	seq64_t min = (seq64_t) ~0;
	time_t nowtime;
	struct tm *nowtm;
	char tmbuf[128], buf[256];

	if (argc != 2) {
		printf("Usage: timedb_export <file>\n");
		exit(1);
	}

	fd = open(argv[1], O_RDONLY);
	if (fd < 0) {
		printf("Cannot open file: %s!\n", strerror(errno));
		exit(1);
	}

	ret = fstat(fd, &sb);
	if (ret < 0) {
		printf("Cannot fstat file: %s!\n", strerror(errno));
		exit(1);
	}

	if (!S_ISREG(sb.st_mode)) {
		printf("%s is not a file\n", argv[1]);
		exit(1);
	}

	binary = mmap(0, sb.st_size, PROT_READ, MAP_SHARED, fd, 0);
	if (binary == MAP_FAILED) {
		printf("Error mmaping db: %s\n", strerror(errno));
		exit(1);
	}

	posix_fadvise(fd, 0, 0, POSIX_FADV_SEQUENTIAL);
	th = (struct timedb_hdr *) binary;

	off = sizeof(*th);
	for (i = 0; i < th->block_entries; ++i) {
		tb = (struct timedb_block *) ((uint8_t *) binary + off);
		if (tb->seqnr < min) {
			min = tb->seqnr;
			start = off;
		}
		off = next_block(th, binary, sb.st_size, off);
	}

	nowtime = th->start.tv_sec;
	nowtm = localtime(&nowtime);

	memset(tmbuf, 0, sizeof(tmbuf));
	memset(buf, 0, sizeof(buf));

	strftime(tmbuf, sizeof(tmbuf), "%Y-%m-%d %H:%M:%S", nowtm);
	snprintf(buf, sizeof(buf), "%s.%06d", tmbuf, th->start.tv_usec);

	printf("# start.tv_sec: %u\n", th->start.tv_sec);
        printf("# start.tv_usec: %u\n", th->start.tv_usec);
	printf("# start: %s\n", buf);
	printf("# interval: %lu us\n", th->interval);
	printf("# order: old->new\n");
	printf("# seq | cells\n");

	off = start;
	for (i = 0; i < th->block_entries; ++i) {
		print_block(th, binary, off);
		off = next_block(th, binary, sb.st_size, off);
	}

	munmap(binary, sb.st_size);
	close(fd);

	return 0;
}
