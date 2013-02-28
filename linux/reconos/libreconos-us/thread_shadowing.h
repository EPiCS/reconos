///
/// \file thread_shadowing.h
/// Thread shadowing framework.
///
/// \author     Sebastian Meisner   <sebastian.meisner@upb.de>
/// \date       31.05.2011
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2011.
//

#ifndef __THREAD_SHADOWING_H__
#define __THREAD_SHADOWING_H__

#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <semaphore.h>
#include <sys/time.h>
#include "reconos.h"
#include "fifo.h"
//
// Generic constraints
//
#define TS_MAX_REDUNDANT_THREADS 3
#define TS_THREAD_NONE  0
#define TS_THREAD_SW    1
#define TS_THREAD_HW    2

//
// Reliability Constants
//
#define TS_REL_DEFAULT 1000

//
// Shadow status
//
//#define TS_INACTIVE 	0
//#define TS_PREACTIVE	1
//#define TS_ACTIVE		2

typedef enum shadow_state {TS_INACTIVE, TS_PREACTIVE, TS_ACTIVE} shadow_state_t;

//
// Other Constants
//
#define TS_PARAM_SIZE 20
#define TS_RETVAL_SIZE 8
#define TS_EXIT_CODE 16
//
// error statistics
//
typedef struct error_stats {
	unsigned int count;
	unsigned int recovered;
} error_stats_t;

void shadow_error_inc(error_stats_t *e, unsigned int n);

typedef struct os_call {
	unsigned int index;
	char *function; // not a function pointer, because it points to a __FUNCTION__ string
	char params[TS_PARAM_SIZE]; // Size arbitrarily chosen
	char retval[TS_RETVAL_SIZE]; // Size choosen so that the biggest return value
								 // of all calls will fit in this field.
	void* retdata; // side effect data, used to store data which was transferred via parameters
	unsigned int retdata_length;

	struct timeval timestamp; // for benchmarking error detection latency

} os_call_t;

//
// Shadowing system runtime options
//
#define TS_MANUAL_SCHEDULE	0x01 // Set number of shadows manually
#define TS_SYNCHRONIZED		0x02 // Wait until all threads call same os function
//
// Attributes of reliable thread wrapper:
// - needs information about both hw and sw threads.
// - needs information about desired reliability level
// - resources used to copy the input data
//
struct shadowedthread;
//forward declaration
typedef struct shadowedthread {
	//
	// Struct mutex: protects all fields except "next", which is protected by global ts_mutex.
	//
	pthread_mutex_t mutex;

	//
	// general configuration
	//
	void* (*input_copy)(void *src); // User supplied copy function for input data
	int (*input_comp)(void *src, void *dst); // User supplied compare function for output data
	uint32_t reliability; // determines when and how often shadowing will be applied
	uint32_t options; // MANUAL_SCHEDULE, SYNCHRONIZED
	//uint32 status;

	// Resources are semaphores, mailboxes etc.
	struct reconos_resource *resources;
	uint32_t resources_count;

	//
	// Thread Management
	//
	pthread_t threads[TS_MAX_REDUNDANT_THREADS];
	uint8_t threads_type[TS_MAX_REDUNDANT_THREADS]; // see TS_THREAD_* defines
	void*   init_data; //

	shadow_state_t sh_status; // State of the shadow thread
	sem_t  			sh_wait_sem;

	// At the moment we assume that num_hw_threads + num_sw_threads <= TS_MAX_REDUNDANT_THREADS
	uint8_t num_hw_threads; // Scheduled threads
	uint8_t num_sw_threads;
	uint8_t running_num_hw_threads; // Actually running threads
	uint8_t running_num_sw_threads;

	// sw-threads only
	void* (*sw_thread)(void*); // Pointer to thread function
	pthread_attr_t sw_attr; // same attributes for all sw threads

	// hw-threads only
	struct reconos_hwt hw_thread[TS_MAX_REDUNDANT_THREADS];
	uint8_t hw_slot_nums[TS_MAX_REDUNDANT_THREADS];

	//
	// os-calls
	//
	unsigned int os_calls_idx;
	fifo_t os_calls;

	//
	// error statistics
	//
	error_stats_t errors;

	//
	// List housekeeping
	//
	struct shadowedthread *next;
} shadowedthread_t;

//
// OS-Call Management
//
//void shadow_os_call_init( os_call_t * oc );
void shadow_os_call_new(shadowedthread_t *sh, os_call_t * os_call,
		const char *function, char *params, unsigned int params_length);
void shadow_os_call_add_retdata(shadowedthread_t *sh, os_call_t * os_call,
		void *retdata, unsigned int retdata_len);
void shadow_os_call_get_retdata(shadowedthread_t *sh, os_call_t * os_call,
		void ** retdata, unsigned int * retdata_len);
void shadow_os_call_finish(shadowedthread_t *sh, os_call_t * os_call,
		void * retval, unsigned int retval_length);
void shadow_os_call_get_retval(shadowedthread_t *sh, void * retval,
		unsigned int retval_length, const char *function, char *params,
		unsigned int params_length);
void shadow_os_call_dump(os_call_t * oc);

//
// Shadow Configuration
//

// Obligatory
void shadow_init(shadowedthread_t *sh);
int shadow_set_reliability(shadowedthread_t *sh, uint32_t rel);
int shadow_set_copycompare(shadowedthread_t *sh, void* (*input_copy)(void *src),
		int (*input_comp)(void *src, void *dst));
int shadow_set_swthread(shadowedthread_t *sh, void* (*entry)(void*));
//int  shadow_set_hwthread( shadowedthread_t *sh, struct reconos_hwt* hwt[TS_MAX_REDUNDANT_THREADS]);
int shadow_set_resources(shadowedthread_t *sh, struct reconos_resource * res,
		unsigned int res_count);

// Optional
int shadow_set_options(shadowedthread_t *sh, uint32_t options);
int shadow_set_threadcount(shadowedthread_t *sh, uint8_t hw, uint8_t sw);
int shadow_set_hwslots(shadowedthread_t *sh, uint8_t hwt, uint8_t hwslot);
int shadow_set_initdata(shadowedthread_t *sh, void* init_data);
int shadow_check_configuration(shadowedthread_t *sh);

int shadow_get_stack(shadowedthread_t *sh, unsigned int thread_idx, void ** stackaddr, size_t *stacksize);

//
// Shadow internal functions
//
void 			shadow_set_state( shadowedthread_t *sh, shadow_state_t s);
shadow_state_t 	shadow_get_state( shadowedthread_t *sh );
int shadow_list_count();
int is_shadowed(pthread_t handle);
int is_shadowed_in_parent(pthread_t handle, shadowedthread_t **parent);
void shadow_wake_up_all(shadowedthread_t *sh);
void ts_lock();
void ts_unlock();

//
// Debugging
//
void shadow_dump(shadowedthread_t *sh);
void shadow_dump_all();

void shadow_thread_create(shadowedthread_t * sh);
int shadow_join(shadowedthread_t * sh, void **value_ptr);
#endif
