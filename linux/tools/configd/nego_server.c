#define _GNU_SOURCE
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/poll.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <fcntl.h>
#include <stdio.h>
#include <pthread.h>
#include <signal.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>

#include "xutils.h"
#include "reconfig.h"
//#define PORT 9930

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

static pthread_t thread;

extern sig_atomic_t sigint;

//XXX hack
static char buff[MAXMSG];
static size_t buff_len;

static enum server_state_num server_swait1(int sock)
{
	struct pollfd fds;
//	char buff[MAXMSG];
	ssize_t ret;
	struct pn_hdr *hdr;

	fds.fd = sock;
	fds.events = POLLIN;

	poll(&fds, 1, -1);
	if ((fds.revents & POLLIN) != POLLIN)
		return STATE_SWAIT1;

//	ret = recvfrom(sock, buff, sizeof(buff), MSG_PEEK, NULL, NULL);
	ret = read(sock, buff, sizeof(buff)); //XXX MSG_PEEK
	if (ret <= 0)
		goto out_purge;
	buff_len = ret; //XXX
	hdr = (struct pn_hdr *) buff;
	if (hdr->type != TYPE_SUGGEST)
		goto out_purge;
	if (ntohs(hdr->ack) != 0 || hdr->seq == 0)
		goto out_purge;

	return STATE_SCOMPOSE;
out_purge:
	//recvfrom(sock, buff, sizeof(buff), 0, NULL, NULL); XXX
	return STATE_SWAIT1;
}

static int process_proposals(uint8_t *str, size_t len)
{
	int i, max, num = 0, pick;
	uint8_t *tmp = str;

	for (i = 0; i < len; ++i) {
		if (tmp[i] == 0)
			num++;
	}
	if (num < 1)
		return -EINVAL;
	max = num;

	printd("Got %d proposals:\n", num);
	do {
		printd("  %s\n", tmp);
		if (--num <= 0)
			break;
		while (*tmp != 0)
			tmp++;
		tmp++;
	} while (tmp < (str + len));

	/* pick a random one */
	srand(time(NULL));
	pick = random() % max;

	return pick;
}

static enum server_state_num server_scompose(int sock)
{
	int ret;
//	char buff[MAXMSG];
	ssize_t len;
	struct pn_hdr *hdr;
	struct pn_hdr_compose *chdr;

//	sacurrlen = sizeof(sacurrent);
//	ret = recvfrom(sock, buff, sizeof(buff), 0,
//		       (struct sockaddr *) &sacurrent, &sacurrlen);
//	ret = read(sock, buff, sizeof(buff));
//	if (ret <= 0 || ret < sizeof(*hdr))
//		return STATE_SWAIT1;

	len = buff_len; //ret;
	hdr = (struct pn_hdr *) buff;
	chdr = (struct pn_hdr_compose *) buff + sizeof(*hdr);

	last_seq_on_server_from_remote = ntohs(hdr->seq);
	last_seq_on_server_from_us = ntohs(hdr->seq) + 1;

	ret = process_proposals((uint8_t *) buff + sizeof(*hdr),
				len - sizeof(*hdr));
	if (ret < 0)
		return STATE_SWAIT1;

	hdr->ack = htons(last_seq_on_server_from_remote);
	hdr->seq = htons(last_seq_on_server_from_us);
	hdr->type = TYPE_COMPOSE;
	chdr->which = ret;

//	ret = sendto(sock, buff, sizeof(*hdr) + sizeof(*chdr), 0,
//		     (struct sockaddr *) &sacurrent, sacurrlen);
	ret = write(sock, buff, sizeof(*hdr) + sizeof(*chdr));
	if (ret <= 0)
		return STATE_SWAIT1;

	return STATE_SWAIT2;
}

static enum server_state_num server_swait2(int sock)
{
	struct pollfd fds;
//	char buff[MAXMSG];
	ssize_t ret;
	struct pn_hdr *hdr;
	struct sockaddr_in sa;
	socklen_t slen = sizeof(sa);

	fds.fd = sock;
	fds.events = POLLIN;

	poll(&fds, 1, 1000 * 10);
	if ((fds.revents & POLLIN) != POLLIN)
		return STATE_SWAIT1;

//	ret = recvfrom(sock, buff, sizeof(buff), MSG_PEEK,
//		       (struct sockaddr *) &sa, &slen);
	ret = read(sock, buff, sizeof(buff)); //XXX: MSG_PEEK
	if (ret <= 0)
		goto out_purge;
	hdr = (struct pn_hdr *) buff;
	if (hdr->type != TYPE_ACK && hdr->type != TYPE_NACK)
		goto out_purge;
	if (ntohs(hdr->ack) != last_seq_on_server_from_us || hdr->seq == 0)
		goto out_purge;
	if (sacurrlen != slen)
		goto out_purge;
	if (memcmp(&sacurrent, &sa, sacurrlen))
		goto out_purge;

	return STATE_SDONE;
out_purge:
	//recvfrom(sock, buff, sizeof(buff), 0, NULL, NULL); XXX
	return STATE_SWAIT1;
}

static enum server_state_num server_sdone(int sock)
{
	char buff[MAXMSG];
	ssize_t ret;
	struct pn_hdr *hdr;
	struct sockaddr_in saother;
//	socklen_t salen;

//	salen = sizeof(saother);
//	ret = recvfrom(sock, buff, sizeof(buff), 0,
//		       (struct sockaddr *) &saother, &salen);
//	ret = read(sock, buff, sizeof(buff));
//	if (ret <= 0)
//		return STATE_SWAIT1;

	hdr = (struct pn_hdr *) buff;
	if (hdr->type == TYPE_NACK)
		return STATE_SWAIT1;

	/* Established! */

	while (!sigint) {
	//	ret = recvfrom(sock, buff, sizeof(buff), MSG_PEEK, NULL, NULL);
		ret = read(sock, buff, sizeof(buff)); // MSG_PEEK XXX
		if (ret <= 0)
			return STATE_SDONE;
		buff_len = ret;
		hdr = (struct pn_hdr *) buff;
		if (hdr->type == TYPE_SUGGEST)
			return STATE_SWAIT1;
	}

	return STATE_SDONE;
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
	while (!sigint) {
		printd("In state: %s\n", state_name[cstate]);
		cstate = state_machine[cstate].func(sock);
	}
}

static void *nego_server(void *fbname)
{
	int sock, ret;
//	struct sockaddr_in same;

//	sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
//	if (sock < 0)
//		panic("socket");

//	memset(&same, 0, sizeof(same));
//	same.sin_family = AF_INET;
//	same.sin_port = htons(PORT);
//	same.sin_addr.s_addr = htonl(INADDR_ANY);

//	ret = bind(sock, (struct sockaddr *) &same, sizeof(same));
//	if (ret < 0)
//		panic("bind");

	sock = open("/dev/lana_re_cfg", O_RDWR);
	if (sock < 0)
		panic("open\n");

	ret = ioctl(sock, -1073477120, fbname);
	if (ret < 0)
		panic("ioctl\n");

	server_state_machine(sock);

	close(sock);
	pthread_exit(0);
}

void start_negotiation_server(char fbname[64])
{
	int ret = pthread_create(&thread, NULL, nego_server, fbname);
	if (ret < 0)
		panic("Cannot create thread!\n");

	printd("Negotiation server started!\n");
}

void stop_negotiation_server(void)
{
	pthread_join(thread, NULL);

	printd("Negotiation server stopped!\n");
}
