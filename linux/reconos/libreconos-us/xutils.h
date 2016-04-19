/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef XUTILS_H
#define XUTILS_H

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef __deprecated
# define __deprecated		/* unimplemented */
#endif

#ifndef likely
# define likely(x)		__builtin_expect(!!(x), 1)
#endif

#ifndef unlikely
# define unlikely(x)		__builtin_expect(!!(x), 0)
#endif

#ifndef array_size
# define array_size(x)		(sizeof(x) / sizeof((x)[0]) + __must_be_array(x))
#endif

#ifndef __must_be_array
# define __must_be_array(x)		\
	build_bug_on_zero(__builtin_types_compatible_p(typeof(x), typeof(&x[0])))
#endif

#ifndef build_bug_on_zero
# define build_bug_on_zero(e)	(sizeof(char[1 - 2 * !!(e)]) - 1)
#endif

extern size_t strlcpy(char *dest, const char *src, size_t size);
extern int slprintf(char *dst, size_t size, const char *fmt, ...);
extern int open_or_die(const char *file, int flags);
extern void *xmalloc_aligned(size_t size, size_t alignment);


static inline void whine(char *msg, ...)
{
	va_list vl;

	va_start(vl, msg);
	vfprintf(stderr, msg, vl);
	va_end(vl);

	fflush(stderr);
}

#endif /* XUTILS_H */
