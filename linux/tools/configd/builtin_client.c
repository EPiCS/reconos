/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/ioctl.h>

int main(void)
{
	int sock, ret;
	char name[512];

	sock = socket(27, SOCK_RAW, 0);
	if (sock < 0) {
		perror("socket");
		exit(1);
	}

	memset(name, 0, sizeof(name));
	ret = ioctl(sock, 35296, name);
	if (ret < 0) {
		perror("ioctl");
		exit(1);
	}

	printf("Socket -> Fblock: %s\n", name);

	close(sock);

	return 0;
}
