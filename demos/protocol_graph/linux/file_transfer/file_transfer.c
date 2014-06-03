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
#define MTU	1500

struct bind_msg {
	char name[FBNAMSIZ];
	char app[FBNAMSIZ];
	char props[MAX_PROPS][10];
	int flags;
};

static int bind_config(struct bind_msg *bmsg)
{
	int sock, rc;
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

	read(sock, &rc, sizeof(rc));

	close(sock);
	return rc;
}


int main(int argc, char **argv)
{
	char msg_buff[MTU];
	FILE *fp;
	int sock, ret, server, tot_len = 0, len;
	char buff[512];
	struct bind_msg *bmsg;

	if (argc == 1)
		panic("Usage: %s <client/server>\n", argv[0]);

	/* open socket for communication */
	sock = socket(27, SOCK_RAW, 0);
	if (sock < 0)
		panic("Cannot create socket!\n");

	/* specify communication properties */
	memset(buff, 0, sizeof(buff));
	bmsg = (struct bind_msg *) buff;

	if (!strcmp("client", argv[1])) {
		server = 0;
		strcpy(bmsg->app, "ftp");
		//strcpy(bmsg->props[0], "reliable");
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

	ret = bind_config(bmsg);
	if (ret < 0)
		panic("Cannot bind configuration!\n");

	/* communication should be established */
	
      	/* open the file for transmission*/
	if (server){
		/* wait for client to be setup */
		printf("press enter when client is running\n");
		getc(stdin);
     		fp = fopen("rfc6921.txt", "r");
      		if (fp == NULL) {
        		printf("I couldn't open file for reading.\n");
         		exit(0);
      		}
   		/* send file */
		while ((len = fread(msg_buff, 1, MTU, fp)) > 0){
			ret = sendto(sock, msg_buff, len, 0, NULL, 0);
			if (ret == -1){
				perror("sendto");
				sleep(1);	
			}
			tot_len += len;
			printf("sent msg\n");
		}
		fprintf(stderr, "sent file, length %d\n", tot_len);
      		fclose(fp);
	} else {
		fp = fopen("copy_rfc6921.txt", "w");
		while (tot_len < 15100){
			ret = recvfrom(sock, msg_buff, MTU, 0, NULL, NULL);
			if (ret < 0) {
				if (errno != 11)
					printf("Error: ret:%d, errno:%d\n", ret, errno);
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
