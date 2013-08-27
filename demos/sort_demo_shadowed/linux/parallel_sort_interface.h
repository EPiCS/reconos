/*
 * parallel_sort_interface.h
 *
 *  Created on: 22.07.2013
 *      Author: meise
 */

#ifndef PARALLEL_SORT_INTERFACE_H_
#define PARALLEL_SORT_INTERFACE_H_

struct parallel_sort_interface {
	void (*init)(void);
	void (*setup_resources)(void *(**actual_sort_thread)(void* data), int ** actual_slot_map, struct reconos_resource ** res);
	void (*put_data)(unsigned int*data, size_t data_size_bytes, size_t block_size_bytes, thread_counts);
	void (*get_data)(unsigned int*data, size_t data_size_bytes, size_t block_size_bytes, thread_counts);

};

#endif /* PARALLEL_SORT_INTERFACE_H_ */
