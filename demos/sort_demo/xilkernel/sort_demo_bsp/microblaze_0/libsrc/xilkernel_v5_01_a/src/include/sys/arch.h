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
// $Id: arch.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file arch.h
//! Includes architecture specific files into one single file (sys/arch.h)
//----------------------------------------------------------------------------------------------------//

#ifndef _SYS_ARCH_H
#define _SYS_ARCH_H

#include <os_config.h>

#ifdef MB_XILKERNEL
#include <arch/microblaze/arch.h>
#endif

#ifdef PPC_XILKERNEL
#include <arch/ppc/arch.h>
#ifndef __ASM__
#include <xtime_l.h>
#include <xil_exception.h>
#endif
#endif
#endif /* _SYS_ARCH_H */
