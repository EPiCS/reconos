///
/// \file thread_shadowing.h
/// Thread shadowing framework. Implementation file.
///
/// \author     Sebastian Meisner   <sebastian.meisner@upb.de>
/// \date       31.05.2011
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2011.
//

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>

#define _GNU_SOURCE
#include <pthread.h>

#include <errno.h>
#include <sys/time.h>

#include "reconos.h"
#include "max_covering_intervals.h"
#include "thread_shadowing.h"
#include "thread_shadowing_schedule.h"
#include "glist.h"

// #define DEBUG 1

#ifdef DEBUG
#define TS_DEBUG(message) printf("TS: " message)
#define TS_DEBUG1(message, arg1) printf("TS: " message, (arg1))
#define TS_DEBUG2(message, arg1, arg2) printf("TS: " message, (arg1), (arg2))
#else
#define TS_DEBUG(message)
#define TS_DEBUG1(message, arg1)
#define TS_DEBUG2(message, arg1, arg2)
#endif

//
// Private global information
//

shadowedthread_t *shadow_list_head = NULL;
static pthread_mutex_t ts_mutex = PTHREAD_MUTEX_INITIALIZER;

//
// Private functions
//

static void shadow_errors_init(error_stats_t *e) {
	e->count = 0;
	e->recovered = 0;
}

void shadow_error_inc(error_stats_t *e, unsigned int n) {
	if (e) {
		e->count += n;
	}
}

// Returns number of shadowed threads in global list. Does _not_ return number of shadow threads.
int shadow_list_count() {
	shadowedthread_t *current = shadow_list_head;
	int sum = 0;
	while (current) {
		sum++;
		current = current->next;
	}
	return sum;
}

// Adds new shadowed thread at end of thread list.
static int shadow_list_add(shadowedthread_t * sh) {
	shadowedthread_t *lh = shadow_list_head;

	assert(sh);
	//"sh == NULL");
	ts_lock();
	if (shadow_list_head == NULL) {
		shadow_list_head = sh;
	} else {
		while (lh->next != NULL) {
			lh = lh->next;
		}
		lh->next = sh;
		sh->next = NULL;
	}
	ts_unlock();
	return true;
}

// Looks through the stack and thread structure arrays and returns the
// index of a given thread type.
static int shadow_get_next_index(shadowedthread_t *sh, unsigned int index,
		unsigned int type) {
	int i;
	for (i = index; i < TS_MAX_REDUNDANT_THREADS; i++) {
		if (sh->threads_type[i] == type) {
			return i;
		}
	}
	return -1;

}

static int shadow_add_hw_thread(shadowedthread_t *sh) {
	int index;

	TS_DEBUG1("Entering shadow_add_hw_thread with sh=%p\n", (void*)sh);
	// Look for free stack and thread structure
	index = shadow_get_next_index(sh, 0, TS_THREAD_NONE);
	TS_DEBUG1("Got free index: %d\n", index);
	if (index == -1) {
		return false;
	}
	// Create HW-Thread
	TS_DEBUG1("set resources; &(sh->hw_thread[index]) is : %p\n", &(sh->hw_thread[index]));
	reconos_hwt_setresources(&(sh->hw_thread[index]), sh->resources,
			sh->resources_count);
	TS_DEBUG("create hw thread\n");
	reconos_hwt_create(&sh->hw_thread[index], sh->hw_slot_nums[index], NULL);

	sh->threads[index] = sh->hw_thread[index].delegate;

	TS_DEBUG("Created HW Thread.");
	sh->threads_type[index] = TS_THREAD_HW;
	sh->running_num_hw_threads++;
	return true;
}

// @WARNING: Before calling this function, make sure the thread doesn't hold any
// locks (mutexes, semaphores etc.).
static int shadow_remove_hw_thread(shadowedthread_t *sh) {
	int index;

	// find removable hw thread
	index = shadow_get_next_index(sh, 0, TS_THREAD_HW);
	if (index == -1) {
		return false;
	}

	// remove hw thread
	pthread_cancel(sh->hw_thread[index].delegate);

	sh->threads[index] = (pthread_t) 0;

	sh->threads_type[index] = TS_THREAD_NONE;
	sh->running_num_hw_threads--;
	return true;
}

static int shadow_add_sw_thread(shadowedthread_t *sh) {
	int index;
	int ret;
	// Look for free stack and thread structure
	index = shadow_get_next_index(sh, 0, TS_THREAD_NONE);
	if (index == -1) {
		return false;
	}

	// Create thread
	TS_DEBUG("Adding SW Thread \n");
	pthread_attr_init(&(sh->sw_attr));
	TS_DEBUG("Adding SW Thread: attributes initialized\n");
	ret = pthread_create(&(sh->threads[index]), //handle
			&(sh->sw_attr), sh->sw_thread, //start function
			sh->resources); // @todo: allow to pass resources and init_data
	TS_DEBUG1("Adding SW Thread:Thread creted with retun value: %i \n", ret);
	switch (ret) {
	case 0:
		sh->threads_type[index] = TS_THREAD_SW;
		sh->running_num_sw_threads++;
		return true;
		break;
	case EAGAIN:
		printf("shadow_add_sw_thread: Not enough resources.");
		return false;
		break;
	case EINVAL:
		printf("shadow_add_sw_thread: Invalid attr.");
		return false;
		break;
	case EPERM:
		printf("shadow_add_sw_thread: No permission.");
		return false;
		break;
	}
	return false;
}

// @WARNING: Before calling this function, make sure the thread doesn't hold any
// locks (mutexes, semaphores etc.).
static int shadow_remove_sw_thread(shadowedthread_t *sh) {
	int index;

	// find removable sw thread
	index = shadow_get_next_index(sh, 0, TS_THREAD_SW);
	if (index == -1) {
		return false;
	}

	// remove sw thread
	pthread_cancel(sh->threads[index]);
	sh->threads_type[index] = TS_THREAD_NONE;
	sh->running_num_sw_threads--;
	return true;
}

//
// Adds or removes shadows to/from a shadowed thread.
// @TODO: Does not preserve state information!
//
static void shadow_set_threads(shadowedthread_t *sh) {

	int i;

	assert(sh->num_sw_threads + sh->num_hw_threads <= TS_MAX_REDUNDANT_THREADS);
	//, "Too many threads scheduled!");
	TS_DEBUG("\t shadow_set_threads() says: hello!\n");
	if (sh->num_hw_threads != sh->running_num_hw_threads) {
		//
		// Number of scheduled and running threads differ.
		//
		TS_DEBUG("\t shadow_set_threads() says: fumbling with hw threads!\n");
		if (sh->num_hw_threads < sh->running_num_hw_threads) {
			//
			// Kill unneeded threads
			//
			unsigned int threads_to_remove = (sh->running_num_hw_threads
					- sh->num_hw_threads);
			for (i = 0; i < threads_to_remove; i++) {
				TS_DEBUG("\t Removing another hw thread.. \n");
				assert(shadow_remove_hw_thread(sh));
				//, "FAILED: remove hw thread");
			}
		} else {
			//
			// Start additional threads
			//
			unsigned int threads_to_start = (sh->num_hw_threads
					- sh->running_num_hw_threads);
			for (i = 0; i < threads_to_start; i++) {
				TS_DEBUG("\t Adding another hw thread.. \n");
				assert(shadow_add_hw_thread(sh));
				//, "FAILED: add hw thread");
			}
		}
	}

	if (sh->num_sw_threads != sh->running_num_sw_threads) {
		//
		// Number of scheduled and running threads differ.
		//
		TS_DEBUG("\t shadow_set_threads() says: fumbling with sw threads!\n");
		if (sh->num_sw_threads < sh->running_num_sw_threads) {
			//
			// Kill unneeded threads
			//
			unsigned int threads_to_remove = (sh->running_num_sw_threads
					- sh->num_sw_threads);
			for (i = 0; i < threads_to_remove; i++) {
				TS_DEBUG("\t Removing another sw thread.. \n");
				assert(shadow_remove_sw_thread(sh));
				//, "FAILED: remove sw thread");
			}
		} else {
			//
			// Start additional threads
			//
			unsigned int threads_to_start = (sh->num_sw_threads
					- sh->running_num_sw_threads);
			for (i = 0; i < threads_to_start; i++) {
				TS_DEBUG("\t Adding another sw thread.. \n");
				assert(shadow_add_sw_thread(sh));
				//, "FAILED: add sw thread");
			}
		}
	}
}

//
// Public API
//

void shadow_init(shadowedthread_t *sh) {
	assert(sh);
	int error;

	// Default is 0 for all fields.
	memset(sh, 0, sizeof(shadowedthread_t));

	// Now define the exceptions...
	error = pthread_mutex_init(&sh->mutex, NULL);
	if (error) {
		perror("mutex_init failed!");
	}
	error = sem_init(&sh->sh_wait_sem, 0, 0);
	if (error) {
		perror("sem_init failed!");
	}
	fifo_init(&(sh->os_calls), 1, sizeof(os_call_t));
	// ...and call substructure initializers
	shadow_errors_init(&(sh->errors));

}

void shadow_dump(shadowedthread_t *sh) {
	int i;
	assert(sh);
	//, "sh == NULL");

	printf("Dump of shadowed thread %p \n", sh);
	printf("\tThread reliability %d \n", sh->reliability);
	printf("\tCopy function: %s set; Compare function: %s set \n",
			sh->input_copy ? "" : "not", sh->input_comp ? "" : "not");
	printf("\tInit data: %p\n", sh->init_data);

	for (i = 0; i < TS_MAX_REDUNDANT_THREADS; i++) {
		printf("\tThread %d: pthread %lu, Type %s \n", i, sh->threads[i],
				(sh->threads_type[i] == TS_THREAD_NONE) ?
						"TS_THREAD_NONE" :
						((sh->threads_type[i] == TS_THREAD_SW) ?
								"TS_THREAD_SW" :
								((sh->threads_type[i] == TS_THREAD_HW) ?
										"TS_THREAD_HW" : "UNKNOWN")));
	}

	printf("\tScheduled Threads: %d/%d  Running Threads: %d/%d (SW/HW)\n",
			sh->num_sw_threads, sh->num_hw_threads, sh->running_num_sw_threads,
			sh->running_num_hw_threads);

	printf("\n\tSW thread entry address: %p \n", sh->sw_thread);
	// Maybe add info about pthread attributes ...

	for (i = 0; i < TS_MAX_REDUNDANT_THREADS; i++) {
		printf(
				"\tHW thread %d control structure at %p and assigned slot: %d \n",
				i, &(sh->hw_thread[i]), sh->hw_slot_nums[i]);
	}

	printf("\tCurrent os-call index: %i \n", sh->os_calls_idx);

	// Missing:
	// - Error Printing
	// - List Management
}

void shadow_dump_all() {
	shadowedthread_t * current = shadow_list_head;
	while (current) {
		shadow_dump(current);
		current = current->next;
	}
}

int shadow_set_reliability(shadowedthread_t *sh, uint32_t rel) {
	assert(sh);
	//, "sh == NULL");
	sh->reliability = rel;
	return true;
}

int shadow_set_copycompare(shadowedthread_t *sh, void* (*input_copy)(void *src),
		int (*input_comp)(void *src, void *dst)) {
	assert(sh);
	//, "sh == NULL");
	sh->input_copy = input_copy;
	sh->input_comp = input_comp;
	return true;
}

int shadow_set_swthread(shadowedthread_t *sh, void* (*entry)(void*)) {
	assert(sh);
	//, "sh == NULL");
	sh->sw_thread = entry;
	return true;
}

//int shadow_set_hwthread( shadowedthread_t *sh, struct reconos_hwt * hwt[TS_MAX_REDUNDANT_THREADS]){
//    assert(sh); //, "sh == NULL");
//    memcpy(sh->hw_thread, hwt, TS_MAX_REDUNDANT_THREADS * sizeof(struct reconos_hwt *));
//    return true;
//}

int shadow_set_resources(shadowedthread_t *sh, struct reconos_resource * res,
		unsigned int res_count) {
	assert(sh);
	//, "sh == NULL");
	sh->resources = res;
	sh->resources_count = res_count;
	return true;
}

int shadow_set_options(shadowedthread_t *sh, uint32_t options) {
	assert(sh);
	//, "sh == NULL");
	sh->options = options;
	return true;
}

// Set TS_MANUAL_SCHEDULE in options!
int shadow_set_threadcount(shadowedthread_t *sh, uint8_t hw, uint8_t sw) {
	assert(sh);
	//, "sh == NULL");
	sh->num_hw_threads = hw;
	sh->num_sw_threads = sw;
	return true;
}

int shadow_set_hwslots(shadowedthread_t *sh, uint8_t hwt, uint8_t hwslot) {
	assert(sh);
	//, "sh == NULL");
	if (hwt < TS_MAX_REDUNDANT_THREADS) {
		sh->hw_slot_nums[hwt] = hwslot;
		return true;
	} else {
		return false;
	}
}

int shadow_set_initdata(shadowedthread_t *sh, void* init_data) {
	assert(sh);
	//, "sh == NULL");
	sh->init_data = init_data;
	return true;
}

int shadow_get_stack(shadowedthread_t *sh, unsigned int thread_idx, void ** stackaddr, size_t *stacksize) {
	assert(sh);
	pthread_attr_t attr;
	pthread_getattr_np(sh->threads[thread_idx],&attr); //@WARNING: Non portable!
	pthread_attr_getstack(&attr, stackaddr, stacksize);
	return true;

}
//
// Private API
//

int shadow_check_configuration(shadowedthread_t *sh) {
	assert(sh);
	//, "Argument is NULL, no configuration passed to function.");
	assert(sh->input_copy);
	//, "Copy function not set!");
	assert(sh->input_comp);
	//, "Compare function not set!");

	// Check if at least one thread, may it be hw or sw, is configured.
	assert(sh->sw_thread || sh->hw_thread);
	//, "Neither a sw nor a hw thread is configured!");
	return true;
}

// Change shadowing status of a shadowed thread.
void shadow_set_state(shadowedthread_t *sh, shadow_state_t s) {
	assert(sh);
	sh->sh_status = s;
//	switch(s){
//	case TS_INACTIVE:
//		printf("Shadow Thread %8lu of thread %8lu changed state to TS_INACTIVE.\n", sh->threads[1], sh->threads[0]);
//		break;
//	case TS_PREACTIVE:
//		printf("Shadow Thread %8lu of thread %8lu changed state to TS_PREACTIVE.\n", sh->threads[1], sh->threads[0]);
//		break;
//	case TS_ACTIVE:
//		printf("Shadow Thread %8lu of thread %8lu changed state to TS_ACTIVE.\n", sh->threads[1], sh->threads[0]);
//		break;
//	}

}

shadow_state_t shadow_get_state(shadowedthread_t *sh) {
	assert(sh);
	return sh->sh_status;
}

//void shadow_wake_up_all ( shadowedthread_t *sh ) {
//    int i;
//    for (i = 0; i < TS_MAX_REDUNDANT_THREADS; i++) {
//        // Resuming non-supended thread does nothing, so we can 
//        // safely resume all threads.
//        cyg_thread_resume(sh->threads_handle[i]);
//    }
//}

// Lock to the shadow list management
void ts_lock() {
	pthread_mutex_lock(&ts_mutex);
}

// Unlock the shadow list management
void ts_unlock() {
	pthread_mutex_unlock(&ts_mutex);
}

// Lock a shadow structure
void sh_lock(shadowedthread_t *sh) {
	pthread_mutex_lock(&sh->mutex);
}

// Unlock a shadow structure
void sh_unlock(shadowedthread_t *sh) {
	pthread_mutex_unlock(&sh->mutex);
}

//
// Does the given handle belong to the shadowing subsystem?
// The passed handle may either be returned by the 
// shadow_thread_create() or the pthread_create() functions.
// If a shadow thread is found to match the handle, the parent parameter will
// be filled with a pointer to the corresponding shadowedthread_t structure,
// else it will be NULLED.
//

int is_shadowed_in_parent(pthread_t handle, shadowedthread_t **parent) {
	int i;
	shadowedthread_t *sh = (shadowedthread_t *) handle;
	shadowedthread_t *temp = shadow_list_head;

	TS_DEBUG1("Checking if handle %d is a shadowedthread_attr_t \n", (int)handle);
	*parent = NULL;
	while ((temp != sh) && (temp != NULL)) {
		//look through thread array
		for (i = 0; i < TS_MAX_REDUNDANT_THREADS; i++) {
			TS_DEBUG1("Looking at thread handle %d\n", i);
			if (temp->threads[i] == (pthread_t) sh) {
				TS_DEBUG1("Thread handle %d is it!\n", i);
				if (parent != NULL) {
					*parent = temp;
				}TS_DEBUG1("Yes ,handle %lu is a shadowedthread_attr_t \n", (unsigned long int)handle);
				return true;
			}
		}

		TS_DEBUG1("Next Node is %p \n", temp->next);
		temp = temp->next;
	}
	if ((temp == sh) && (temp != NULL)) {
		TS_DEBUG1("Yes ,handle %lu is a shadowedthread_attr_t \n", (unsigned long int)handle);
		return true;
	} else {
		TS_DEBUG1("No ,handle %lu is _not_ a shadowedthread_attr_t \n", (unsigned long int)handle);
		return false;
	}
}

int is_shadowed(pthread_t handle) {
	return is_shadowed_in_parent(handle, NULL);
}

//
// Checks if two os calls are the same.
//
int shadow_os_call_compare(os_call_t * a, os_call_t * b) {
	TS_DEBUG("shadow_os_call_compare \n");
	if (a && b && (memcmp(a, b, sizeof(os_call_t)) == 0)) {
		return 1;
	} else {
		// Warning, a and/or b may be a NULL pointer here!
		return 0;
	}
}

int all_the_same(const unsigned int * array, unsigned int length) {
	unsigned int i;
	for (i = 0; i < length - 1; i++) {
		if (array[i] != array[i + 1]) {
			return 0;
		}
	}
	return 1;
}

unsigned int get_smallest(const unsigned int * array, unsigned int length) {
	unsigned int i;
	unsigned int smallest = array[0];

	for (i = 1; i < length - 1; i++) {
		if (array[i] < smallest) {
			smallest = array[i];
		}
	}
	return smallest;
}

// Does the first part out of two of initalizing the os_call structure.
//
// Called only by the leading thread!
void shadow_os_call_new(shadowedthread_t *sh, os_call_t * os_call,
		const char *function, char *params, unsigned int params_length) {
	TS_DEBUG("Entered shadow_os_call_new\n");
	assert(sh);
	assert(os_call);
	assert(function);

	// Clear it
	memset(os_call, 0, sizeof(os_call));
	os_call->index = sh->os_calls_idx;
	sh->os_calls_idx++;
	os_call->function = (char *) function; // we accept to lose the 'const' qualifier
	memset(os_call->retval, 0, TS_RETVAL_SIZE);
	memset(os_call->params, 0, TS_PARAM_SIZE);
	memcpy(os_call->params, params,
			TS_PARAM_SIZE > params_length ? params_length : TS_PARAM_SIZE);

	// for benchmarking error detection latency
	gettimeofday(&os_call->timestamp, NULL);

	TS_DEBUG("Leaving shadow_os_call_new\n");
}

// Saves the return value to the os_call structure and pushes it into the fifo.
// From there the shadow thread will fetch it to check against his own call.
// Called only by the leading thread!
void shadow_os_call_finish(shadowedthread_t *sh, os_call_t * os_call,
		void * retval, unsigned int retval_length) {
	TS_DEBUG("Entered shadow_os_call_finish\n");
	assert(sh);
	assert(os_call);
	assert(retval);
	memcpy(os_call->retval, retval,
			TS_RETVAL_SIZE > retval_length ? retval_length : TS_RETVAL_SIZE);
	if (sh->num_hw_threads + sh->num_sw_threads > 1) {
		fifo_push(&sh->os_calls, os_call);
	}
	//printf("%8lu FIFO_PUSH\n", pthread_self());
	//shadow_os_call_dump(os_call);
	TS_DEBUG("Leaving shadow_os_call_finish\n");
}

// Helper function for benchmarking thread shadowing
//static unsigned long calc_timediff_ms(struct timeval start, struct timeval stop) {
//	unsigned long ms;
//	struct timeval diff;
//
//	// calculate difference
//	timersub(&stop, &start, &diff);
//	// convert to miliseconds
//	ms = diff.tv_sec * 1000 + diff.tv_usec / 1000;
//	// this is very dirty, but allows to print the value via printf("%lu",ms)
//	return ms;
//}

static unsigned long calc_timediff_us(struct timeval start, struct timeval stop) {
	unsigned long us;
	struct timeval diff;

	// calculate difference
	timersub(&stop, &start, &diff);
	// convert to miliseconds
	us = diff.tv_sec * 1000000 + diff.tv_usec;
	// this is very dirty, but allows to print the value via printf("%lu",ms)
	return us;
}

// Checks if the supplied function and params match the ones from the os_call fifo.
// Then copies the return value from the most advanced thread to the parameter retval
// Called only by the shadowing thread!
void shadow_os_call_get_retval(shadowedthread_t *sh, void * retval,
		unsigned int retval_length, const char *function, char *params,
		unsigned int params_length) {
	int i;
	os_call_t os_call;
	TS_DEBUG("Entered shadow_os_call_get_retval\n");

	assert(sh);

	fifo_pop(&sh->os_calls, &os_call); // should block when empty!
	//printf("%8lu FIFO_POP\n",pthread_self());
	//shadow_os_call_dump(&os_call);
	// Checks...
	if (function == NULL) {
		pthread_t tid = pthread_self();
		printf("#################################################\n");
		printf("# ERROR: function parameter is NULL!\n");
		printf("# Thread ID %lu \n", tid);
		printf("#################################################\n");
		exit(TS_EXIT_CODE);
		//return;
	}
	if (os_call.function == NULL) {
		struct timeval now;
		gettimeofday(&now, NULL);
		unsigned long timediff = calc_timediff_us(os_call.timestamp, now);
		pthread_t tid = pthread_self();

		printf("#################################################\n");
		printf("# ERROR: os_call.function member is NULL!\n");
		printf("# call index: %i , shadow call: %s , original call: %s \n",
				os_call.index, function, os_call.function);
		printf("# Detected after %lu us\n", timediff);
		printf("# Thread ID %lu \n", tid);
		printf("#################################################\n");
		exit(TS_EXIT_CODE);
		//return;
	}
	if (strcmp(os_call.function, function) != 0) {
		struct timeval now;
		gettimeofday(&now, NULL);
		unsigned long timediff = calc_timediff_us(os_call.timestamp, now);
		pthread_t tid = pthread_self();

		printf("#################################################\n");
		printf("# ERROR: function calls  do not match!\n");
		printf("# call index: %i , shadow call: %s , original call: %s \n",
				os_call.index, function, os_call.function);
		printf("# Detected after %lu us\n", timediff);
		printf("# Thread ID %lu \n", tid);
		printf("#################################################\n");
		exit(TS_EXIT_CODE);
		//return;
	}
	if (memcmp(os_call.params, params, params_length) != 0) {
		struct timeval now;
		gettimeofday(&now, NULL);
		unsigned long timediff = calc_timediff_us(os_call.timestamp, now);
		pthread_t tid = pthread_self();

		printf("#################################################\n");
		printf(
				"# ERROR: parameters of function %s , call index %i, do not match!\n",
				os_call.function, os_call.index);
		printf("# My parameters:        ");
		for (i = 0;
				i
						< (TS_PARAM_SIZE > params_length ?
								params_length : TS_PARAM_SIZE); ++i) {
			printf("%2.2x", params[i]);
		}
		printf("\n# Should be parameters: ");
		for (i = 0;
				i
						< (TS_PARAM_SIZE > params_length ?
								params_length : TS_PARAM_SIZE); ++i) {
			printf("%2.2x", os_call.params[i]);
		}
		printf("\n# Detected after %lu us\n", timediff);
		printf("# Thread ID %lu \n", tid);
		printf("\n#################################################\n");
		exit(TS_EXIT_CODE);
		//return;
	}

	// All fine, return retval
	if (retval) {
		memcpy(retval, os_call.retval,
				TS_RETVAL_SIZE > retval_length ?
						retval_length : TS_RETVAL_SIZE);
	}

	TS_DEBUG("Leaving shadow_os_call_get_retval\n");
}

//
// Debug functions: print os call lists
//

// Print information of one os_call
void shadow_os_call_dump(os_call_t * oc) {
	int i;

	printf("%5u Func: %s Params: ", oc->index, oc->function);

	for (i = 0; i < TS_PARAM_SIZE; ++i) {
		printf("%2.2hhx", oc->params[i]);
	}

	printf(" RetVal: ");
	for (i = 0; i < TS_RETVAL_SIZE; ++i) {
		printf("%2.2hhx ", oc->retval[i]);
	}
	printf("\n");
}

//
// Helper function to count the set bits in an unsigned word.
// Applies the SWAR algorithm.
//
//static unsigned int number_of_set_bits(unsigned int i)
//{
//    i = i - ((i >> 1) & 0x55555555);
//    i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
//    return (((i + (i >> 4)) & 0xF0F0F0F) * 0x1010101) >> 24;
//}

//
// Shadowed thread creation.
//
void shadow_thread_create(shadowedthread_t * sh) // Init data passed to worker threads
{
	//
	// Sanity checks
	//
	assert(sh);
	assert(shadow_check_configuration(sh));
	//"Shadow thread configuration invalid!");

	//
	// Insert in global data structures
	//
	TS_DEBUG("Adding shadowed thread to global list \n");
	shadow_list_add(sh);
	//shadow_dump(sh);
	//
	// Calculate first schedule according to reliability demands and available resources.
	//
	TS_DEBUG("Calling Scheduler \n");
	shadow_schedule(sh, SCHED_FLAG_INIT);
	//shadow_dump(sh);
	TS_DEBUG1("\tScheduler decided for %d sw threads \n", sh->num_sw_threads);TS_DEBUG1("\tScheduler decided for %d hw threads \n", sh->num_hw_threads);TS_DEBUG1("\tRunning sw threads: %d \n", sh->running_num_sw_threads);TS_DEBUG1("\tRunning hw threads: %d \n", sh->running_num_hw_threads);

	//
	// Activate new threads, deactivate unneeded ones.
	//
	TS_DEBUG("Activating Threads \n");
	shadow_set_threads(sh);
	//shadow_dump(sh);
}

int shadow_join(shadowedthread_t * sh, void **value_ptr) {
	int i;
	int ret = 0;

	assert(sh);
	for (i = 0; i < TS_MAX_REDUNDANT_THREADS; i++) {
		if (sh->threads_type[i] != TS_THREAD_NONE) {
			ret = pthread_join(sh->threads[i], value_ptr);
		}
	}
	return ret;
}
