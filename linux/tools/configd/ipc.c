/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <signal.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>

#include "ipc.h"
#include "xutils.h"

#define SOCK_ADDR	"/tmp/configdsock"

static pthread_t thread;

extern sig_atomic_t sigint;

static void *ipc_server(void *null)
{
	int sock, ret;
	struct sockaddr_un saddr;
	socklen_t slen;
	uint8_t buff[4096];

	unlink(SOCK_ADDR);
	sock = socket(AF_UNIX, SOCK_STREAM, 0);
	if (sock < 0) {
		printd("Cannot create af_unix socket: %s\n", strerror(errno));
		pthread_exit(NULL);
	}

	memset(&saddr, 0, sizeof(saddr));
	saddr.sun_family = AF_UNIX;
	strncpy(saddr.sun_path, SOCK_ADDR, sizeof(saddr.sun_path));

	slen = sizeof(saddr);
	ret = bind(sock, (struct sockaddr *) &saddr, slen);
	if (ret < 0) {
		printd("Cannot bind af_unix socket: %s\n", strerror(errno));
		goto out;
	}

	ret = listen(sock, 10);
	if (ret < 0) {
		printd("Cannot listen af_unix socket: %s\n", strerror(errno));
		goto out;
	}

	while (!sigint) {
		int csock;
		struct sockaddr_un caddr;
		socklen_t clen;
		fd_set socks;
		ssize_t ret;
		struct timeval timeout;

		memset(&caddr, 0, sizeof(caddr));
		clen = sizeof(caddr);

		timeout.tv_sec = 1;
		timeout.tv_usec = 0;

		FD_ZERO(&socks);
		FD_SET(sock, &socks);

		select(sock + 1, &socks, NULL, NULL, &timeout);
		if (sigint)
			break;
		if (!FD_ISSET(sock, &socks))
			continue;

		csock = accept(sock, (struct sockaddr *) &caddr, &clen);
		if (csock < 0) {
			printd("Cannot accept client: %s\n", strerror(errno));
			continue;
		}

		ret = read(csock, buff, sizeof(buff));
		if (ret <= 0) {
			printd("Read returned with %s\n", strerror(errno));
			close(csock);
			continue;
		}

		close(csock);
	}

out:
	printd("IPC thread shut down\n");
	close(sock);
	pthread_exit(NULL);
}

void start_ipc_server(void)
{
	int ret = pthread_create(&thread, NULL, ipc_server, NULL);
	if (ret < 0)
		panic("Cannot create thread!\n");

	printd("IPC server started!\n");
}

void stop_ipc_server(void)
{
	pthread_join(thread, NULL);

	printd("IPC server stopped!\n");
}
