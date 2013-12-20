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
//! @file config_cparam.h
//! This contains the configuration parameter's for Message Queue, 
//! Shared Memory and Dynamic Buffer mgmt routines. The following fields are 
//! defined  based on the values in sys/init.c
//----------------------------------------------------------------------------------------------------//
#ifndef CONFIG_CPARAM_H
#define CONFIG_CPARAM_H

#include <os_config.h>
#include <config/config_param.h>

/************************************************************************/
/* Memory sizes for the various memory blocks			        */
/************************************************************************/

// The total Memory needed for all PID queue's in the system. This includes
// ready queue and semaphore wait queues.

#ifdef CONFIG_SEMA
#define PID_QUEUE_MSIZE  ((N_PRIO*MAX_READYQ)+(MAX_SEM*MAX_SEM_WAITQ))
#else
#define PID_QUEUE_MSIZE  (N_PRIO*MAX_READYQ)
#endif

#ifdef CONFIG_PTHREAD_MUTEX
#define PTHREAD_MUTEX_QUEUE_MSIZE (MAX_PTHREAD_MUTEX * MAX_PTHREAD_MUTEX_WAITQ)
#endif

#ifdef CONFIG_PTHREAD_SUPPORT
// The total memory needed for all the thread context. Calculated based on
// definition in config_param.h
#define PTHREAD_STACK_MSIZE (MAX_PTHREADS * PTHREAD_STACK_SIZE)
#endif

#ifdef CONFIG_SHM
// Total Memory size for the various Shared Memory
// This is how it is calculated from (struct _shm_init):	
// -# Add msize of all the shared memory to get the total msize
#ifndef SHM_MSIZE 
#define SHM_MSIZE 	 100
#endif
#endif

#ifdef CONFIG_MALLOC
// Total Memory size for the Dynamic buffer management	
// This is how it is calculated from (struct _malloc_init):
//  -#	msize for a single memory block = mem_bsize * n_blocks
//  -#	Add msize of all the Memory blocks to get the total msize
 
#ifndef MALLOC_MSIZE 
#define MALLOC_MSIZE 	 120
#endif
#endif

/************************************************************************/
/* Maximum number of various elements - See config_init.h		*/
/************************************************************************/
#ifndef N_INIT_PROCESS 
#define N_INIT_PROCESS 	0	
#endif

#ifndef N_INIT_SELF_PTHREADS
#define N_INIT_SELF_PTHREADS   0
#endif
#ifndef N_INIT_MELF_PTHREADS
#define N_INIT_MELF_PTHREADS   0
#endif

#ifdef CONFIG_SHM
#ifndef N_SHM 
#define N_SHM		1	
#endif
#endif

#ifdef CONFIG_MALLOC
#ifndef N_MALLOC_BLOCKS 
#define N_MALLOC_BLOCKS	2	
#endif
#ifndef TOT_MALLOC_BLOCKS 
#define TOT_MALLOC_BLOCKS 20	// Total number of memory blocks in the 
				// system. This is:			
				//  - Sum of n_blocks field of all elements  in malloc_config[]	 
#endif
#endif

#endif
