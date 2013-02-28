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

#define BUFFSIZE	128

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
//	if (!!in)
//		printf("Got: ");
//	else
//		printf("Put: ");
	for (i = 0; i < len; i++){
		fprintf(stderr, "%02x ", buff[i]);
		if ((i + 1) % 8 == 0){
			fprintf(stderr, "   ");
		}
		if ((i + 1) % 16 == 0){
			fprintf(stderr, "\n");
		}
	}
//	printf("\n");
}


/*static void compare_buffer(char send[BUFFSIZE], char recv[BUFFSIZE]){
	int j;
	for (j = 0; j < BUFFSIZE; j++){ 
		unsigned char written_val = send[j];
		unsigned char read_val = recv[j];
		fprintf(stderr, "%x %x", written_val, read_val);
		if ((j + 1) % 8 == 0){
			fprintf(stderr,  "    ");
		}
		if ((j + 1) % 16 == 0){
			fprintf(stderr,  "\n");
		}
	}
	fprintf(stderr, "\n");
}
*/

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
	char buff_sender[BUFFSIZE],  buff_receiver[BUFFSIZE], orig[BUFFSIZE];
	char name[FBNAMSIZ];
	int iterations = 10000;
	int i = 0;
	struct timeval start_time, end_time;

	sock = socket(27, SOCK_RAW, 0);
	if (sock < 0)
		panic("Cannot create socket!\n");

	ret = ioctl(sock, 35296, name);
	if (ret < 0)
		panic("Cannot do ioctl!\n");

	fprintf(stderr, "app 2 instance: %s\n", name);
	printf("app 2 instance: %s\n", name);
	
	preparebuff(buff_sender, run++);
	memcpy(orig, buff_sender, sizeof(buff_sender));

	
	for (i = 0; i < iterations; i++) {

	//	fprintf(stderr,"-%d ", run);

	//	preparebuff(buff_sender, run++);
	//	memcpy(orig, buff_sender, sizeof(buff_sender));

	//	printbuff(buff_sender,sizeof(buff_sender));
	retry:
		ret = sendto(sock, buff_sender, sizeof(buff_sender), 0, NULL, 0);
		if (ret == -1){
			perror("sendto");
			fprintf(stderr, "iteration: %d\n", i);
			sleep(15);
			gettimeofday(&start_time, NULL); //first time we fail anyway since the protocol stack is not yet built...
			goto retry;
		}
	/*	ret = recvfrom(sock, buff_receiver, sizeof(buff_receiver), 0, NULL, 0);
		if (ret == -1){
		//	perror("recvfrom");
		//	fprintf(stderr, "recvfrom failed");
		//	sleep(5);
			continue;
		}

	//	printbuff(buff_receiver, 1);
		fprintf(stderr, "received new message with len %d: \n", ret);
		printbuff(buff_receiver, ret);

	//	compare_buffer(buff_sender, buff_receiver);
		
		if (memcmp(buff_sender, buff_receiver, sizeof(buff_sender)))
			fprintf(stderr, " ... is NOT OK!\n");
		else
			fprintf(stderr, " ... is OK!\n");
*/
	//	memset(buff_sender, 0, sizeof(buff_sender));
	//	memset(buff_receiver, 0, sizeof(buff_receiver));
//		sleep(1);
	}

	gettimeofday(&end_time, NULL); 
	int delta = (end_time.tv_sec - start_time.tv_sec)*1000000 + (end_time.tv_usec - start_time.tv_usec);
	printf("\ndone: start_time.tv_sec %d, tv_usec %d, end_time.tv_sec %d, tv_usec %d, delta in usec %d\n", start_time.tv_sec, start_time.tv_usec, end_time.tv_sec, end_time.tv_usec, delta);
	fprintf(stderr, "\n done: start_time.tv_sec %d, tv_usec %d, end_time.tv_sec %d, tv_usec %d, delta in usec %d\n", start_time.tv_sec, start_time.tv_usec, end_time.tv_sec, end_time.tv_usec, delta);
	close(sock);
	return 0;
}
