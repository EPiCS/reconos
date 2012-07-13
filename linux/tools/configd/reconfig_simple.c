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
#include "xutils.h"
#include "xt_vlink.h"
#include "xt_fblock.h"

static uint32_t fbnum = 0; //FIXME

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
