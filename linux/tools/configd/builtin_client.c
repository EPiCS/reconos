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
	int sock, ret, i, server = 0;
	char buff[512];
	struct bind_msg *bmsg;

	if (argc == 1)
		panic("Usage: %s <client/server>\n", argv[0]);

	sock = socket(27, SOCK_RAW, 0);
	if (sock < 0)
		panic("Cannot create socket!\n");

	memset(buff, 0, sizeof(buff));
	bmsg = (struct bind_msg *) buff;

	if (!strcmp("client", argv[1])) {
		server = 0;
		strcpy(bmsg->app, "http");
		bmsg->props[0] = RELIABLE;
		bmsg->flags = TYPE_CLIENT;
		printf("client!\n");
	} else {
		server = 1;
		strcpy(bmsg->app, "http");
		bmsg->flags = TYPE_SERVER;
		printf("server!\n");
	}

	ret = ioctl(sock, 35296, bmsg->name);
	if (ret < 0)
		panic("Cannot do ioctl!\n");

	printf("our instance: %s\n", bmsg->name);
	printf("our requirements: ");
	for (i = 0; i < 2; ++i)
		printf("%s ", fblock_props_to_str[bmsg->props[i]]);
	printf("\n");

	ret = bind_config(bmsg);
	if (ret < 0)
		panic("Cannot bind configuration!\n");

	memset(buff, 0xff, sizeof(buff));
	while (1) {
		if (server) {
			ret = sendto(sock, buff, 64, 0, NULL, 0);
			if (ret < 0) {
				printf("Error: ret:%d, errno:%d\n", ret, errno);
				continue;
			}
			printf("Sent: ");
			for (i = 0; i < 64; ++i)
				printf("%02x ", (uint8_t) buff[i]);
			printf("\n");
			sleep(1);
		} else {
			ret = recvfrom(sock, buff, 64, 0, NULL, NULL);
			if (ret < 0) {
				if (errno != 11)
					printf("Error: ret:%d, errno:%d\n", ret, errno);
				continue;
			}
			printf("Got: ");
			for (i = 0; i < 64; ++i)
				printf("%02x ", (uint8_t) buff[i]);
			printf("\n");
		}
	}

	close(sock);
	return 0;
}
