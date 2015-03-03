#ifndef LOGGING_H
#define LOGGING_H

//#define DEBUG logging_debug
#define DEBUG(...)
#define INFO logging_debug
//#define INFO(...)

void logging_init();

void logging_debug(const char *fmt, ...);

#endif
