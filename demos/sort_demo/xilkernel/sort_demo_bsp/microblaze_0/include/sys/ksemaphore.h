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
// $Id: ksemaphore.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file ksemaphore.h
//! Kernel level semaphore definitions and declarations
//----------------------------------------------------------------------------------------------------//

#ifndef _KSEMAPHORE_H
#define _KSEMAPHORE_H

#include <sys/types.h>
#include <sys/ktypes.h>
#include <semaphore.h>

#ifdef __cplusplus
extern "C" {
#endif

int    sys_sem_init(sem_t* sem, int pshared, unsigned value);
sem_t* sys_sem_open(const char* name, int oflag, mode_t mode, unsigned value);
int    sys_sem_close(sem_t* sem);
int    sys_sem_unlink(const char* name);
int    sys_sem_getvalue(sem_t* sem, int* sval);
int    sys_sem_wait_x(sem_t* sem);
int    sys_sem_trywait(sem_t *sem);
int    sys_sem_post(sem_t* sem);
int    sys_sem_destroy(sem_t* sem);
int    sem_force_destroy (sem_t* sem);

void sem_heap_init(void);
sem_info_t* get_sem_by_semt( sem_t* sem);
sem_info_t* get_sem_by_name( char*  sem);
sem_t* get_semt_by_name( char* name);

#ifdef __cplusplus
}       
#endif 

#endif /* _KSEMAPHORE_H */
