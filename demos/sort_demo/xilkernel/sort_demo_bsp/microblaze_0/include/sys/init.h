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
// $Id: init.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file init.h
//! This files contains structures, that are used for configuring the system. 
//! The values are specified in sys/init.c
//----------------------------------------------------------------------------------------------------//

#ifndef _INIT_H
#define _INIT_H

#include <config/config_cparam.h>
#include <config/config_param.h>
#include <sys/ktypes.h>
#ifdef __MICROBLAZE__
#include <sys/mpu.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

//----------------------------------------------------------------------------------------------------//
//! Processes to be initialised at the start of the system are defined here.
//----------------------------------------------------------------------------------------------------//
struct _process_init {
    unsigned int p_start_addr ;	 // Start address of the process 
    int priority ;		 // Priority of the process 
} ;

//----------------------------------------------------------------------------------------------------//
//! Threads to be a part of kernel executable to be initialised at the start of the
//! system are defined here.
//----------------------------------------------------------------------------------------------------//
struct _elf_pthread_init {
    void (*start_func)(void);	 // Start address of the thread
    int priority ;	         // Priority of the thread
} ;

//----------------------------------------------------------------------------------------------------//
//! The shared memory in the system are defined here.
//! There is a entry for each Shared Memory
//----------------------------------------------------------------------------------------------------//
struct _shm_init {
    unsigned int shm_size ;		// Size of the Shared Memory 
} ;

//----------------------------------------------------------------------------------------------------//
//! The dynamic memory (buffer) management module is configured here.
//! The system can have memory blocks of different sizes. Memory blocks of 
//! different size and the number of memory blocks is specified here.
//----------------------------------------------------------------------------------------------------//
typedef struct bufmalloc_init_s {
    unsigned int bsiz;                  // Memory Block size 
    char         nblks;                 // Number of blocks of the size 
} bufmalloc_init_t;

void soft_tmr_init(void);
void pthread_init(void);
void bufmalloc_init(void);
void hw_init(void);
int xmk_add_static_thread(void* (*start_routine)(void *), int sched_priority);    
void xilkernel_init (void);
void xilkernel_start (void);

#ifdef __cplusplus
}       
#endif 

#endif /* _INIT_H */
