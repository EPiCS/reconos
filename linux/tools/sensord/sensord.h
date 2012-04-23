/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef SENSORD_H
#define SENSORD_H

#include <stdarg.h>
#include <syslog.h>

#include "loader.h"
#include "plugin.h"

#define __init			/* unimplemented */
#define __exit			/* unimplemented */

#define plugin_init(fn)		int plugin_init_fn(void) { return (fn)(); }
#define plugin_exit(fn)		void plugin_exit_fn(void) { (fn)(); }

#define PLUGIN_LICENSE(x)	/* unimplemented */
#define PLUGIN_AUTHOR(x)	/* unimplemented */
#define PLUGIN_DESC(x)		/* unimplemented */

/* Print routine plugins have to use */
static inline void printp(const char *format, ...)
{
	va_list vl;
	va_start(vl, format);
	vsyslog(LOG_INFO, format, vl);
	va_end(vl);
}

static inline void printd(const char *format, ...)
{
	va_list vl;
	va_start(vl, format);
	vsyslog(LOG_INFO, format, vl);
	va_end(vl);
}

#define MAX_PATH		1024

#define PLUGIN_DIR		"/opt/sensord/plugins/"
#define RRD_DIR			"/opt/sensord/rrds/"

#endif /* SENSORD_H */
