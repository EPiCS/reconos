/*
 * cpuusage.h
 *
 *  Created on: Aug 6, 2015
 *      Author: meise
 */

#ifndef CPUUSAGE_H_
#define CPUUSAGE_H_

#include <stdio.h>
#include <stdlib.h>

#define __STDC_FORMAT_MACROS
#include <stdint.h>

// user mode, user mode low prio(nice), system mode, idle task, iowait, irq time, softirq time, steal(virtualized), guest (virtual cpu)
typedef struct {
	uint32_t user;
	uint32_t nice;
	uint32_t system;
	uint32_t idle;
	uint32_t iowait;
	uint32_t irq;
	uint32_t softirq;
} cpustats_t;

void cpuusage_init();
double cpuusage_average();

#endif /* CPUUSAGE_H_ */
