/* $Id: xpseudo_asm_rvct.h,v 1.1.4.1 2011/10/24 09:35:18 sadanan Exp $ */
/*******************************************************************************
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
*******************************************************************************/
/*****************************************************************************/
/**
*
* @file xpseudo_asm_rvct.h
*
* This header file contains macros for using __inline assembler code. It is
* written specifically for RVCT.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a sdm  11/18/09 First Release
* </pre>
*
******************************************************************************/

#ifndef XPSEUDO_ASM_RVCT_H  /* prevent circular inclusions */
#define XPSEUDO_ASM_RVCT_H  /* by using protection macros */

/***************************** Include Files ********************************/

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/* necessary for pre-processor */
#define stringify(s)	tostring(s)
#define tostring(s)	#s

/* cpsr read/write */
/*#define mfcpsr() 	({ unsigned int val; \
			  val = register unsigned int Reg __asm("cpsr");\
			  val;})*/

#define mtcpsr(v)	{ volatile register unsigned int Reg __asm("cpsr");\
			  Reg = v; }

/* general purpose register read/write */
/*#define mfgpr(rn) 	({ unsigned int val; \
			  register unsigned int Reg __asm("r" stringify(rn));\
			  val = Reg; \
			  val;})*/

#define mtgpr(rn, v)	{ volatile register unsigned int Reg __asm("r" stringify(rn));\
			  Reg = v; }

/* CP15 operations */
/*#define mfcp(rn)	({ unsigned int val; \
			  val = register unsigned int Reg __asm(rn); \
			  val;})*/

#define mtcp(rn, v)	{ volatile register unsigned int Reg __asm(rn); \
			  Reg = v; } \
			   dsb();

/************************** Variable Definitions ****************************/

/************************** Function Prototypes *****************************/

__asm void cpsiei(void);

__asm void cpsidi(void);

__asm void cpsief(void);

__asm void cpsidf(void);

/* memory synchronization operations */

/* Instruction Synchronization Barrier */
__asm void isb(void);

/* Data Synchronization Barrier */
__asm void dsb(void);

/* Data Memory Barrier */
__asm void dmb(void);

/* Memory Operations */
__asm unsigned int ldr(unsigned int adr);

__asm unsigned int ldrb(unsigned int adr);

__asm void str(unsigned int adr, unsigned int val);

__asm void strb(unsigned int adr, unsigned int val);

/* Count leading zeroes (clz) */
__asm unsigned int clz(unsigned int arg);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* XPSEUDO_ASM_RVCT_H */
