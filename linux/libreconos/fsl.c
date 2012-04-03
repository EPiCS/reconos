#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdint.h>
#include <unistd.h>

#include "fsl.h"
#include "xutils.h"

#define FSL_MAX		16
#define FSL_PATH_MAX	256

static int fsl_fd[FSL_MAX] = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};

static inline int fsl_within_range(int num)
{
	return (num >= 0 && num < array_size(fsl_fd));
}

static inline void fsl_within_range_assert(int num)
{
	assert(num >= 0 && num < array_size(fsl_fd));
}

static inline int fsl_already_open(int num)
{
	fsl_within_range_assert(num);
	return fsl_fd[n] != -1;
}

static void fsl_close_all(void)
{
	int num;
	for (num = 0; num < array_size(fsl_fd); ++num)
		if (fsl_fd[num] != -1)
			close(fsl_fd[num]);
}

static void fsl_open(int num)
{
	char path[FSL_PATH_MAX];

	slprintf(path, sizeof(path), "/dev/fsl%d", num);
	fsl_fd[n] = open_or_die(path, O_RDWR);

	atexit(fsl_close_all);
}

void fsl_write(int num, uint32_t value)
{
	fsl_within_range_assert(num);
	if (!fsl_already_open(num))
		fsl_open(num);

	/* XXX: @aagne: what about checking return values? ---DB */
	write(fsl_fd[num], &value, sizeof(value));
}

uint32_t fsl_read(int num)
{
	uint32_t value;

	fsl_within_range_assert(num);
	if (!fsl_already_open(num))
		fsl_open(num);

	/* XXX: @aagne: what about checking return values? ---DB */
	read(fsl_fd[num], &value, sizeof(value));
	return value;
}
