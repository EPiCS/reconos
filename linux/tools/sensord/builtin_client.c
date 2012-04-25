/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <stdio.h>
#include <stdint.h>
#include <signal.h>

#include "xutils.h"
#include "notification.h"

#define PLUGIN_TO_TEST	"dummy-1"

enum threshold_type {
	upper_threshold,
	lower_threshold,
};

static void upper_threshold_triggered(int num)
{
	if (num != SIGUSR1)
		return;

	printf("ALERT: upper threshold triggered!\n");
}

static void lower_threshold_triggered(int num)
{
	if (num != SIGUSR2)
		return;

	printf("ALERT: lower threshold triggered!\n");
}

static int register_threshold(int sock, enum threshold_type type,
			      double cells_thres[2], uint8_t cells_active[2])
{
	char buff[4096];
	struct notfct_hdr *hdr;

	memset(buff, 0, sizeof(buff));
	hdr = (struct notfct_hdr *) buff;
	hdr->cmd = type == upper_threshold ?
		   CMD_SET_UPPER_THRES : CMD_SET_LOWER_THRES;
	hdr->proc = getpid();
	strncpy(hdr->plugin_inst, PLUGIN_TO_TEST, sizeof(hdr->plugin_inst));
	memcpy(buff + sizeof(*hdr), cells_thres, sizeof(cells_thres));
	memcpy(buff + sizeof(*hdr) + sizeof(cells_thres), cells_active,
	       sizeof(cells_active));

	return write(sock, buff, sizeof(*hdr) + sizeof(cells_thres) +
		     sizeof(cells_active));
}

int main(void)
{
	int sock, ret;
	struct sockaddr_un saddr;
	socklen_t slen;
	double cells_thres[2];
	uint8_t cells_active[2];

	signal(SIGUSR1, upper_threshold_triggered);
	signal(SIGUSR2, lower_threshold_triggered);

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

	printf("Connected!\n");

	cells_thres[0] = 1.0;
	cells_thres[1] = 1.0;
	cells_active[0] = 1;
	cells_active[1] = 1;
	register_threshold(sock, upper_threshold, cells_thres, cells_active);

	cells_thres[0] = 0.0;
	cells_thres[1] = 0.0;
	cells_active[0] = 1;
	cells_active[1] = 1;
	register_threshold(sock, lower_threshold, cells_thres, cells_active);

	printf("Threshold registered!\n");

	close(sock);
	return 0;
}
