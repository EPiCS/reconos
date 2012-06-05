/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <linux/netlink.h>
#include <linux/types.h>
#include <linux/if.h>

#include "xt_vlink.h"
#include "xt_fblock.h"

int main(int argc, char **argv)
{
	int i;
	for (i = 1; i < argc; ++i) {
		int j = atoi(argv[i]);
		if (j < 0 || j >= __MAX_PROP)
			return 0;
		printf("%d -> %s\n", j, fblock_props_to_str[j]);
	}
	return 0;
}
