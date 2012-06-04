/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <signal.h>
#include <errno.h>
#include <linux/netlink.h>
#include <linux/types.h>
#include <linux/if.h>

#include "xt_vlink.h"
#include "xt_fblock.h"
#include "xutils.h"
#include "notification.h"

#define PLUGIN_TO_TEST	"linkqual"

static void *buffshared = NULL;

static sig_atomic_t need_reliability = 0, need_reliability_switched = 0;

static void send_netlink(struct lananlmsg *lmsg)
{
	int sock, ret;
	struct sockaddr_nl src_addr, dest_addr;
	struct nlmsghdr *nlh;
	struct iovec iov;
	struct msghdr msg;

	if (unlikely(!lmsg))
		return;

	sock = socket(PF_NETLINK, SOCK_RAW, NETLINK_USERCTL);
	if (unlikely(sock < 0))
		panic("Cannot get NETLINK_USERCTL socket from kernel! "
		      "Modules not loaded?!\n");

	memset(&src_addr, 0, sizeof(src_addr));
	src_addr.nl_family = AF_NETLINK;
	src_addr.nl_pad = 0;
	src_addr.nl_pid = getpid();
	src_addr.nl_groups = 0;

	ret = bind(sock, (struct sockaddr *) &src_addr, sizeof(src_addr));
	if (unlikely(ret))
		panic("Cannot bind socket!\n");

	memset(&dest_addr, 0, sizeof(dest_addr));
	dest_addr.nl_family = AF_NETLINK;
	dest_addr.nl_pad = 0;
	dest_addr.nl_pid = 0;
	dest_addr.nl_groups = 0;

	nlh = xzmalloc(NLMSG_SPACE(sizeof(*lmsg)));
	nlh->nlmsg_len = NLMSG_SPACE(sizeof(*lmsg));
	nlh->nlmsg_pid = getpid();
	nlh->nlmsg_type = USERCTLGRP_CONF;
	nlh->nlmsg_flags = NLM_F_REQUEST;

	memcpy(NLMSG_DATA(nlh), lmsg, sizeof(*lmsg));

	iov.iov_base = nlh;
	iov.iov_len = nlh->nlmsg_len;

	memset(&msg, 0, sizeof(msg));
	msg.msg_name = &dest_addr;
	msg.msg_namelen = sizeof(dest_addr);
	msg.msg_iov = &iov;
	msg.msg_iovlen = 1;

	ret = sendmsg(sock, &msg, 0);
	if (unlikely(ret < 0))
		panic("Cannot send NETLINK message to the kernel!\n");

	close(sock);
	xfree(nlh);
}

static void reconfig_reliability(void)
{
	if (need_reliability == 1 && need_reliability_switched == 1) {
		printf("Need reliability!\n");
		/* ... include reliability */
	} else if (need_reliability == 0 && need_reliability_switched == 1) {
		printf("Don't need reliability!\n");
		/* ... exclude reliability */
	}

	need_reliability_switched = 0;
}

static void upper_threshold_triggered(int num)
{
	if (num != SIGUSR1)
		return;
	if (need_reliability == 1)
		need_reliability_switched = 1;
	need_reliability = 0;
}

static void lower_threshold_triggered(int num)
{
	if (num != SIGUSR2)
		return;
	if (need_reliability == 0)
		need_reliability_switched = 1;
	need_reliability = 1;
}

static void register_threshold(enum threshold_type type, double *cells_thres,
			       uint8_t *cells_active, size_t num)
{
	int sock;
	ssize_t ret;
	char buff[4096];
	struct notfct_hdr *hdr;
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

	memset(buff, 0, sizeof(buff));
	hdr = (struct notfct_hdr *) buff;
	hdr->cmd = type == upper_threshold ?
		   CMD_SET_UPPER_THRES : CMD_SET_LOWER_THRES;
	hdr->proc = getpid();
	strncpy(hdr->plugin_inst, PLUGIN_TO_TEST, sizeof(hdr->plugin_inst));
	memcpy(buff + sizeof(*hdr), cells_thres, sizeof(*cells_thres) * num);
	memcpy(buff + sizeof(*hdr) + sizeof(*cells_thres) * num, cells_active,
	       sizeof(*cells_active) * num);

	ret = write(sock, buff, sizeof(*hdr) + (sizeof(*cells_thres) +
		    sizeof(*cells_active)) * num);
	if (ret <= 0)
		panic("Cannot write to server: %s\n", strerror(errno));

	close(sock);
}

int main(void)
{
	key_t key;
	int shmid;
	double cells_thres[1];
	uint8_t cells_active[1];
	char buff[256];
	struct timeval timeout;

	signal(SIG_THRES_UPPER, upper_threshold_triggered);
	signal(SIG_THRES_LOWER, lower_threshold_triggered);

	cells_thres[0] = 0.5;
	cells_active[0] = 1;
	register_threshold(upper_threshold, cells_thres, cells_active, 1);

	cells_thres[0] = 0.40;
	cells_active[0] = 1;
	register_threshold(lower_threshold, cells_thres, cells_active, 1);

	memset(buff, 0, sizeof(buff));
	snprintf(buff, sizeof(buff), "/tmp/%u", (unsigned int) getpid());

	close(creat(buff, S_IRUSR | S_IWUSR));

	key = ftok(buff, 42);
	if (key < 0)
		panic("ftok error: %s\n", strerror(errno));

	shmid = shmget(key, sizeof(struct shmnot_hdr), 0666 | IPC_CREAT);
	if (shmid < 0)
		panic("shmget error!");

	buffshared = shmat(shmid, NULL, 0);
	if (buffshared == (int *) (-1))
		panic("Cannot attach to segment!");

	while (1) {
		timeout.tv_sec = 0;
		timeout.tv_usec = 100000;

		select(0, NULL, NULL, NULL, &timeout);
		reconfig_reliability();
	}

	shmdt(buffshared);

	return 0;
}
