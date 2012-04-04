/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#define _GNU_SOURCE
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "xutils.h"

size_t strlcpy(char *dest, const char *src, size_t size)
{
	size_t ret = strlen(src);

	if (size) {
		size_t len = (ret >= size) ? size - 1 : ret;

		memcpy(dest, src, len);
		dest[len] = '\0';
	}

	return ret;
}

int slprintf(char *dst, size_t size, const char *fmt, ...)
{
	int ret;
	va_list ap;

	va_start(ap, fmt);
	ret = vsnprintf(dst, size, fmt, ap);
	dst[size - 1] = '\0';
	va_end(ap);

	return ret;
}

int open_or_die(const char *file, int flags)
{
	int ret = open(file, flags);
	if (ret < 0)
		panic("Cannot open file %s!\n", file);

	return ret;
}

void *xmalloc_aligned(size_t size, size_t alignment)
{
	int ret;
	void *ptr;

	if (unlikely(size == 0))
		panic("xmalloc_aligned: zero size\n");

	ret = posix_memalign(&ptr, alignment, size);
	if (unlikely(ret != 0))
		panic("xmalloc_aligned: out of memory (allocating %zu "
		      "bytes)\n", size);

	return ptr;
}
