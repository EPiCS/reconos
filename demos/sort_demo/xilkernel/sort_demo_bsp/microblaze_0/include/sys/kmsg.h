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
// $Id: kmsg.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file kmsg.h
//! Kernel message queue definitions and declarations
//----------------------------------------------------------------------------------------------------//

#ifndef _KMSG_H
#define _KMSG_H

#include <sys/ktypes.h>
#include <sys/ksemaphore.h>
#include <sys/msg.h>
#include <sys/queue.h>

#ifdef __cplusplus
extern "C" {
#endif

#define MSGQ_MAX_BYTES  100

// System calls
int sys_msgctl(int msqid, int cmd, struct msqid_ds *buf);
int sys_msgget(key_t key, int msgflg); 
ssize_t sys_msgrcv(int msqid, void *msgp, size_t msgsz, long msgtyp, int msgflg);
int sys_msgsnd(int msqid, const void *msgp, size_t msgsz, int msgflg);

#ifdef __cplusplus
}       
#endif 

#endif /* _KMSG_H */
