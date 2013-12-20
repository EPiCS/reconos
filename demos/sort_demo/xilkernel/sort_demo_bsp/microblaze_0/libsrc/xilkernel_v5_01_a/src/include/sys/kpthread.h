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
//! @file kpthread.h
//! Kernel pthread declarations and definitions
//----------------------------------------------------------------------------------------------------//
#ifndef _KPTHREAD_H
#define _KPTHREAD_H

#include <os_config.h>
#include <config/config_cparam.h>
#include <config/config_param.h>
#include <sys/ktypes.h>
#include <pthread.h>

#ifdef __cplusplus
extern "C" {
#endif

// Defines

#define PTHREAD_INVALID          0xFF
#define PTHREAD_MUTEX_INVALID    0xFFFF
// Sched state
#define PTHREAD_STATE_ALIVE     1
#define PTHREAD_STATE_EXIT      2
#define PTHREAD_STATE_DETACHED  3
#define PTHREAD_STATE_BLOCKED   4

void pthread_terminate (pthread_info_t *thread);

// pthreads - Kernel implementation
int sys_pthread_create (pthread_t *thread, const pthread_attr_t *attr,
	 void *(*start_func)(void*), void *param);
void sys_pthread_exit (void *retval) ;
int sys_pthread_join (pthread_t target, void **retval);
pthread_t sys_pthread_self (void);
int sys_pthread_detach (pthread_t thread);
int sys_pthread_equal (pthread_t thread_1, pthread_t thread_2);
int pthread_attr_init (pthread_attr_t *attr);
int pthread_attr_destroy (pthread_attr_t *attr);

#if SCHED_TYPE == SCHED_PRIO
int pthread_attr_setschedparam (pthread_attr_t *attr,
	 const struct sched_param *spar);
int pthread_attr_getschedparam (const pthread_attr_t *attr,
	 struct sched_param *spar);
#endif

int pthread_attr_getdetachstate (const pthread_attr_t *attr, int *dstate);
int pthread_attr_setdetachstate (pthread_attr_t *attr, int dstate);
int pthread_attr_getstack (const pthread_attr_t *attr, void **stackaddr,
	 size_t *stacksize);
int pthread_attr_setstack (pthread_attr_t *attr, void *stackaddr,
	 size_t stacksize);

#ifdef CONFIG_PTHREAD_MUTEX
int sys_pthread_mutex_init (pthread_mutex_t *mutex,
	 const pthread_mutexattr_t *attr);
int sys_pthread_mutex_destroy (pthread_mutex_t *mutex);
int sys_pthread_mutex_lock (pthread_mutex_t *mutex);
int sys_pthread_mutex_trylock (pthread_mutex_t *mutex);
int sys_pthread_mutex_unlock (pthread_mutex_t *mutex);
int pthread_mutexattr_init (pthread_mutexattr_t *attr);
int pthread_mutexattr_destroy (pthread_mutexattr_t *attr);
int pthread_mutexattr_gettype(const pthread_mutexattr_t *attr, int *type);
int pthread_mutexattr_settype(pthread_mutexattr_t *attr, int type);
#endif

#if SCHED_TYPE == SCHED_PRIO
int       sys_pthread_getschedparam (pthread_t thread, int *policy, struct sched_param *param);
int       sys_pthread_setschedparam (pthread_t thread, int policy, struct sched_param *param);
#endif

#ifdef __cplusplus
}       
#endif 

#endif /* _KPTHREAD_H */
