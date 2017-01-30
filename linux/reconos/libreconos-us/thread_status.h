/*
 * thread_status.h
 *
 *  Created on: 19.01.2017
 *      Author: meise
 */

#ifndef SRC_THREAD_STATUS_H_
#define SRC_THREAD_STATUS_H_

#define __STDC_FORMAT_MACROS
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>


typedef struct {
	int32_t pid; // 1, %d
	char     comm[32]; // 2, %s
	char     state; // 3, %c
	int32_t  ppid; // 4, %d
	int32_t  pgrp; //5, %d
	int32_t num_threads; // 20, %ld
	uint32_t startcode; // 26, %lu
	uint32_t endcode; // 27, %lu
	uint32_t startstack; // 28, %lu
	uint32_t kstkesp; // 29, %lu
	uint32_t kstkeip; // 30, %lu
} threadstats_t;

void thread_status_init();
void thread_status_fetch(uint32_t * num_of_threads);
void thread_status_get(uint32_t thread_num, threadstats_t *ts);
void thread_status_print(const threadstats_t *ts);
void thread_status_print_all();

#endif /* SRC_THREAD_STATUS_H_ */
