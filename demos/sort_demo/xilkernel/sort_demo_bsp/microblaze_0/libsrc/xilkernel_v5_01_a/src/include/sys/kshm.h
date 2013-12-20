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
// $Id: kshm.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file kshm.h
//! Kernel level shared memory declarations and definitions
//----------------------------------------------------------------------------------------------------//

#ifndef _KSHM_H
#define _KSHM_H

#include <sys/ktypes.h>
#include <sys/msg.h>
#include <sys/shm.h>

#ifdef __cplusplus
extern "C" {
#endif

// SHM system calls
int   sys_shmget (key_t key, size_t size, int shmflg);
int   sys_shmctl (int shmid, int cmd, struct shmid_ds* buf);
void* sys_shmat  (int shmid, const void *shmaddr, int shmflg);
int   sys_shmdt  (const void *shmaddr);

#ifdef __cplusplus
}       
#endif 

#endif /* _KSHM_H */
