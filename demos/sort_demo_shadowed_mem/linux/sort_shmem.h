/*
 * sort_shmem.h
 *
 *  Created on: 22.07.2013
 *      Author: meise
 */

#ifndef SORT_SHMEM_H_
#define SORT_SHMEM_H_

#include "reconos.h"
#include "parallel_sort_interface.h"
#include "sort_demo.h"
#include "bubblesort.h"
#include <limits.h>
#include <stddef.h>

#include "mbox.h"

extern struct parallel_sort_interface sort_shmem_interface;

void *sort_shmem_thread(void* data);

void sort_shmem_setup_resources(const struct parallel_sort_params_in * pin, struct parallel_sort_params_out * pout);
void sort_shmem_put_data(const struct parallel_sort_params_in * pin);
void sort_shmem_get_data(const struct parallel_sort_params_in * pin);
void sort_shmem_terminate(const struct parallel_sort_params_in * pin);
void sort_shmem_teardown_resources(const struct parallel_sort_params_in * pin, struct parallel_sort_params_out * pout);

#endif /* SORT_SHMEM_H_ */
