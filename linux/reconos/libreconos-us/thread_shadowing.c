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
#include <unistd.h>
#include <limits.h>

#define _GNU_SOURCE
#include <pthread.h>

#include <errno.h>
#include <signal.h>
#include <sys/ucontext.h>
#include <sys/time.h>

#include "reconos.h"
#include "max_covering_intervals.h"
#include "thread_shadowing.h"
#include "thread_shadowing_schedule.h"
#include "glist.h"
#include "timing.h"

//#define DEBUG 1

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
static pthread_once_t shadow_system_is_initialized = PTHREAD_ONCE_INIT;
static pthread_t shadow_watchdog;
//
// Private functions
//

/**
 * @brief This thread periodically checks, whether a shadowed thread is stuck in an infinite loop.
 */
void* shadow_watchdog_thread(void* data){
	//inputs? -> none needed!

	// Setup
	long watchdog_time_us  =  100000; //_us ^= microseconds
	long watchdog_delta_us = 1000000; //watchdog_time_us * 10;
	timing_t delta;
	shadowedthread_t * sh;
	func_call_t fc;
	int fill_level;
	timing_t now;
	// Periodically check on runtime
	while(1){
		usleep(watchdog_time_us);
		//printf("############################################## Start Run\n");
		now = gettime();
		for(sh = shadow_list_head; sh != NULL; sh = sh->next ){
			//Version 1: Just print Fifo status
			fill_level = fifo_peek(&sh->func_calls, &fc);

			if (fill_level) {
				delta = func_call_timediff2_us(&now, &fc);
				if (timer2us(&delta) > watchdog_delta_us){
					printf("WATCHDOG: FIFO %p, FILL_LEVEL %i", &sh->func_calls, fill_level);
					printf(", DELAY(us) %10li\n",timer2us(&delta));
					func_call_dump(&fc);
				}
			}
		}
		//printf("############################################## Stopp Run\n");
	}
	return NULL;
}


static void shadow_system_init(){
	// Start watchdog thread
	int retval = pthread_create(&shadow_watchdog, NULL, shadow_watchdog_thread, NULL);
	switch (retval) {
		case 0:
			// All went fine
			TS_DEBUG("Watchdog thread created.\n");
			break;
		case EAGAIN:
			printf("shadow_system_init: Not enough resources to create watchdog thread.");
			exit(-1);
			break;
		case EINVAL:
			printf("shadow_system_init: Invalid attr.");
			exit(-1);
			break;
		case EPERM:
			printf("shadow_system_init: No permission.");
			exit(-1);
			break;
		}
}

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
	printf("Adding HW Thread \n");
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
	printf("Adding SW Thread \n");
	pthread_attr_init(&(sh->sw_attr));
	TS_DEBUG("Adding SW Thread: attributes initialized\n");
	ret = pthread_create(&(sh->threads[index]), //handle
			&(sh->sw_attr), shadow_starter, //start function
			sh); // @todo: allow to pass resources and init_data
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
	sh->sh_status = TS_ACTIVE;
	fifo_init(&(sh->func_calls), 1, sizeof(func_call_t));
	sh->error_handler = shadow_error_abort;

	sh->min_error_detection_latency = (timing_t){.tv_sec= LONG_MAX, .tv_usec = LONG_MAX};
	sh->min_error_detection_offline_time = (timing_t){.tv_sec= LONG_MAX, .tv_usec = LONG_MAX};

	// ...and call substructure initializers
	shadow_errors_init(&(sh->errors));

}

/**
 * @brief Shadowing systems signal handler for segmentation faults.
 */
void shadow_sig_handler(int sig, siginfo_t *siginfo, void * context){
	pthread_t tid = pthread_self();
	ucontext_t* uc = (ucontext_t*) context;

#ifndef HOST_COMPILE
	void * prog_address = (void*)uc->uc_mcontext.regs.pc;
#else
	void * prog_address = (void*)uc->uc_mcontext.gregs[14];
#endif
	void * mem_address  = (void*) siginfo->si_addr;

    // Yeah, i know using printf in a signal context is not save.
    // But with a SIGSEGV the programm is messed up anyway, so what?
	switch( sig ){
	case SIGKILL:
		printf("SIGKILL: thread %lu killed at programm address %p, tried to access %p.\n",
		    		tid, prog_address, mem_address);
		break;
	case SIGABRT:
		printf("SIGABRT: thread %lu killed at programm address %p, tried to access %p.\n",
		    		tid, prog_address, mem_address);
		break;
	case SIGFPE:
		printf("SIGFPE: thread %lu killed at programm address %p, tried to access %p.\n",
		    		tid, prog_address, mem_address);
		break;
	case SIGILL:
		printf("SIGILL: thread %lu killed at programm address %p, tried to access %p.\n",
		    	tid, prog_address, mem_address);
		break;
	case SIGSEGV:
		printf("SIGSEGV: thread %lu killed at programm address %p, tried to access %p.\n",
				tid, prog_address, mem_address);
		break;
	}
#ifdef SHADOWING
    // Print OS call lists for debugging
    int i;
    for (i=0; i < running_threads; i++){
    	shadow_dump(sh + i);
    }
#endif
    exit(32);
}

/**
 * @brief Gets started before the actual worker thread, to set up some signal handlers.
 */
void* shadow_starter(void* data){
	shadowedthread_t * sh = (shadowedthread_t*)data;
	TS_DEBUG("Entering shadow starter.\n");
	//
	// Install signal handler for several fault signals
	//
	struct sigaction act={
			.sa_sigaction = shadow_sig_handler,
			.sa_flags =  SA_SIGINFO
	};

	// Kill: we got killed by external program. Maybe we hang?
	sigaction(SIGKILL, &act, NULL);

	// Abort: called by programm if something went terribly wrong.
	sigaction(SIGABRT, &act, NULL);

	// Floating point exception. Did you divide by zero?
	sigaction(SIGFPE, &act, NULL);

	// Illegal instruction: processes doesn't like/know your instructions.
	sigaction(SIGILL, &act, NULL);

	// Segmentatzion fault: wrong memory accesses
	sigaction(SIGSEGV, &act, NULL);

	// Start actual worker thread
	TS_DEBUG("Leaving shadow starter, calling actual worker function.\n");
	return sh->sw_thread(sh->resources);

}

void shadow_dump_timestats(shadowedthread_t *sh){
	assert(sh);
	printf("Timestats (min,avg,max) in us of shadowed thread %p: dot %li, %li, %li , detlat: %li, %li, %li\n",
			sh,
			timer2us(&sh->min_error_detection_offline_time),
			timer2us(&sh->sum_error_detection_offline_time)/sh->cnt_error_detection_offline_time,
			timer2us(&sh->max_error_detection_offline_time),
			timer2us(&sh->min_error_detection_latency),
			timer2us(&sh->sum_error_detection_latency)/sh->cnt_error_detection_latency,
			timer2us(&sh->max_error_detection_latency));
}

void shadow_dump_timestats_all(){
	shadowedthread_t * current = shadow_list_head;
	long int min_error_detection_offline_time=LONG_MAX;
	long int sum_error_detection_offline_time=0;
	long int cnt_error_detection_offline_time=0;
	long int max_error_detection_offline_time=LONG_MIN;

	long int min_error_detection_latency=LONG_MAX;
	long int sum_error_detection_latency=0;
	long int cnt_error_detection_latency=0;
	long int max_error_detection_latency=LONG_MIN;

	while(current){
		if (min_error_detection_offline_time > timer2us(&current->min_error_detection_offline_time)){
			min_error_detection_offline_time = timer2us(&current->min_error_detection_offline_time);
		}
		sum_error_detection_offline_time += timer2us(&current->sum_error_detection_offline_time);
		cnt_error_detection_offline_time += current->cnt_error_detection_offline_time;
		if (max_error_detection_offline_time < timer2us(&current->max_error_detection_offline_time)){
			max_error_detection_offline_time = timer2us(&current->max_error_detection_offline_time);
		}

		if (min_error_detection_latency > timer2us(&current->min_error_detection_latency)){
			min_error_detection_latency = timer2us(&current->min_error_detection_latency);
		}
		sum_error_detection_latency += timer2us(&current->sum_error_detection_latency);
		cnt_error_detection_latency += current->cnt_error_detection_latency;
		if (max_error_detection_latency < timer2us(&current->max_error_detection_latency)){
			max_error_detection_latency = timer2us(&current->max_error_detection_latency);
		}

		shadow_dump_timestats(current);
		current = current->next;
	}
	printf("Timestats summary (min/avg/max) in us: dot %li, %li, %li, detlat: %li, %li, %li\n",
				min_error_detection_offline_time,
				sum_error_detection_offline_time / cnt_error_detection_offline_time,
				max_error_detection_offline_time,
				min_error_detection_latency,
				sum_error_detection_latency / cnt_error_detection_latency,
				max_error_detection_latency);
}

void shadow_dump(shadowedthread_t *sh) {
	int i;
	assert(sh);

	printf("Dump of shadowed thread %p \n", sh);
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

	printf("\tCurrent os-call index: %i \n", sh->func_calls_idx);

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

int shadow_set_swthread(shadowedthread_t *sh, void* (*entry)(void*)) {
	assert(sh);

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

	sh->resources = res;
	sh->resources_count = res_count;
	return true;
}

int shadow_set_options(shadowedthread_t *sh, uint32_t options) {
	assert(sh);

	sh->options = options;
	return true;
}

/**
 * @brief Copies parameters in shadowedthread structure. shadow_set_threads actually starts/ends threads.
 * @Note  When TS_MANUAL_SCHEDULE is not set in options, shadow scheduler may activate/deactivate
 *        threads as it thinks is best!
 */
int shadow_set_threadcount(shadowedthread_t *sh, uint8_t hw, uint8_t sw) {
	assert(sh);

	sh->num_hw_threads = hw;
	sh->num_sw_threads = sw;
	return true;
}

int shadow_set_hwslots(shadowedthread_t *sh, uint8_t hwt, uint8_t hwslot) {
	assert(sh);

	if (hwt < TS_MAX_REDUNDANT_THREADS) {
		sh->hw_slot_nums[hwt] = hwslot;
		return true;
	} else {
		return false;
	}
}

int shadow_set_program(shadowedthread_t *sh, const char* progname){
	assert(sh);
	int i;
	for (i=0; i< TS_MAX_REDUNDANT_THREADS; i++){
		reconos_hwt_setprogram(&sh->hw_thread[i], progname);
	}
	return true;
}

int shadow_set_initdata(shadowedthread_t *sh, void* init_data) {
	assert(sh);

	sh->init_data = init_data;
	return true;
}

extern int pthread_getattr_np(pthread_t thread, pthread_attr_t *attr);
extern int pthread_attr_getstack(pthread_attr_t *attr, void **stackaddr, size_t *stacksize);

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

/**
 * @brief check if shadow thread is properly configured
 * @todo Needs more checks!
 */
int shadow_check_configuration(shadowedthread_t *sh) {
	assert(sh);

	// Check if at least one thread, may it be hw or sw, is configured.
	assert(sh->sw_thread || sh->hw_thread);

	return true;
}

// Change shadowing status of a shadowed thread.
void shadow_set_state(shadowedthread_t *sh, shadow_state_t s) {
	assert(sh);
	if (sh->sh_status == TS_ACTIVE && s == TS_INACTIVE){
		// set deactivation timestamp
		sh->deactivation_time = gettime();
	}
	if (sh->sh_status == TS_PREACTIVE && s == TS_ACTIVE){
		// calculate error detection offline time
		timing_t now = gettime();
		timing_t diff;
		timerdiff(&now, &sh->deactivation_time, &diff);
		if ( timercmp(&diff,&sh->max_error_detection_offline_time, >) ){
			sh->max_error_detection_offline_time = diff;
		}
		if ( timercmp(&diff,&sh->min_error_detection_offline_time, <) ){
			sh->min_error_detection_offline_time = diff;
		}
		timeradd(&sh->sum_error_detection_offline_time, &diff, &sh->sum_error_detection_offline_time);
		sh->cnt_error_detection_offline_time++;

	}

	sh->sh_status = s;

#ifdef DEBUG
	switch(s){
	case TS_INACTIVE:
		TS_DEBUG2("Shadow Thread %8lu of thread %8lu changed state to TS_INACTIVE.\n", sh->threads[1], sh->threads[0]);
		break;
	case TS_PREACTIVE:
		TS_DEBUG2("Shadow Thread %8lu of thread %8lu changed state to TS_PREACTIVE.\n", sh->threads[1], sh->threads[0]);
		break;
	case TS_ACTIVE:
		TS_DEBUG2("Shadow Thread %8lu of thread %8lu changed state to TS_ACTIVE.\n", sh->threads[1], sh->threads[0]);
		break;
	}
#endif

}

shadow_state_t shadow_get_state(shadowedthread_t *sh) {
	assert(sh);
	return sh->sh_status;
}

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

/**
 * @brief Returns true if the calling thread is the leading thread.
 */
int is_leading_thread(shadowedthread_t *sh, pthread_t this){
	// If there are HWT, then they come first in the sh->threads array.
	// In transmodal case, we assume one HWT and one SWT. Therfore HWT will be at
	// sh->threads[0] and SWT will be at sh->threads[1]
	if(sh->options & TS_HW_LEADS){
		return sh->threads[0] == this;
	}else if(sh->options & TS_SW_LEADS){
		return sh->threads[1] == this;
	}else{
		return sh->threads[0] == this;
	}
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

/**
 * @brief Pushes a function call object into a fifo for later retrieval by the shadow thread.
 */
void shadow_func_call_push(shadowedthread_t *sh, func_call_t * func_call){
	assert(sh);
	assert(func_call);
	// Add correct call index
	func_call->index = sh->func_calls_idx;
	sh->func_calls_idx++;

	// Push into internal fifo
	if (sh->num_hw_threads + sh->num_sw_threads > 1) {
			fifo_push(&sh->func_calls, func_call);
	}
}

/*
 * @brief Pops a function call object from a fifo, so a shadow thread can compare it with its own function call.
 */
void shadow_func_call_pop(shadowedthread_t *sh, func_call_t * func_call){
	assert(sh);
	assert(func_call);
	// Pop from internal fifo - should block when empty!
	fifo_pop(&sh->func_calls, func_call);
}


/**
 * @brief Error handler called when function calls do not match. Aborts program.
 */
void shadow_error_abort(shadowedthread_t * sh, int error, func_call_t * a, func_call_t * b)
{
	pthread_t tid = pthread_self();
	timing_t diff = func_call_timediff_us(a,b);
	printf("\n#################################################\n");
	printf("# ERROR: Thread ID %lu,  %s\n",tid, func_call_strerror(error));
	printf("# a: "); func_call_dump(a);
	printf("# b: "); func_call_dump(b);
	printf("# Detected after: %lu us\n", timer2us(&diff));
	printf("#################################################\n");
	if ( error != FC_ERR_NONE){
		exit(FC_EXIT_CODE);
	}
}

void shadow_error(shadowedthread_t * sh, int error, func_call_t * a, func_call_t * b)
{
	assert(sh);
	sh->error_handler(sh, error, a, b);
}

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

	//
	// If first call, init the shadow system itself
	//
	pthread_once(&shadow_system_is_initialized, shadow_system_init);

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
	//for (i = 0; i < TS_MAX_REDUNDANT_THREADS; i++) {
	for (i = 0; i < 1; i++) {
		if (sh->threads_type[i] != TS_THREAD_NONE) {
			ret = pthread_join(sh->threads[i], value_ptr);
		}
	}
	return ret;
}
