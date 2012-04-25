/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <stdio.h>
#include <signal.h>

#include "xutils.h"

#define SOCK_ADDR	"sensordsock"

static void upper_threshold_triggered(int num)
{
	if (num != SIGUSR1)
		return;

	printf("ALERT: upper threshold triggered!\n");
}

static void lower_threshold_triggered(int num)
{
	if (num != SIGUSR2)
		return;

	printf("ALERT: lower threshold triggered!\n");
}

int main(void)
{
	int sock, ret;
	struct sockaddr_un saddr;
	socklen_t slen;

	signal(SIGUSR1, upper_threshold_triggered);
	signal(SIGUSR2, lower_threshold_triggered);

	sock = socket(AF_UNIX, SOCK_STREAM, 0);
	if (sock < 0)
		panic("Cannot create socket!\n");

	memset(&saddr, 0, sizeof(saddr));
	saddr.sun_family = AF_UNIX;
	strncpy(saddr.sun_path, SOCK_ADDR, sizeof(saddr.sun_path));

	slen = sizeof(saddr);
	ret = connect(sock, (struct sockaddr *) &saddr, slen);

	printf("Connected!\n");

	close(sock);
	return 0;
}
