/*
 *                                                        ____  _____
 *                            ________  _________  ____  / __ \/ ___/
 *                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
 *                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
 *                         /_/   \___/\___/\____/_/ /_/\____//____/
 *
 * ======================================================================
 *
 *   title:        ReconOS library - Utils
 *
 *   project:      ReconOS
 *   author:       Andreas Agne, University of Paderborn
 *                 Markus Happe, University of Paderborn
 *                 Daniel Borkmann, ETH Zürich
 *                 Sebastian Meisner, University of Paderborn
 *                 Christoph Rüthing, University of Paderborn
 *   description:  Some simple helper funtions
 *
 * ======================================================================
 */

#ifndef RECONOS_UTILS_H
#define RECONOS_UTILS_H

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#define RECONOS_NODEBUG

#ifdef RECONOS_DEBUG
 #define debug(...) printf(__VA_ARGS__)
#else
 #define debug(...)
#endif

static inline void die() {
	exit(EXIT_FAILURE);
}

static inline void panic(char *msg, ...) {
	va_list vl;

	va_start(vl, msg);
	vfprintf(stderr, msg, vl);
	va_end(vl);

	fflush(stderr);
	die();
}

static inline void whine(char *msg, ...) {
	va_list vl;

	va_start(vl, msg);
	vfprintf(stderr, msg, vl);
	va_end(vl);

	fflush(stderr);
}

#endif /* RECONOS_UTILS_H */