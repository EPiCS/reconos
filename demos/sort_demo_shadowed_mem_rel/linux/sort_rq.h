/*
 * sort_rq.h
 *
 *  Created on: 22.07.2013
 *      Author: meise
 */

#ifndef SORT_RQ_H_
#define SORT_RQ_H_

#include "reconos.h"
#include "parallel_sort_interface.h"
#include "sort_demo.h"
#include "bubblesort.h"
#include <limits.h>
#include <stddef.h>

#include "rqueue.h"

extern struct parallel_sort_interface sort_rq_interface;

void *sort_rq_thread(void* data);

void sort_rq_setup_resources(const struct parallel_sort_params_in * pin, struct parallel_sort_params_out * pout);
void sort_rq_put_data(const struct parallel_sort_params_in * pin);
void sort_rq_get_data(const struct parallel_sort_params_in * pin);
void sort_rq_terminate(const struct parallel_sort_params_in * pin);
void sort_rq_teardown_resources(const struct parallel_sort_params_in * pin, struct parallel_sort_params_out * pout);

#endif /* SORT_RQ_H_ */
