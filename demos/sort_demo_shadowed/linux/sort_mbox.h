/*
 * sort_mbox.h
 *
 *  Created on: 22.07.2013
 *      Author: meise
 */

#ifndef SORT_MBOX_H_
#define SORT_MBOX_H_

#include "mbox.h"
#include "reconos.h"
#include "sort_demo.h"
#include "bubblesort.h"
#include <limits.h>

void *sort_thread_mbox(void* data);

void sort_mbox_setup_resources(void *(**actual_sort_thread)(void* data), const int ** actual_slot_map, struct reconos_resource res[MAX_THREADS][2],int buffer_size, struct gengetopt_args_info args_info);
void sort_mbox_put_data(int buffer_size);
void sort_mbox_get_data(int buffer_size);
void sort_mbox_terminate();


#endif /* SORT_MBOX_H_ */
