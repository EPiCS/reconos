#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>

#include "common.h"

#define BUFLEN 512
#define NPACK 10
#define PORT 9930
#define SRV_IP "127.0.0.1"

enum client_state_num {
	STATE_CSUGGEST,
	STATE_CWAIT,
	STATE_CDONE,
};

struct client_state {
	volatile enum server_state_num num;
	enum state_num (*func)(int sock);
};

void die(char *s)
{
	perror(s);
	exit(1);
}

int main(void)
{
	int s, i;
	struct sockaddr_in si_other;
	char buf[BUFLEN];
	socklen_t slen = sizeof(si_other);

	if ((s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0)
		die("socket");

	memset((char *) &si_other, 0, sizeof(si_other));
	si_other.sin_family = AF_INET;
	si_other.sin_port = htons(PORT);

	if (inet_aton(SRV_IP, &si_other.sin_addr)==0) {
		fprintf(stderr, "inet_aton() failed\n");
		exit(1);
	}

	for (i=0; i<NPACK; i++) {
		printf("Sending packet %d\n", i);
		sprintf(buf, "This is packet %d\n", i);

		if (sendto(s, buf, BUFLEN, 0, (struct sockaddr *)& si_other,
			   slen) < 0)
			die("sendto()");
	}

	close(s);
	return 0;
}
