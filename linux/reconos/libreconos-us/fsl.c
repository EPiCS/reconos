/*
 * Copyright 2012 Andreas Agne <agne@upb.de>
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#include <pthread.h>

#include "fsl.h"
#include "xutils.h"
#include "thread_shadowing_error_handler.h"

#define DEBUG 1
#define OUTPUT stderr

#ifdef DEBUG
    #define FSL_DEBUG(message) fprintf(OUTPUT, "FSL: " message)
    #define FSL_DEBUG1(message, arg1) fprintf(OUTPUT, "FSL: " message, (arg1))
    #define FSL_DEBUG2(message, arg1, arg2) fprintf(OUTPUT, "FSL: " message, (arg1), (arg2))
	#define FSL_DEBUG3(message, arg1, arg2, arg3) fprintf(OUTPUT, "FSL: " message, (arg1), (arg2), (arg3))
	#define FSL_DEBUG4(message, arg1, arg2, arg3, arg4) fprintf(OUTPUT, "FSL: " message, (arg1), (arg2), (arg3), (arg4))
#else
    #define FSL_DEBUG(message)
    #define FSL_DEBUG1(message, arg1)
    #define FSL_DEBUG2(message, arg1, arg2)
	#define FSL_DEBUG3(message, arg1, arg2, arg3)
	#define FSL_DEBUG4(message, arg1, arg2, arg3, arg4)
#endif

static int fsl_fd[FSL_MAX] = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};

static inline int fsl_within_range(int num)
{
	return (num >= 0 && num < array_size(fsl_fd));
}

static inline void fsl_within_range_assert(int num)
{
	assert(fsl_within_range(num));
}

static inline int fsl_already_open(int num)
{
	fsl_within_range_assert(num);
	return fsl_fd[num] != -1;
}

/*
 * Unused ?
 *
static void fsl_close_all(void)
{
	int num;
	for (num = 0; num < array_size(fsl_fd); ++num)
		if (fsl_fd[num] != -1)
			close(fsl_fd[num]);
}
*/


static void fsl_open(int num)
{
	char path[FSL_PATH_MAX];

	slprintf(path, sizeof(path), "/dev/fsl%d", num);
	fsl_fd[num] = open_or_die(path, O_RDWR);

//	atexit(fsl_close_all);
}

void fsl_write(int num, uint32_t value)
{
	ssize_t ret;

	fsl_within_range_assert(num);
	if (!fsl_already_open(num))
		fsl_open(num);
	//fprintf(OUTPUT, "fsl_write: slot %i value 0x%x\n", num, value);
	/* XXX: @aagne: what about checking return values? ---DB */
	FSL_DEBUG3("Thread %8li Writing to FSL%2.2i: 0x%8.8x\n", pthread_self(), num, value);
	ret = write(fsl_fd[num], &value, sizeof(value));
	if (ret < 0){
		//whine("fsl_write error: %s\n", strerror(errno));
		sh_file_readwrite_error_handler("/dev/fsl??", 0,0, ret, sizeof(value));
	}
}

void fsl_write_block(int num, void * block_start, size_t byte_count)
{
	ssize_t ret;

	fsl_within_range_assert(num);
	if (!fsl_already_open(num))
		fsl_open(num);
	//fprintf(OUTPUT, "fsl_write: slot %i value 0x%x\n", num, value);
	/* XXX: @aagne: what about checking return values? ---DB */
	ret = write(fsl_fd[num], block_start, byte_count);
	FSL_DEBUG3("Thread %8li Wrote Block from FSL%2.2i: %li bytes\n",pthread_self(), num, byte_count);
	if (ret < 0){
		//whine("fsl_write error: %s\n", strerror(errno));
		sh_file_readwrite_error_handler("/dev/fsl??", 0,0, ret, byte_count);
	}
}

uint32_t fsl_read(int num)
{
	ssize_t ret;
	uint32_t value;

	fsl_within_range_assert(num);
	if (!fsl_already_open(num))
		fsl_open(num);

	/* XXX: @aagne: what about checking return values? ---DB */
	ret = read(fsl_fd[num], &value, sizeof(value));
	FSL_DEBUG3("Thread %8li Read from FSL%2.2i: 0x%8.8x\n",pthread_self(), num, value);
	if (ret < 0){
		//whine("fsl_read error: %s\n", strerror(errno));
		sh_file_readwrite_error_handler("/dev/fsl??", ret, sizeof(value), 0,0);
	}
	//fprintf(OUTPUT, "fsl_read: slot %i value 0x%x\n", num, value);
	return value;
}

void fsl_read_block(int num, void * block_start, size_t byte_count)
{
	ssize_t ret;

	fsl_within_range_assert(num);
	if (!fsl_already_open(num))
		fsl_open(num);

	/* XXX: @aagne: what about checking return values? ---DB */
	ret = read(fsl_fd[num], block_start, byte_count);

	FSL_DEBUG3("Thread %8li Read Block from FSL%2.2i: %li bytes\n",pthread_self(), num, byte_count);

	if (ret < 0){
		//whine("fsl_read error: %s\n", strerror(errno));
		sh_file_readwrite_error_handler("/dev/fsl??", ret, byte_count, 0,0);
	}
	//fprintf(OUTPUT, "fsl_read: slot %i value 0x%x\n", num, value);
}
