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
//! @file timer_intr.c  
//! This module contains the timer interrupt handler routine and associated 
//! support routines for microblaze.
//----------------------------------------------------------------------------------------------------//

#include <os_config.h> 
#include <sys/process.h>
#ifdef CONFIG_INTC
#include <xintc.h>
extern XIntc sys_intc;
#endif

#ifdef CONFIG_STATS
unsigned int budget_ticks;
#endif

//void timer_int_handler(void* unused);
void timer_int_handler(void);
extern void soft_tmr_handler (void);
extern signed char resched;
extern process_struct *current_process;
unsigned int kernel_ticks;   //! Ticks since kernel startup
char timer_need_refresh = 0; //! Do we need a reset?
unsigned char sched_partial_tick;

//----------------------------------------------------------------------------------------------------//
//  @func - timer_int_handler
//! @desc
//!   System timer interrupt handler
//!   - Do a rescheduling operation
//!   - If a context switch occurs within this routine,
//!     - When returning out of process_scheduler, process executing will return in the appropriate
//!       context when it was switched out on a previous flow through this execution path.
//!   - Reset PIT interval to start a full time slice (if PIT in the system) (if INTC not present)
//! @param
//!   - none
//! @return
//!   - nothing
//! @note
//!   - May NOT return from this routine if a NEW process context is scheduled in the scheduler
//!   - A context switch does not occur within this routine if an INTC is present. The switch 
//!     occurs at the end of the INTC ISR.
//----------------------------------------------------------------------------------------------------//
void timer_int_handler (void)
{
    // Update global kernel ticks so far
    kernel_ticks++;
#ifdef CONFIG_STATS
    current_process->active_ticks++;
    budget_ticks++;
#endif
#ifdef CONFIG_TIME 
    soft_tmr_handler ();
#endif

    if (sched_partial_tick) {
#if SCHED_TYPE == SCHED_RR
        // Avoid one more starvation case. On a partial schedule tick,
        // you want to give the next full time quantum to the thread
        // which was scheduled partially and not any thread that 
        // timed out in soft_tmr_handler. 
        // Note: We do this only for RR scheduling where we don't 
        //       want starvation.
        resched = 0;
#endif
        sched_partial_tick = 0;
    } else {
        resched = 1;
    }

    timer_need_refresh = 1;
}
