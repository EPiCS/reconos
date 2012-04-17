/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include "sensord.h"

static __init int dummy_init(void)
{
	printf("Hello World!\n");
	return 0;
}

static __exit void dummy_exit(void)
{
	printf("Goodbye World!\n");
}

plugin_init(dummy_init);
plugin_exit(dummy_exit);

PLUGIN_LICENSE("GPL");
PLUGIN_AUTHOR("Daniel Borkmann <daniel.borkmann@tik.ee.ethz.ch>");
PLUGIN_DESC("A simple dummy sensord plugin");
