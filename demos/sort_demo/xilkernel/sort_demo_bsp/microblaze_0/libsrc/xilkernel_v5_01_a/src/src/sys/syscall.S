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

/*
//----------------------------------------------------------------------------------------//
//! @file
//! syscall.S - Contains the system call table
//-----------------------------------------------------------------------------------------//
*/
#include <os_config.h>

.global syscall_table        

/*
 * System call table - System call number defined in syscall.h
 * If the module is not included in the system, then the location
 * in the table is replaced by 0.
 */
        .section .rodata
        .align 2
syscall_table:                                          /* System call table */ 
        .long 0
#ifdef CONFIG_ELF_PROCESS        
        .long sys_elf_process_create                    /*  1 */
        .long sys_elf_exit                              /*  2 */
#else   
        .long 0
        .long 0                                        
#endif
        
#ifdef CONFIG_KILL
        .long sys_kill                                  /*  3 */
#else
        .long 0
#endif
        .long sys_process_status                        /*  4 */
        .long sys_get_reentrancy                        /*  5 */
#ifdef CONFIG_YIELD
        .long sys_yield                                 /*  6 */
#else
        .long 0
#endif

        .long sys_get_currentPID                        /*  7 */
        .long 0                                         /*  8 */
        .long 0                                         /*  9 */

#ifdef CONFIG_PTHREAD_SUPPORT
        .long sys_pthread_create                        /* 10 */
        .long sys_pthread_exit                          /* 11 */
        .long sys_pthread_join                          /* 12 */
        .long sys_pthread_self                          /* 13 */
        .long sys_pthread_detach                        /* 14 */
        .long sys_pthread_equal                         /* 15 */
#ifdef CONFIG_PRIOSCHED
        .long sys_pthread_getschedparam                 /* 16 */
        .long sys_pthread_setschedparam                 /* 17 */
#else
        .long 0
        .long 0
#endif
#else   
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
#endif

#ifdef CONFIG_PTHREAD_MUTEX
        .long sys_pthread_mutex_init                    /* 18 */
        .long sys_pthread_mutex_lock                    /* 19 */
        .long sys_pthread_mutex_trylock                 /* 20 */
        .long sys_pthread_mutex_unlock                  /* 21 */
        .long sys_pthread_mutex_destroy                 /* 22 */
#else
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
#endif
        .long 0                                         /* 23 */
        .long 0                                         /* 24 */
        .long 0                                         /* 25 */
        .long 0                                         /* 26 */
        .long 0                                         /* 27 */
        .long 0                                         /* 28 */
        .long 0                                         /* 29 */
        
#ifdef CONFIG_SEMA
        .long sys_sem_init                              /* 30 */                
        .long sys_sem_wait_x                            /* 31 */
        .long sys_sem_trywait                           /* 32 */
        .long sys_sem_post                              /* 33 */
        .long sys_sem_destroy                           /* 34 */
#ifdef CONFIG_NAMED_SEMA        
        .long sys_sem_open                              /* 35 */
        .long sys_sem_close                             /* 36 */
        .long sys_sem_unlink                            /* 37 */
#else
        .long 0
        .long 0
        .long 0        
#endif        
        .long sys_sem_getvalue                          /* 38 */
#ifdef CONFIG_TIME
        .long sys_sem_timedwait                         /* 39 */
#else           
        .long 0
#endif
        .long 0                                         /* 40 */
#else
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0                                 
        .long 0                                 
#endif
        
#ifdef CONFIG_MSGQ
        .long sys_msgget                                /* 41 */
        .long sys_msgctl                                /* 42 */
        .long sys_msgsnd                                /* 43 */
        .long sys_msgrcv                                /* 44 */
        .long 0                                         /* 45 */
#else                   
        .long 0                                 
        .long 0
        .long 0
        .long 0
        .long 0 
#endif

#ifdef CONFIG_SHM
        .long sys_shmget                                /* 46 */
        .long sys_shmctl                                /* 47 */
        .long sys_shmat                                 /* 48 */
        .long sys_shmdt                                 /* 49 */
#else
        .long 0
        .long 0
        .long 0
        .long 0
#endif
        
#ifdef CONFIG_BUFMALLOC
        .long sys_bufcreate                             /* 50 */
        .long sys_bufdestroy                            /* 51 */
        .long sys_bufmalloc                             /* 52 */
        .long sys_buffree                               /* 53 */
        .long 0                                         /* 54 */
#else
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
#endif
        
#ifdef CONFIG_TIME
        .long sys_xget_clock_ticks                      /* 55 */
        .long sys_sleep                                 /* 56 */
        .long sys_time                                  /* 57 */
#else
        .long 0                 
        .long 0
        .long 0
#endif
        
#ifdef CONFIG_INTC
        .long sys_register_int_handler                  /* 58 */
        .long sys_unregister_int_handler                /* 59 */
        .long sys_enable_interrupt                      /* 60 */
        .long sys_disable_interrupt                     /* 61 */
        .long sys_acknowledge_interrupt                 /* 62 */
#else
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
#endif
        
#ifdef CONFIG_STATS
        .long sys_get_kernel_stats                      /* 63 */
#else
        .long 0                                 
#endif
        .long 0                                         /* 64 */
        .long 0                                         /* 65 */
        .long 0                                         /* 66 */
        .long 0                                         /* 67 */
        .long 0                                         /* 68 */
        .long 0                                         /* 69 */
        .long 0                                         /* 70 */        
        .long 0                                         /* 71 */
        .long 0                                         /* 72 */
        
#ifdef CONFIG_NET
        .long xilsock_socket                            /* 73 */
        .long xilsock_bind                              /* 74 */
        .long xilsock_listen                            /* 75 */
        .long xilsock_accept                            /* 76 */
        .long xilsock_recv                              /* 77 */
        .long xilsock_send                              /* 78 */        
        .long xilsock_recv                              /* 79 */
        .long xilsock_sendto                            /* 80 */
        .long xilsock_close                             /* 81 */
#else
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
#endif
