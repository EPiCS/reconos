/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include "reconfig.h"
#include "notification.h"
#include "xutils.h"
#include "stack.h"

static void setup_cleanup_vlink(int cmd)
{
	int sock, ret, if_num, i;
	struct vlinknlmsg vmsg;
	struct ifconf ifc;
	struct ifreq *ifr;
	char buff[1024];

	sock = socket(AF_INET, SOCK_DGRAM, 0);
	if (sock < 0)
		panic("Cannot create socket!\n");

	ifc.ifc_len = sizeof(buff);
	ifc.ifc_buf = buff;

	ret = ioctl(sock, SIOCGIFCONF, &ifc);
	if (ret < 0)
		panic("Cannot do ioctl!\n");

	ifr = ifc.ifc_req;
	if_num = ifc.ifc_len / sizeof(struct ifreq);

	for (i = 0; i < if_num; ++i) {
		struct ifreq *item = &ifr[i];

		if (!strncmp(item->ifr_name, "lo", strlen(item->ifr_name)))
			continue;

		memset(&vmsg, 0, sizeof(vmsg));
		vmsg.cmd = cmd;
		vmsg.flags = 0;

		strlcpy((char *) vmsg.virt_name, item->ifr_name,
			sizeof(vmsg.virt_name));
		strlcpy((char *) vmsg.real_name, item->ifr_name,
			sizeof(vmsg.real_name));

		send_netlink_vlink(&vmsg);
	}
}

void setup_initial_stack(void)
{
	setup_cleanup_vlink(VLINKNLCMD_START_HOOK_DEVICE);

	printd("Initial stack set up!\n");
}

void cleanup_stack(void)
{
	setup_cleanup_vlink(VLINKNLCMD_STOP_HOOK_DEVICE);

	printd("Stack cleaned up!\n");
}

static sig_atomic_t need_reliability = 0, need_reliability_switched = 0;

static void __reconfig_reliability_check_for_inclusion(void)
{
	/* Walk the stack, and trigger reconfig */
}

static void __reconfig_reliability_check_for_exclusion(void)
{
	/* Walk the stack, and trigger reconfig */
}

void reconfig_notify_reliability(int type)
{
	if (type == SIG_THRES_UPPER) {
		if (need_reliability == 1)
			need_reliability_switched = 1;
		need_reliability = 0;
	} else {
		if (need_reliability == 0)
			need_reliability_switched = 1;
		need_reliability = 1;
	}
}

void reconfig_reliability(void)
{
	if (need_reliability == 1 && need_reliability_switched == 1) {
		printd("Need reliability!\n");
		__reconfig_reliability_check_for_inclusion();
	} else if (need_reliability == 0 && need_reliability_switched == 1) {
		printd("Don't need reliability!\n");
		__reconfig_reliability_check_for_exclusion();
	}

	need_reliability_switched = 0;
}
