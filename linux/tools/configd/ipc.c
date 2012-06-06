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
#define MAX_PROPS	32

static pthread_t thread;

extern sig_atomic_t sigint;

struct bind_msg {
	char name[FBNAMSIZ];
	enum fblock_props props[MAX_PROPS];
};

static void *ipc_server(void *null)
{
	int sock, ret;
	struct sockaddr_un saddr;
	socklen_t slen;

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
		int csock, i;
		struct sockaddr_un caddr;
		socklen_t clen;
		fd_set socks;
		ssize_t ret;
		struct timeval timeout;
		struct bind_msg bmsg;

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

		ret = read(csock, &bmsg, sizeof(bmsg));
		if (ret != sizeof(bmsg)) {
			printd("Read returned with %s\n", strerror(errno));
			close(csock);
			continue;
		}

		printd("%s wants to have:", bmsg.name);
		for (i = 0; i < MAX_PROPS; ++i) {
			if (bmsg.props[i] != 0)
				printd(" property %u\n", bmsg.props[i]);
		}

		// reconfig bind bmsg.name to iface via setopt
		// select protos from properties, init, and bind

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
