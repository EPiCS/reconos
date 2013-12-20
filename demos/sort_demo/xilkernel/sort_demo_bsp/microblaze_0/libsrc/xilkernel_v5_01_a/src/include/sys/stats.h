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
// $Id: stats.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file stats.h
//! Kernel statistics collection definitions and structures
//----------------------------------------------------------------------------------------------------//

#ifndef _STATS_H
#define _STATS_H

#include <os_config.h>
#include <sys/ktypes.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SCHED_HISTORY_SIZ    25

//! Process Status structure used for process_status
typedef struct _ps_stat{
    pid_t 	        pid ;           //! Process ID 
    unsigned char 	state ;		//! State of process 
    unsigned long       aticks;         //! Active ticks
    signed char         priority;       //! Process priority
} p_stat;

//! Kernel statistics structure
typedef struct kstats_s {
    unsigned int kernel_ticks;
    pid_t        sched_history[SCHED_HISTORY_SIZ];
    int          pstat_count;
    p_stat       *pstats;
} kstats_t;

#ifdef __cplusplus
}       
#endif 

#endif /* _STATS_H */
