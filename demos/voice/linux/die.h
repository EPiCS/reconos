/*
 * Lightweight Autonomic Network Architecture
 * Copyright 2011 Daniel Borkmann <dborkma@tik.ee.ethz.ch>,
 * Swiss federal institute of technology (ETH Zurich)
 * Subject to the GPL.
 */

#ifndef DIE_H
#define DIE_H

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include <syslog.h>

#include "compiler.h"

static inline void error_and_die(int status, char *msg, ...)
{
	va_list vl;
	va_start(vl, msg);
	vfprintf(stderr, msg, vl);
	va_end(vl);
	exit(status);
}

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
	die();
}

#define syslog_panic(msg...)		\
do {					\
	syslog(LOG_ERR, ##msg);		\
	die();				\
} while (0)

static inline void whine(char *msg, ...)
{
	va_list vl;
	va_start(vl, msg);
	vfprintf(stderr, msg, vl);
	va_end(vl);
}

#define syslog_whine(msg...)		\
do {					\
	syslog(LOG_WARNING, ##msg);	\
} while (0)

static inline void info(char *msg, ...)
{
	va_list vl;
	va_start(vl, msg);
	vfprintf(stdout, msg, vl);
	va_end(vl);
}

#define syslog_info(msg...)		\
do {					\
	syslog(LOG_INFO, ##msg);	\
} while (0)

static inline void BUG(char *msg, ...)
{
	va_list vl;
	whine("BUG: ");
	va_start(vl, msg);
	vfprintf(stderr, msg, vl);
	va_end(vl);
	die();
}

static inline void BUG_ON(int cond, char *msg, ...)
{
	va_list vl;
	if (unlikely(cond)) {
		whine("BUG: ");
		va_start(vl, msg);
		vfprintf(stderr, msg, vl);
		va_end(vl);
		die();
	}
}

#ifdef _DEBUG_
static inline void debug(char *msg, ...)
{
	va_list vl;
	va_start(vl, msg);
	vfprintf(stderr, msg, vl);
	va_end(vl);
	fflush(stderr);
}
#else
static inline void debug(char *msg, ...)
{
	/* NOP */
}
#endif /* _DEBUG_ */
#endif /* DIE_H */
