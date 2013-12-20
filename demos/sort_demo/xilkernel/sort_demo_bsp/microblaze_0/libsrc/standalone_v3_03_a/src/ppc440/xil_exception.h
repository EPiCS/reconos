/******************************************************************************
*
* (c) Copyright 2009 Xilinx, Inc. All rights reserved.
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
/*****************************************************************************/
/**
*
* @file xil_exception.h
*
* This header file contains exception related driver functions (or
* macros) that can be used to access the device. The user should refer to the
* hardware device specification for more details of the device operation.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00  hbm  07/28/09 Initial release
*
* </pre>
*
* @note
*
* None.
*
******************************************************************************/

#ifndef XIL_EXCEPTION_H /* prevent circular inclusions */
#define XIL_EXCEPTION_H /* by using protection macros */

#include "xil_types.h"

#include "xpseudo_asm.h"

#ifdef __cplusplus
extern "C" {
#endif

/************************** Constant Definitions ****************************/

#define XIL_EXCEPTION_CRITICAL                      0x00020000
#define XIL_EXCEPTION_NON_CRITICAL                  0x00008000
#define XIL_EXCEPTION_MACHINE_CHECK                 0x00001000
#define XIL_EXCEPTION_DEBUG                         0x00000200
#define XIL_EXCEPTION_ALL                           0x00029200

#define XIL_EXCEPTION_ID_FIRST                      0
#define XIL_EXCEPTION_ID_CRITICAL_INT               0
#define XIL_EXCEPTION_ID_MACHINE_CHECK              1
#define XIL_EXCEPTION_ID_DATA_STORAGE_INT           2
#define XIL_EXCEPTION_ID_INSTRUCTION_STORAGE_INT    3
#define XIL_EXCEPTION_ID_NON_CRITICAL_INT           4
#define XIL_EXCEPTION_ID_ALIGNMENT_INT              5
#define XIL_EXCEPTION_ID_PROGRAM_INT                6
#define XIL_EXCEPTION_ID_FPU_UNAVAILABLE_INT        7
#define XIL_EXCEPTION_ID_SYSTEM_CALL                8
#define XIL_EXCEPTION_ID_APU_AVAILABLE              9
#define XIL_EXCEPTION_ID_DEC_INT                    10
#define XIL_EXCEPTION_ID_FIT_INT                    11
#define XIL_EXCEPTION_ID_WATCHDOG_TIMER_INT         12
#define XIL_EXCEPTION_ID_DATA_TLB_MISS_INT          13
#define XIL_EXCEPTION_ID_INSTRUCTION_TLB_MISS_INT   14
#define XIL_EXCEPTION_ID_DEBUG_INT                  15
#define XIL_EXCEPTION_ID_LAST                       15

/*
 * XIL_EXCEPTION_ID_INT is defined for all processors.
 */
#define XIL_EXCEPTION_ID_INT           XIL_EXCEPTION_ID_NON_CRITICAL_INT

/**************************** Type Definitions ******************************/

/**
 * This typedef is the exception handler function.
 */
typedef void (*Xil_ExceptionHandler)(void *Data);


/***************** Macros (Inline Functions) Definitions ********************/


/****************************************************************************/
/**
* Enable exceptions with mask.
*
* @param    Mask for exceptions to be enabled. 
*
* @return   None.
*
* @note     This is specific to PPC440.
*
******************************************************************************/
#define Xil_ExceptionEnableMask(Mask) \
            	mtmsr(mfmsr() | (Mask))

/****************************************************************************/
/**
* Enable the non-critical exception.
*
* @return   None.
*
* @note     None.
*
******************************************************************************/
#define Xil_ExceptionEnable() \
		Xil_ExceptionEnableMask(XIL_EXCEPTION_NON_CRITICAL)

/****************************************************************************/
/**
* Disable exceptions with mask.
*
* @param    Mask for exceptions to be enabled. 
*
* @return   None.
*
* @note     This is specific to PPC440.
*
******************************************************************************/
#define Xil_ExceptionDisableMask(Mask) \
            	mtmsr(mfmsr() & ~ (Mask))

/****************************************************************************/
/**
* Disable Non-critical exception.
*
* @return   None.
*
* @note     None.
*
******************************************************************************/
#define Xil_ExceptionDisable() \
		Xil_ExceptionDisableMask(XIL_EXCEPTION_NON_CRITICAL)


/************************** Function Prototypes ******************************/

extern void Xil_ExceptionRegisterHandler(u32 Id,
					 Xil_ExceptionHandler Handler,
					 void *Data);

extern void Xil_ExceptionRemoveHandler(u32 Id);

extern void Xil_ExceptionInit(void);

#ifdef __cplusplus
}
#endif

#endif
