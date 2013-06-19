/* $Id: xmpmc_intr.c,v 1.1.2.1 2010/07/12 06:19:04 svemula Exp $ */
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
* @file xmpmc_intr.c
*
* The implementation of the XMpmc component's functionality that is related
* to interrupts. See xmpmc.h for more information about the component. The
* functions that are contained in this file require that the hardware device
* is built with interrupt support.
*
* @note		None
*
* <pre>
*
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a mta  02/24/07 First release
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
* Enable the core's interrupt output signal. Interrupts enabled through
* XMpmc_IntrEnable() will not occur until the global enable bit is set
* by this function. This function is designed to allow all interrupts to be
* enabled easily for exiting a critical section.
*
* @param	InstancePtr is the MPMC component to operate on.
*
* @return	None.

* @note		This function will assert if the hardware device has not been
*		built with interrupt capabilities.
*
*****************************************************************************/
void XMpmc_IntrGlobalEnable(XMpmc * InstancePtr)
{
	u32 Register;

	/*
	 * Assert arguments
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr->ConfigPtr.EccSupportPresent == TRUE);

	Register = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_DGIE_OFFSET);
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress, XMPMC_DGIE_OFFSET,
			Register | XMPMC_DGIE_GIE_MASK);
}

/****************************************************************************/
/**
* Disable the core's interrupt output signal. Interrupts enabled through
* XMpmc_IntrEnable() will not occur until the global enable bit is set by
* XMpmc_IntrGlobalEnable(). This function is designed to allow all
* interrupts to be disabled easily for entering a critical section.
*
* @param	InstancePtr is the MPMC component to operate on.
*
* @return 	None.
*
* @note		This function will assert if the hardware device has not been
*		built with interrupt capabilities.
*
*****************************************************************************/
void XMpmc_IntrGlobalDisable(XMpmc * InstancePtr)
{
	u32 Register;

	/*
	 * Assert arguments.
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr->ConfigPtr.EccSupportPresent == TRUE);

	Register = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_DGIE_OFFSET);
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress, XMPMC_DGIE_OFFSET,
			Register & (~XMPMC_DGIE_GIE_MASK));
}

/****************************************************************************/
/**
* Enable ECC interrupts so that specific ECC errors will cause an interrupt.
* The function XMpmc_IntrGlobalEnable must also be called to enable any
* interrupt to occur.
*
* @param 	InstancePtr is the MPMC component to operate on.
* @param 	Mask is the mask to enable. Bit positions of 1 are enabled.
*		The mask is formed by OR'ing bits from XMPMC_IPIXR_*_MASK.
*
* @return 	None.
*
* @note		This function will assert if the hardware device has not been
*		built with interrupt capabilities.
*
*****************************************************************************/
void XMpmc_IntrEnable(XMpmc * InstancePtr, u32 Mask)
{
	u32 Register;

	/*
	 * Assert arguments.
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr->ConfigPtr.EccSupportPresent == TRUE);

	/*
	 * Read the interrupt enable register and only enable the specified
	 * interrupts without disabling or enabling any others.
	 */
	Register = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_IPIER_OFFSET);
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress, XMPMC_IPIER_OFFSET,
			Register | Mask);
}

/****************************************************************************/
/**
* Disable ECC interrupts so that ECC errors will not cause an interrupt.
*
* @param 	InstancePtr is the MPMC component to operate on.
* @param 	Mask is the mask to disable. Bits set to 1 are disabled.
*		The mask is formed by OR'ing bits from XMPMC_IPIXR_*_MASK.
*
* @return 	None.
*
* @note 	This function will assert if the hardware device has not been
*		built with interrupt capabilities.
*
*****************************************************************************/
void XMpmc_IntrDisable(XMpmc * InstancePtr, u32 Mask)
{
	u32 Register;

	/*
	 * Assert arguments.
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr->ConfigPtr.EccSupportPresent == TRUE);

	/*
	 * Read the interrupt enable register and only disable the specified
	 * interrupts without enabling or disabling any others.
	 */
	Register = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_IPIER_OFFSET);
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress, XMPMC_IPIER_OFFSET,
			Register & (~Mask));
}

/****************************************************************************/
/**
* Clear pending interrupts with the provided mask. An interrupt must be
* cleared after software has serviced it or it can cause another interrupt.
*
* @param 	InstancePtr is the MPMC component to operate on.
* @param 	Mask is the mask to clear pending interrupts for. Bit positions
*		of 1 are cleared. This mask is formed by OR'ing bits from
*		XMPMC_IPIXR_*_MASK.
*
* @return 	None.
*
* @note		This function will assert if the hardware device has not been
*		built with interrupt capabilities.
*
*****************************************************************************/
void XMpmc_IntrClear(XMpmc * InstancePtr, u32 Mask)
{
	u32 Register;

	/*
	 * Assert arguments.
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr->ConfigPtr.EccSupportPresent == TRUE);

	/*
	 * Read the interrupt status register and only clear the interrupts
	 * that are specified without affecting any others. Since the register
	 * is a toggle on write, make sure any bits to be written are already
	 * set.
	 */
	Register = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_IPISR_OFFSET);
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress, XMPMC_IPISR_OFFSET,
			Register & Mask);

}

/****************************************************************************/
/**
* Returns the interrupt enable mask as set by XMpmc_IntrEnable() which
* indicates which ECC interrupts are enabled or disabled.
*
* @param	InstancePtr is the MPMC component to operate on.
*
* @return	Mask of bits made from XMPMC_IPIXR_*_MASK.
*
* @note 	This function will assert if the hardware device has not been
*		built with interrupt capabilities.
*
*****************************************************************************/
u32 XMpmc_IntrGetEnabled(XMpmc * InstancePtr)
{
	/*
	 * Assert arguments.
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertNonvoid(InstancePtr->ConfigPtr.EccSupportPresent == TRUE);

	return XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
			      XMPMC_IPIER_OFFSET);
}

/****************************************************************************/
/**
* Returns the status of interrupts which indicates which ECC interrupts are
* pending.
*
* @param	InstancePtr is the MPMC component to operate on.
*
* @return 	Mask of bits made from XMPMC_IPIXR_*_MASK.
*
* @note		The interrupt status indicates the status of the device
*		irregardless if the interrupts from the devices have been
*		enabled or not through XMpmc_IntrEnable().
*
* 		This function will assert if the hardware device has not
*		been built with interrupt capabilities.
*
*****************************************************************************/
u32 XMpmc_IntrGetStatus(XMpmc * InstancePtr)
{
	/*
	 * Assert arguments
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertNonvoid(InstancePtr->ConfigPtr.EccSupportPresent == TRUE);

	return XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
			      XMPMC_IPISR_OFFSET);
}
