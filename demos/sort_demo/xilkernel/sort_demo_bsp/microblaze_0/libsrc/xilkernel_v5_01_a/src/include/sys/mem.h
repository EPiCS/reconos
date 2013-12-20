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
// $Id: mem.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file mem.h
//! Kernel level memory allocation definitions and declarations
//----------------------------------------------------------------------------------------------------//
#ifndef _SYS_MEM_H
#define _SYS_MEM_H

#include <config/config_param.h>
#include <config/config_cparam.h>
#include <sys/ktypes.h>
#include <sys/queue.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SEMQ_START 	(N_PRIO*MAX_READYQ)

//! This is used by buffer management routines.
//! Each Memory Block of different sizes is associated with each structure
struct _malloc_info {
    unsigned int mem_bsize ;	//! Memory Block Size 
    unsigned char max_blks ;	//! Max. number of mem blocks 
    unsigned char n_blks ;	//! No. of mem blocks allocated 
    unsigned short start_blk ;	//! The starting mem. blk number 
    signed char *start_addr ;	//! Starting memory location for this bll 
};

void    alloc_pidq_mem( queuep queue, unsigned int qtype, unsigned int qno ) ;
int     se_process_init(void) ;
int     kb_pthread_init(void);
void    alloc_msgq_mem( queuep queue, unsigned int qno ) ;
void    msgq_init(void) ;
void    shm_init(void) ;
void    bss_mem_init(void) ;
int     alloc_bss_mem( unsigned int *start, unsigned int *end ) ;
void    free_bss_mem( unsigned int memid ) ;
void    malloc_init(void) ;
void    sem_heap_init(void);
void    bufmalloc_mem_init(void);

#ifdef __cplusplus
}       
#endif 

#endif /* _SYS_MEM_H */
