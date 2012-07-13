/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

//XXX everything here is a rough hack!

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

void insert_and_bind_elem_to_stack(char *type, int prio, char *name, size_t len)
{
	int first = 1, sprio, i, upper_idx = 0, lower_idx = 0;
	FILE *fp;
	char fb_pipeline[64][FBNAMSIZ];
	char buff[1024], *ptr, tname[FBNAMSIZ];

	insert_elem_to_stack(type, name, len);

	/* XXX We assume we're the only app in the stack!
	 * Needs to be fixed later. Extremly lame approach here! */

	fp = fopen("/proc/net/lana/fblocks", "r");
	if (!fp)
		panic("LANA not running?\n");

	memset(fb_pipeline, 0, sizeof(fb_pipeline));
	memset(buff, 0, sizeof(buff));

	while (fgets(buff, sizeof(buff), fp) != NULL) {
		buff[sizeof(buff) - 1] = 0;
		if (first) {
			first = 0;
			continue;
		}

		memset(tname, 0, sizeof(tname));
		if (sscanf(buff, "%s %*s", tname) != 1)
			continue;
		ptr = &buff[strlen(buff) - 1];
		while (*ptr != ' ')
			ptr--;
		if (*ptr == ' ')
			ptr++;
		else
			panic("Ahhhhh!\n");
		sprio = atoi(ptr);
		strlcpy(fb_pipeline[sprio], tname, sizeof(tname));

		memset(buff, 0, sizeof(buff));
	}

	fclose(fp);

	memset(fb_pipeline[prio], 0, sizeof(fb_pipeline[prio]));
	for (i = prio; i < 64; ++i) {
		if (strlen(fb_pipeline[i]) > 0) {
			upper_idx = i;
			break;
		}
	}

	for (i = prio; i >= 0; --i) {
		if (strlen(fb_pipeline[i]) > 0) {
			lower_idx = i;
			break;
		}
	}

	printd("Breaking up %s -> %s for inclusion of %s!\n",
	       fb_pipeline[upper_idx], fb_pipeline[lower_idx], name);

	unbind_elems_in_stack(fb_pipeline[lower_idx], fb_pipeline[upper_idx]);
	bind_elems_in_stack(fb_pipeline[lower_idx], name);
	bind_elems_in_stack(name, fb_pipeline[upper_idx]);
}

void remove_and_unbind_elem_from_stack(char *name, size_t len)
{
	int first = 1, sprio, i, upper_idx = 0, lower_idx = 0, we = -1, prio;
	FILE *fp;
	char fb_pipeline[64][FBNAMSIZ];
	char buff[1024], *ptr, tname[FBNAMSIZ];

	/* XXX We assume we're the only app in the stack!
	 * Needs to be fixed later. Extremly lame approach here! */

	fp = fopen("/proc/net/lana/fblocks", "r");
	if (!fp)
		panic("LANA not running?\n");

	memset(fb_pipeline, 0, sizeof(fb_pipeline));
	memset(buff, 0, sizeof(buff));

	while (fgets(buff, sizeof(buff), fp) != NULL) {
		buff[sizeof(buff) - 1] = 0;
		if (first) {
			first = 0;
			continue;
		}

		memset(tname, 0, sizeof(tname));
		if (sscanf(buff, "%s %*s", tname) != 1)
			continue;
		ptr = &buff[strlen(buff) - 1];
		while (*ptr != ' ')
			ptr--;
		if (*ptr == ' ')
			ptr++;
		else
			panic("Ahhhhh!\n");
		sprio = atoi(ptr);
		strlcpy(fb_pipeline[sprio], tname, sizeof(tname));

		if (!strncmp(fb_pipeline[sprio], name, len))
			we = sprio;

		memset(buff, 0, sizeof(buff));
	}

	fclose(fp);
	prio = we;
	if (prio < 0)
		return;

	memset(fb_pipeline[prio], 0, sizeof(fb_pipeline[prio]));
	for (i = prio; i < 64; ++i) {
		if (strlen(fb_pipeline[i]) > 0) {
			upper_idx = i;
			break;
		}
	}

	for (i = prio; i >= 0; --i) {
		if (strlen(fb_pipeline[i]) > 0) {
			lower_idx = i;
			break;
		}
	}

	printd("Breaking up %s -> %s -> %s for removal of %s!\n",
	       fb_pipeline[upper_idx], name, fb_pipeline[lower_idx], name);

	unbind_elems_in_stack(fb_pipeline[lower_idx], name);
	unbind_elems_in_stack(name, fb_pipeline[upper_idx]);
	bind_elems_in_stack(fb_pipeline[lower_idx], fb_pipeline[upper_idx]);

	remove_elem_from_stack(name);
}
