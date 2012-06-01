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

#define MODULE	"wireless_snr"

int adjust_dbm_level(int in_dbm, int dbm_val)
{
	if (!in_dbm)
		return dbm_val;

	return dbm_val - 0x100;
}

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

static void wireless_snr_fetch(struct plugin_instance *self)
{
	int ret;
	struct iw_statistics ws;
	int signal_level, noise_level;

	memset(&ws, 0, sizeof(ws));

	ret = wireless_sigqual("wlan0", &ws); //FIXME
	if (ret != 0)
		return;

	signal_level = adjust_dbm_level(ws.qual.updated & IW_QUAL_DBM,
					ws.qual.level);

	noise_level = adjust_dbm_level(ws.qual.updated & IW_QUAL_DBM,
				       ws.qual.noise);

	self->cells[0] = (float64_t) (signal_level - noise_level);
}

struct plugin_instance wireless_snr_plugin = {
	.name			=	MODULE,
	.basename		=	MODULE,
	.fetch			=	wireless_snr_fetch,
	.schedule_int		=	TIME_IN_MSEC(200),
	.block_entries		=	1000000,
	.cells_per_block	=	1,
};

static __init int wireless_snr_init(void)
{
	struct plugin_instance *pi = &wireless_snr_plugin;

	pi->cells = malloc(pi->cells_per_block * sizeof(double));
	assert(pi->cells);

	return register_plugin_instance(pi);
}

static __exit void wireless_snr_exit(void)
{
	struct plugin_instance *pi = &wireless_snr_plugin;

	free(pi->cells);
	unregister_plugin_instance(pi);
}

plugin_init(wireless_snr_init);
plugin_exit(wireless_snr_exit);

PLUGIN_LICENSE("GPL");
PLUGIN_AUTHOR("Daniel Borkmann <daniel.borkmann@tik.ee.ethz.ch>");
PLUGIN_DESC("A simple SNR sensord plugin");
