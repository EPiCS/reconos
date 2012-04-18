/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <errno.h>
#include <syslog.h>
#include <string.h>

#include "plugin.h"
#include "loader.h"

static struct plugin_instance *table[MAX_PLUGINS] = {0};
static int count = 0;

static int get_free_slot(void)
{
	int i;
	for (i = 0; i < MAX_PLUGINS; ++i) {
		if (table[i] == NULL)
			return i;
	}
	return -ENOMEM;
}

void init_plugin(void)
{
	int i;
	for (i = 0; i < MAX_PLUGINS; ++i)
		table[i] = NULL;
	count = 0;
}

void for_each_plugin(void (*fn)(struct plugin_instance *self))
{
	int i;
	for (i = 0; i < MAX_PLUGINS; ++i) {
		if (!table[i])
			continue;
		fn(table[i]);
	}
}

int register_plugin_instance(struct plugin_instance *pi)
{
	if (!pi->name || !pi->basename || pi->type == TYPE_INVALID ||
	    !pi->fetch || pi->schedule_int == 0)
		return -EINVAL;
	if (count + 1 > MAX_PLUGINS)
		return -ENOMEM;

	pi->slot = get_free_slot();
	table[pi->slot] = pi;
	count++;

	get_plugin(pi->basename);

	/* TODO: add to scheduler */

	syslog(LOG_INFO, "[%s] activated!\n", pi->name);

	return 0;
}

void unregister_plugin_instance(struct plugin_instance *pi)
{
	/* TODO: rm from scheduler */

	table[pi->slot] = NULL;
	count--;

	put_plugin(pi->basename);

	syslog(LOG_INFO, "[%s] deactivated!\n", pi->name);
}
