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
//! @file debugmon.c
//! Kernel inbuilt debug monitor routines for Microblaze
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

#ifdef CONFIG_DEBUGMON

extern signed char idle_task_pid;
extern unsigned int budget_ticks;
extern process_struct ptable[] ;	 
extern signed char current_pid ;	 
extern process_struct *current_process;
extern process_struct *ctx_save_process;
extern signed char prev_pid; 
extern struct _queue ready_q[] ;		
extern signed char entry_mode;  
extern signed char resched;     

void debugmon_dump_proc_info (void)
{
    int i, j;

    xmk_enter_kernel ();
    DBG_PRINT ("DEBUGMON: kernel_dump_proc_info ----> \r\n");
    for (i = 0; i<MAX_PROCESS_CONTEXTS; i++) {
        if (!ptable[i].is_allocated)
            continue;

        DBG_PRINT ("=============================>\r\n");
        DBG_PRINT ("pid: ");
        putnum (ptable[i].pid);
        DBG_PRINT ("\r\nstate: ");
        putnum (ptable[i].state);
        DBG_PRINT ("\r\nisrflag: ");
        putnum (ptable[i].pcontext.isrflag);

        for (j=0; j<33; j++) {
            DBG_PRINT ("\r\nregs[");
            putnum (j);
            DBG_PRINT ("]: ");
            putnum (ptable[i].pcontext.regs[j]);
        }
        DBG_PRINT ("\r\n=============================>\r\n\r\n");
    }
    DBG_PRINT ("DEBUGMON: kernel_dump_proc_info ENDS\r\n");    
    while (1);
}


void debugmon_stack_check (void)
{
    unsigned int cur_sp;
    unsigned int saddr, ssize;

    if (current_process->thread != NULL && current_process->thread->thread_attr.stackaddr != NULL) {
        cur_sp = current_process->pcontext.regs[1];
        saddr  = (unsigned int) current_process->thread->thread_attr.stackaddr;
        ssize  = current_process->thread->thread_attr.stacksize;

        if ((cur_sp > saddr) || (cur_sp <= (saddr - ssize))) {
            DBG_PRINT ("DEBUGMON: Stack check failed for PID: ");
            putnum (current_process->pid);
            DBG_PRINT (", SP: ");
            putnum (current_process->pcontext.regs[1]);
            DBG_PRINT (", Base: ");
            putnum (saddr);
            DBG_PRINT (", Limit: ");
            putnum ((saddr - ssize));
            DBG_PRINT ("\r\n");
            debugmon_dump_proc_info ();
        }
    }
}

void debugmon_dump_sched_info (void)
{
    int i;
    char *qp;

    print ("Scheduler: current_pid: ");
    putnum (current_pid);
    print (", prev_pid: ");
    putnum (prev_pid);
    print ("\r\n");

    print ("ready_q[0].item_count: ");
    putnum(ready_q[0].item_count);
    print ("\r\n");
    qp = (char*)ready_q[0].items;
    qp += ready_q[0].qfront;

    print ("Items: ( ");
    for (i=0; i<ready_q[0].item_count; i++) {
	putnum(*qp++);
	print (" ");
    }
    print (")\r\n");
}

#endif /* CONFIG_DEBUGMON */
