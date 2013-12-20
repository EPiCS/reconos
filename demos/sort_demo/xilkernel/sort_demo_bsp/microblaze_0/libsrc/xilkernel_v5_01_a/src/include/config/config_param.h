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
//! @file config_param.h 
//! This file contains configuration parameter's for process Management, 
//! thread Management and semaphore routines.
//----------------------------------------------------------------------------------------------------//

#ifndef _CONFIG_PARAM_H
#define _CONFIG_PARAM_H

#include <os_config.h>
#include <sys/ksched.h>

#if SCHED_TYPE == SCHED_RR 
#ifdef N_PRIO             
#undef N_PRIO
#endif
#define N_PRIO 1 	// N_PRIO always 1 for SCHED_RR 
#define PRIO_HIGHEST 0 // Highest priority 
#define PRIO_LOWEST  0 // Lowest  priority 
#endif /* SCHED_TYPE == SCHED_RR */

#if SCHED_TYPE == SCHED_PRIO 	// SCHED_PRIO 
#ifndef N_PRIO                  // was not defined in os_config.h 
#define N_PRIO 32	        // Number of priority levels 
#define PRIO_HIGHEST  0         // Highest priority 
#define PRIO_LOWEST  31	        // Least Priority 
#else                           
#define PRIO_HIGHEST 0
#define PRIO_LOWEST (N_PRIO-1)
#endif
#endif	/* SCHED_TYPE == SCHED_PRIO */


/************************************************************************/
/*	InterProcess Communication options				*/
/************************************************************************/

// Semaphore Specific Configs 
#ifdef CONFIG_SEMA

#ifndef MAX_SEM 
#define MAX_SEM 20		// Max Semaphore count 
#endif
#ifndef MAX_SEM_WAITQ 
#define MAX_SEM_WAITQ 10	// Max semaphore wait Q length 
#endif
#endif 	/* CONFIG_SEMA */


#ifdef CONFIG_MSGQ 
#ifndef CONFIG_SEMA
#error "Message queues require semaphores. Please define CONFIG_SEMA"
#endif
#ifndef NUM_MSGQS 
#define NUM_MSGQS     10
#endif
#ifndef MSGQ_CAPACITY 
#define MSGQ_CAPACITY 10
#endif
#endif 	/* CONFIG_MSGQ */

#ifdef CONFIG_PTHREAD_MUTEX
#ifndef CONFIG_PTHREAD_SUPPORT
#error "Pthread mutex requires pthread support. Please define CONFIG_PTHREAD_SUPPORT"
#endif
#ifndef MAX_PTHREAD_MUTEX 
#define MAX_PTHREAD_MUTEX  5
#endif

#ifndef MAX_PTHREAD_MUTEX_WAITQ      
#define MAX_PTHREAD_MUTEX_WAITQ 10  // Max pthread_mutex wait Q length 
#endif
#endif

/************************************************************************/
/* Memory Management related options.					*/
/************************************************************************/

#ifdef CONFIG_PTHREAD_SUPPORT
#ifndef MAX_PTHREADS          
#define MAX_PTHREADS	5	// Max number of threads
#endif

#ifndef PTHREAD_STACK_SIZE 
#define PTHREAD_STACK_SIZE	600	// Should be a multiple of 4
					// for word alignment	
#endif
#endif	/* CONFIG_PTHREAD_SUPPORT */

#ifdef CONFIG_ELF_PROCESS
#define MAX_PROCESS_CONTEXTS (MAX_PROCS + MAX_PTHREADS)
#else
#ifdef CONFIG_PTHREAD_SUPPORT
#define MAX_PROCESS_CONTEXTS (MAX_PTHREADS)
#else
#define MAX_PROCESS_CONTEXTS 0
#endif
#endif  /* CONFIG_PTHREAD_SUPPORT */

#endif	/* _CONFIG_PARAM_H */
