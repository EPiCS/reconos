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
//! @file mem.c  
//! This contains the Memory allocation routines. 
//! - All the memory initialization routines for various system modules is 
//!   defined here. The memory for all the modules are allocated statically,
//!   the size of which can be configured by the user. This can be specified
//!   in structures defined in sys/init.c. Based on this the total memory
//!   requirements for each module is calculated.
//! - This also contains routines that allocate thread context and 
//!   buffer management.
//----------------------------------------------------------------------------------------------------//

#include <stdio.h>
#include <os_config.h>
#include <config/config_cparam.h>
#include <config/config_param.h>
#include <sys/arch.h>
#include <sys/process.h>
#include <sys/mem.h>
#include <sys/init.h>
#include <sys/shm.h>
#include <sys/kmsg.h>
#include <sys/kpthread.h>
#include <sys/ksched.h>
#include <sys/decls.h>
#include <sys/bufmalloc.h>
#include <errno.h>

//! Memory allocated for storing Process IDs. This memory is used for Ready
//! Queue and Semaphore Queue. The memory is split as follows:
//! -# Memory for Ready Queue's.
//! -# Memory for Semaphore Queue's.
pid_t pid_queue_mem[PID_QUEUE_MSIZE] ;
extern process_struct ptable[MAX_PROCESS_CONTEXTS] ;   

#ifdef CONFIG_PTHREAD_SUPPORT
//! Total Memory allocated for thread context. This depends on the number of
//! threads in the system and size of the thread context. This is user
//! customizable.
 
char thread_stack_mem[PTHREAD_STACK_MSIZE] ;

//! Array of table used to keep track of Memory ID for the allocated thread
//! context.
//! 0 - unallocated
//! 1 - allocated

char thread_stack_memid[MAX_PTHREADS] ;	
#endif

#ifdef CONFIG_PTHREAD_MUTEX
pid_t pthread_mutex_queue_mem[PTHREAD_MUTEX_QUEUE_MSIZE];
#endif

#ifdef CONFIG_MSGQ
//! Memory allocated for storing Message pointers in Message Queues. 
//! The total memory is user customizable.
//! Each msg_t structure contains a pointer to the actual message and the size of the message
#define MSG_QUEUE_MSIZE (NUM_MSGQS * MSGQ_CAPACITY * sizeof(msg_t))
char msg_queue_mem[MSG_QUEUE_MSIZE] ;
extern msgid_ds msgq_heap[] ;
#endif /* CONFIG_MSGQ */

#ifdef CONFIG_SHM

//! Memory allocated for Shared Memory modules. The total memory is user 
//! customizable.
 
char shm_mem[SHM_MSIZE] ;
extern struct _shm_init shm_config[] ;
extern shm_info_t shm_heap[] ;
#endif


#ifdef CONFIG_BUFMALLOC
membuf_t        smbufs[N_STATIC_BUFS];
//! Total memory allocated for buffer management. The memory is divided among
//! different memory sized blocks based on the user configuration.
char bufmallocmem[BUFMALLOC_MSIZE] ;
extern struct bufmalloc_init_s bufmalloc_cfg[];
#endif /* CONFIG_BUFMALLOC */

//----------------------------------------------------------------------------------------------------//
//  @func - alloc_pidq_mem
//! @desc
//!   Allocate memory to the process ID queue's. 
//!   - This includes the Ready_Q and Semaphore_Q. Initial memory is allocated 
//!     for Ready queue, followed by the semaphore queue.
//! @param
//!  - queue is the queue of PIDs
//!  - qtype is the queue type. Can be READY_Q or SEMA_Q
//!  - qno is the Queue number. (eg) There are N_PRIO number of
//!    Ready Queue. The qno denotes this number. Memory for
//!    queues is allocated sequentially.
//! @return
//!   - None
//! @note
//!   - SEMA_Q is valid only if CONFIG_SEMA is defined.
//----------------------------------------------------------------------------------------------------//
void alloc_pidq_mem (queuep queue, unsigned int qtype, unsigned int qno)
{
    if (qtype == READY_Q) {
	queue->items = pid_queue_mem + (qno * MAX_READYQ * sizeof (pid_t)) ;
    } 
#ifdef CONFIG_SEMA
    else if (qtype == SEM_Q) {
	queue->items = (pid_queue_mem + SEMQ_START) + (qno * MAX_SEM_WAITQ * sizeof (pid_t));
    }
#endif
#ifdef CONFIG_PTHREAD_MUTEX
    else if (qtype == PTHREAD_MUTEX_Q) {
	queue->items = pthread_mutex_queue_mem + (qno * MAX_PTHREAD_MUTEX_WAITQ * sizeof (pid_t));
    }
#endif
}

#ifdef CONFIG_MSGQ
//----------------------------------------------------------------------------------------------------//
//  @func - alloc_msgq_mem
//! @desc 
//!   Allocate memory to the Message Queues from statically allocated memory pool.
//! @param
//!   - queue is the queue of PIDs
//!   - qno is the Queue number. 
//! @return
//!   - None
//! @note
//!   - None
//----------------------------------------------------------------------------------------------------//
void alloc_msgq_mem( queuep queue, unsigned int qno )
{
    // It is always called in Sequence during system initialization !!
    static unsigned int msgq_start_ptr = 0 ;

    queue->items = (msg_queue_mem + msgq_start_ptr) ;
    msgq_start_ptr += (sizeof(msg_t) * MSGQ_CAPACITY);
}

//----------------------------------------------------------------------------------------------------//
//  @func - msgq_init
//! @desc
//!   The message Queue structures are initialized. 
//!   - Based on the system configuration the message queues are created and 
//!     defaults assigned to them.
//! @return
//!   - Nothing
//! @note
//!   - None
//----------------------------------------------------------------------------------------------------//
void msgq_init(void)
{
    unsigned int i = 0 ;
    for( ; i < NUM_MSGQS; i++ ){
	msgq_heap[i].msgid = -1;
	msgq_heap[i].msgq_len = MSGQ_CAPACITY;
	msgq_heap[i].stats.msg_qbytes = MSGQ_MAX_BYTES;
	msgq_heap[i].stats.msg_lspid = -1;
	msgq_heap[i].stats.msg_lrpid = -1;
	// Allocate space in the queue to contain msgq_len number of pointers
	alloc_q (&msgq_heap[i].msg_q, MSGQ_CAPACITY, MSG_Q, sizeof(msg_t),i);
    }
}
#endif	/* CONFIG_MSGQ */


#ifdef CONFIG_SHM
//----------------------------------------------------------------------------------------------------//
//  @func - shm_init
//! @desc
//!   The shared memory structures are initialized based on the system configuration.
//! @return
//!   - Nothing
//! @note
//!   - None
//----------------------------------------------------------------------------------------------------//
void shm_init(void)
{
    unsigned int i = 0 ;
    unsigned int offset = 0 ;
	
    for( ; i < N_SHM; i++ ) {
	shm_heap[i].shm_id = -1;
	shm_heap[i].shm_segsz = shm_config[i].shm_size ;
	shm_heap[i].shm_addr = (char *)(shm_mem+ offset) ;
	offset += shm_config[i].shm_size;
    }
}
#endif 	/* CONFIG_SHM */

#ifdef CONFIG_PTHREAD_SUPPORT
//----------------------------------------------------------------------------------------------------//
//  @func - bss_mem_init
//! @desc
//!   Initialize the bss memory allocation array. Used for thread stack allocation
//! @return
//!   - Nothing
//! @note
//!   - Included only if pthread support is required
//----------------------------------------------------------------------------------------------------//
void bss_mem_init (void)
{
    unsigned int i ;
    for(i = 0; i < MAX_PTHREADS; i++)
	thread_stack_memid[i] = 0 ;
}
//----------------------------------------------------------------------------------------------------//
//  @func - alloc_bss_mem
//! @desc 
//!   Allocate memory for the bss memory, from the memory pool.
//! @param
//!   - start is the start address of the bss memory
//!   - end is the end address of the bss memory
//! @return
//!   -	On Success, start and end are assigned the start and end address of
//! 	bss memory respectively. Mem ID is returned.
//!   - -1 on Error
//! @note
//!   - Included only if pthread support is required
//----------------------------------------------------------------------------------------------------//
int alloc_bss_mem (unsigned int *start, unsigned int *end)
{
    unsigned int i ;

    for(i = 0; i < MAX_PTHREADS; i++ ){
	if( thread_stack_memid[i] == 0 ){ 
	    /* Need to align along the boundary */
	    *start = (unsigned int)thread_stack_mem + (PTHREAD_STACK_SIZE*i) ;
	    *end = (*start + PTHREAD_STACK_SIZE) ;
	    thread_stack_memid[i] = 1 ;
	    return i ;
	}
    }

    return -1 ;
}

//----------------------------------------------------------------------------------------------------//
//  @func - free_bss_mem
//! @desc
//!   Free the bss memory allocated for the thread.
//! @return
//!   - Nothing
//! @note
//!   - None
//----------------------------------------------------------------------------------------------------//
void free_bss_mem (unsigned int memid)
{
    thread_stack_memid[memid] = 0 ;
}
#endif		/* CONFIG_PTHREAD_SUPPORT */


#ifdef CONFIG_BUFMALLOC
//----------------------------------------------------------------------------------------------------//
//  @func - bufmalloc_mem_init
//! @desc 
//!   Create buffer memory pools for statically specified mem configurations
//! @return
//!   - Nothing
//! @note
//!   - None
//----------------------------------------------------------------------------------------------------//
void bufmalloc_mem_init (void)
{
    int i;
    void *ptr = bufmallocmem;
    unsigned int bufsiz;

    for (i = 0; i < N_STATIC_BUFS; i++) {
        bufsiz = bufmalloc_cfg[i].bsiz * bufmalloc_cfg[i].nblks;
        if (sys_bufcreate (&smbufs[i], ptr, bufmalloc_cfg[i].nblks, bufmalloc_cfg[i].bsiz) != 0) {
            DBG_PRINT ("XMK: Error while initializing statically allocated block memory resources.\r\n");
            return;
        }
        ptr = ptr + bufsiz;
    }
}
    
#endif /* CONFIG_BUFMALLOC */
