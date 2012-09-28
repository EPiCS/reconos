#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdint.h>
#include <sys/ioctl.h>
#include <linux/netlink.h>
#include <linux/types.h>
#include <linux/if.h>

#include "xt_vlink.h"
#include "xt_fblock.h"
#include "xutils.h"

#define SOCK_ADDR	"/tmp/configdsock"

struct bind_msg {
	char name[FBNAMSIZ];
	char app[FBNAMSIZ];
	enum fblock_props props[MAX_PROPS];
	int flags;
};

static int bind_config(struct bind_msg *bmsg)
{
	int sock;
	ssize_t ret;
	struct sockaddr_un saddr;
	socklen_t slen;

	sock = socket(AF_UNIX, SOCK_STREAM, 0);
	if (sock < 0)
		panic("Cannot create socket!\n");

	memset(&saddr, 0, sizeof(saddr));
	saddr.sun_family = AF_UNIX;
	strncpy(saddr.sun_path, SOCK_ADDR, sizeof(saddr.sun_path));

	slen = sizeof(saddr);
	ret = connect(sock, (struct sockaddr *) &saddr, slen);
	if (ret < 0)
		panic("Cannot connect to server!\n");

	ret = write(sock, bmsg, sizeof(*bmsg));
	if (ret <= 0)
		panic("Cannot write to server: %s\n", strerror(errno));

	close(sock);
	return 0;
}

int main(int argc, char **argv)
{
	int sock, ret, i, j, client = -1;
	char buff[512];
	struct bind_msg *bmsg;

	if (argc!=2)
		panic("usage: %s <client|server>\n", argv[0]);

	if (!strncmp("client", argv[1], strlen("client")))
		client = 1;
	else if (!strncmp("server", argv[1], strlen("server")))
		client = 0;
	else
		panic("usage: %s <client|server>\n", argv[0]);

	sock = socket(27, SOCK_RAW, 0);
	if (sock < 0)
		panic("Cannot create socket!\n");

//	sleep(100000);

	memset(buff, 0, sizeof(buff));
	bmsg = (struct bind_msg *) buff;
	if (client) {
		bmsg->props[0] = DUMMY;
		strcpy(bmsg->app, "ping");
		bmsg->flags = TYPE_CLIENT;
	} else {
		strcpy(bmsg->app, "ping");
		bmsg->flags = TYPE_SERVER;
	}

	ret = ioctl(sock, 35296, bmsg->name);
	if (ret < 0)
		panic("Cannot do ioctl!\n");

	ret = bind_config(bmsg);
	if (ret < 0)
		panic("Cannot bind configuration!\n");

	printf("Config bound! Listening ....\n");
	sleep(30);
	memset(buff, 0xff, sizeof(buff));
	while (1) {
		buff[0] = j;
		j++;
		if (client) {
			ret = sendto(sock, buff, 64, 0, NULL, 0);
			printf("Sent %d bytes: ", ret);
			for (i = 0; i < ret; ++i) {
				printf("%2x ", buff[i]);
			}
			printf("\n");
		} else {
			ret = recvfrom(sock, buff, sizeof(buff), 0, NULL, 0);
			if (ret < 0) {
				sleep(1);
				continue;
			}
			printf("Received %d bytes: ", ret);
			for (i = 0; i < ret; ++i) {
				printf("%2x ", buff[i]);
			}
			printf("\n");
		}
		sleep(1);
	}

	close(sock);
	return 0;
}
