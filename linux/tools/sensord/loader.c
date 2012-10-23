/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include "loader.h"
#include "plugin.h"
#include "sensord.h"
#include "xutils.h"

static struct plugin *table[MAX_PLUGINS];
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

void init_loader(void)
{
	int i;
	for (i = 0; i < MAX_PLUGINS; ++i)
		table[i] = NULL;
	count = 0;
}

int plugin_present(const char *so_path)
{
	int i, ret = 0;

	for (i = 0; i < MAX_PLUGINS; ++i) {
		if (!table[i])
			continue;
		if (!strncmp(table[i]->so_path, so_path, strlen(so_path))) {
			ret = 1;
			break;
		}
	}

	return ret;
}

int load_plugin(struct plugin *p)
{
	int ret;
	char *error;

	if (count + 1 > MAX_PLUGINS)
		return -ENOMEM;
	if (!p->basename || !p->so_path)
		return -EINVAL;

	p->sym_fd = dlopen(p->so_path, RTLD_LAZY);
	if (!p->sym_fd) {
		printd("Failed to open shared lib %s!\n", p->so_path);
		return -EIO;
	}

	p->fn_init = dlsym(p->sym_fd, "plugin_init_fn");
	if ((error = dlerror()) != NULL) {
		printd("[%s] %s!\n", p->so_path, error);
		goto err;
	}

	p->fn_exit = dlsym(p->sym_fd, "plugin_exit_fn");
	if ((error = dlerror()) != NULL) {
		printd("[%s] %s\n", p->so_path, error);
		goto err;
	}

	ret = p->fn_init();
	if (ret < 0) {
		printd("[%s] %s\n", p->so_path, strerror(-ret));
		goto err;
	}

	p->slot = get_free_slot();
	table[p->slot] = p;
	count++;

	printd("[%s] loaded on slot %d!\n", p->so_path, p->slot);

	return 0;
err:
	dlclose(p->sym_fd);
	printd("[%s] not loaded!\n", p->so_path);

	return -EIO;
}

void unload_plugin(struct plugin *p)
{
	table[p->slot] = NULL;
	count--;

	p->fn_exit();
	dlclose(p->sym_fd);

	printd("[%s] unloaded!\n", p->so_path);

	xfree(p->so_path);
	xfree(p->basename);
	xfree(p);
}

void unload_all_plugins(void)
{
	int i;
	for (i = 0; i < MAX_PLUGINS; ++i) {
		if (!table[i])
			continue;
		unload_plugin(table[i]);
	}
}
