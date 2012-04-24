/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

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

static int *fetch;
static size_t fetch_len;
static size_t fetch_num = 0;

static void fetch_block(struct timedb_hdr *th, uint8_t *binary, off_t offset,
			uint64_t i)
{
	int j;
	uint8_t *block = binary + offset;
	seq64_t s = block_to_seq(block);

	if (s >= th->seq_next || s == 0) {
		s = 0;
		printf("%zu: seq:%lu ", i, s);
		for (j = 0; j < th->cells_per_block - 1; ++j)
			printf("%lf ", 0.0);
	} else {
		printf("%zu: seq:%lu ", i, s);
		for (j = 0; j < th->cells_per_block - 1; ++j)
			printf("%lf ", block_to_data_off(block, j));
	}
	printf("\n");
}

static off_t prev_block(struct timedb_hdr *th, uint8_t *binary, size_t max,
			off_t curr)
{
	off_t before;

	if (curr == sizeof(*th)) {
		before = max - sizeof(uint64_t) * th->cells_per_block;
	} else {
		before = curr - sizeof(uint64_t) * th->cells_per_block;
	}

	return before;
}

static inline char *next_token(char *q, int sep)
{
	if (q)
		q = strchr(q, sep);
		/*
		 * glibc defines this as a macro and gcc throws a false
		 * positive ``logical ‘&&’ with non-zero constant will
		 * always evaluate as true'' in older versions. See:
		 * http://gcc.gnu.org/bugzilla/show_bug.cgi?id=36513
		 */
	if (q)
		q++;
	return q;
}

int main(int argc, char **argv)
{
	int fd, ret;
	uint64_t i;
	char *p, *q;
	struct stat sb;
	uint8_t *binary;
	struct timedb_hdr *th;
	off_t last;

	if (argc < 3) {
		printf("Usage: timedb_get <file> <block(s)>\n");
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

	fetch_len = th->block_entries;
	fetch = malloc(fetch_len * sizeof(*fetch));
	assert(fetch);
	memset(fetch, 0, fetch_len * sizeof(fetch));

	q = argv[2];
	while (p = q, q = next_token(q, ','), p) {
		unsigned int a;	 /* Beginning of range */
		unsigned int b;	 /* End of range */
		unsigned int s;	 /* Stride */
		char *c1, *c2;

		if (sscanf(p, "%u", &a) < 1)
			return -EINVAL;

		b = a;
		s = 1;

		c1 = next_token(p, '-');
		c2 = next_token(p, ',');

		if (c1 != NULL && (c2 == NULL || c1 < c2)) {
			if (sscanf(c1, "%u", &b) < 1)
				return -EINVAL;

			c1 = next_token(c1, ':');

			if (c1 != NULL && (c2 == NULL || c1 < c2))
				if (sscanf(c1, "%u", &s) < 1)
					return -EINVAL;
		}

		if (!(a <= b))
			return -EINVAL;

		while (a <= b) {
			if (a >= fetch_len) {
				printf("Error in range: too large!\n");
				exit(1);
			}
			fetch[a] = 1;
			fetch_num++;
			a += s;
		}
	}

	last = th->offset_next;
	for (i = 0; i < fetch_len && fetch_num > 0; ++i) {
		last = prev_block(th, binary, sb.st_size, last);
		if (fetch[i]) {
			fetch_block(th, binary, last, i);
			fetch_num--;
		}
	}

	munmap(binary, sb.st_size);
	close(fd);

	return 0;
}
