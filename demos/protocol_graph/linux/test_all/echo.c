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
#include <sys/time.h>
#include <linux/netlink.h>
#include <linux/types.h>
#include <linux/if.h>

#include "xt_vlink.h"
#include "xt_fblock.h"

#define BUFFSIZE	63

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


static void printbuff(char buff[BUFFSIZE], int len)
{
	int i;
	for (i = 0; i < len; i++){
		fprintf(stderr, "%02x ", buff[i]);
		if ((i + 1) % 8 == 0){
			fprintf(stderr, "   ");
		}
		if ((i + 1) % 16 == 0){
			fprintf(stderr, "\n");
		}
	}
}


static void preparebuff(char buff[BUFFSIZE], int run)
{
	int i = BUFFSIZE, j = run % BUFFSIZE, l;
	for (l = 0; i-- > 0; ++l) {
		buff[l] = (uint8_t) j;
		j = (j + 1) % BUFFSIZE;
	}
}

int main(void)
{
	int sock, ret, run = 0;
	char buff_sender[BUFFSIZE];
	char buff_receiver[2 * BUFFSIZE];
	char name[FBNAMSIZ];
	int iterations = 41;
	int i = 0;

	sock = socket(27, SOCK_RAW, 0);
	if (sock < 0)
		panic("Cannot create socket!\n");

	ret = ioctl(sock, 35296, name);
	if (ret < 0)
		panic("Cannot do ioctl!\n");

	fprintf(stderr, "our instance: %s\n", name);
	printf("our instance: %s\n", name);
	preparebuff(buff_sender, run++);
	
	for (i = 0; i < iterations; i++) {

		printbuff(buff_sender, sizeof(buff_sender));
	retry_send:
		ret = sendto(sock, buff_sender, sizeof(buff_sender), 0, NULL, 0);
		if (ret == -1){
			perror("sendto");
			fprintf(stderr, "iteration: %d\n", i);
			sleep(25);
			goto retry_send;
		}
		fprintf(stderr, "[echo:]##############waiting######################\n");
	retry_rcv:
		ret = recvfrom(sock, buff_receiver, sizeof(buff_receiver), 0, NULL, 0);
		if (ret == -1){
			perror("recvfrom");
			sleep(5);
			goto retry_rcv;
		}
		fprintf(stderr, "[echo:]##############received new message with len %d######################\n", ret);
		printbuff(buff_receiver, ret);
	}

	close(sock);
	return 0;
}

