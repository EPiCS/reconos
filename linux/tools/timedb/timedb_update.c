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

int main(int argc, char **argv)
{
	int fd, argvp;
	uint8_t *block;
	ssize_t ret;
	size_t block_len;
	struct timedb_hdr th;
	struct timedb_block *tb;
	uint64_t off_curr, bnum;

	if (argc < 3) {
		printf("Usage: timedb_update <file> <data-cells-of-block>\n");
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

	if (argc - 2 != th.cells_per_block - 1) {
		printf("Wrong number of data arguments!\n");
		exit(1);
	}

	block_len = th.cells_per_block * sizeof(uint64_t);
	block = malloc(block_len);
	assert(block);

	tb = (struct timedb_block *) block;
	tb->seqnr = th.seq_next;
	for (argvp = 0; argvp < th.cells_per_block - 1;) {
		tb->cells[argvp] = atof(argv[argvp + 2]);
		argvp++;
	}

	lseek(fd, th.offset_next, SEEK_SET);
	ret = write(fd, block, block_len);
	if (ret != block_len) {
		printf("Error while writing data set: %s\n", strerror(errno));
		exit(1);
	}

	off_curr = lseek(fd, 0, SEEK_CUR);
	bnum = (off_curr - sizeof(th)) / block_len;

	if (bnum == th.block_entries)
		th.offset_next = sizeof(th);
	else
		th.offset_next = off_curr;
	th.seq_next++;

	lseek(fd, 0, SEEK_SET);
	ret = write(fd, &th, sizeof(th));
	if (ret != sizeof(th)) {
		printf("Error writing block head: %s\n", strerror(errno));
		exit(1);
	}

	free(block);
	close(fd);
	return 0;
}
