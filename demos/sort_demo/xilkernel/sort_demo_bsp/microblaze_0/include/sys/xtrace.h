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
// $Id: xtrace.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file xtrace.h
//! Kernel level trace API
//----------------------------------------------------------------------------------------------------//

#ifndef _XTRACE_H
#define _XTRACE_H

#include <config/config_param.h>
#include <config/config_cparam.h>
#include <sys/ktypes.h>
#include <sys/queue.h>

#ifdef __cplusplus
extern "C" {
#endif

enum xtrace_event {
    XSCHED_EVENT,
    XSEM_EVENT,
    XTIMER_EVENT,
    XCUSTOM_EVENT
};

enum xtrace_action {
    XSCHED_RESCHED,
    XSEM_WAIT,
    XSEM_TIMEWAIT,
    XSEM_WAIT_TIMEOUT,
    XSEM_WAIT_UNBLOCK,
    XSEM_ACQUIRE,
    XSEM_POST,
    XSEM_POST_UNBLOCK,
    XTIMER_TIMEOUT,
    XTIMER_TICK,
    XTIMER_ADD,
    XTIMER_REMOVE,
    XCUSTOM_ACTION1,
    XCUSTOM_ACTION2,
    XCUSTOM_ACTION3,
    XCUSTOM_ACTION4,
    XCUSTOM_ACTION5,   
    XCUSTOM_ACTION6
};

typedef struct xtrace_pkt_s {
    enum xtrace_event   event;
    pid_t               pid;
    unsigned int        resource;
    enum xtrace_action  action;
    unsigned int        custom[2];
} xtrace_pkt_t;

void xtrace_log_event (enum xtrace_event event, enum xtrace_action action,
                       unsigned int resource, unsigned int custom0, unsigned int custom1);
void xtrace_print_log (void);


#if 0
#define CONFIG_XTRACE
#define CONFIG_XTRACE_MEM_START      0x9a000000
#define CONFIG_XTRACE_MAX_COUNT      100000
#endif


#ifndef CONFIG_XTRACE
#undef xtrace_log_event
#define xtrace_log_event(...) do { } while (0)
#endif

#ifdef __cplusplus
}       
#endif 

#endif /* _XTRACE_H */
