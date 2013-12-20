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
// $Id: msg.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file msg.h
//! Standard POSIX Message queue definitions and declarations
//----------------------------------------------------------------------------------------------------//
#ifndef _MSG_H
#define _MSG_H

#include <sys/ipc.h>
#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

#define MSG_NOERROR 1


typedef unsigned int msgqnum_t;
typedef unsigned int msglen_t;

struct msqid_ds {
    //struct ipc_perm msg_perm;
    msgqnum_t msg_qnum;   // Number of messages in the Q
    msglen_t  msg_qbytes; // Total number of bytes in the Q
    pid_t     msg_lspid;  // Process ID of last msgsnd().
    pid_t     msg_lrpid;  // Process ID of last msgrcv ().
};

int     msgctl (int msgid, int cmd, struct msqid_ds *buf);
int     msgget (key_t key, int msgflg); 
ssize_t msgrcv (int msgid, void *msgp, size_t msgsz, long msgtyp, int msgflg);
int     msgsnd (int msgid, const void *msgp, size_t msgsz, int msgflg);

#ifdef __cplusplus
}       
#endif 

#endif // _MSG_H
