/*
 * sort_rq.h
 *
 *  Created on: 22.07.2013
 *      Author: meise
 */

#ifndef SORT_RQ_H_
#define SORT_RQ_H_

#include "reconos.h"
#include "rqueue.h"
#include "sort_demo.h"
#include "bubblesort.h"
#include <limits.h>

void *sort_thread_rqueue(void* data);

void sort_rq_setup_resources(void *(**actual_sort_thread)(void* data), const int ** actual_slot_map, struct reconos_resource res[MAX_THREADS][2], int buffer_size, struct gengetopt_args_info args_info);
void sort_rq_put_data(int buffer_size);
void sort_rq_get_data(int buffer_size);
void sort_rq_terminate();

#endif /* SORT_RQ_H_ */
