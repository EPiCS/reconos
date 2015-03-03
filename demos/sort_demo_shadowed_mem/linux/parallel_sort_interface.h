/*
 * parallel_sort_interface.h
 *
 *  Created on: 22.07.2013
 *      Author: meise
 */

#ifndef PARALLEL_SORT_INTERFACE_H_
#define PARALLEL_SORT_INTERFACE_H_

struct parallel_sort_params_out {
	void *(*sort_thread_main)(void* data); // pointer to function for execution on main processor
	char * sort_program_worker; // file name of program image to load onto worker cpu
	char * sort_program_hwt; // file name of partial bitstream of a hardware thread
	struct reconos_resource * res; // dynamically allocated. Array size will be thread_count*reconos_resource_count
	int reconos_resources_count; // how many resources needs one thread?
};

struct parallel_sort_params_in {
	char ** actual_slot_map;
	unsigned int * data;
	size_t data_size_bytes;
	size_t block_size_bytes;
	int thread_count;
};

struct parallel_sort_interface {
	void (*setup_resources)(const struct parallel_sort_params_in * pin, struct parallel_sort_params_out * pout);
	void (*put_data)(const struct parallel_sort_params_in * pin);
	void (*get_data)(const struct parallel_sort_params_in * pin);
	void (*terminate)(const struct parallel_sort_params_in * pin);
	void (*teardown_resources)(const struct parallel_sort_params_in * pin, struct parallel_sort_params_out * pout);
};

#endif /* PARALLEL_SORT_INTERFACE_H_ */
