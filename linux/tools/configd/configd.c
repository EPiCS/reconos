/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <sys/types.h>
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

#include "xutils.h"
#include "notification.h"

#define PLUGIN_TO_TEST	"wireless_snr"

static void *buffshared = NULL;

static sig_atomic_t need_reliability = 0;

static void upper_threshold_triggered(int num)
{
	struct shmnot_hdr *s = buffshared;

	if (num != SIGUSR1)
		return;

	printf("ALERT: upper threshold triggered on %s (%lf, %d)!\n",
	       s->plugin_inst, s->val, s->cell_num);
}

static void lower_threshold_triggered(int num)
{
	struct shmnot_hdr *s = buffshared;

	if (num != SIGUSR2)
		return;

	printf("ALERT: lower threshold triggered on %s (%lf, %d)!\n",
	       s->plugin_inst, s->val, s->cell_num);
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

int main(void)
{
	key_t key;
	int shmid;
	double cells_thres[2], cells[2];
	uint8_t cells_active[2];
	char buff[256];

	signal(SIG_THRES_UPPER, upper_threshold_triggered);
	signal(SIG_THRES_LOWER, lower_threshold_triggered);

	cells_thres[0] = 0.95;
	cells_thres[1] = 0.95;
	cells_active[0] = 1;
	cells_active[1] = 1;
	register_threshold(upper_threshold, cells_thres, cells_active, 2);

	cells_thres[0] = 0.05;
	cells_thres[1] = 0.05;
	cells_active[0] = 1;
	cells_active[1] = 1;
	register_threshold(lower_threshold, cells_thres, cells_active, 2);

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

	while (1) {
		sleep(5);
	}

	shmdt(buffshared);

	return 0;
}
