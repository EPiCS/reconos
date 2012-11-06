#ifndef XUTILS_H
#define XUTILS_H

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <syslog.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <linux/netlink.h>
#include <linux/types.h>
#include <linux/if.h>

#include "xt_vlink.h"
#include "xt_fblock.h"

#define TYPE_SUGGEST	1
#define TYPE_COMPOSE	2
#define TYPE_ACK	3
#define TYPE_NACK	4

#define MAXMSG		256

struct pn_hdr {
	uint16_t seq;
	uint16_t ack;
	uint8_t type;
};

struct pn_hdr_compose {
	uint8_t which;
};

#define STATE_MAP_SET(s, f)  {	\
	.num  = (s),		\
	.func = (f)		\
}

extern void *xmalloc(size_t size);
extern void *xzmalloc(size_t size);
extern void *xrealloc(void *ptr, size_t nmemb, size_t size);
extern void xfree(void *ptr);
extern size_t strlcpy(char *dest, const char *src, size_t size);
extern char *xstrdup(const char *str);
extern void send_netlink_fbctl(struct lananlmsg *lmsg);
extern void send_netlink_vlink(struct vlinknlmsg *vmsg);

static inline void *xmemdup(const void *data, size_t len)
{
	return memcpy(xmalloc(len), data, len);
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

static inline void check_for_root_maybe_die(void)
{
	if (geteuid() != 0 || geteuid() != getuid())
		panic("Uhhuh, not root?!\n");
}

#ifndef likely
# define likely(x)		__builtin_expect(!!(x), 1)
#endif

#ifndef unlikely
# define unlikely(x)		__builtin_expect(!!(x), 0)
#endif

#ifndef array_size
# define array_size(x)	(sizeof(x) / sizeof((x)[0]) + __must_be_array(x))
#endif

#ifndef __must_be_array
# define __must_be_array(x)						\
	build_bug_on_zero(__builtin_types_compatible_p(typeof(x),	\
						       typeof(&x[0])))
#endif

#ifndef build_bug_on_zero
# define build_bug_on_zero(e)	(sizeof(char[1 - 2 * !!(e)]) - 1)
#endif

static inline void printd(const char *format, ...)
{
	va_list vl;

	va_start(vl, format);
	vsyslog(LOG_INFO, format, vl);
	va_end(vl);
}

static inline char *bin2hex_compat(uint8_t *hash, size_t lhsh, char *str, size_t lstr)
{
	char *ret = str;
	if (lhsh >= lstr)
		return NULL;
	while (lhsh-- > 0) {
		str += sprintf(str, "%02x", *hash);
		hash++;
	}
	*str = '\0';
	return ret;
}

#endif /* XUTILS_H */
