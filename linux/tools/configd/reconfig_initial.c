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
#include "props.h"
#include "xt_vlink.h"
#include "xt_fblock.h"

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
		if (!strncmp(item->ifr_name, "wlan0", strlen(item->ifr_name))) //XXX
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
	cleanup_pipeline();
	setup_cleanup_vlink(VLINKNLCMD_STOP_HOOK_DEVICE);

	printd("Stack cleaned up!\n");
}
