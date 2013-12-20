////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2004 Xilinx, Inc.  All rights reserved.
//
// Xilinx, Inc.
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A
// COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
// ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
// STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
// IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
// FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
// XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
// THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
// ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
// FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE.
//
// $Id: ksched.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file ksched.h
//! Kernel level scheduling definitions and declarations
//----------------------------------------------------------------------------------------------------//

#ifndef _KSCHED_H
#define _KSCHED_H

#include <os_config.h>
#include <sys/ktypes.h>
#include <sys/sched.h>

#ifdef __cplusplus
extern "C" {
#endif

// Scheduling algorithm.
#ifndef SCHED_OTHER
#define SCHED_OTHER     0    // Other 
#endif
#ifndef SCHED_FIFO
#define SCHED_FIFO      1    // FIFO scheduling 
#endif
#ifndef SCHED_RR
#define SCHED_RR 	2    // Round Robin Scheduling type 
#endif

// This will go away in the future
#define SCHED_PRIO 	3    // Priority Preemptive Scheduling type 


void readyq_init(void) ;
void process_scheduler(void) ;
void process_scheduler_and_switch (void);
void suspend (void);

#if SCHED_TYPE == SCHED_RR
void sched_rr (void);
#elif SCHED_TYPE == SCHED_PRIO
void sched_prio(void);
#endif


#ifdef MB_XILKERNEL
#define XMK_CONTEXT_SWITCH(prevpid)  microblaze_context_switch(prevpid)
#else // PPC
#define XMK_CONTEXT_SWITCH(prevpid)  ppc_context_switch(prevpid)
#endif // MB_XILKERNEL

#ifdef __cplusplus
}       
#endif 

#endif /* _KSCHED_H */
