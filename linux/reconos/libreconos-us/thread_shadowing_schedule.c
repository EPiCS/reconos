///
/// \file thread_shadowing.h
/// Thread shadowing framework. Implementation of scheduler.
///
/// \author     Sebastian Meisner   <sebastian.meisner@upb.de>
/// \date       10.06.2011
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2011.
//

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <pthread.h>
#include <semaphore.h>

#include "thread_shadowing.h"
#include "thread_shadowing_schedule.h"

//
// Debugging
//
//#define DEBUG 1

#ifdef DEBUG
#define SCHED_DEBUG(message) printf("SCHED: " message)
#define SCHED_DEBUG1(message, arg1) printf("SCHED: " message, (arg1))
#define SCHED_DEBUG2(message, arg1, arg2) printf("SCHED: " message, (arg1), (arg2))
#define SCHED_DEBUG3(message, arg1, arg2, arg3) printf("SCHED: " message, (arg1), (arg2), (arg3))
#define SCHED_DEBUG4(message, arg1, arg2, arg3, arg4) printf("SCHED: " message, (arg1), (arg2), (arg3), (arg4))
#else
#define SCHED_DEBUG(message)
#define SCHED_DEBUG1(message, arg1)
#define SCHED_DEBUG2(message, arg1, arg2)
#define SCHED_DEBUG3(message, arg1, arg2, arg3)
#define SCHED_DEBUG4(message, arg1, arg2, arg3, arg4)
#endif

// Pointer to the global system information structure, which contains 
// the heat and error maps, current hw slot allocations and much more.
//static sys_info_t * sys_info;

//
extern shadowedthread_t *shadow_list_head;

// shadow_schedule() will be called by different threads, so we have to 
// protect our own data structures against concurrent access.
static pthread_mutex_t shadow_schedule_mutex = PTHREAD_MUTEX_INITIALIZER;

//
// Inits global data structures of the shadow scheduler
void shadow_schedule_init() {
	// Mutex already initialized
}

//
// Debug Routine
//
void shadow_schedule_dump(shadowedthread_t *shadow_list_head) {
	shadowedthread_t *current = shadow_list_head;
	int semval = 1337;
	while (current) {
		sem_getvalue(&current->sh_wait_sem, &semval);
		SCHED_DEBUG3("Thread %lu active:%s semaphore count:%i\n",
				current->threads[0],
				current->sh_status == TS_INACTIVE ? "inactive" : (
				current->sh_status == TS_PREACTIVE ? "pre-active":
													 "active"),
				semval);
		current = current->next;
	}
}

//
// Information that influences the scheduling decision:
// - availability of sw and hw implementations
// - temperature map
// - error map
// - available hw slots
// - available cpus
// - reliability requirements of thread
// @TODO:  This is a stub. A theoretically well sounded algorithm has to be found for this complex 
//          problem of finding a suitable set of parameters, where all reliability constraints are met.
//
// First implementation: Shadow all threads in a round robin style.
// @param shadow_list_head To schedule the shadow threads we need access to the list of shadowed threads.
// @param flags Modifies behaviour of scheduling. Allowed flags start with SCHED_FLAG_ and currently comprise:
//				SCHED_FLAG_NONE Default behaviour; makes next shadow thread runnable
//				SCHED_FLAG_INIT Used in shadow_thread_create; just makes sure at least one shadow thread will run
void shadow_schedule(shadowedthread_t *this_shadow,  uint32 flags) {
	SCHED_DEBUG("Scheduler called...\n");
	pthread_mutex_lock(&shadow_schedule_mutex);

	shadowedthread_t *current = shadow_list_head;

	if (flags & SCHED_FLAG_INIT) {
		SCHED_DEBUG("Just checking if at least one thread is active...\n");
		bool found_active = false;
		// Make sure one shadow thread is active
		// 1st: look for an active thread
		// 2nd: if no active thread, activate first one
		while (current) {
			if (shadow_get_state(current) == TS_ACTIVE) {
				found_active = true;
				break; // out of while loop!
			}
			current = current->next;
		}
		if (!found_active) {
			shadow_set_state(shadow_list_head, TS_ACTIVE);
			sem_post(&shadow_list_head->sh_wait_sem);
		}
	} else {
		// Default behaviour: Round robin schedule
		// State Machine: Only reschedule if this is an active thread
		switch(shadow_get_state(this_shadow)){
			case TS_INACTIVE:
				break; // Do nothing

			case TS_PREACTIVE:
				shadow_set_state(this_shadow, TS_ACTIVE);
				sem_post(&this_shadow->sh_wait_sem);
				break;

			case TS_ACTIVE:
				shadow_set_state(this_shadow, TS_INACTIVE);
				// find next thread to schedule
				//@TODO: What about locking?
				if (this_shadow->next == NULL) {
					SCHED_DEBUG1("Activating thread %lu\n",
							shadow_list_head->threads[0]);
					shadow_set_state(shadow_list_head, TS_PREACTIVE);
				} else {
					SCHED_DEBUG1("Activating thread %lu\n",
							this_shadow->next->threads[0]);
					shadow_set_state(this_shadow->next, TS_PREACTIVE);
				}
				break;
		}


//				// Set resources of shadow threads
//				if (!(current->options & TS_MANUAL_SCHEDULE)) {
//					current->num_sw_threads = 1;
//					current->num_hw_threads = 0;
//					current->hw_slot_nums[0] = 0;
//					current->hw_slot_nums[1] = 1;
//					current->hw_slot_nums[2] = 2;
//				}

	}
	shadow_schedule_dump(shadow_list_head);
	pthread_mutex_unlock(&shadow_schedule_mutex);
	SCHED_DEBUG("Scheduler leaving...\n");
}
