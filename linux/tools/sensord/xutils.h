/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef XUTILS_H
#define XUTILS_H

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

extern void *xmalloc(size_t size);
extern void *xzmalloc(size_t size);
extern void xfree(void *ptr);
extern size_t strlcpy(char *dest, const char *src, size_t size);
extern char *xstrdup(const char *str);

static inline void die(void)
{
	exit(EXIT_FAILURE);
}

static inline void panic(char *msg, ...)
{
	va_list vl;

	va_start(vl, msg);
	vfprintf(stderr, msg, vl);
	va_end(vl);

	fflush(stderr);
	die();
}


#endif /* XUTILS_H */
