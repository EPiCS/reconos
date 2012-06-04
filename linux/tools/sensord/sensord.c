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
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <syslog.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <libgen.h>
#include <sched.h>
#include <signal.h>

#include "loader.h"
#include "plugin.h"
#include "sensord.h"
#include "storage.h"
#include "xutils.h"
#include "notification.h"
#include "sched.h"
#include "timedb.h"

sig_atomic_t sigint = 0;

static void sighandler(int num)
{
	sigint = 1;
	printd("SIGINT catched!\n");
}

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
	char *foo, *bar;

	if (plugin_present(file))
		return;

	p = xmalloc(sizeof(*p));
	p->so_path = xstrdup(file);
	bar = cut_ending(basename((foo = xstrdup(file))));
	p->basename = xstrdup(bar);
	xfree(foo);

	ret = load_plugin(p);
	if (ret < 0) {
		printd("Cannot load plugin: %s!\n", strerror(-ret));
		xfree(p);
	}
}

static void *so_watch_task(void *null)
{
	while (likely(!sigint)) {
		walk_dir(PLUGIN_DIR, load_so_plugin);
		sleep(5);
	}

	printd("So-watch thread shut down\n");
	pthread_exit(NULL);
}

static void create_shmem_maybe(struct event_block *block, pid_t pid)
{
	char buff[256];
	key_t key;

	memset(buff, 0, sizeof(buff));
	snprintf(buff, sizeof(buff), "/tmp/%u", (unsigned int) pid);

	close(creat(buff, S_IRUSR | S_IWUSR));

	key = ftok(buff, 42);
	if (key < 0)
		panic("Cannot generate key for %s!\n", buff);

	block->shmid = shmget(key, sizeof(struct shmnot_hdr), 0600 | IPC_CREAT);
	if (block->shmid < 0)
		panic("Cannot get an shm descriptor!\n");

	block->shmem = shmat(block->shmid, NULL, 0);
	if (block->shmem == (int *) (-1))
		panic("Cannot attach to segment!\n");

	printd("shared mem created on %s\n", buff);
}

static void destroy_shmem(struct event_block *block, pid_t pid)
{
	char buff[256];

	memset(buff, 0, sizeof(buff));
	snprintf(buff, sizeof(buff), "/tmp/%u", (unsigned int) pid);

	shmdt(block->shmem);
	shmctl(block->shmid, IPC_RMID, 0);

	if (unlink(buff) == 0)
		printd("shared mem destroyed on %s\n", buff);
}

static void af_unix_task_do_set_thres(uint8_t *request, size_t len,
				      enum threshold_type type)
{
	size_t cells_len, cells_alen;
	struct notfct_hdr *hdr;
	struct plugin_instance *pi;
	struct event_block *block, *found;

	hdr = (struct notfct_hdr *) request;
	hdr->plugin_inst[sizeof(hdr->plugin_inst) - 1] = 0;

	pi = get_plugin_by_name(hdr->plugin_inst);
	if (!pi) {
		printd("No such plugin instance!\n");
		return;
	}

	cells_len = pi->cells_per_block * sizeof(uint64_t);
	cells_alen = pi->cells_per_block * sizeof(uint8_t);

	block = xmalloc(sizeof(*block));
	memset(block, 0, sizeof(*block));
	block->next = NULL;
	block->proc = hdr->proc;
	block->prio = PRIO_MEDIUM;
	block->type = type;
	block->cells_thres = xmemdup(request + sizeof(*hdr), cells_len);
	block->cells_active = xmemdup(request + sizeof(*hdr) + cells_len,
				      cells_alen);

	found = get_block_by_pid(&pi->pid_notifier.head, block->proc);
	if (found) {
		block->shmid = found->shmid;
		block->shmem = found->shmem;
	} else {
		create_shmem_maybe(block, hdr->proc);
	}

	register_event_hook(&pi->pid_notifier.head, block);
}

static void af_unix_task_do_unset_thres(uint8_t *request, size_t len)
{
	int first = 1;
	struct notfct_hdr *hdr;
	struct event_block *found = NULL, *block = NULL;
	struct plugin_instance *pi;

	hdr = (struct notfct_hdr *) request;
	hdr->plugin_inst[sizeof(hdr->plugin_inst) - 1] = 0;

	pi = get_plugin_by_name(hdr->plugin_inst);
	if (!pi) {
		printd("No such plugin instance!\n");
		return;
	}

	while ((found = get_block_by_pid(&pi->pid_notifier.head, hdr->proc))) {
		unregister_event_hook(&pi->pid_notifier.head, found);

		if (first) {
			block = found;
			first = 0;
		} else
			xfree(found);
	}

	if (block) {
		destroy_shmem(block, hdr->proc);
		xfree(block);
	}
}

static void af_unix_task_do_get_value(int sock, uint8_t *request, size_t len)
{
	ssize_t ret;
	size_t cells_len;
	struct notfct_hdr *hdr;
	struct plugin_instance *pi;
	int64_t offset;
	float64_t *cells;

	hdr = (struct notfct_hdr *) request;
	hdr->plugin_inst[sizeof(hdr->plugin_inst) - 1] = 0;

	pi = get_plugin_by_name(hdr->plugin_inst);
	if (!pi) {
		printd("No such plugin instance!\n");
		return;
	}

	memcpy(&offset, request + sizeof(*hdr), sizeof(offset));

	cells_len = pi->cells_per_block * sizeof(uint64_t);
	cells = xmalloc(cells_len);

	storage_get_block(pi, offset, cells, pi->cells_per_block);

	ret = write(sock, cells, cells_len);
	xfree(cells);
}

static void *af_unix_task(void *null)
{
	int sock, ret;
	struct sockaddr_un saddr;
	socklen_t slen;
	uint8_t buff[4096];

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

	while (likely(!sigint)) {
		int csock;
		struct sockaddr_un caddr;
		struct notfct_hdr *hdr;
		socklen_t clen;
		fd_set socks;
		ssize_t ret;
		struct timeval timeout;

		memset(&caddr, 0, sizeof(caddr));
		clen = sizeof(caddr);

		timeout.tv_sec = 1;
		timeout.tv_usec = 0;

		FD_ZERO(&socks);
		FD_SET(sock, &socks);

		select(sock + 1, &socks, NULL, NULL, &timeout);
		if (sigint)
			break;
		if (!FD_ISSET(sock, &socks))
			continue;

		csock = accept(sock, (struct sockaddr *) &caddr, &clen);
		if (csock < 0) {
			printd("Cannot accept client: %s\n", strerror(errno));
			continue;
		}

		ret = read(csock, buff, sizeof(buff));
		if (ret <= 0) {
			printd("Read returned with %s\n", strerror(errno));
			close(csock);
			continue;
		}

		hdr = (struct notfct_hdr *) buff;
		switch (hdr->cmd) {
		case CMD_SET_UPPER_THRES:
			af_unix_task_do_set_thres(buff, ret, upper_threshold);
			break;
		case CMD_SET_LOWER_THRES:
			af_unix_task_do_set_thres(buff, ret, lower_threshold);
			break;
		case CMD_GET_VALUE:
			af_unix_task_do_get_value(csock, buff, ret);
			break;
		case CMD_SET_UNDO_THRES:
			af_unix_task_do_unset_thres(buff, ret);
			break;
		default:
			close(csock);
			continue;
		}

		close(csock);
	}

out:
	printd("IPC thread shut down\n");
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

static void batch_remove_event_list(struct plugin_instance *pi)
{
	struct event_block *block = pi->pid_notifier.head;

	while (unregister_event_hook(&pi->pid_notifier.head,
				     block) == 0) {
		destroy_shmem(block, block->proc);
		xfree(block);
		block = pi->pid_notifier.head;
	}
}

static void system_cleanup(void)
{
	sched_remove_all_tasks();
	for_each_plugin(batch_remove_event_list);
	unload_all_plugins();
}

int main(void)
{
	int ret;
	pthread_t twatch;
	pthread_t tserve;

	check_for_root_maybe_die();

	signal(SIGINT, sighandler);

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
	system_cleanup();

	printd("sensord halted!\n");
	closelog();

	return 0;
}
