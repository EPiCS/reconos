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

#define SOCK_ADDR "/tmp/configdsock"
#define MAX_PROPS 32
//#define MTU	65
#define MTU	1499
//#define MTU     512


int main(int argc, char **argv)
{
	char msg_buff[MTU];
	char name[FBNAMSIZ];
	FILE *fp;
	int sock, ret, server, tot_len = 0, len;
	char buff[512];
	int cur_len = 64;

	if (argc == 1)
		panic("Usage: %s <client/server>\n", argv[0]);

	/* open socket for communication */
	sock = socket(27, SOCK_RAW, 0);
	if (sock < 0)
		panic("Cannot create socket!\n");

	/* specify communication properties */
	memset(buff, 0, sizeof(buff));

	if (!strcmp("client", argv[1])) {
		server = 0;
		printf("client!\n");
	} else {
		server = 1;
		printf("server!\n");
	}

	ret = ioctl(sock, 35296, name);
	if (ret < 0)
		panic("Cannot do ioctl!\n");
	printf("our instance: %s\n", name);
	fprintf(stderr, "our instance: %s\n", name);
	/* communication should be established */
	memset(msg_buff, 0xfe, MTU);	
      	/* open the file for transmission*/
	if (server){
		/* wait for client to be setup */
		sleep(30);
     		fp = fopen("rfc6921.txt", "r");
      		if (fp == NULL) {
        		printf("I couldn't open file for reading.\n");
         		exit(0);
      		}
   		/* send file */
	//	while ((len = fread(msg_buff, 1, cur_len, fp)) > 0){
		while(cur_len <= MTU){
			fprintf(stderr, "-+-+-+-+-+read %d\n", cur_len);
			printf("-+-+-+-+-+read %d\n", cur_len);
			ret = sendto(sock, msg_buff, cur_len, 0, NULL, 0);
			if (ret == -1){
				perror("sendto");
				sleep(2);	
			}
			cur_len++;

			tot_len += cur_len;
			//printf("sent msg\n");
			sleep(1);
		}
		fprintf(stderr, "sent file, length %d\n", tot_len);
      		fclose(fp);
	} else {
		printf("open file\n");
		fprintf(stderr, "open file\n");
		fp = fopen("copy_rfc6921.txt", "w");
		while (tot_len < 15100){
			ret = recvfrom(sock, msg_buff, MTU, 0, NULL, NULL);
			perror("recvfrom");			
			if (ret < 0) {
				if (errno != 11)
					printf("Error: ret:%d, errno:%d\n", ret, errno);
				sleep(5);
				continue;
			}
			fwrite(msg_buff, 1, ret, fp);
			printf("received msg \n");
			/* hack for now to detect EOF */
			tot_len += ret;
		}
		printf("file received completely\n");	
		fclose(fp);
	}

   	close(sock);
	fprintf(stderr, "done");
	return 0;
}
