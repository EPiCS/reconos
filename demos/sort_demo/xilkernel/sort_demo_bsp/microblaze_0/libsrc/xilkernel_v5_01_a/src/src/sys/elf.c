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
//! @file elf.c
//! ELF file related routines (Creating processes out of ELF files)
//----------------------------------------------------------------------------------------------------//

#include <stdio.h>
#include <os_config.h>
#include <sys/init.h>
#include <config/config_param.h>
#include <config/config_cparam.h>
#include <sys/arch.h>
#include <sys/ktypes.h>
#include <sys/ksched.h>
#include <sys/process.h>
#include <sys/mem.h>
#include <sys/queue.h>
#include <sys/ksemaphore.h>
#include <sys/msg.h>
#include <sys/shm.h>
#include <sys/decls.h>
#include <sys/stats.h>

#ifdef CONFIG_ELF_PROCESS

#ifdef CONFIG_PTHREAD_SUPPORT
#include <sys/kpthread.h>
#endif

//----------------------------------------------------------------------------------------------------//
// Data
//----------------------------------------------------------------------------------------------------//

//----------------------------------------------------------------------------------------------------//
// Declarations
//----------------------------------------------------------------------------------------------------//
extern process_struct ptable[] ;
extern signed char current_pid;
extern char process_startup_stack[];

//----------------------------------------------------------------------------------------------------//
// Definitions
//----------------------------------------------------------------------------------------------------//

//----------------------------------------------------------------------------------------------------//
//  @func - sys_elf_process_create
//! @desc
//!   Process creation.
//!   - Reserves a pid for the process.
//!   - Initilaizes the process structure. Also loads the r15 with the start
//!     address of the process.
//!   - Places the process in the READY_Q.
//!   - If SCHED_PRIO, calls the process_scheduler for scheduling.
//!
//! @param
//!   - pstart_addr is the start address of the process
//!   - priority is the priority of the process
//! @return
//!   - PID of the new process.
//!   - -1 on Error. Max. process exceeded.
//! @note
//!   - None
//----------------------------------------------------------------------------------------------------//
pid_t sys_elf_process_create (void* pstart_addr, unsigned int priority)
{
    pid_t pid;
    process_struct *pcb;
    unsigned int stackaddr;

    pid = proc_create (priority);

    if (pid == -1)
        return -1;

    pcb = &ptable[pid];

    stackaddr = ((unsigned int)process_startup_stack                    // Temporary stack for new launched process in case it is interrupted
                 + PROCESS_STARTUP_STACKSZ + SSTACK_PTR_ADJUST);        // before its own stack is setup

    setup_initial_context (&ptable[pid], current_pid, pstart_addr, stackaddr, 0);

    return pid;
}


//----------------------------------------------------------------------------------------------------//
//  @func - sys_elf_exit
//! @desc
//!   Remove the process entry from the process table.
//!   - Set the is_allocated flag to '0'. Set the current_pid to -1. so that the
//!     next process gets scheduled.
//! @return
//!   - 0 on Success
//! @note
//!   - None
//----------------------------------------------------------------------------------------------------//
int sys_elf_exit()
{
    process_invalidate (&ptable[current_pid]);
    suspend ();
    return 0 ;
}

#endif /* CONFIG_ELF_PROCESS */
