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
//! @file xilkernel_main.c
//! Initialises the system by calling sys_init(), hw_init() and blocks the kernel
//! On first timer interrupt the first process gets scheduled.
//----------------------------------------------------------------------------------------------------//

#include <xmk.h>
#include <os_config.h>

#include <xil_exception.h>

#ifdef MB_XILKERNEL
#include <sys/process.h>
#endif

#ifdef PPC_XILKERNEL
#include <config/config_param.h>
#include <config/config_cparam.h>
#include <sys/ktypes.h>
#include <xparameters.h>
#include <sys/process.h>
#include <xpseudo_asm.h>
#include <xtime_l.h>
#include <sys/syscall.h>
#endif /* PPC_XILKERNEL */
#include <sys/decls.h>
#include <sys/init.h>
#include <sys/mem.h>
#include <pthread.h>
#include <stdio.h>

//----------------------------------------------------------------------------------------------------//
// Declarations
//----------------------------------------------------------------------------------------------------//
#ifdef CONFIG_STATIC_ELF_PROCESS_SUPPORT
extern struct _process_init se_process_table[] ;
#endif

#ifdef CONFIG_PTHREAD_SUPPORT
extern pthread_attr_t default_attr;

#ifdef CONFIG_STATIC_PTHREAD_SUPPORT
extern struct _elf_pthread_init kb_pthread_table[];
#endif
#endif

extern void idle_task (void);
extern void init_idle_task (void);

//----------------------------------------------------------------------------------------------------//
// Definitions
//----------------------------------------------------------------------------------------------------//


//----------------------------------------------------------------------------------------------------//
//  @func - xilkernel_main
//! @desc
//!   Entry point of the kernel
//! @return
//!   - Nothing.
//! @note
//!   - Routine does not return. (Caller does not get back control)
//----------------------------------------------------------------------------------------------------//
void xilkernel_main(void)
{
    DBG_PRINT("XMK: Starting kernel.\r\n");

    xilkernel_init ();
    xilkernel_start ();
}

//----------------------------------------------------------------------------------------------------//
//  @func - xilkernel_init
//! @desc
//!   Initialize the system - This function is called at the start of system.
//!   It initializes the system.
//!   - Initializes the process vector table.
//!   - Creates the Idle process (pid - 0).
//!   - Creates the static set of processes.
//! @return
//!   - Nothing.
//----------------------------------------------------------------------------------------------------//
void xilkernel_init(void)
{
    unsigned int i = 0 ;

    DBG_PRINT("XMK: Initializing Hardware.\r\n");
    hw_init();                                                  // Do hardware specific initialization

    DBG_PRINT("XMK: System initialization.\r\n");
    for( ; i < MAX_PROCESS_CONTEXTS; i++ ) {
        ptable[i].is_allocated = 0 ;
        ptable[i].pcontext.isrflag = 0;
    }

#ifdef MB_XILKERNEL
    kernel_sp = (void*)((unsigned int)&_stack + SSTACK_PTR_ADJUST);
#elif defined(PPC_XILKERNEL)
    kernel_sp = (void*)((unsigned int)&__stack + SSTACK_PTR_ADJUST);
#endif
    readyq_init();

#ifdef CONFIG_PTHREAD_SUPPORT
    pthread_init();
#endif
#ifdef CONFIG_SEMA
    sem_heap_init();
#endif
#ifdef CONFIG_MSGQ
    msgq_init();
#endif
#ifdef CONFIG_SHM
    shm_init();
#endif
#ifdef CONFIG_BUFMALLOC
    bufmalloc_init ();
#endif

    init_idle_task ();

#ifdef CONFIG_STATIC_ELF_PROCESS_SUPPORT
    se_process_init() ;                                           // Create statically specified separate executable processes
#endif

#ifdef CONFIG_STATIC_PTHREAD_SUPPORT
    kb_pthread_init ();                                           // Create statically specified kernel bundled threads
#endif

#ifdef CONFIG_TIME
    soft_tmr_init ();
#endif
}

//----------------------------------------------------------------------------------------------------//
//  @func - xilkernel_start
//! @desc
//!   Start the kernel by enabling interrupts and starting to execute the idle task.
//! @return
//!   - Nothing.
//! @note
//!   - Routine does not return.
//! @desc
//----------------------------------------------------------------------------------------------------//
void xilkernel_start (void)
{
    DBG_PRINT("XMK: Process scheduling starts.\r\n");
    Xil_ExceptionEnable();
    idle_task ();                                                       // Does not return
}

#ifdef CONFIG_STATIC_ELF_PROCESS_SUPPORT
//----------------------------------------------------------------------------------------------------//
//  @func - se_process_init
//! @desc
//!   Create the statically specified set of separate executable processes.
//! @return
//!   - 0 on success
//!   - -1 on error
//! @note
//!   - Used only in the case of separate executable process support
//----------------------------------------------------------------------------------------------------//
int se_process_init(void)
{
    struct _process_init *pinit ;
    unsigned int i = 0 ;

    // Atleast a single process should be loaded during initialisation.
    pinit = se_process_table;
    for( i = 0; i < N_INIT_PROCESS; i++) {
	if (sys_elf_process_create((void*)pinit->p_start_addr, pinit->priority) < 0) {
	    DBG_PRINT ("XMK: se_process_init: sys_process_create failed.\r\n");
	    return -1;
	}
	pinit++ ;
    }
    return 0;
}
#endif /* CONFIG_STATIC_ELF_PROCESS_SUPPORT */

#ifdef CONFIG_PTHREAD_SUPPORT
#ifdef CONFIG_STATIC_PTHREAD_SUPPORT
//----------------------------------------------------------------------------------------------------//
//  @func - kb_pthread_init
//! @desc
//!   Create the statically specified pthreads that do not have an ELF file associated with it.
//!   Threads in kernel space. Stack allocated from BSS memory pool.
//! @return
//!   - 0 on success
//!   - error code from sys_pthread_create
//! @note
//!   - None
//----------------------------------------------------------------------------------------------------//
int kb_pthread_init(void)
{
    struct _elf_pthread_init *pinit ;
    unsigned int i = 0 ;
    pthread_t tid;
    pthread_attr_t attr = default_attr;
    int ret;

    // Load the system processes to run during init.
    pinit = kb_pthread_table;

    for( i=0; i<N_INIT_SELF_PTHREADS; i++) {
#if SCHED_TYPE == SCHED_PRIO
	attr.schedparam.sched_priority = pinit->priority;
#endif
	ret = sys_pthread_create (&tid, &attr, (void*)pinit->start_func, NULL);
	if (ret != 0) {
	    DBG_PRINT("XMK: kb_pthread_init: sys_pthread_create failed.\r\n");
	    return -1;
	}
	pinit++;
    }

    return 0;
}
#endif /* CONFIG_STATIC_PTHREAD_SUPPORT */


int xmk_add_static_thread(void* (*start_routine)(void *), int sched_priority)
{
    pthread_t tid;
    pthread_attr_t attr = default_attr;
    int ret;

#if SCHED_TYPE == SCHED_PRIO
    attr.schedparam.sched_priority = sched_priority;
#endif
    sched_priority = 0; /* Dummy to remove compilation issues */

    ret = sys_pthread_create (&tid, &attr, start_routine, NULL);
    if (ret != 0) {
        DBG_PRINT("XMK: xmk_add_static_thread: sys_pthread_create failed.\r\n");
        return -1;
    }

    return 0;
}

#endif /* CONFIG_PTHREAD_SUPPORT */

