/*
 *                                                        ____  _____
 *                            ________  _________  ____  / __ \/ ___/
 *                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
 *                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
 *                         /_/   \___/\___/\____/_/ /_/\____//____/
 *
 * ======================================================================
 *
 *   title:        Architecture specific code - Zynq, Linux
 *
 *   project:      ReconOS
 *   author:       Christoph Rüthing, University of Paderborn
 *   description:  Functions needed for ReconOS which are architecure
 *                 specific and are implemented here.
 *
 * ======================================================================
 */


#ifdef RECONOS_ARCH_zynq
#ifdef RECONOS_OS_linux

#include "arch.h"

#include "../../linux/driver/include/reconos.h"

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include "pthread.h"

#define PROC_CONTROL_DEV "/dev/reconos/proc-control"


/* == OSIF related functions ============================================ */

int reconos_osif_open(int num) {
	char dev[25];
	int fd;

	if (num < 0)
		return -1;

	snprintf(dev, 25, "/dev/reconos/osif-%d", num);
	fd = open(dev, O_RDWR);
	if (fd < 0)
		panic("[reconos_core] error while opening osif %d\n", num);

	return fd;
}

uint32_t reconos_osif_read(int fd) {
	uint32_t data;
	int ret;

	ret = read(fd, &data, sizeof(data));
	if (ret < 0)
		panic("[reconos-core] error reading from osif\n");

	return data;
}

void reconos_osif_write(int fd, uint32_t data) {
	int ret;

	ret = write(fd, &data, sizeof(data));
	if (ret < 0)
		panic("[reconos-core] error writing to osif\n");
}

void reconos_osif_close(int fd) {
	close(fd);
}


/* == Proc control related functions ==================================== */

int reconos_proc_control_open() {
	int fd;

	fd = open(PROC_CONTROL_DEV, O_RDWR);
	if (fd < 0)
		panic("[reconos_core] error while opening proc control\n");

	return fd;
}

int reconos_proc_control_get_num_hwts(int fd) {
	int data;

	ioctl(fd, RECONOS_PROC_CONTROL_GET_NUM_HWTS, &data);

	return data;
}

int reconos_proc_control_get_tlb_hits(int fd) {
	int data;

	ioctl(fd, RECONOS_PROC_CONTROL_GET_TLB_HITS, &data);

	return data;
}

int reconos_proc_control_get_tlb_misses(int fd) {
	int data;

	ioctl(fd, RECONOS_PROC_CONTROL_GET_TLB_MISSES, &data);

	return data;
}

uint32_t reconos_proc_control_get_fault_addr(int fd) {
	uint32_t data;

	ioctl(fd, RECONOS_PROC_CONTROL_GET_FAULT_ADDR, &data);

	return data;
}

void reconos_proc_control_clear_page_fault(int fd) {
	ioctl(fd, RECONOS_PROC_CONTROL_CLEAR_PAGE_FAULT, NULL);
}

void reconos_proc_control_set_pgd(int fd) {
	ioctl(fd, RECONOS_PROC_CONTROL_SET_PGD_ADDR, NULL);
}

void reconos_proc_control_sys_reset(int fd) {
	ioctl(fd, RECONOS_PROC_CONTROL_SYS_RESET, NULL);
}

void reconos_proc_control_hwt_reset(int fd, int num, int reset) {
	if (reset)
		ioctl(fd, RECONOS_PROC_CONTROL_SET_HWT_RESET, &num);
	else
		ioctl(fd, RECONOS_PROC_CONTROL_CLEAR_HWT_RESET, &num);
}

void reconos_proc_control_cache_flush(int fd) {
	ioctl(fd, RECONOS_PROC_CONTROL_CACHE_FLUSH, NULL);
}

void reconos_proc_control_close(int fd) {
	close(fd);
}


/* == Reconfiguration related functions ================================= */

int is_configured = 0;
pthread_mutex_t mutex;

inline void init_xdevcfg() {
	if (!is_configured) {
		pthread_mutex_init(&mutex, NULL);
		is_configured = 1;
	}
}

int load_partial_bitstream(uint32_t *bitstream, unsigned int bitstream_length) {
	int fd;
	char d = '1';

	init_xdevcfg();

	//printf("... Programming FPGA with partial bitstream\n");
	//printf("... Bitstream has size of %d bytes and begins with 0x%x 0x%x 0x%x\n", bitstream_length * 4, bitstream[0], bitstream[1], bitstream[2]);

	pthread_mutex_lock(&mutex);

	fd = open("/sys/class/xdevcfg/xdevcfg/device/is_partial_bitstream", O_WRONLY);
	if (!fd) {
		printf("[xdevcfg lib] failed to open\n");
		exit(EXIT_FAILURE);
	}
	write(fd, &d, 1);
	close(fd);

	fd = open("/dev/xdevcfg", O_WRONLY);
	if (!fd) {
		printf("[xdevcfg lib] failed to open\n");
		exit(EXIT_FAILURE);
	}
	write(fd, bitstream, bitstream_length * 4);
	close(fd);

	fd = open("/sys/class/xdevcfg/xdevcfg/device/prog_done", O_RDONLY);
	if (!fd) {
		printf("[xdevcfg lib] failed to open\n");
		exit(EXIT_FAILURE);
	}
	do {
		read(fd, &d, 1);
		//printf("... Waiting for programming to finish, currently reading %c\n", d);
	} while(d != '1');
	close(fd);

	pthread_mutex_unlock(&mutex);

	return 0;
}


/* == Initialization function =========================================== */

void reconos_drv_init() {
	// nothing to do here
}

#endif
#endif
