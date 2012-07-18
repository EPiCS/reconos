#define _GNU_SOURCE
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/poll.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

#include "common.h"

#define PORT 9930

enum server_state_num {
	STATE_SWAIT1 = 0,
	STATE_SCOMPOSE,
	STATE_SWAIT2,
	STATE_SDONE,
	__STATE_MAX,
};

struct server_state {
	enum server_state_num num;
	enum server_state_num (*func)(int sock);
};

static uint16_t last_seq_on_server_from_remote = 0;
static uint16_t last_seq_on_server_from_us = 0;
static struct sockaddr_in sacurrent;
static socklen_t sacurrlen;

void die(char *s)
{
	perror(s);
	exit(1);
}

static enum server_state_num server_swait1(int sock)
{
	struct pollfd fds;
	char buff[MAXMSG];
	ssize_t ret;
	struct pn_hdr *hdr;

	fds.fd = sock;
	fds.events = POLLIN;

	poll(&fds, 1, -1);
	if ((fds.revents & POLLIN) != POLLIN)
		return STATE_SWAIT1;

	ret = recvfrom(sock, buff, sizeof(buff), MSG_PEEK, NULL, NULL);
	if (ret <= 0)
		goto out_purge;
	hdr = (struct pn_hdr *) buff;
	if (hdr->type != TYPE_SUGGEST)
		goto out_purge;
	if (hdr->ack != 0 || hdr->seq == 0)
		goto out_purge;

	return STATE_SCOMPOSE;
out_purge:
	/* Purge buffer if we can */
	recvfrom(sock, buff, sizeof(buff), 0, NULL, NULL);
	return STATE_SWAIT1;
}

static enum server_state_num server_scompose(int sock)
{
	char buff[MAXMSG];
	ssize_t ret;
	struct pn_hdr *hdr;

	sacurrlen = sizeof(sacurrent);
	ret = recvfrom(sock, buff, sizeof(buff), 0,
		       (struct sockaddr *) &sacurrent, &sacurrlen);
	if (ret <= 0)
		return STATE_SWAIT1;

	hdr = (struct pn_hdr *) buff;
	last_seq_on_server_from_remote = hdr->seq;
	last_seq_on_server_from_us = hdr->seq + 1; //or random

	/* do sth with composition */

	hdr->ack = last_seq_on_server_from_remote;
	hdr->seq = last_seq_on_server_from_us;
	hdr->type = TYPE_COMPOSE;

	ret = sendto(sock, buff, sizeof(buff), 0,
		     (struct sockaddr *) &sacurrent, sacurrlen);
	if (ret <= 0)
		return STATE_SWAIT1;

	return STATE_SWAIT2;
}

static enum server_state_num server_swait2(int sock)
{
	struct pollfd fds;
	char buff[MAXMSG];
	ssize_t ret;
	struct pn_hdr *hdr;
	struct sockaddr_in sa;
	socklen_t slen = sizeof(sa);

	fds.fd = sock;
	fds.events = POLLIN;

	/* 10 sec timeout */
	poll(&fds, 1, 1000 * 10);
	if ((fds.revents & POLLIN) != POLLIN)
		return STATE_SWAIT1;

	ret = recvfrom(sock, buff, sizeof(buff), MSG_PEEK,
		       (struct sockaddr *) &sa, &slen);
	if (ret <= 0)
		goto out_purge;
	hdr = (struct pn_hdr *) buff;
	if (hdr->type != TYPE_ACK && hdr->type != TYPE_NACK)
		goto out_purge;
	if (hdr->ack != last_seq_on_server_from_us || hdr->seq == 0)
		goto out_purge;
	if (sacurrlen != slen)
		goto out_purge;
	if (memcmp(&sacurrent, &sa, sacurrlen))
		goto out_purge;

	return STATE_SDONE;
out_purge:
	/* Purge buffer if we can */
	recvfrom(sock, buff, sizeof(buff), 0, NULL, NULL);
	return STATE_SWAIT1;
}

static enum server_state_num server_sdone(int sock)
{
	char buff[MAXMSG];
	ssize_t ret;
	struct pn_hdr *hdr;
	struct sockaddr_in saother;
	socklen_t salen;

	salen = sizeof(saother);
	ret = recvfrom(sock, buff, sizeof(buff), 0,
		       (struct sockaddr *) &saother, &salen);
	if (ret <= 0)
		return STATE_SWAIT1;

	hdr = (struct pn_hdr *) buff;
	if (hdr->type == TYPE_NACK)
		return STATE_SWAIT1;

	/* callback for data */

	return STATE_SWAIT1;
}

static struct server_state state_machine[__STATE_MAX] = {
	STATE_MAP_SET(STATE_SWAIT1, server_swait1),
	STATE_MAP_SET(STATE_SCOMPOSE, server_scompose),
	STATE_MAP_SET(STATE_SWAIT2, server_swait2),
	STATE_MAP_SET(STATE_SDONE, server_sdone),
};

static char *state_name[__STATE_MAX] = {
	"STATE_SWAIT1",
	"STATE_SCOMPOSE",
	"STATE_SWAIT2",
	"STATE_SDONE",
};

static void server_state_machine(int sock)
{
	enum server_state_num cstate = STATE_SWAIT1;
	while (1) {
		printf("In state: %s\n", state_name[cstate]);
		cstate = state_machine[cstate].func(sock);
	}
}

int main(void)
{
	int sock, ret;
	struct sockaddr_in same;

	sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (sock < 0)
		die("socket");

	memset(&same, 0, sizeof(same));
	same.sin_family = AF_INET;
	same.sin_port = htons(PORT);
	same.sin_addr.s_addr = htonl(INADDR_ANY);

	ret = bind(sock, (struct sockaddr *) &same, sizeof(same));
	if (ret < 0)
		die("bind");

	server_state_machine(sock);

	close(sock);
	return 0;
}
