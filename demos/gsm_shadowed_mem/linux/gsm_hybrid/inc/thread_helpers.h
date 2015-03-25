/*
 * thread_helpers.h
 *
 *  Created on: Mar 18, 2015
 *      Author: meise
 */

#ifndef THREAD_HELPERS_H_
#define THREAD_HELPERS_H_

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <pthread.h>
#include <assert.h>
#include <string.h>

#include "reconos.h"
#include "slot_map.h"
//#ifdef SHADOWING
#include "thread_shadowing.h"
//#include "thread_shadowing_subs.h"
//#endif



//#ifdef SHADOWING

void prepare_threads_shadowing(int thread_count,
								struct reconos_resource * res,
								int reconos_resource_count,
								shadowedthread_t * sh,
								const char* worker_progname,
								void *(*actual_sort_thread)(void* data),
								int shadow_schedule);

void start_threads_shadowing_hw(int hwt_count,
								shadowedthread_t * sh,
								unsigned int * sh_free_idx,
								char * const actual_slot_map[],
								char * hwt_type,
								int shadow_flag,
								int shadow_transmodal_flag);

void start_threads_shadowing_sw(int swt_count,
								shadowedthread_t * sh,
								unsigned int * sh_free_idx,
								char * const actual_slot_map[],
								char * hwt_type,
								int shadow_flag,
								int shadow_transmodal_flag);

void start_threads_shadowing_host(int mt_count,
								shadowedthread_t * sh,
								unsigned int * sh_free_idx,
								char * const actual_slot_map[],
								char * hwt_type,
								int shadow_flag,
								int shadow_transmodal_flag);

void join_threads_shadowing(shadowedthread_t * sh, unsigned int running_threads);

//#endif //SHADOWING

void start_threads_hw(int hwt_count,
						struct reconos_resource * res,
						int reconos_resource_count,
						struct reconos_hwt * hwt,
						char * hwt_type,
						char * const actual_slot_map[]);

void start_threads_sw(int swt_count,
						struct reconos_resource * res,
						int reconos_resource_count,
						struct reconos_hwt * hwt_worker,
						const char* worker_progname,
						char * const actual_slot_map[]);

void start_threads_host(int mt_count,
						struct reconos_resource * res,
						int reconos_resource_count,
						pthread_t * swt,
						pthread_attr_t * swt_attr,
						void *(*actual_sort_thread)(void* data));

void join_threads(unsigned int num_sw_threads, pthread_t * swt,
				unsigned int num_hw_threads, struct reconos_hwt * hwt);

#endif /* THREAD_HELPERS_H_ */
