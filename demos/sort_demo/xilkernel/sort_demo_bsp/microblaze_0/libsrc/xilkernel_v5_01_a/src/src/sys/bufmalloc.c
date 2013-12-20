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
//! @file bufmalloc.c  
//! Block memory allocation support
//----------------------------------------------------------------------------------------------------//
#include <os_config.h>
#include <stdio.h>
#include <config/config_cparam.h>
#include <config/config_param.h>
#include <sys/arch.h>
#include <sys/types.h>
#include <sys/decls.h>
#include <sys/init.h>
#include <errno.h>
#include <sys/bufmalloc.h>

#ifdef CONFIG_BUFMALLOC
//----------------------------------------------------------------------------------------------------//
// Declarations  
//----------------------------------------------------------------------------------------------------//

#define    MEM_TO_BLK(membufp, mem)             (((unsigned int)mem - (unsigned int)membufp->memptr)/(membufp->blksiz))
#define    MEM_WITHIN_BUF(membufp, mem)         (((mem >= membufp->memptr) && (mem < membufp->limit))?1:0)     

typedef struct membuf_info_s {
    char        active;
    void        *memptr;
    void        *limit;
    void        *freep;
    int         nblks;
    int         nfree;
    size_t      blksiz;
} membuf_info_t;

void*   get_mbufblk    (membuf_info_t *mbufptr);
extern  void bufmalloc_mem_init (void);
//----------------------------------------------------------------------------------------------------//
// Data  
//----------------------------------------------------------------------------------------------------//
membuf_info_t   mbufheap[N_MBUFS];

//----------------------------------------------------------------------------------------------------//
// Definitions  
//----------------------------------------------------------------------------------------------------//
void bufmalloc_init (void)
{
    int i;
    for (i = 0; i < N_MBUFS; i++)
        mbufheap[i].active = 0;

    bufmalloc_mem_init ();
}

void* get_mbufblk (membuf_info_t *mbufptr)
{
    void *ret;

    if (!mbufptr->nfree) 
        return NULL;
    
    ret = mbufptr->freep;
    mbufptr->freep = (*(void**)ret);
    mbufptr->nfree--;
    
    return ret;
}

//----------------------------------------------------------------------------------------------------//
//  @func - sys_bufcreate
//! @desc
//!   Free the memory allocated by bufmalloc
//! @param
//!   - mem is the address of the memory block, that was got from bufmalloc
//! @return
//!   - Nothing
//! @note
//!   - WARNING. ALIGNMENT requirements have to be met or exception handlers required.
//----------------------------------------------------------------------------------------------------//
int sys_bufcreate (membuf_t *mbuf, void *memptr, int nblks, size_t blksiz)
{
    int i;
    membuf_info_t *mbufptr;
    void **cur, **next;

    if ((mbuf == NULL) || (memptr == NULL) || (nblks <= 0) || (blksiz < sizeof (void*))) {
        kerrno = EINVAL;
        return -1;
    }

    mbufptr = &mbufheap[0];
    for (i = 0; i < N_MBUFS; i++) {                                                     // Find first free membuf descriptor
        if (!mbufptr->active)
            break;
        mbufptr++;
    }

    if (i == N_MBUFS) {
        kerrno = EAGAIN;
        return -1;
    }

    mbufptr->active  = 1;
    mbufptr->memptr  = memptr;
    mbufptr->nblks   = nblks;
    mbufptr->blksiz  = blksiz;
    mbufptr->nfree   = nblks;
    mbufptr->freep   = memptr;
    mbufptr->limit   = (void*)((unsigned int)memptr + (nblks * blksiz));
    *mbuf = (membuf_t)i;                                                                // Return membuf identifier

    cur  = (void**)memptr;
    next = (void**)((unsigned int)memptr + blksiz);
    for (i = 0; i < (nblks - 1); i++) {                                                 // Initialize free list in the the memory block
        *cur = (void*)next;                                                             // Alignment constraints should be met here
        cur  = next;                                                                    // Otherwise, unaligned exceptions will occur
        next = (void**)((unsigned int)next + blksiz);
    }
    *cur = (void*) NULL;
    return 0;
}

int sys_bufdestroy (membuf_t mbuf)
{
    if (mbuf >= 0 && mbuf < N_MBUFS)
        mbufheap[mbuf].active = 0;
    else {
        kerrno = EINVAL;
        return -1;
    }
        
    return 0;
}

void* sys_bufmalloc (membuf_t mbuf, size_t siz)
{
    membuf_info_t   *mbufptr;
    void* ret = NULL;
    int i;

    if ((mbuf != MEMBUF_ANY) && ((mbuf < 0 || mbuf > N_MBUFS)))
        return NULL;
    
    if (mbuf == MEMBUF_ANY) {
        mbufptr = &mbufheap[0];
        for (i = 0; i < N_MBUFS; i++) {
            if (mbufptr->active && mbufptr->blksiz >= siz) {                            // Get first pool that can fit the request
                ret = get_mbufblk (mbufptr);
                if (ret)
                    break;
            }
            mbufptr++;
        }
    } else {
        mbufptr = &mbufheap[mbuf];
        
        if (!mbufptr->active) {
            kerrno = EINVAL;
            return NULL;
        }
        ret = get_mbufblk (mbufptr);
    }
    
    if (ret == NULL)
        kerrno = EAGAIN;
    return ret;
}

void sys_buffree (membuf_t mbuf, void *mem)
{
    membuf_info_t   *mbufptr;
    void** newblk;
    int blk, i;

    if ((mbuf != MEMBUF_ANY) && ((mbuf < 0 || mbuf > N_MBUFS)))
        return;
    
    if (mbuf == MEMBUF_ANY) {
        mbufptr = &mbufheap[0];
        for (i = 0; i < N_MBUFS; i++) {
            if (mbufptr->active && MEM_WITHIN_BUF (mbufptr, mem)) 
                break;
            mbufptr++;
        }
        if (i == N_MBUFS)
            return;
    } else
        mbufptr = &mbufheap[mbuf];

    blk = MEM_TO_BLK (mbufptr, mem);
    if (blk < 0 || blk > mbufptr->nblks)
        return;
    
    newblk = (void**)((unsigned int)mbufptr->memptr + 
                      (mbufptr->blksiz * blk));                                         // Forcing it to be a valid chain offset within the block

    *newblk = mbufptr->freep;
    mbufptr->freep = (void*)newblk;
    mbufptr->nfree++;
}
#endif /* CONFIG_BUFMALLOC */
