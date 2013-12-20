/******************************************************************************
*
* (c) Copyright 2010 Xilinx, Inc. All rights reserved.
*
* This file contains confidential and proprietary information of Xilinx, Inc.
* and is protected under U.S. and international copyright and other
* intellectual property laws.
*
* DISCLAIMER
* This disclaimer is not a license and does not grant any rights to the
* materials distributed herewith. Except as otherwise provided in a valid
* license issued to you by Xilinx, and to the maximum extent permitted by
* applicable law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL
* FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS,
* IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
* MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE;
* and (2) Xilinx shall not be liable (whether in contract or tort, including
* negligence, or under any other theory of liability) for any loss or damage
* of any kind or nature related to, arising under or in connection with these
* materials, including for any direct, or any indirect, special, incidental,
* or consequential loss or damage (including loss of data, profits, goodwill,
* or any type of loss or damage suffered as a result of any action brought by
* a third party) even if such damage or loss was reasonably foreseeable or
* Xilinx had been advised of the possibility of the same.
*
* CRITICAL APPLICATIONS
* Xilinx products are not designed or intended to be fail-safe, or for use in
* any application requiring fail-safe performance, such as life-support or
* safety devices or systems, Class III medical devices, nuclear facilities,
* applications related to the deployment of airbags, or any other applications
* that could lead to death, personal injury, or severe property or
* environmental damage (individually and collectively, "Critical
* Applications"). Customer assumes the sole risk and liability of any use of
* Xilinx products in Critical Applications, subject only to applicable laws
* and regulations governing limitations on product liability.
*
* THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE
* AT ALL TIMES.
*
******************************************************************************/
//----------------------------------------------------------------------------------------------------//
//! @file sched.c
//! This file contains routines for process scheduling
//----------------------------------------------------------------------------------------------------//

#include <stdio.h>
#include <os_config.h>
#include <sys/ksched.h>
#include <sys/entry.h>
#include <config/config_param.h>
#include <config/config_cparam.h>
#include <sys/process.h>
#include <sys/decls.h>

//----------------------------------------------------------------------------------------------------//
// Data
//----------------------------------------------------------------------------------------------------//


// Ready Queue - Array of N_PRIO process queues
struct _queue ready_q[N_PRIO] ;
signed char entry_mode = ENTRY_MODE_USER;       // Current entry mode into kernel
signed char resched = 0;                        // Indicates if rescheduling occurred elsewhere
char did_resched = 0;                           // Indicates if the kernel completed the rescheduling

#ifdef CONFIG_STATS
signed char sched_history[SCHED_HISTORY_SIZ];
int shp = 0;
#endif
//----------------------------------------------------------------------------------------------------//
// Declarations
//----------------------------------------------------------------------------------------------------//
extern unsigned int budget_ticks;
extern process_struct *ctx_save_process;
extern int save_context (process_struct *);
extern void restore_context (void);

int scheduler (void);

//----------------------------------------------------------------------------------------------------//
// Definitions
//----------------------------------------------------------------------------------------------------//

void readyq_init(void)
{
    unsigned int i = 0 ;

    for (;i < N_PRIO; i++ ) {
	alloc_q (&ready_q[i], MAX_READYQ, READY_Q, sizeof(char), i);
    }
}
int scheduler (void)
{

#ifdef CONFIG_DEBUGMON
    debugmon_dump_sched_info ();
#endif

    if (current_process->state == PROC_DEAD) {
	ctx_save_process = NULL;
	prev_pid = -1;
    }
    else if (current_process->pcontext.isrflag == 1) {    // If entered the kernel through an ISR, context saved in ISR itself
	ctx_save_process = NULL;
	prev_pid = current_pid;
    }
    else {
	ctx_save_process = current_process;
	prev_pid = current_pid;
    }

#if SCHED_TYPE == SCHED_RR
    sched_rr ();
#elif SCHED_TYPE == SCHED_PRIO
    sched_prio ();
#endif

    if( current_pid == -1 ) {
	DBG_PRINT ("XMK: Unable to find schedulable process. Kernel Halt.\r\n") ;
	while(1);
    }

    did_resched = 1;    // scheduler indicates that it completed the rescheduling
    resched = 0;        // scheduler always resets resched flag

#ifdef CONFIG_DEBUGMON
    debugmon_stack_check ();
#endif

#ifdef CONFIG_STATS
    if (shp != SCHED_HISTORY_SIZ)
	sched_history[shp++] = current_pid;
#endif

    if (prev_pid == current_pid)
	return 1;

    return 0;
}

#if SCHED_TYPE == SCHED_RR
//----------------------------------------------------------------------------------------------------//
//  @func - sched_rr
//! @desc
//!   Round Robin Scheduler.
//! @return
//!   - Nothing
//! @note
//!   - None
//----------------------------------------------------------------------------------------------------//
void sched_rr (void)
{
    signed char ready = -1;

    // Enqueue only currently running processes. Else,
    // If PROC_DEAD, no need to enqueue
    // If PROC_WAIT or PROC_TIMED_WAIT, already enqueued in appropriate wait queue
    // If PROC_DELAY, is in one of the timer queues
    // If idle_task, then does not need to enter the queue
    if (current_process->state == PROC_RUN) {
        ptable[current_pid].state = PROC_READY;
	if(current_pid != idle_task_pid)
	    penq (&ready_q[0], current_pid, 0);
    }

    SET_CURRENT_PROCESS (-1);

    while (ready_q[0].item_count != 0) {
	pdeq (&ready_q[0], &ready, 0);
	if (ptable[ready].state == PROC_DEAD) {   // Flush out dead processes
	    ready = -1;
	    continue;
	}
	else break;
    }

    if (ready == -1)
	ready = idle_task_pid;

#if 0
    DBG_PRINT ("XMK: Scheduler: scheduled pid: ");
    putnum (ready);
    DBG_PRINT ("\r\n");
#endif

    ptable[ready].state = PROC_RUN;
    SET_CURRENT_PROCESS (ready);
}
#endif /* SCHED_TYPE == SCHED_RR */

#if SCHED_TYPE == SCHED_PRIO
//----------------------------------------------------------------------------------------------------//
//  @func - sched_prio
//! @desc
//!   Pre-emptive strict priority scheduler
//! @return
//!   - Nothing
//! @note
//!   - None
//----------------------------------------------------------------------------------------------------//
void sched_prio (void)
{
    int i;
    signed char ready = -1;

    // Enqueue only currently running processes. Else,
    // If PROC_DEAD, no need to enqueue
    // If PROC_WAIT or PROC_TIMED_WAIT, already enqueued in appropriate wait queue
    // If PROC_DELAY, is in one of the timer queues
    // If idle_task, then does not need to enter the queue
    if (current_process->state == PROC_RUN) {
	ptable[current_pid].state = PROC_READY;
	if (current_pid != idle_task_pid)
	    penq (&ready_q[ptable[current_pid].priority], current_pid, 0);
    }

    SET_CURRENT_PROCESS (-1);

    for (i=0; i <= PRIO_LOWEST; i++) {
	while (ready_q[i].item_count != 0) {
	    pdeq (&ready_q[i], &ready, 0);
	    if (ptable[ready].state == PROC_DEAD) {   // Flush out dead processes
		ready = -1;
		continue;
	    }
	    else break;
	}

	if (ready != -1)
	    break;
    }

    if (ready == -1)
	ready = idle_task_pid;

#if 0
    DBG_PRINT ("XMK: Scheduler: scheduled pid: ");
    putnum (ready);
    DBG_PRINT ("\r\n");
#endif

    ptable[ready].state = PROC_RUN;
    SET_CURRENT_PROCESS (ready);
}
#endif /* SCHED_TYPE == SCHED_PRIO */

//----------------------------------------------------------------------------------------------------//
//  @func - suspend
//! @desc
//!   Suspend a process inside the kernel. A rescheduling followed by the corresponding context
//!   switch occurs within this routine.
//! @return
//!   - Nothing
//! @note
//!   - This routine is not expected to be invoked from within an ISR. i.e no suspension allowed in
//!     an ISR.
//----------------------------------------------------------------------------------------------------//
void suspend (void)
{
#ifdef CONFIG_STATS
    current_process->active_ticks++;
    budget_ticks++;
#endif
    if (scheduler ()) {
	DBG_PRINT ("XMK: Scheduling error. Cannot suspend current process.\r\n");
	while (1)
	    ;
    }

    if (ctx_save_process != NULL)
	if (save_context (ctx_save_process))    // Save context returns 0 during save
	    return;                             // When saved context is restored, returns a 1

    restore_context ();
}



