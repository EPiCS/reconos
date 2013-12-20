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
//! @file arch.h
//! PPC405 specific definitions, constants, declarations
//----------------------------------------------------------------------------------------------------//
#ifndef _PPC_ARCH_H
#define _PPC_ARCH_H

#define STACK_ALIGN                8

#ifndef __ASM__
#define SSTACK_PTR_ADJUST ((int)-8)

//! Process Management Data Structures
//! Context data structure

//////////////////////////////////////////////////////////////////////////////////////
//
// Context map:
//
//    +------------+  + 0
//    |     MSR    | 
//    +------------+  + 4
//    |     PC     | 
//    +------------+  + 8
//    |     LR     | 
//    +------------+  + 12
//    |     CTR    | 
//    +------------+  + 16
//    |     XER    | 
//    +------------+  + 20
//    |     CR     | 
//    +------------+  + 24
//    |     r0     | 
//    |      .     |
//    |      .     |
//    |      .     |
//    |     r31    | 
//    +------------+  + 152
//
//////////////////////////////////////////////////////////////////////////////////////
struct _process_context { 
    unsigned int regs[38]; 	// Process context information store
    char isrflag;
} __attribute__ ((packed, aligned(STACK_ALIGN)));

#define PCONTEXT_SIZ  (sizeof(struct _process_context))

#else

#define SSTACK_PTR_ADJUST      (-8)

#endif

#define CTX_INDEX_MSR           0
#define CTX_INDEX_PC            1
#define CTX_INDEX_LR            2
#define CTX_INDEX_CTR           3
#define CTX_INDEX_XER           4
#define CTX_INDEX_CR            5
#define CTX_INDEX_GPR(r)        (6 + r)

// Various offsets within the context structure
#define CTX_OFFSET              (0)                        // Offset of context structure within process structure
#define CTX_MSR_FIELD           (0)
#define CTX_PC_FIELD            (CTX_MSR_FIELD + 4)
#define CTX_LR_FIELD            (CTX_PC_FIELD  + 4)
#define CTX_CTR_FIELD           (CTX_LR_FIELD  + 4)
#define CTX_XER_FIELD           (CTX_CTR_FIELD + 4)
#define CTX_CR_FIELD            (CTX_XER_FIELD + 4)
#define CTX_GPR_FIELD           (CTX_CR_FIELD  + 4)
#define CTX_GPR_REG_FIELD(reg)  (CTX_GPR_FIELD + (reg * 4))
#define CTX_SIZE                (38 * 4)
#define ISRFLAG_OFFSET          (CTX_OFFSET + CTX_SIZE)

#define ISRFLAG_SYSTEM_CALL     0
#define ISRFLAG_NON_CRITICAL    1
#define ISRFLAG_CRITICAL        2
#define ISRFLAG_NEW_PROC        3

// Various stack sizes used in the kernel
#define PROCESS_STARTUP_STACKSZ    400

#endif /* _PPC_ARCH_H */
