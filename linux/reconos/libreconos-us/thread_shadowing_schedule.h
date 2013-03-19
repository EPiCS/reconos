///
/// \file thread_shadowing.h
/// Thread shadowing framework. Scheduler include file.
///
/// \author     Sebastian Meisner   <sebastian.meisner@upb.de>
/// \date       10.06.2011
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2011.
//

#ifndef __THREAD_SHADOWING_SCHEDULE_H__
#define __THREAD_SHADOWING_SCHEDULE_H__

#include "thread_shadowing.h"

#define SCHED_FLAG_NONE 0
#define SCHED_FLAG_INIT 1

void shadow_schedule_init();
void shadow_schedule( shadowedthread_t *this_shadow, uint32 flags);
 
void shadow_schedule_dump(shadowedthread_t *shadow_list_head);

#endif
