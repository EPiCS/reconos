/*
 *                                                        ____  _____
 *                            ________  _________  ____  / __ \/ ___/
 *                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
 *                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
 *                         /_/   \___/\___/\____/_/ /_/\____//____/
 *
 * ======================================================================
 *
 *   title:        ReconOS library - Private header file
 *
 *   project:      ReconOS
 *   author:       Andreas Agne, University of Paderborn
 *                 Christoph Rüthing, University of Paderborn
 *   description:  Head file with private only definitions.
 *
 * ======================================================================
 */

#ifndef RECONOS_PRIVATE_H
#define RECONOS_PRIVATE_H

#include <pthread.h>

struct proc_control {
	pthread_t page_fault_handler;
	int fd;
	int page_faults;
};

struct reconos_runtime {
	struct proc_control proc_control;
	struct reconos_configuration* (*scheduler)(struct reconos_hwt *hwt);
};

extern struct reconos_runtime reconos_runtime;

#endif /* RECONOS_PRIVATE_H */
