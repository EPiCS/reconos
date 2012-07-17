#include <sys/socket.h>
#include <sys/un.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <signal.h>
#include <errno.h>
#include <linux/netlink.h>
#include <linux/types.h>
#include <linux/if.h>
#include <syslog.h>

#include "xt_vlink.h"
#include "xt_fblock.h"
#include "xutils.h"
#include "ipc.h"
#include "props.h"
#include "reconfig.h"
#include "notification.h"

#define PLUGIN_TO_TEST	"linkqual"

static void *buffshared = NULL;

sig_atomic_t sigint = 0;

extern int compile_source(char *file, int verbose);

static void sighandler(int num)
{
	sigint = 1;
	printd("SIGINT catched!\n");
}

static void upper_threshold_triggered(int num)
{
	if (num != SIGUSR1)
		return;

	reconfig_notify_reliability(SIG_THRES_UPPER);
	/* ... */
}

static void lower_threshold_triggered(int num)
{
	if (num != SIGUSR2)
		return;

	reconfig_notify_reliability(SIG_THRES_LOWER);
	/* ... */
}

static void register_threshold(enum threshold_type type, double *cells_thres,
			       uint8_t *cells_active, size_t num)
{
	int sock;
	ssize_t ret;
	char buff[4096];
	struct notfct_hdr *hdr;
	struct sockaddr_un saddr;
	socklen_t slen;

	sock = socket(AF_UNIX, SOCK_STREAM, 0);
	if (sock < 0)
		panic("Cannot create socket!\n");

	memset(&saddr, 0, sizeof(saddr));
	saddr.sun_family = AF_UNIX;
	strncpy(saddr.sun_path, SOCK_ADDR, sizeof(saddr.sun_path));

	slen = sizeof(saddr);
	ret = connect(sock, (struct sockaddr *) &saddr, slen);
	if (ret < 0)
		panic("Cannot connect to server!\n");

	memset(buff, 0, sizeof(buff));
	hdr = (struct notfct_hdr *) buff;
	hdr->cmd = type == upper_threshold ?
		   CMD_SET_UPPER_THRES : CMD_SET_LOWER_THRES;
	hdr->proc = getpid();
	strncpy(hdr->plugin_inst, PLUGIN_TO_TEST, sizeof(hdr->plugin_inst));
	memcpy(buff + sizeof(*hdr), cells_thres, sizeof(*cells_thres) * num);
	memcpy(buff + sizeof(*hdr) + sizeof(*cells_thres) * num, cells_active,
	       sizeof(*cells_active) * num);

	ret = write(sock, buff, sizeof(*hdr) + (sizeof(*cells_thres) +
		    sizeof(*cells_active)) * num);
	if (ret <= 0)
		panic("Cannot write to server: %s\n", strerror(errno));

	close(sock);
}

int main(int argc, char **argv)
{
	key_t key;
	int shmid;
	double cells_thres[1];
	uint8_t cells_active[1];
	char buff[256];
	struct timeval timeout;

	if (argc != 2)
		panic("No config file given!\n");

	compile_source(argv[argc - 1], 0);

	check_for_root_maybe_die();

	signal(SIG_THRES_UPPER, upper_threshold_triggered);
	signal(SIG_THRES_LOWER, lower_threshold_triggered);
	signal(SIGINT, sighandler);

	printf("Beware, this is a huge fucked up hack! :-(\n");

	openlog("configd", LOG_PID | LOG_CONS | LOG_NDELAY, LOG_DAEMON);

	cells_thres[0] = 0.5;
	cells_active[0] = 1;
	register_threshold(upper_threshold, cells_thres, cells_active, 1);

	cells_thres[0] = 0.40;
	cells_active[0] = 1;
	register_threshold(lower_threshold, cells_thres, cells_active, 1);

	memset(buff, 0, sizeof(buff));
	snprintf(buff, sizeof(buff), "/tmp/%u", (unsigned int) getpid());

	close(creat(buff, S_IRUSR | S_IWUSR));

	key = ftok(buff, 42);
	if (key < 0)
		panic("ftok error: %s\n", strerror(errno));

	shmid = shmget(key, sizeof(struct shmnot_hdr), 0666 | IPC_CREAT);
	if (shmid < 0)
		panic("shmget error!");

	buffshared = shmat(shmid, NULL, 0);
	if (buffshared == (int *) (-1))
		panic("Cannot attach to segment!");

	setup_initial_stack();
	start_property_fetcher();
	start_ipc_server();

	while (!sigint) {
		timeout.tv_sec = 0;
		timeout.tv_usec = 100000;

		select(0, NULL, NULL, NULL, &timeout);

//		reconfig_reliability();
		/* ... */
	}

	stop_property_fetcher();
	stop_ipc_server();
	cleanup_stack();

	shmdt(buffshared);

	closelog();
	return 0;
}
