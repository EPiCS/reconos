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
// $Id: timer.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file timer.h
//! Declarations and defines for timer related functionality
//----------------------------------------------------------------------------------------------------//
#ifndef _TIMER_H
#define _TIMER_H

#include <config/config_param.h>
#include <config/config_cparam.h>
#include <sys/ktypes.h>
#include <sys/unistd.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct soft_tmr_s {
    unsigned int timeout;
    pid_t pid;
} soft_tmr_t;

void     soft_tmr_init(void) ;
int      add_tmr (pid_t pid, unsigned ticks);
unsigned 
int      remove_tmr (pid_t pid);
void     soft_tmr_handler (void);
unsigned 
int      xget_clock_ticks (void);

unsigned 
int      sys_xget_clock_ticks (void);
time_t   sys_time (time_t *timer);
unsigned sys_sleep (unsigned ticks);

#ifdef __cplusplus
}       
#endif 

#endif /* _TIMER_H */
