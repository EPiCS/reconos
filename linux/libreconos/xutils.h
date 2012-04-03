#ifndef XUTILS_H
#define XUTILS_H

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

#ifndef round_up
# define round_up(x, alignment)	(((x) + (alignment) - 1) & ~((alignment) - 1))
#endif

size_t strlcpy(char *dest, const char *src, size_t size);
int slprintf(char *dst, size_t size, const char *fmt, ...);
int open_or_die(const char *file, int flags);

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

static inline void whine(char *msg, ...)
{
	va_list vl;

	va_start(vl, msg);
	vfprintf(stderr, msg, vl);
	va_end(vl);

	fflush(stderr);
}

#endif /* XUTILS_H */
