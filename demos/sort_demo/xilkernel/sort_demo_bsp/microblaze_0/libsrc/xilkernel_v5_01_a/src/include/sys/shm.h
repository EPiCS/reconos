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
// $Id: shm.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file shm.h
//! Standard POSIX Shared memory declarations and definitions
//----------------------------------------------------------------------------------------------------//
#ifndef _SHM_H
#define _SHM_H

#include <sys/types.h>
#include <sys/ipc.h>


#ifdef __cplusplus
extern "C" {
#endif

#define SHM_RDONLY    1     // Attach read-only (else read-write). 
#define SHM_RND       2     // Round attach address to SHMLBA. 

#define SHMLBA        4     // Segment low boundary address multiple. 



typedef unsigned int shmatt_t;

// Each Shared Memory is associated with this structure.
// @Note: shmid_ds not fully posix compliant.
// Commented out fields unsupported.
struct shmid_ds {
    //struct ipc_perm shm_perm;          // Operation permission structure. 
    size_t          shm_segsz;           // Size of segment in bytes. 
    pid_t           shm_lpid;            // Process ID of last shared memory operation. 
    pid_t           shm_cpid;            // Process ID of creator. 
    shmatt_t        shm_nattch;          // Number of current attaches. 
    //time_t          shm_atime;         // Time of last shmat (). 
    //time_t          shm_dtime;         // Time of last shmdt (). 
    //time_t          shm_ctime ;        // Time of last change by shmctl ().
};

int   shmget (key_t key, size_t size, int shmflg);
int   shmctl (int shmid, int cmd, struct shmid_ds* buf);
void* shmat (int shmid, const void *shmaddr, int shmflg);
int   shmdt (const void *shmaddr);

#ifdef __cplusplus
}       
#endif 

#endif /* _SHM_H */
