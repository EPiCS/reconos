/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <pthread.h>
#include <dirent.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <syslog.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <libgen.h>
#include <sched.h>

#include "loader.h"
#include "plugin.h"
#include "sensord.h"
#include "xutils.h"
#include "notification.h"
#include "sched.h"

static void walk_dir(const char *dir, void (*fn)(const char *))
{
	char name[MAX_PATH];
	struct dirent *dp;
	DIR *dfd;

	dfd = opendir(dir);
	if (!dfd) {
		printd("Cannot open %s!\n", dir);
		return;
	}

	while ((dp = readdir(dfd)) != NULL) {
		if (!strcmp(dp->d_name, ".") || !strcmp(dp->d_name, ".."))
			continue;

		if (strlen(dir) + strlen(dp->d_name) + 2 > sizeof(name))
			printd("Name %s %s too long\n", dir, dp->d_name);
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
		printd("Cannot load plugin: %s!\n", strerror(-ret));
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

static void *af_unix_task(void *null)
{
	int sock, ret;
	struct sockaddr_un saddr;
	socklen_t slen;

	unlink(SOCK_ADDR);
	sock = socket(AF_UNIX, SOCK_STREAM, 0);
	if (sock < 0) {
		printd("Cannot create af_unix socket: %s\n", strerror(errno));
		pthread_exit(NULL);
	}

	memset(&saddr, 0, sizeof(saddr));
	saddr.sun_family = AF_UNIX;
	strncpy(saddr.sun_path, SOCK_ADDR, sizeof(saddr.sun_path));

	slen = sizeof(saddr);
	ret = bind(sock, (struct sockaddr *) &saddr, slen);
	if (ret < 0) {
		printd("Cannot bind af_unix socket: %s\n", strerror(errno));
		goto out;
	}

	ret = listen(sock, 10);
	if (ret < 0) {
		printd("Cannot listen af_unix socket: %s\n", strerror(errno));
		goto out;
	}

	while (1) {
		int csock;
		struct sockaddr_un caddr;
		socklen_t clen;

		memset(&caddr, 0, sizeof(caddr));
		clen = sizeof(caddr);

		csock = accept(sock, (struct sockaddr *) &caddr, &clen);
		printd("New client request!\n");

		while (1) {
			sleep(5);
		}

		close(csock);
	}

out:
	close(sock);
	pthread_exit(NULL);
}

static inline int get_default_sched_policy(void)
{
	return SCHED_FIFO;
}

static inline int get_default_sched_prio(void)
{
	return sched_get_priority_max(get_default_sched_policy());
}

static inline int get_default_proc_prio(void)
{
	return -20;
}

static int set_proc_prio(int priority)
{
	int ret = setpriority(PRIO_PROCESS, getpid(), priority);
	if (ret)
		panic("Can't set nice val to %i!\n", priority);

	return 0;
}

static int set_sched_status(int policy, int priority)
{
	int ret, min_prio, max_prio;
	struct sched_param sp;

	max_prio = sched_get_priority_max(policy);
	min_prio = sched_get_priority_min(policy);

	if (max_prio == -1 || min_prio == -1)
		whine("Cannot determine scheduler prio limits!\n");
	else if (priority < min_prio)
		priority = min_prio;
	else if (priority > max_prio)
		priority = max_prio;

	memset(&sp, 0, sizeof(sp));
	sp.sched_priority = priority;

	ret = sched_setscheduler(getpid(), policy, &sp);
	if (ret) {
		whine("Cannot set scheduler policy!\n");
		return -EINVAL;
	}

	ret = sched_setparam(getpid(), &sp);
	if (ret) {
		whine("Cannot set scheduler prio!\n");
		return -EINVAL;
	}

	return 0;
}

int main(void)
{
	int ret;
	pthread_t twatch;
	pthread_t tserve;

	check_for_root_maybe_die();

	set_proc_prio(get_default_proc_prio());
	set_sched_status(get_default_sched_policy(), get_default_sched_prio());

	init_loader();
	init_plugin();

	openlog("sensord", LOG_PID | LOG_CONS | LOG_NDELAY, LOG_DAEMON);
	printd("sensord starting ...\n");

	sched_init();

	ret = pthread_create(&twatch, NULL, so_watch_task, NULL);
	if (ret < 0) {
		printd("Thread creation failed!\n");
		die();
	}

	ret = pthread_create(&tserve, NULL, af_unix_task, NULL);
	if (ret < 0) {
		printd("Thread creation failed!\n");
		die();
	}


	pthread_join(tserve, NULL);
	pthread_join(twatch, NULL);

	sched_cleanup();

	printd("sensord halted!\n");
	closelog();

	return 0;
}
