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
//! @file libsemaphore.c
//! This contains system call wrapper functions for POSIX Semaphore routines
//----------------------------------------------------------------------------------------------------//
#include <os_config.h>
#include <sys/syscall.h>
#include <semaphore.h>
#include <stdarg.h>
#include <sys/ksemaphore.h>

extern void* make_syscall (void *arg1, void *arg2, void *arg3, void *arg4, void *arg5, int syscall_num);

#ifdef CONFIG_SEMA
int sem_init(sem_t* sem, int pshared, unsigned value)
{
    return (int) make_syscall ((void*)sem, (void*)pshared, (void*)value, NULL, NULL, SC_SEM_INIT);
}

int sem_trywait(sem_t* sem)
{
    return (int) make_syscall ((void*)sem, NULL, NULL, NULL, NULL, SC_SEM_TRYWAIT);
}

int sem_wait(sem_t* sem)
{
    return (int) make_syscall ((void*)sem, NULL, NULL, NULL, NULL, SC_SEM_WAIT);
}

#ifdef CONFIG_TIME
int sem_timedwait (sem_t* sem, unsigned int ticks)
{
    return (int) make_syscall ((void*)sem, (void*)ticks, NULL, NULL, NULL, SC_SEM_TIMED_WAIT);
}
#endif

int sem_getvalue(sem_t* sem, int* sval)
{
    return (int) make_syscall ((void*)sem, (void*)sval, NULL, NULL, NULL, SC_SEM_GETVALUE);
}

int sem_post(sem_t* sem)
{
    return (int) make_syscall ((void*)sem, NULL, NULL, NULL, NULL, SC_SEM_POST);
}

#ifdef CONFIG_NAMED_SEMA
sem_t* sem_open(const char* name, int oflag, ...)
{
    mode_t mode;
    unsigned value;
    va_list varptr;
    
    if( !(oflag & O_CREAT) )                         // Other flags unsupported
	return (sem_t*)SEM_FAILED;

    if (!(oflag & O_EXCL)) {

	va_start( varptr, oflag );
	
	mode = va_arg( varptr, mode_t );
	value = va_arg( varptr, unsigned );
	
	va_end (varptr);
    }

    return (sem_t*) make_syscall ((void*)name, (void*)oflag, (void*)mode, (void*)value, NULL, SC_SEM_OPEN);
}

int sem_unlink(const char* name)
{
    return (int) make_syscall ((void*)name, NULL, NULL, NULL, NULL, SC_SEM_UNLINK);
}

int sem_close(sem_t* sem)
{
    return (int) make_syscall ((void*)sem, NULL, NULL, NULL, NULL, SC_SEM_CLOSE);
}
#endif

int sem_destroy(sem_t* sem)
{
    return (int) make_syscall ((void*)sem, NULL, NULL, NULL, NULL, SC_SEM_DESTROY);
}
#endif /* CONFIG_SEMA */
