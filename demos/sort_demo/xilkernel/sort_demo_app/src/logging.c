#include "xmk.h"
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <stdarg.h>

static pthread_mutex_t mutex;

void logging_init(){
	pthread_mutex_init(&mutex,NULL);
}

void logging_debug(const char *fmt, ...)
{
	va_list argp;

	pthread_mutex_lock(&mutex);

	va_start(argp, fmt);
	vprintf(fmt, argp);
	va_end(argp);

	fflush(stdout);

	pthread_mutex_unlock(&mutex);
}
