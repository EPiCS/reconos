/*
 * sort_shmem.h
 *
 *  Created on: 22.07.2013
 *      Author: meise
 */

#ifndef SORT_SHMEM_H_
#define SORT_SHMEM_H_

#include "reconos.h"
#include "sort_demo.h"
#include "mbox.h"
#include "bubblesort.h"
#include <limits.h>

void *sort_thread_shmem(void* data);

void sort_shmem_setup_resources(void *(**actual_sort_thread)(void* data), const int ** actual_slot_map, struct reconos_resource res[MAX_THREADS][2], int buffer_size,struct gengetopt_args_info args_info);
void sort_shmem_put_data(int buffer_size);
void sort_shmem_get_data(int buffer_size);
void sort_shmem_terminate();

#endif /* SORT_SHMEM_H_ */
