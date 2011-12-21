/* $Id: xmpmc_selftest.c,v 1.1.2.1 2010/07/12 06:19:04 svemula Exp $ */
/******************************************************************************
*
* (c) Copyright 2007-2010 Xilinx, Inc. All rights reserved.
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
* @file xmpmc_selftest.c
*
* The implementation of the XMpmc component's functionality that is related
* to self test. See xmpmc.h for more information about the component.
*
* @note		None.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a mta  02/22/07 First release
* 4.00a ktn  10/30/09 Updated to use HAL Processor API's. _m is removed from
*		      all the macro names/definitions.
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xmpmc.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Variable Definitions ****************************/

/************************** Function Prototypes *****************************/

/****************************************************************************/
/**
* Perform a self-test on the MPMC device. Self-test will read, write and verify
* that some of the registers of the device are functioning correctly. This
* function will restore the state of the device to state it was in prior to
* the function call.
*
* @param	InstancePtr is the MPMC component to operate on.
*
* @return	XST_SUCCESS if successful else XST_FAILURE.
*
* @note		None.
*
*****************************************************************************/
int XMpmc_SelfTest(XMpmc * InstancePtr)
{
	int Status = XST_SUCCESS;
	u32 IeRegister;
	u32 GieRegister;
	u32 PmCtrlReg;


	/*
	 * Assert arguments
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Self Test for the MPMC ECC functionality.
	 */
	if (InstancePtr->ConfigPtr.EccSupportPresent == TRUE) {

		/*
		 * Save a copy of the Global Interrupt Enable register
		 * and interrupt enable register before writing them so
		 * that they can be restored.
		 */
		GieRegister = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
					     XMPMC_DGIE_OFFSET);

		IeRegister = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
					    XMPMC_IPIER_OFFSET);
		/*
		 * Disable the Global Interrupt so that enabling the interrupts
		 * won't affect the user.
		 */
		XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress,
				XMPMC_DGIE_OFFSET, 0);

		/*
		 * Enable the Single Error interrupt and then verify that the
		 * register reads back correctly.
		 */
		XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress,
				XMPMC_IPIER_OFFSET,
				XMPMC_IPIXR_SE_IX_MASK);

		if (XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				   XMPMC_IPIER_OFFSET) !=
				   XMPMC_IPIXR_SE_IX_MASK) {
			Status = XST_FAILURE;
		}

		/*
		 * Restore the IP Interrupt Enable Register to the value before
		 * the test.
		 */
		XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress,
				XMPMC_IPIER_OFFSET, IeRegister);

		/*
		 * Restore the Global Interrupt Register to the value before the
		 * test.
		 */
		XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress,
				XMPMC_DGIE_OFFSET, GieRegister);

	}

	/*
	 * Self Test for the MPMC Static Phy functionality.
	 */
	if (InstancePtr->ConfigPtr.StaticPhyPresent == TRUE) {

	}

	/*
	 * Self Test for the MPMC Performance Monitor functionality.
	 */
	if (InstancePtr->ConfigPtr.PerfMonitorEnable == TRUE) {


		/*
		 * Save a copy of the Performance Monitor Control Register
		 * before writing it so that it can be restored.
		 */
		PmCtrlReg = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
					  XMPMC_PMCTRL_OFFSET);

		/*
		 * Disable the Performance Monitoring for all the ports and
		 * verify that it is disabled.
		 */
		XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress,
				XMPMC_PMCTRL_OFFSET, 0x0);
		if (XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				   XMPMC_PMCTRL_OFFSET) != 0x0) {
			Status = XST_FAILURE;
		}

		/*
		 * Enable the Performance Monitoring for the Port 0 and
		 * verify that it is enabled.
		 */
		XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress,
				XMPMC_PMCTRL_OFFSET, XMPMC_PMREG_PM0_MASK);
		if (XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
					XMPMC_PMCTRL_OFFSET) !=
					XMPMC_PMREG_PM0_MASK) {
			Status = XST_FAILURE;
		}


		/*
		 * Restore the Performance Monitor Control Register to the value
		 * before the test.
		 */
		XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress,
				XMPMC_PMCTRL_OFFSET, PmCtrlReg);

	}


	return Status;
}

