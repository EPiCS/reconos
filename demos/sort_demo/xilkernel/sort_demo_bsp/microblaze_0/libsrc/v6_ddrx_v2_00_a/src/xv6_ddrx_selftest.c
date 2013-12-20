/* $Id: xv6_ddrx_selftest.c,v 1.1.2.2 2011/05/12 05:39:12 sadanan Exp $ */
/******************************************************************************
*
* (c) Copyright 2011 Xilinx, Inc. All rights reserved.
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
* @file xv6_ddrx_selftest.c
*
* The implementation of the XV6_Ddrx driver's self test function.
* See xv6_ddrx.h for more information about the driver.
*
* @note
*
* None
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 2.00a sdm  05/02/11 First release
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xv6_ddrx.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Variable Definitions ****************************/

/************************** Function Prototypes *****************************/

/*****************************************************************************/
/**
* Run a self-test on the driver/device. Unless ECC is enabled in hardware, this
* function does nothing.
*
* With ECC and ECC_TEST enabled, this function does a minimal test where some of
* the ECC registers are written and read.
*
* @param	InstancePtr is a pointer to the XV6_Ddrx instance.
*
* @return 	XST_SUCCESS unless data mismatch occurs when ECC registers are
*		written to and read back.
*
* @note		None.
*
******************************************************************************/
int XV6_Ddrx_SelfTest(XV6_Ddrx *InstancePtr)
{
	u32 Reg;

	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/* Do nothing if ECC is not enabled in the hardware */
	if (InstancePtr->Config.EccPresent == 0) {
		return (XST_SUCCESS);
	}

	if (InstancePtr->Config.CtrlBaseAddress == 0) {
		return (XST_SUCCESS);
	}

	/* Save the contents of the ECC IRQ enable register */
	Reg = XV6_Ddrx_ReadReg(InstancePtr->Config.CtrlBaseAddress,
			       XV6_DDRX_ECC_EN_IRQ_OFFSET);

	/* Write and read the ECC IRQ enable register */
	XV6_Ddrx_WriteReg(InstancePtr->Config.CtrlBaseAddress,
			  XV6_DDRX_ECC_EN_IRQ_OFFSET, 0);
	if (XV6_Ddrx_ReadReg(InstancePtr->Config.CtrlBaseAddress,
			     XV6_DDRX_ECC_EN_IRQ_OFFSET) != 0) {
		return (XST_FAILURE);
	}

	/* Restore the contents of the ECC IRQ enable register */
	XV6_Ddrx_WriteReg(InstancePtr->Config.CtrlBaseAddress,
			  XV6_DDRX_ECC_EN_IRQ_OFFSET, Reg);

	/* Save the contents of the CE counter register */
	Reg = XV6_Ddrx_ReadReg(InstancePtr->Config.CtrlBaseAddress,
			       XV6_DDRX_CE_CNT_OFFSET);

	/* Write and read the CE counter register */
	XV6_Ddrx_WriteReg(InstancePtr->Config.CtrlBaseAddress,
			  XV6_DDRX_CE_CNT_OFFSET, 0xFF);
	if (XV6_Ddrx_ReadReg(InstancePtr->Config.CtrlBaseAddress,
			      XV6_DDRX_CE_CNT_OFFSET) != 0xFF) {
		return (XST_FAILURE);
	}

	XV6_Ddrx_WriteReg(InstancePtr->Config.CtrlBaseAddress,
			  XV6_DDRX_CE_CNT_OFFSET, 0);
	if (XV6_Ddrx_ReadReg(InstancePtr->Config.CtrlBaseAddress,
			      XV6_DDRX_CE_CNT_OFFSET) != 0) {
		return (XST_FAILURE);
	}

	/* Restore the contents of the CE counter register */
	XV6_Ddrx_WriteReg(InstancePtr->Config.CtrlBaseAddress,
			  XV6_DDRX_CE_CNT_OFFSET, Reg);

	return (XST_SUCCESS);
}
