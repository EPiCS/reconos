/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <asm/unistd.h>

#include "timedb.h"
#include "xutils.h"
#include "storage.h"
#include "plugin.h"
#include "sensord.h"

#define IOPRIO_CLASS_SHIFT      13

enum {
	ioprio_class_none,
	ioprio_class_rt,
	ioprio_class_be,
	ioprio_class_idle,
};

enum {
	ioprio_who_process = 1,
	ioprio_who_pgrp,
	ioprio_who_user,
};

static const char *const to_prio[] = {
	"none", "realtime", "best-effort", "idle", };

static inline int ioprio_set(int which, int who, int ioprio)
{
	return syscall(SYS_ioprio_set, which, who, ioprio);
}

static void ioprio_setpid(pid_t pid, int ioprio, int ioclass)
{
	int ret = ioprio_set(ioprio_who_process, pid,
			     ioprio | ioclass << IOPRIO_CLASS_SHIFT);
	if (ret < 0)
		panic("Failed to set io prio for pid!\n");
}

static int ioprio_set_flag = 0;

static int storage_create_db(char *path, uint64_t interval, uint64_t tot_blocks,
			     uint16_t cells)
{
	int fd, dummy = 0;
	ssize_t ret;
	struct timedb_hdr th;

	if (interval == 0 || tot_blocks == 0 || cells == 0) {
		printd("Invalid argument for creating timedb!\n");
		return -EINVAL;
	}

	timedb_fill_hdr(&th, interval, tot_blocks, cells);

	fd = open(path, O_CREAT | O_RDWR | O_TRUNC, S_IRUSR | S_IWUSR);
	if (fd < 0) {
		printf("Cannot open file: %s!\n", strerror(errno));
		return -EINVAL;
	}

	ret = write(fd, &th, sizeof(th));
	if (ret != sizeof(th)) {
		printf("Cannot write to file: %s!\n", strerror(errno));
		return -EINVAL;
	}

	lseek(fd, th.block_entries * th.cells_per_block * sizeof(uint64_t) - 1,
	      SEEK_CUR);

	ret = write(fd, &dummy, 1);
	if (ret != 1) {
		printf("Cannot write to file: %s!\n", strerror(errno));
		return -EINVAL;
	}

	return fd;
}

void storage_register_task(struct plugin_instance *p)
{
	int fd;
	char name[256];

	memset(name, 0, sizeof(name));
	snprintf(name, sizeof(name), "%s%s", DATABASE_DIR, p->name);

	fd = open(name, O_RDWR);
	if (fd < 0) {
		fd = storage_create_db(name, p->schedule_int, p->block_entries,
				       p->cells_per_block);
		if (fd < 0)
			panic("Cannot create database!\n");
		printd("timedb database %s created!\n", name);
	}

	p->timedb_fd = fd;

	if (!ioprio_set_flag) {
		ioprio_setpid(getpid(), 4, ioprio_class_rt);
		ioprio_set_flag = 1;
	}
}

void storage_unregister_task(struct plugin_instance *p)
{
	fsync(p->timedb_fd);
	close(p->timedb_fd);
}

static uint64_t prev_block(struct timedb_hdr *th, uint8_t *binary, size_t max,
			   uint64_t curr)
{
	uint64_t before;

	if (curr == sizeof(*th)) {
		before = max - sizeof(uint64_t) * th->cells_per_block;
	} else {
		before = curr - sizeof(uint64_t) * th->cells_per_block;
	}

	return before;
}

void storage_get_block(struct plugin_instance *p, int64_t off,
		       float64_t *cells, size_t len)
{
	int i, j;
	ssize_t ret;
	struct stat sb;
	struct timedb_hdr *th;
	uint8_t *binary;
	uint64_t last;

	ret = fstat(p->timedb_fd, &sb);
	if (ret < 0) {
		printd("Cannot fstat the database!\n");
		return;
	}

	binary = mmap(0, sb.st_size, PROT_READ, MAP_SHARED, p->timedb_fd, 0);
	if (binary == MAP_FAILED) {
		printd("Error mmaping db: %s\n", strerror(errno));
		return;
	}

	th = (struct timedb_hdr *) binary;

	last = th->offset_next;
	for (i = 0; i < th->block_entries; ++i) {
		//FIXME: do it more efficient
		last = prev_block(th, binary, sb.st_size, last);
		if (i == off) {
			for (j = 0; j < len; ++j)
				cells[j] = block_to_data_off(binary +last, j);
			break;
		}
	}

	munmap(binary, sb.st_size);
}

void storage_update_task(struct plugin_instance *p, double *cells, size_t len)
{
	int i;
	uint8_t *block;
	ssize_t ret;
	size_t block_len;
	struct timedb_hdr th;
	struct timedb_block *tb;
	uint64_t off_curr, bnum;

	lseek(p->timedb_fd, 0, SEEK_SET);

	ret = read(p->timedb_fd, &th, sizeof(th));
	if (ret != sizeof(th)) {
		printd("Cannot read from file: %s!\n", strerror(errno));
		return;
	}

	if (th.cells_per_block - 1 != len) {
		printd("Invalid argument: wrong number of cells!\n");
		return;
	}

	block_len = th.cells_per_block * sizeof(uint64_t);
	block = xmalloc(block_len);

	tb = (struct timedb_block *) block;
	tb->seqnr = th.seq_next;
	for (i = 0; i < th.cells_per_block - 1; ++i)
		tb->cells[i] = cells[i];

	lseek(p->timedb_fd, th.offset_next, SEEK_SET);

	ret = write(p->timedb_fd, block, block_len);
	if (ret != block_len) {
		printd("Error while writing data set: %s\n", strerror(errno));
		goto out;
	}

	off_curr = lseek(p->timedb_fd, 0, SEEK_CUR);
	bnum = (off_curr - sizeof(th)) / block_len;

	if (bnum == th.block_entries)
		th.offset_next = sizeof(th);
	else
		th.offset_next = off_curr;
	th.seq_next++;

	lseek(p->timedb_fd, 0, SEEK_SET);

	ret = write(p->timedb_fd, &th, sizeof(th));
	if (ret != sizeof(th)) {
		printd("Error writing block head: %s\n", strerror(errno));
		goto out;
	}
out:
	xfree(block);
}
