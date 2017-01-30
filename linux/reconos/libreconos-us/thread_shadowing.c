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

# ifndef S_SPLINT_S
#include <sys/ucontext.h>
#endif

#include <sys/time.h>

#include "reconos.h"
#include "max_covering_intervals.h"
#include "thread_shadowing.h"
#include "thread_shadowing_error_handler.h"
#include "thread_shadowing_schedule.h"
#include "timing.h"

//#define DEBUG 1
#define OUTPUT stderr

#ifdef DEBUG
#define TS_DEBUG(message) fprintf(OUTPUT, "TS: " message)
#define TS_DEBUG1(message, arg1) fprintf(OUTPUT, "TS: " message, (arg1))
#define TS_DEBUG2(message, arg1, arg2) fprintf(OUTPUT, "TS: " message, (arg1), (arg2))
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

// For statistics
static uint32_t function_intercepted[IDX_SIZE];
static uint32_t function_shadowed[IDX_SIZE];

//
// Private functions
//

/**
 * @brief This thread periodically checks, whether a shadowed thread is stuck in an infinite loop.
 */
void* shadow_watchdog_thread(void* data){
	//inputs? -> none needed!

	// Setup
	uint32_t watchdog_time_us  = 10000000; //_us ^= microseconds
	uint32_t watchdog_delta_us = 10000000; //watchdog_time_us * 10;
	timing_t delta;
	shadowedthread_t * sh;
	func_call_t fc;
	int fill_level;
	int lock_status;
	int sem_value;
	timing_t now;
	fprintf(stderr, "SHADOW_WATCHDOG_THREAD ID %8lu: started, stack around %p, globals around %p\n", pthread_self(), &watchdog_time_us, &shadow_list_head);
	// Periodically check on runtime
	while(true){
		usleep(watchdog_time_us);
		//fprintf(OUTPUT, "############################################## Start Run\n");
		now = gettime();


		lock_status = ts_lock_status();

		//fill_level = fifo_peek(&shadow_list_head->func_calls, &fc);
		//sem_getvalue(&shadow_list_head->sh_wait_sem , &sem_value);
		//fprintf(OUTPUT, "WATCHDOG: FIFO %p, FILL_LEVEL %i, LOCK_STATUS %i, WAIT_SEMAPHORE %i\n", &shadow_list_head->func_calls, fill_level, lock_status, sem_value);
		//func_call_dump(&fc);

		ts_lock();
		for(sh = shadow_list_head; sh != NULL; sh = sh->next ){
			//Version 1: Just print Fifo status
			fill_level = fifo_peek(&sh->func_calls, &fc);

			if (fill_level != 0) {
				sem_getvalue(&sh->sh_wait_sem , &sem_value);
				delta = func_call_timediff2_us(&now, &fc);
				if (timer2us(&delta) > watchdog_delta_us){
					fprintf(OUTPUT, "WATCHDOG: FIFO %p, FILL_LEVEL %i, LOCK_STATUS %s, WAIT_SEMAPHORE %i", &sh->func_calls, fill_level, lock_status == 0?"unlocked":"locked", sem_value);
					fprintf(OUTPUT, ", DELAY(us) %10li\n",timer2us(&delta));
					func_call_dump(&fc);
					shadow_dump_all();
					sh_watchdog_error_handler(timer2us(&delta));
				}
			}
		}
		ts_unlock();
		//fprintf(OUTPUT, "############################################## Stopp Run\n");
	}
	return NULL;
}


static void shadow_system_init(){
	// Start watchdog thread
	int retval = pthread_create(&shadow_watchdog, NULL, shadow_watchdog_thread, NULL);
	if (retval !=0 ){
		fprintf(OUTPUT, "shadow_system_init: creation of watchdog thread failed.\n");
		exit(-1);
	}
	TS_DEBUG("Watchdog thread created.\n");
	// reset global statistics
	memset(function_intercepted, 0, IDX_SIZE*sizeof(uint32_t));
	memset(function_shadowed, 0, IDX_SIZE*sizeof(uint32_t));
}

/*
 * @TODO: Remove function, because it is unused
 */
static void shadow_errors_init(error_stats_t *e) {
	assert(e != NULL);
	e->count = 0;
	e->recovered = 0;
}

/*
 * @TODO: Remove function, because it is unused
 */
void shadow_error_inc(error_stats_t *e, unsigned int n) {
	if (e) {
		e->count += n;
	}
}

// Returns number of shadowed threads in global list. Does _not_ return number of shadow threads.
uint32_t shadow_list_count() {
	shadowedthread_t *current = shadow_list_head;
	uint32_t sum = 0;
	ts_lock();
	while (current) {
		sum++;
		current = current->next;
	}
	ts_unlock();
	return sum;
}

// Adds new shadowed thread at end of thread list.
static void shadow_list_add(shadowedthread_t * sh) {
	shadowedthread_t *lh = shadow_list_head;

	assert(sh != NULL);

	if (shadow_list_head == NULL) {
		shadow_list_head = sh;
	} else {
		while (lh->next != NULL) {
			lh = lh->next;
		}
		lh->next = sh;
		sh->next = NULL;
	}
}

// Looks through the stack and thread structure arrays and returns the
// index of a given thread type.
static int shadow_get_next_index(shadowedthread_t *sh, uint8_t index,
		uint8_t type) {
	uint8_t i;
	for (i = index; i < TS_MAX_REDUNDANT_THREADS; i++) {
		if (sh->threads_type[i] == type) {
			return (int)i;
		}
	}
	return -1;

}

static bool shadow_add_hw_thread(shadowedthread_t *sh) {
	int index;
	int retval;
	fprintf(OUTPUT, "Adding HW Thread \n");
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
	sh->threads[index] = sh->hw_thread[index].delegate;
	sh->threads_type[index] = TS_THREAD_HW;
	sh->running_num_hw_threads++;

	TS_DEBUG("create hw thread\n");
	retval = reconos_hwt_create(&sh->hw_thread[index], sh->hw_slot_nums[index], NULL);
	if (retval !=0 ){
		fprintf(OUTPUT, "shadow_add_hw_thread: creation of hw-thread failed.\n");
		exit(-1);
	}
	sh->threads[index] = sh->hw_thread[index].delegate;
	TS_DEBUG("Created HW Thread.");

	return true;
}

// @WARNING: Before calling this function, make sure the thread doesn't hold any
// locks (mutexes, semaphores etc.).
static bool shadow_remove_hw_thread(shadowedthread_t *sh) {
	int index;
	int retval;

	// find removable hw thread
	index = shadow_get_next_index(sh, 0, TS_THREAD_HW);
	if (index == -1) {
		return false;
	}

	// remove hw thread
	retval=pthread_cancel(sh->hw_thread[index].delegate);
	if (retval !=0 ){
		fprintf(OUTPUT, "shadow_remove_hw_thread: cancellation of hw-thread failed.\n");
		exit(-1);
	}
	sh->threads[index] = (pthread_t) 0;

	sh->threads_type[index] = TS_THREAD_NONE;
	sh->running_num_hw_threads--;
	return true;
}

static bool shadow_add_sw_thread(shadowedthread_t *sh) {
	int index;
	int retval;
	// Look for free stack and thread structure
	index = shadow_get_next_index(sh, 0, TS_THREAD_NONE);
	if (index == -1) {
		return false;
	}

	// Create thread
	TS_DEBUG("Adding SW Thread \n");
	fprintf(OUTPUT, "Adding SW Thread \n");

	retval = pthread_attr_init(&(sh->sw_attr));
	if (retval !=0 ){
		fprintf(OUTPUT, "shadow_add_sw_thread: attr-init failed.\n");
		exit(-1);
	}

	TS_DEBUG("Adding SW Thread: attributes initialized\n");
	retval = pthread_create(&(sh->threads[index]), //handle
			&(sh->sw_attr), shadow_starter, //start function
			sh); // @todo: allow to pass resources and init_data
	if (retval !=0 ){
		fprintf(OUTPUT, "shadow_add_sw_thread: creation of sw-thread failed.\n");
		exit(-1);
	}
	TS_DEBUG1("Adding SW Thread:Thread creted with retun value: %i \n", ret);
	sh->threads_type[index] = TS_THREAD_SW;
	sh->running_num_sw_threads++;
	return true;
}

// @WARNING: Before calling this function, make sure the thread doesn't hold any
// locks (mutexes, semaphores etc.).
static bool shadow_remove_sw_thread(shadowedthread_t *sh) {
	int index;
	int retval;
	// find removable sw thread
	index = shadow_get_next_index(sh, 0, TS_THREAD_SW);
	if (index == -1) {
		return false;
	}

	// remove sw thread
	retval = pthread_cancel(sh->threads[index]);
	if (retval !=0 ){
		fprintf(OUTPUT, "shadow_remove_sw_thread: cancellation of sw-thread failed.\n");
		exit(-1);
	}

	sh->threads_type[index] = TS_THREAD_NONE;
	sh->running_num_sw_threads--;
	return true;
}

//
// Adds or removes shadows to/from a shadowed thread.
// @TODO: Does not preserve state information!
//
static void shadow_set_threads(shadowedthread_t *sh) {

	uint8_t i;
	uint8_t threads_to_remove;
	uint8_t threads_to_start;

	assert(sh!=NULL);
	assert(sh->num_sw_threads + sh->num_hw_threads <= TS_MAX_REDUNDANT_THREADS);

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
			threads_to_remove = (sh->running_num_hw_threads - sh->num_hw_threads);
			for (i = 0; i < threads_to_remove; i++) {
				TS_DEBUG("\t Removing another hw thread.. \n");
				assert(shadow_remove_hw_thread(sh));
			}
		} else {
			//
			// Start additional threads
			//
			threads_to_start = (sh->num_hw_threads - sh->running_num_hw_threads);
			for (i = 0; i < threads_to_start; i++) {
				TS_DEBUG("\t Adding another hw thread.. \n");
				assert(shadow_add_hw_thread(sh));
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
			threads_to_remove = (sh->running_num_sw_threads - sh->num_sw_threads);
			for (i = 0; i < threads_to_remove; i++) {
				TS_DEBUG("\t Removing another sw thread.. \n");
				assert(shadow_remove_sw_thread(sh));
			}
		} else {
			//
			// Start additional threads
			//
			threads_to_start = (sh->num_sw_threads - sh->running_num_sw_threads);
			for (i = 0; i < threads_to_start; i++) {
				TS_DEBUG("\t Adding another sw thread.. \n");
				assert(shadow_add_sw_thread(sh));
			}
		}
	}
}

//
// Public API
//

void shadow_init(shadowedthread_t *sh) {
	assert(sh != NULL);

	// Default shadowing level is highest level:
	// use all available error checking mechanisms
	sh->level = 3;

	// Default is 0 for all fields.
	memset(sh, 0, sizeof(shadowedthread_t));

	// Now define the exceptions...
	if ( sem_init(&sh->sh_wait_sem, 0, 0) != 0) {
		perror("sem_init failed!");
	}

	sh->sh_status = TS_INACTIVE;

	(void)fifo_init( &(sh->func_calls), 512, sizeof(func_call_t) );
	sh->error_callback = NULL; // User supplied call back function

	sh->min_error_detection_latency.tv_sec= LONG_MAX;
	sh->min_error_detection_latency.tv_usec = LONG_MAX;
	sh->min_error_detection_offline_time.tv_sec= LONG_MAX;
	sh->min_error_detection_offline_time.tv_usec = LONG_MAX;

	// ...and call substructure initializers
	shadow_errors_init(&(sh->errors));
}

/**
 * @brief Shadowing systems signal handler for segmentation faults.
 */
# ifndef S_SPLINT_S
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
		fprintf(OUTPUT, "SIGKILL: thread %lu killed at programm address %p, tried to access %p.\n",
		    		tid, prog_address, mem_address);
		break;
	case SIGABRT:
		fprintf(OUTPUT, "SIGABRT: thread %lu killed at programm address %p, tried to access %p.\n",
		    		tid, prog_address, mem_address);
		break;
	case SIGFPE:
		fprintf(OUTPUT, "SIGFPE: thread %lu killed at programm address %p, tried to access %p.\n",
		    		tid, prog_address, mem_address);
		break;
	case SIGILL:
		fprintf(OUTPUT, "SIGILL: thread %lu killed at programm address %p, tried to access %p.\n",
		    	tid, prog_address, mem_address);
		break;
	case SIGSEGV:
		fprintf(OUTPUT, "SIGSEGV: thread %lu killed at programm address %p, tried to access %p.\n",
				tid, prog_address, mem_address);
		break;
	default:
		fprintf(OUTPUT, "SIGUNKNOWN: thread %lu killed at programm address %p, tried to access %p.\n",
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
    exit(64+sig);
}
#endif

/**
 * @brief Gets started before the actual worker thread, to set up some signal handlers.
 */
void* shadow_starter(void* data){
	struct sigaction act;
	shadowedthread_t * sh = (shadowedthread_t*)data;

	fprintf(stderr, "SHADOW_WATCHDOG_THREAD: started, stack around %p\n", &sh);
	TS_DEBUG("Entering shadow starter.\n");
	//
	// Install signal handler for several fault signals
	//
	act.sa_sigaction = shadow_sig_handler;
	act.sa_flags =  SA_SIGINFO;

	// Kill: we got killed by external program. Maybe we hang?
	sigaction(SIGKILL, &act, NULL);

	// Abort: called by programm if something went terribly wrong.
	sigaction(SIGABRT, &act, NULL);

	// Floating point exception. Did you divide by zero?
	sigaction(SIGFPE, &act, NULL);

	// Illegal instruction: processes doesn't like/know your instructions.
	sigaction(SIGILL, &act, NULL);

	// Segmentation fault: wrong memory accesses
	sigaction(SIGSEGV, &act, NULL);

	// Start actual worker thread
	TS_DEBUG("Leaving shadow starter, calling actual worker function.\n");
	return sh->sw_thread(sh->resources);
}

void shadow_dump_cyclestats(shadowedthread_t *sh){
	assert(sh != NULL);
	fprintf(OUTPUT, "Cycle Stats of shadowed thread %p: inactive: %4lu, preactive: %4lu, active: %4lu\n",
			sh,
			(unsigned long) sh->ts_inactive_cycles,
			(unsigned long) sh->ts_preactive_cycles,
			(unsigned long) sh->ts_active_cycles);
}

void shadow_dump_cyclestats_all(){
	shadowedthread_t * current = shadow_list_head;
	uint32_t active_cycles=0;
	uint32_t preactive_cycles=0;
	uint32_t inactive_cycles=0;
	uint32_t thread_count=0;

	while(current){
		active_cycles += current->ts_active_cycles;
		preactive_cycles += current->ts_preactive_cycles;
		inactive_cycles += current->ts_inactive_cycles;
		thread_count++;

		shadow_dump_cyclestats(current);
		current = current->next;
	}
	if (thread_count != 0){
	fprintf(OUTPUT, "Cycle Stats Summary: inactive: %3f, preactive: %3f, active: %3f\n",
			(double)inactive_cycles/(double)thread_count,
			(double)preactive_cycles/(double)thread_count,
			(double)active_cycles/(double)thread_count);
	}else {
		fprintf(OUTPUT, "Cycle Stats Summary: no threads!\n");
	}
}

void shadow_dump_timestats(shadowedthread_t *sh){
	assert(sh!=NULL);
	fprintf(OUTPUT, "Timestats (min,avg,max) in us of shadowed thread %p: dot %li, %li, %li , detlat: %li, %li, %li\n",
			sh,
			timer2us(&sh->min_error_detection_offline_time),
			sh->cnt_error_detection_offline_time!= 0?
					timer2us(&sh->sum_error_detection_offline_time)/sh->cnt_error_detection_offline_time:
					INT_MAX,
			timer2us(&sh->max_error_detection_offline_time),
			timer2us(&sh->min_error_detection_latency),
			sh->cnt_error_detection_latency != 0?
					timer2us(&sh->sum_error_detection_latency)/sh->cnt_error_detection_latency:
					INT_MAX,
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
	fprintf(OUTPUT, "Timestats summary (min/avg/max) in us: dot %li, %li, %li, detlat: %li, %li, %li\n",
				min_error_detection_offline_time,
				cnt_error_detection_offline_time != 0 ?
						sum_error_detection_offline_time / cnt_error_detection_offline_time:
						INT_MAX,
				max_error_detection_offline_time,
				min_error_detection_latency,
				cnt_error_detection_latency != 0 ?
						sum_error_detection_latency / cnt_error_detection_latency:
						INT_MAX,
				max_error_detection_latency);
}

void shadow_sfs_dump(shadowed_function_state* sfs);

void shadow_dump(shadowedthread_t *sh) {
	int i;
	assert(sh!=NULL);

	fprintf(OUTPUT, "Dump of shadowed thread %p \n", sh);
	fprintf(OUTPUT, "\tLevel: %hhu \n", sh->level);
	fprintf(OUTPUT, "\tInit data: %p\n", sh->init_data);

	for (i = 0; i < TS_MAX_REDUNDANT_THREADS; i++) {
		fprintf(OUTPUT, "\tThread %d: pthread %lu, Type %s \n", i, sh->threads[i],
				(sh->threads_type[i] == TS_THREAD_NONE) ?
						"TS_THREAD_NONE" :
						((sh->threads_type[i] == TS_THREAD_SW) ?
								"TS_THREAD_SW" :
								((sh->threads_type[i] == TS_THREAD_HW) ?
										"TS_THREAD_HW" : "UNKNOWN")));
	}

	fprintf(OUTPUT, "\tScheduled Threads: %hhu/%hhu  Running Threads: %hhu/%hhu (SW/HW)\n",
			sh->num_sw_threads, sh->num_hw_threads, sh->running_num_sw_threads,
			sh->running_num_hw_threads);

	fprintf(OUTPUT, "\n\tSW thread entry address: %p \n", sh->sw_thread);
	// Maybe add info about pthread attributes ...

	for (i = 0; i < TS_MAX_REDUNDANT_THREADS; i++) {
		fprintf(OUTPUT,
				"\tHW thread %d control structure at %p and assigned slot: %hhu \n",
				i, &(sh->hw_thread[i]), sh->hw_slot_nums[i]);
	}

	fprintf(OUTPUT, "\tCurrent os-call index: %u \n", sh->func_calls_idx);

	for (i = 0; i < TS_MAX_REDUNDANT_THREADS; i++) {
		if ( sh->sfs[i] != NULL ){
			shadow_sfs_dump(sh->sfs[i]);
		}
	}
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


void inline shadow_func_stat_inc_i(uint32_t idx){
	function_intercepted[idx]++;
}

void inline shadow_func_stat_inc_s(uint32_t idx){
	function_shadowed[idx]++;
}

void shadow_dump_func_stats(){
	int i;
	fprintf(OUTPUT, "Function stats legend: yield, exit, mbox_init, mbox_destroy, mbox_put, mbox_get, rq_init, rq_close, rq_receive, rq_send\n");
	fprintf(OUTPUT, "Function stats intercepted: %u", function_intercepted[0]);
	for (i=1; i< IDX_SIZE; i++){
		fprintf(OUTPUT, ", %u", function_intercepted[i]);
	}
	fprintf(OUTPUT, "\n");
	fprintf(OUTPUT, "Function stats shadowed: %u", function_shadowed[0]);
	for (i=1; i< IDX_SIZE; i++){
		fprintf(OUTPUT, ", %u", function_shadowed[i]);
	}
	fprintf(OUTPUT, "\n");
}


void shadow_set_level(shadowedthread_t *sh, uint8_t l) {
	assert(sh != NULL);
	// limit the level to allowed levels
	if( l < 1 ){ l = 1;}
	if( l > 3 ){ l = 3;}
	sh->level = l;
}

void shadow_set_swthread(shadowedthread_t *sh, void* (*entry)(void*)) {
	assert(sh != NULL);
	sh->sw_thread = entry;
}

void shadow_set_resources(shadowedthread_t *sh, struct reconos_resource * res,
						unsigned int res_count) {
	assert(sh != NULL);
	sh->resources = res;
	sh->resources_count = res_count;
}

void shadow_set_options(shadowedthread_t *sh, uint32_t options) {
	assert(sh != NULL);
	sh->options = options;
}

/**
 * @brief Copies parameters in shadowedthread structure. shadow_set_threads actually starts/ends threads.
 * @Note  When TS_MANUAL_SCHEDULE is not set in options, shadow scheduler may activate/deactivate
 *        threads as it thinks is best!
 */
void shadow_set_threadcount(shadowedthread_t *sh, uint8_t hw, uint8_t sw) {
	assert(sh != NULL);

	sh->num_hw_threads = hw;
	sh->num_sw_threads = sw;
}

bool shadow_set_hwslots(shadowedthread_t *sh, uint8_t hwt, uint8_t hwslot) {
	assert(sh != NULL);

	if (hwt < TS_MAX_REDUNDANT_THREADS) {
		sh->hw_slot_nums[hwt] = hwslot;
		return true;
	} else {
		return false;
	}
}

void shadow_set_program(shadowedthread_t *sh, const char* progname){
	int i;
	assert(sh != NULL);
	for (i=0; i< TS_MAX_REDUNDANT_THREADS; i++){
		reconos_hwt_setprogram(&sh->hw_thread[i], progname);
	}
}

void shadow_set_initdata(shadowedthread_t *sh, void* init_data) {
	assert(sh != NULL);
	sh->init_data = init_data;
}

void shadow_set_errorhandler(shadowedthread_t *sh, void (*eh)(sh_err_t error)){
	assert(sh != NULL);
	sh->error_callback = eh;
}

extern int pthread_getattr_np(pthread_t thread, pthread_attr_t *attr);

#ifndef HOST_COMPILE
extern int pthread_attr_getstack(pthread_attr_t *attr, void **stackaddr, size_t *stacksize);
#endif

void shadow_get_stack(shadowedthread_t *sh, unsigned int thread_idx, void ** stackaddr, size_t *stacksize) {
	pthread_attr_t attr;
	int retval;
	assert(sh != NULL);
	retval = pthread_getattr_np(sh->threads[thread_idx],&attr); //@WARNING: Non portable!
	if (retval != 0 ){
		fprintf(OUTPUT, "shadow_get_stack: thread_getattr_np failed.\n");
		exit(-1);
	}
	retval = pthread_attr_getstack(&attr, stackaddr, stacksize);
	if (retval != 0 ){
		fprintf(OUTPUT, "shadow_get_stack: pthread_attr_getstack failed.\n");
		exit(-1);
	}
}
//
// Private API
//

/**
 * @brief check if shadow thread is properly configured
 * @todo Needs more checks!
 */
bool shadow_check_configuration(shadowedthread_t *sh) {
	assert(sh != NULL);

	// Check if at least one thread, may it be hw or sw, is configured.
	assert( (sh->sw_thread    != NULL) ||
			(sh->hw_thread[0].delegate != 0) ||
			(sh->hw_thread[1].delegate != 0) ||
			(sh->hw_thread[2].delegate != 0));
	return true;
}

# ifndef S_SPLINT_S
// Change shadowing status of a shadowed thread.
void shadow_set_state(shadowedthread_t *sh, shadow_state_t s) {
	timing_t now;
	timing_t diff;
	assert(sh != NULL );
	if (sh->sh_status == TS_ACTIVE && s == TS_INACTIVE){
		// set deactivation timestamp
		sh->deactivation_time = gettime();
	}
	if (sh->sh_status == TS_PREACTIVE && s == TS_ACTIVE){
		// calculate error detection offline time
		now = gettime();
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
#endif

shadow_state_t shadow_get_state(shadowedthread_t *sh) {
	assert(sh != NULL);
	return sh->sh_status;
}

// Lock to the shadow list management
void ts_lock() {
	assert(pthread_mutex_lock(&ts_mutex) == 0);
}

// Unlock the shadow list management
void ts_unlock() {
	assert(pthread_mutex_unlock(&ts_mutex) == 0);
}

// Status of the shadow list management lock
int ts_lock_status() {
	int result = pthread_mutex_trylock(&ts_mutex);
	if(result == 0){
		assert(pthread_mutex_unlock(&ts_mutex) == 0);
		return 0;
	} else {
		return 1;
	}
}

/**
 * @brief Returns true if the calling thread is the leading thread.
 */
bool is_leading_thread(shadowedthread_t *sh, pthread_t this){
	// If there are HWT, then they come first in the sh->threads array.
	// In transmodal case, we assume one HWT and one SWT. Therefore HWT will be at
	// sh->threads[0] and SWT will be at sh->threads[1]
	if( (sh->options & TS_HW_LEADS) == TS_HW_LEADS){
		return sh->threads[0] == this;
	}else if( (sh->options & TS_SW_LEADS) == TS_SW_LEADS){
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

bool is_shadowed_in_parent(pthread_t handle, shadowedthread_t **parent) {
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
				}
				TS_DEBUG1("Yes ,handle %lu is a shadowedthread_attr_t \n", (unsigned long int)handle);
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

bool is_shadowed(pthread_t handle) {
	return is_shadowed_in_parent(handle, NULL);
}

/**
 * @brief Pushes a function call object into a fifo for later retrieval by the shadow thread.
 */
void shadow_func_call_push(shadowedthread_t *sh, func_call_t * func_call){
	assert(sh != NULL);
	assert(func_call != NULL);

	// Add correct call index
	ts_lock();
	func_call->index = sh->func_calls_idx;
	sh->func_calls_idx++;
	ts_unlock();
	// Push into internal fifo
	if (sh->num_hw_threads + sh->num_sw_threads > 1) {
			fifo_push(&sh->func_calls, func_call);
	}
}

/*
 * @brief Pops a function call object from a fifo, so a shadow thread can compare it with its own function call.
 */
void shadow_func_call_pop(shadowedthread_t *sh, func_call_t * func_call){
	assert(sh!=NULL);
	assert(func_call!=NULL);
	// Pop from internal fifo - should block when empty!
	fifo_pop(&sh->func_calls, func_call);

}



//
// Shadowed thread creation.
//
void shadow_thread_create(shadowedthread_t * sh) // Init data passed to worker threads
{
	//
	// Sanity checks
	//
	assert(sh != NULL);
	assert(shadow_check_configuration(sh));

	ts_lock();

	//
	// If first call, init the shadow system itself
	//
	assert(pthread_once(&shadow_system_is_initialized, shadow_system_init) == 0);

	//
	// Insert in global data structures
	//
	TS_DEBUG("Adding shadowed thread to global list \n");
	shadow_list_add(sh);
	//shadow_dump(sh);

	//
	// Schedule this thread for the first time
	//
	//shadow_schedule(sh,SCHED_FLAG_NONE);
	shadow_set_state(sh, TS_ACTIVE);

	//
	// Activate new threads, deactivate unneeded ones.
	//
	TS_DEBUG("Activating Threads \n");
	shadow_set_threads(sh);
	//shadow_dump(sh);

	ts_unlock();
}

int shadow_join(shadowedthread_t * sh, void **value_ptr) {
	int i;
	int ret = 0;

	assert(sh != NULL);
	for (i = 0; i < TS_MAX_REDUNDANT_THREADS; i++) {
	//for (i = 0; i < 1; i++) {
		if (sh->threads_type[i] != TS_THREAD_NONE) {
			//TS_DEBUG1("Joining thread %8lu ...\n", sh->threads[i]);
			fprintf(OUTPUT, "TS: " "Joining thread %8lu ...\n", sh->threads[i]);
			ret = pthread_join(sh->threads[i], value_ptr);
		}
	}
	return ret;
}
