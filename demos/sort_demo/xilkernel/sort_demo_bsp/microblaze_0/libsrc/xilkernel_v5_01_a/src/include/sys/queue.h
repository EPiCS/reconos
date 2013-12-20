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
// $Id: queue.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file queue.h
//! Queue management declarations and defines
//----------------------------------------------------------------------------------------------------//
#ifndef _QUEUE_H
#define _QUEUE_H

#include <config/config_param.h>
#include <config/config_cparam.h>
#include <sys/ktypes.h>

#ifdef __cplusplus
extern "C" {
#endif

//! Queue Types 
#define RUN_Q 	        1	//! Used to store Processes in PROC_RUN state 
#define READY_Q         2 	//! Used to store Processes in PROC_READY state 
#define SEM_Q	        3	//! Used for storing processes waiting for semaphore resource 
#define MSG_Q 	        4	//! Used for storing Messages in Message Q 
#define PTHREAD_JOIN_Q  5       //! Used for storing Threads waiting to join in a join Q 
#define PTHREAD_EXIT_Q  6       //! Used for storing Threads in state PTHREAD_STATE_EXIT
#define PTHREAD_MUTEX_Q 7       //! Used for storing processes waiting for mutex resource

// Function prototypes defined in sys/queue.c
void    alloc_q (queuep queue, unsigned char max_items, 
                 unsigned char qtype, unsigned short size, unsigned char qno);
void    qinit (queuep queue);
void    enq (queuep queue, const void *item, unsigned short key);
void    deq (queuep queue, void *item, unsigned short key);
int     pdelq (queuep queue, pid_t item);
void    pdeq (queuep queue, pid_t *item, unsigned short key);
void    penq (queuep queue, pid_t item, unsigned short key);
void    prio_penq (queuep queue, pid_t item, unsigned short key); 
void    prio_pdeq (queuep queue, pid_t *item, unsigned short key); 
int     prio_pdelq (queuep queue, pid_t item);

#ifdef __cplusplus
}       
#endif 

#endif  /* _QUEUE_H */
