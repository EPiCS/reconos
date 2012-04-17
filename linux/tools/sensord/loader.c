/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <syslog.h>
#include <errno.h>
#include <string.h>

#include "loader.h"
#include "atomic.h"

int load_plugin(struct plugin *p)
{
	int ret;
	char *error;

	p->sym_fd = dlopen(p->so_path, RTLD_LAZY);
	if (!p->sym_fd) {
		syslog(LOG_ERR, "Failed to open shared lib %s!\n", p->so_path);
		return -EIO;
	}

	p->fn_init = dlsym(p->sym_fd, "plugin_init_fn");
	if ((error = dlerror()) != NULL) {
		syslog(LOG_ERR, "[%s] %s!\n", p->so_path, error);
		goto err;
	}

	p->fn_exit = dlsym(p->sym_fd, "plugin_exit_fn");
	if ((error = dlerror()) != NULL) {
		syslog(LOG_ERR, "[%s] %s\n", p->so_path, error);
		goto err;
	}

	ret = p->fn_init();
	if (ret < 0) {
		syslog(LOG_ERR, "[%s] %s\n", p->so_path, strerror(-ret));
		goto err;
	}

	p->refcnt = 1;

	syslog(LOG_INFO, "[%s] loaded!\n", p->so_path);
	return 0;
err:
	dlclose(p->sym_fd);
	syslog(LOG_ERR, "[%s] not loaded!\n", p->so_path);
	return -EIO;
}

void unload_plugin(struct plugin *p)
{
	if (p->refcnt != 1) {
		syslog(LOG_INFO, "[%s] still in use!\n", p->so_path);
		return;
	}

	p->fn_exit();
	dlclose(p->sym_fd);

	syslog(LOG_INFO, "[%s] unloaded!\n", p->so_path);
}

void get_plugin(char *basename)
{
}

void put_plugin(char *basename)
{
}
