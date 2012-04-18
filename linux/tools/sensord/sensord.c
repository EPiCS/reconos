/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <pthread.h>
#include <dirent.h>
#include <sys/types.h>
#include <syslog.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>

#include "loader.h"
#include "plugin.h"
#include "sensord.h"
#include "xutils.h"

#define MAX_PATH	1024
#define PLUGIN_DIR	"/opt/sensord/plugins/"

static void walk_dir(const char *dir, void (*fn)(const char *))
{
	char name[MAX_PATH];
	struct dirent *dp;
	DIR *dfd;

	dfd = opendir(dir);
	if (!dfd) {
		syslog(LOG_ERR, "Cannot open %s!\n", dir);
		return;
	}

	while ((dp = readdir(dfd)) != NULL) {
		if (!strcmp(dp->d_name, ".") || !strcmp(dp->d_name, ".."))
			continue;

		if (strlen(dir) + strlen(dp->d_name) + 2 > sizeof(name))
			syslog(LOG_ERR, "Name %s %s too long\n", dir,
			       dp->d_name);
		else {
			memset(name, 0, sizeof(name));
			snprintf(name, sizeof(name), "%s%s", dir, dp->d_name);

			fn(name);
		}
	}

	closedir(dfd);
}

static inline char *cut_ending(char *file)
{
	char *ending = strstr(file, ".so");
	if (ending)
		*ending = 0;
	return file;
}

static void load_so_plugin(const char *file)
{
	int ret;
	struct plugin *p;

	if (plugin_present(file))
		return;

	p = xmalloc(sizeof(*p));
	p->so_path = xstrdup(file);
	p->basename = cut_ending(basename(xstrdup(file)));

	ret = load_plugin(p);
	if (ret < 0) {
		syslog(LOG_ERR, "Cannot load plugin: %s!\n", strerror(-ret));
		xfree(p);
	}
}

static void *so_watch_task(void *null)
{
	while (1) {
		walk_dir(PLUGIN_DIR, load_so_plugin);
		sleep(5);
	}

	pthread_exit(NULL);
}

int main(void)
{
	int ret;
	pthread_t twatch;

	init_loader();
	init_plugin();

	openlog("sensord", LOG_PID | LOG_CONS | LOG_NDELAY, LOG_DAEMON);
	syslog(LOG_INFO, "sensord starting ...\n");

	ret = pthread_create(&twatch, NULL, so_watch_task, NULL);
	if (ret < 0) {
		syslog(LOG_ERR, "Thread creation failed!\n");
		die();
	}

	pthread_join(twatch, NULL);

	syslog(LOG_INFO, "sensord halted!\n");
	closelog();
	return 0;
}
