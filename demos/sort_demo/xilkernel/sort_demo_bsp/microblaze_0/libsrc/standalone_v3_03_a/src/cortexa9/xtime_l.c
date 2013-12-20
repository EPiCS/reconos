/* $Id: xtime_l.c,v 1.1.4.1 2011/10/24 09:35:17 sadanan Exp $ */
/******************************************************************************
*
* (c) Copyright 2009-2010 Xilinx, Inc. All rights reserved.
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
* @file xtime_l.c
*
* This file contains low level functions to get/set time from the Cycle Counter
* register of the ARM Cortex A9 core.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who    Date     Changes
* ----- ------ -------- ---------------------------------------------------
* 1.00a rp/sdm 11/03/09 Initial release.
* </pre>
*
* @note		None.
*
******************************************************************************/
/***************************** Include Files *********************************/

#include "xtime_l.h"
#include "xpseudo_asm.h"
#include "xil_types.h"
#include "xil_assert.h"

/***************** Macros (Inline Functions) Definitions *********************/

/**************************** Type Definitions *******************************/

/************************** Constant Definitions *****************************/

#define CYCLE_COUNTER_MASK			0x80000000

/************************** Variable Definitions *****************************/

static u32 high=0;

/************************** Function Prototypes ******************************/

/****************************************************************************
*
* Set the time in the Cycle Counter Register.
*
* @param	Value to be written to the Cycle Counter Register.
*
* @return	None.
*
* @note		None.
*
****************************************************************************/
void XTime_SetTime(XTime Xtime)
{
	u32 reg;

#ifdef __GNUC__
	/* disable the cycle counter before updating */
	reg = mfcp(XREG_CP15_COUNT_ENABLE_CLR);
#else
	{ register unsigned int Reg __asm(XREG_CP15_COUNT_ENABLE_CLR);
	  reg = Reg; }
#endif

	mtcp(XREG_CP15_COUNT_ENABLE_CLR, reg | CYCLE_COUNTER_MASK);

	/* clear the cycle counter overflow flag */
#ifdef __GNUC__
	reg = mfcp(XREG_CP15_V_FLAG_STATUS);
#else
	{ register unsigned int Reg __asm(XREG_CP15_V_FLAG_STATUS);
	  reg = Reg; }
#endif
	mtcp(XREG_CP15_V_FLAG_STATUS, reg & CYCLE_COUNTER_MASK);

	/* set the time in cyle counter reg */
	mtcp(XREG_CP15_PERF_CYCLE_COUNTER, (u32) Xtime);
	high = Xtime >> 32;

	/* enable the cycle counter */
#ifdef __GNUC__
	reg = mfcp(XREG_CP15_COUNT_ENABLE_SET);
#else
	{ register unsigned int Reg __asm(XREG_CP15_COUNT_ENABLE_SET);
	  reg = Reg; }
#endif
	mtcp(XREG_CP15_COUNT_ENABLE_SET, reg | CYCLE_COUNTER_MASK);
}

/****************************************************************************
*
* Get the time from the Cycle Counter Register.
*
* @param	Pointer to the location to be updated with the time.
*
* @return	None.
*
* @note		None.
*
****************************************************************************/
void XTime_GetTime(XTime *Xtime)
{
	u32 reg;
	u32 low;

	/* loop until we got a consistent result */
	do {
#ifdef __GNUC__
		low = mfcp(XREG_CP15_PERF_CYCLE_COUNTER);
		reg = mfcp(XREG_CP15_V_FLAG_STATUS);
#else
		{ register unsigned int Reg __asm(XREG_CP15_PERF_CYCLE_COUNTER);
		  low = Reg; }
		{ register unsigned int Reg __asm(XREG_CP15_V_FLAG_STATUS);
		  reg = Reg; }
#endif
		if (reg & CYCLE_COUNTER_MASK) {
			/* clear overflow */
			mtcp(XREG_CP15_V_FLAG_STATUS, CYCLE_COUNTER_MASK);
			high++;
		}
	} while (reg & CYCLE_COUNTER_MASK);

	*Xtime = (((XTime) high) << 32) | (XTime) low;
}
