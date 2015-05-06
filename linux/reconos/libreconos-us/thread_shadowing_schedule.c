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
#define DEBUG 1

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
	pthread_t this = pthread_self();
	printf("SCHED Thread %8lu: ", this);
	while (current) {
		sem_getvalue(&current->sh_wait_sem, &semval);
		printf("TID: %lu status:%s sem_cnt:%i; ",
				current->threads[0],
				current->sh_status == TS_INACTIVE ? "inactive" : (
				current->sh_status == TS_PREACTIVE ? "pre-active":
													 "active"),
				semval);
		current = current->next;
	}
	printf("\n");
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
// @param flags Unused at the moment
void shadow_schedule(shadowedthread_t *this_shadow,  uint32 flags) {
	SCHED_DEBUG("Scheduler called...\n");

	shadowedthread_t *current = shadow_list_head;
	int active_count=0;
	int semval;
	if (!(this_shadow->options & TS_MANUAL_SCHEDULE)) {
		// Default behaviour: Round robin schedule
		// State Machine: Only reschedule if this is an active thread
		// The three states {TS_INACTIVE, TS_PREACTIVE, TS_ACTIVE} are needed, because we modify state of another thread.
		// The other thread might be in the middle of a cycle and not synchronized to its shadow. Therefore we
		// set the other threads state to preactive. As soon as the other thread calls ts_yield, it will be at a synchronization
		// point and set its own state from TS_PREACTIVE to TS_ACTIVE, thus activating the shadow.
		switch(shadow_get_state(this_shadow)){
			case TS_INACTIVE:

				SCHED_DEBUG1("RR: TID %lu checking at least one thread is active\n", this_shadow->threads[0]);
				current = shadow_list_head;
				while (current) {
					if ( !(current->options & TS_MANUAL_SCHEDULE) &&
						(shadow_get_state(current) == TS_ACTIVE || shadow_get_state(current) == TS_PREACTIVE))
					{
						active_count++;
					}
					current = current->next;
				}
				if (active_count == 0){
					shadow_set_state(this_shadow, TS_ACTIVE);
					sem_getvalue(&this_shadow->sh_wait_sem, &semval);
					if(semval < 1){sem_post(&this_shadow->sh_wait_sem);}
					this_shadow->ts_active_cycles++;
				} else {
					this_shadow->ts_inactive_cycles++;
				}
				break;

			case TS_PREACTIVE:
				SCHED_DEBUG1("RR: TID %lu set to active\n", this_shadow->threads[0]);
				shadow_set_state(this_shadow, TS_ACTIVE);
				sem_getvalue(&this_shadow->sh_wait_sem, &semval);
				if(semval < 1){sem_post(&this_shadow->sh_wait_sem);}
				this_shadow->ts_active_cycles++;
				break;

			case TS_ACTIVE:
				shadow_set_state(this_shadow, TS_INACTIVE);
				this_shadow->ts_inactive_cycles++;

				// find next thread to schedule
				current = this_shadow->next;
				while ( current != this_shadow){
					if (current == NULL){
						current = shadow_list_head;
					}
					if (current->options & TS_MANUAL_SCHEDULE){
						current = current->next;
						continue;
					}
					SCHED_DEBUG1("RR: TID %lu set to preactive\n",	current->threads[0]);
					shadow_set_state(current, TS_PREACTIVE);
					current->ts_preactive_cycles++;
					break;
				}
				if ( current == this_shadow) {
					// we looped through the list and ended up here again, so there is no other thread to activate.
					// Therefore we stay activated.
					SCHED_DEBUG1("RR: TID %lu keeps state active\n",	current->threads[0]);
					shadow_set_state(this_shadow, TS_ACTIVE);
					sem_getvalue(&this_shadow->sh_wait_sem, &semval);
					if(semval < 1){sem_post(&this_shadow->sh_wait_sem);}
					this_shadow->ts_inactive_cycles--;
					this_shadow->ts_active_cycles++;
				}
				break;
		}
	}  else if ( this_shadow->options & TS_MANUAL_SCHEDULE ) {
		SCHED_DEBUG3("Scheduler Manual: Activating Shadow Thread 0x%p, with threads %lu, %lu \n",this_shadow, this_shadow->threads[0],this_shadow->threads[0]);

		shadow_set_state(this_shadow, TS_ACTIVE);
		sem_getvalue(&this_shadow->sh_wait_sem, &semval);
		if(semval < 1){sem_post(&this_shadow->sh_wait_sem);}
		this_shadow->ts_active_cycles++;
	}
	shadow_schedule_dump(shadow_list_head);

	SCHED_DEBUG("Scheduler leaving...\n");
}
