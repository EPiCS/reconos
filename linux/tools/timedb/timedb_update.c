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
	int fd;
	ssize_t ret;
	struct timedb_hdr th;

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

	close(fd);

	return 0;
}
