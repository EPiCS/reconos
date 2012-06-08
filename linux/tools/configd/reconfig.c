/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <linux/netlink.h>
#include <linux/types.h>
#include <linux/if.h>

#include "reconfig.h"
#include "notification.h"
#include "xutils.h"
#include "xt_vlink.h"
#include "xt_fblock.h"

static uint32_t fbnum = 0; //FIXME

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

		printd("seting up lana for %s\n", item->ifr_name);

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

void insert_elem_to_stack(char *type, char *name, size_t len)
{
	struct lananlmsg lmsg;
	struct lananlmsg_add *msg;

	memset(name, 0, len);
	snprintf(name, len, "fb%u", fbnum++); //FIXME

	memset(&lmsg, 0, sizeof(lmsg));
	lmsg.cmd = NETLINK_USERCTL_CMD_ADD;
	msg = (struct lananlmsg_add *) lmsg.buff;

	strlcpy(msg->name, name, sizeof(msg->name));
	strlcpy(msg->type, type, sizeof(msg->type));

	send_netlink_fbctl(&lmsg);
}

void remove_elem_from_stack(char *name)
{
	struct lananlmsg lmsg;
	struct lananlmsg_rm *msg;

	memset(&lmsg, 0, sizeof(lmsg));
	lmsg.cmd = NETLINK_USERCTL_CMD_RM;
	msg = (struct lananlmsg_rm *) lmsg.buff;

	strlcpy(msg->name, name, sizeof(msg->name));

	send_netlink_fbctl(&lmsg);
}

void bind_elems_in_stack(char *name1, char *name2)
{
	struct lananlmsg lmsg;
	struct lananlmsg_tuple *msg;

	memset(&lmsg, 0, sizeof(lmsg));
	lmsg.cmd = NETLINK_USERCTL_CMD_BIND;
	msg = (struct lananlmsg_tuple *) lmsg.buff;

	strlcpy(msg->name1, name1, sizeof(msg->name1));
	strlcpy(msg->name2, name2, sizeof(msg->name2));

	send_netlink_fbctl(&lmsg);
}

void unbind_elems_in_stack(char *name1, char *name2)
{
	struct lananlmsg lmsg;
	struct lananlmsg_tuple *msg;

	memset(&lmsg, 0, sizeof(lmsg));
	lmsg.cmd = NETLINK_USERCTL_CMD_UNBIND;
	msg = (struct lananlmsg_tuple *) lmsg.buff;

	strlcpy(msg->name1, name1, sizeof(msg->name1));
	strlcpy(msg->name2, name2, sizeof(msg->name2));

	send_netlink_fbctl(&lmsg);
}

void setopt_of_elem_in_stack(char *name, char *opt, size_t len)
{
	struct lananlmsg lmsg;
	struct lananlmsg_set *msg;

	memset(&lmsg, 0, sizeof(lmsg));
	lmsg.cmd = NETLINK_USERCTL_CMD_SET;
	msg = (struct lananlmsg_set *) lmsg.buff;
	strlcpy(msg->name, name, sizeof(msg->name));
	strlcpy(msg->option, opt, sizeof(msg->option));

	send_netlink_fbctl(&lmsg);
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
