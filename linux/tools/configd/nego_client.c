#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/poll.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>

#include "xutils.h"

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
	volatile enum client_state_num num;
	enum state_num (*func)(int sock);
};

int nego_client(void)
{
	int sock, ret, ack, seq;
	struct sockaddr_in si_other;
	char buf[BUFLEN];
	socklen_t slen = sizeof(si_other);
	struct pn_hdr *hdr;
	struct pn_hdr_compose *chdr;
	size_t len;
	struct pollfd fds;

	sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (sock < 0)
		panic("socket");

	memset((char *) &si_other, 0, sizeof(si_other));
	si_other.sin_family = AF_INET;
	si_other.sin_port = htons(PORT);

	ret = inet_aton(SRV_IP, &si_other.sin_addr);
	if (ret == 0) {
		fprintf(stderr, "inet_aton() failed\n");
		exit(1);
	}

	hdr = (struct pn_hdr *) buf;
	hdr->seq = (uint16_t) random();
	hdr->ack = 0;
	hdr->type = TYPE_SUGGEST;
	len = sizeof(*hdr);
	strcpy(buf + sizeof(*hdr), "ch.ethz.csg.dummy,ch.ethz.csg.dummy");
	len += strlen("ch.ethz.csg.dummy,ch.ethz.csg.dummy");
	buf[len] = 0;
	len++;
	strcpy(buf + len, "ch.ethz.csg.blubber,ch.ethz.csg.blubber");
	len += strlen("ch.ethz.csg.blubber,ch.ethz.csg.blubber");
	buf[len] = 0;
	len++;
	ack = hdr->seq;

retry:
	ret = sendto(sock, buf, len, 0, (struct sockaddr *) &si_other, slen);
	if (ret < 0)
		panic("sendto()");

	fds.fd = sock;
	fds.events = POLLIN;

	poll(&fds, 1, 1000 * 15);
	if ((fds.revents & POLLIN) != POLLIN) {
		printf("Timeout! Retry!\n");
		goto retry;
	}

	ret = recvfrom(sock, buf, BUFLEN, 0, NULL, NULL);
	if (ret < sizeof(*hdr) + sizeof(*chdr))
		panic("recvfrom()");

	hdr = (struct pn_hdr *) buf;
	chdr = (struct pn_hdr_compose *) buf + sizeof(*hdr);
	if (ack != hdr->ack)
		panic("Wrong ack number!\n");
	seq = hdr->seq;

	printf("Take %d!\n", chdr->which);

	hdr->type = TYPE_ACK;
	hdr->ack = seq;
	hdr->seq = ack + 1;

	ret = sendto(sock, buf, sizeof(*hdr), 0, (struct sockaddr *) &si_other, slen);
	if (ret < 0)
		panic("sendto()");

	close(sock);
	return 0;
}
