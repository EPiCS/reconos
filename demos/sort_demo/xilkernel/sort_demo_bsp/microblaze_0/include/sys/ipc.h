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
// $Id: ipc.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file ipc.h
//! Standard POSIX IPC defines and declarations
//----------------------------------------------------------------------------------------------------//

#ifndef _IPC_H
#define _IPC_H

#ifdef __cplusplus
extern "C" {
#endif

#define IPC_CREAT	1       // Create entry if key does not exist. 
#define IPC_EXCL	2       // Fail if key exists. 
#define IPC_NOWAIT	3	// Error if request must wait

#define IPC_SET         1       // Set Options 
#define IPC_STAT	1	// Get Options 
#define IPC_RMID	2	// Remove identifier

#define IPC_PRIVATE 0xffffffff  // Private key (Large value greater than any value possible for key)

#ifdef __cplusplus
}       
#endif 

#endif  /* _IPC_H */
