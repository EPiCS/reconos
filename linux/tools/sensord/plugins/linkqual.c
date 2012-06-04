/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#include <time.h>
#include <errno.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <linux/if.h>
#include <linux/socket.h>
#include <linux/types.h>
#include <linux/wireless.h>

#include "sensord.h"

#define MODULE	"linkqual"

static int wireless_sigqual(const char *ifname, struct iw_statistics *stats)
{
	int ret, sock;
	struct iwreq iwr;

	sock = socket(AF_INET, SOCK_DGRAM, 0);
	if (sock < 0)
		return -EIO;

	memset(&iwr, 0, sizeof(iwr));
	strncpy(iwr.ifr_name, ifname, IFNAMSIZ);
	iwr.u.data.pointer = (caddr_t) stats;
	iwr.u.data.length = sizeof(*stats);
	iwr.u.data.flags = 1;

	ret = ioctl(sock, SIOCGIWSTATS, &iwr);

	close(sock);
	return ret;
}

int wireless_rangemax_sigqual(const char *ifname)
{
	int ret, sock, sigqual;
	struct iwreq iwr;
	struct iw_range iwrange;

	sock = socket(AF_INET, SOCK_DGRAM, 0);
	if (sock < 0)
		return -EIO;

	memset(&iwrange, 0, sizeof(iwrange));
	memset(&iwr, 0, sizeof(iwr));
	strncpy(iwr.ifr_name, ifname, IFNAMSIZ);
	iwr.u.data.pointer = (caddr_t) &iwrange;
	iwr.u.data.length = sizeof(iwrange);
	iwr.u.data.flags = 0;

	ret = ioctl(sock, SIOCGIWRANGE, &iwr);
	if (!ret)
		sigqual = iwrange.max_qual.qual;
	else
		sigqual = 0;

	close(sock);
	return sigqual;
}

static void wireless_linkqual_fetch(struct plugin_instance *self)
{
	int ret;
	struct iw_statistics ws;
	int wifi_link_qual, wifi_link_qual_max;
	char *ifname = "wlan0"; //FIXME

	memset(&ws, 0, sizeof(ws));

	ret = wireless_sigqual(ifname, &ws);
	if (ret != 0)
		return;

	wifi_link_qual = ws.qual.qual;
	wifi_link_qual_max = wireless_rangemax_sigqual(ifname);

	self->cells[0] = (float64_t) wifi_link_qual / wifi_link_qual_max;
}

struct plugin_instance wireless_linkqual_plugin = {
	.name			=	MODULE,
	.basename		=	MODULE,
	.fetch			=	wireless_linkqual_fetch,
	.schedule_int		=	TIME_IN_MSEC(200),
	.block_entries		=	1000000,
	.cells_per_block	=	1,
};

static __init int wireless_linkqual_init(void)
{
	struct plugin_instance *pi = &wireless_linkqual_plugin;

	pi->cells = malloc(pi->cells_per_block * sizeof(double));
	assert(pi->cells);

	return register_plugin_instance(pi);
}

static __exit void wireless_linkqual_exit(void)
{
	struct plugin_instance *pi = &wireless_linkqual_plugin;

	free(pi->cells);
	unregister_plugin_instance(pi);
}

plugin_init(wireless_linkqual_init);
plugin_exit(wireless_linkqual_exit);

PLUGIN_LICENSE("GPL");
PLUGIN_AUTHOR("Daniel Borkmann <daniel.borkmann@tik.ee.ethz.ch>");
PLUGIN_DESC("A simple Wifi LinkQual sensord plugin");
