////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2007 Xilinx, Inc.  All rights reserved.
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
// $Id: mpu.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file mpu.h
//! Memory protection related declarations
//----------------------------------------------------------------------------------------------------//

#ifndef _MPU_H
#define _MPU_H

#ifdef __cplusplus
extern "C" {
#endif

#define MPU_PROT_EXEC             0x200
#define MPU_PROT_READWRITE        0x100
#define MPU_PROT_READ             0x0    
#define MPU_PROT_NONE             0x0

//----------------------------------------------------------------------------------------------------//
//! The I/O ranges that must be initialized when an MPU is enabled are configured here.
//! These I/O ranges will not include "memory" ranges.
//----------------------------------------------------------------------------------------------------//
typedef struct xilkernel_io_range_s {
    unsigned int baseaddr;
    unsigned int highaddr;
    unsigned int flags;
} xilkernel_io_range_t;


#ifdef __cplusplus
}       
#endif 

#endif  // _MPU_H
