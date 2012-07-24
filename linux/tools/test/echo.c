#include <stdio.h>
#include <stdarg.h>
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

#define BUFFSIZ	48

static inline void die(void)
{
	exit(EXIT_FAILURE);
}

static inline void panic(char *msg, ...)
{
	va_list vl;

	va_start(vl, msg);
	vfprintf(stderr, msg, vl);
	va_end(vl);

	fflush(stderr);
	die();
}

static void printbuff(char buff[BUFFSIZ], int in)
{
	int i;
	if (!!in)
		printf("Got: ");
	else
		printf("Put: ");
	for (i = 0; i < BUFFSIZ; ++i)
		printf("%02x ", buff[i]);
	printf("\n");
}

static void preparebuff(char buff[BUFFSIZ], int run)
{
	int i = BUFFSIZ, j = run % BUFFSIZ, l;
	for (l = 0; i-- > 0; ++l) {
		buff[l] = (uint8_t) j;
		j = (j + 1) % BUFFSIZ;
	}
}

int main(void)
{
	int sock, ret, run = 0;
	char buff[BUFFSIZ], orig[BUFFSIZ];
	char name[FBNAMSIZ];

	sock = socket(27, SOCK_RAW, 0);
	if (sock < 0)
		panic("Cannot create socket!\n");

	ret = ioctl(sock, 35296, name);
	if (ret < 0)
		panic("Cannot do ioctl!\n");

	printf("our instance: %s\n", name);

	while (1) {
		preparebuff(buff, run++);
		memcpy(orig, buff, sizeof(buff));

		printbuff(buff, 0);
		sendto(sock, buff, sizeof(buff), 0, NULL, 0);
		recvfrom(sock, buff, sizeof(buff), 0, NULL, 0);
		printbuff(buff, 1);

		if (memcmp(orig, buff, sizeof(orig)))
			printf(" ... is NOT OK!\n");
		else
			printf(" ... is OK!\n");

		memset(buff, 0, sizeof(buff));
		memset(orig, 0, sizeof(orig));
		sleep(1);
	}

	close(sock);
	return 0;
}
