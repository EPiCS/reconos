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
// $Id: process.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file process.h
//! Process management declarations and definitions
//----------------------------------------------------------------------------------------------------//
#ifndef _PROCESS_H_
#define _PROCESS_H_

#include <config/config_param.h>
#include <config/config_cparam.h>
#include <sys/queue.h>
#include <sys/ktypes.h>
#include <sys/stats.h>
#include <sys/kpthread.h>

#ifdef __cplusplus
extern "C" {
#endif

//! Process States.
#define PROC_NEW                0   //! Process is new and has not been scheduled yet
#define PROC_RUN                1   //! Process is currently executing
#define PROC_READY              2   //! Process that is ready and considered for scheduling
#define PROC_WAIT               3   //! Process is waiting for a resource. Is out of ready queues and in some wait queue
#define PROC_TIMED_WAIT         4   //! Process is waiting for a resource with a timeout. Is out of ready queues and in some wait queue
#define PROC_DELAY              5   //! Process is waiting for a timeout
#define PROC_DEAD               6   //! State of process that has called exit and is now "dead" 

//----------------------------------------------------------------------------------------------------//
// Function prototypes - defined in sys/process.h
//----------------------------------------------------------------------------------------------------//
// Internal Kernel functions. These routines are not directly called from any
// process. They don't have reentrant code.
 
void xmk_enter_kernel (void);
void xmk_leave_kernel (void);
void process_block (queuep queue, unsigned int state) ;
void process_unblock( queuep queue ) ;
pid_t proc_create (unsigned int priority);
int  process_invalidate (process_struct *proc);

pid_t   sys_elf_process_create (void* pstart_addr, unsigned int priority);
int     sys_elf_exit (void);
int     sys_kill (pid_t pid);
int     sys_process_status (pid_t pid, p_stat *ps);
int     sys_yield(void);
pid_t   sys_get_currentPID(void);
int     sys_get_kernel_stats (kstats_t *stats);


pid_t   get_currentPID(void);
int     kill (pid_t pid);
int     process_status (pid_t pid, p_stat *ps);
int     yield(void);

#ifdef __cplusplus
}       
#endif 

#endif /* _PROCESS_H_ */

