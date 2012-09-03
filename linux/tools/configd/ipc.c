#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <signal.h>
#include <errno.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <linux/types.h>
#include <linux/netlink.h>
#include <linux/if.h>

#include "xt_vlink.h"
#include "xt_fblock.h"
#include "ipc.h"
#include "xutils.h"
#include "props.h"
#include "reconfig.h"

#define SOCK_ADDR	"/tmp/configdsock"

static pthread_t thread;

extern sig_atomic_t sigint;

struct bind_msg {
	char name[FBNAMSIZ];
	enum fblock_props props[MAX_PROPS];
	int flags;
};

#define lower_fb_name	"eth0"	//XXX

static char srv_name[FBNAMSIZ];

static void ipc_do_configure_client(struct bind_msg *bmsg)
{
	int ret, i;
	char type[TYPNAMSIZ];
	size_t num = 0, orig;

	for (i = 0; i < MAX_PROPS; ++i) {
		if (bmsg->props[i] != 0)
			num++;
	}

	bind_elems_in_stack(lower_fb_name, bmsg->name);
	init_reconfig(bmsg->name, "ch.ethz.csg.pf_lana",
		      lower_fb_name, "ch.ethz.csg.eth");

	if (bmsg->flags == TYPE_SERVER) {
		strlcpy(srv_name, bmsg->name, FBNAMSIZ);
		return;
	}

	orig = num;
	while ((ret = find_type_by_properties(type, bmsg->props, &num)) >= -32) {
		char name[FBNAMSIZ];
		printd("Found match for %s: %s,%d (satisfied %zu of %zu)\n",
		       bmsg->name, type, ret, orig - num, orig);

		insert_and_bind_elem_to_stack(type, name, sizeof(name));
		memset(type, 0, sizeof(type));
		memset(name, 0, sizeof(name));
	}

	if (num > 0) {
		printd("Cannot match requirements! Unable to connect socket!\n");
		//XXX cleanup!
		return;
	}

	setopt_of_elem_in_stack(bmsg->name, "iface=eth0", strlen("iface=eth0")); //XXX

	ret = init_negotiation();
	if (ret < 0) {
		printd("Remote end does not support stack config!\n");
		return;
	}
}

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
		int csock;
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

		ipc_do_configure_client(&bmsg);

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
