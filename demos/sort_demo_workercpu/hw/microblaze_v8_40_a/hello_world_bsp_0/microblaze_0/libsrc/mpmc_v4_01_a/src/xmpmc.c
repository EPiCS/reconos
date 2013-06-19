/* $Id: xmpmc.c,v 1.1.2.1 2010/07/12 06:19:04 svemula Exp $ */
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
* @file xmpmc.c
*
* The implementation of the XMpmc component's basic functionality. See xmpmc.h
* for more information about the component.
*
* @note		None.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a mta  02/24/07 First release
* 2.00a mta  10/24/07 Added support for Performance Monitoring and Static Phy
* 4.00a ktn  10/30/09 Updated to use HAL Processor API's. _m is removed from
*		      all the macro names/definitions.
* 4.01a sv   07/12/10 Removed the assert for ConfigPtr.StaticPhyPresent in
*		      XMpmc_GetStaticPhyReg and XMpmc_SetStaticPhyReg APIs
*		      as these APIs can also be used for configuring SDRAM Phy
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xmpmc.h"
#include "xstatus.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Variable Definitions ****************************/

/************************** Function Prototypes *****************************/

/*****************************************************************************/
/**
*
* This function initializes a specific XMpmc instance.
*
* @param	InstancePtr is a pointer to the XMpmc instance.
* @param	ConfigPtr points to the XMpmc device configuration structure.
* @param	EffectiveAddr is the device base address in the virtual memory
*		address space. If the address translation is not used then the
*		physical address is passed.
*		Unexpected errors may occur if the address mapping is changed
*		after this function is invoked.
*
* @return
*		- XST_SUCCESS if successful.
*		- XST_FAILURE if ECC support OR Static Phy OR Performance
*			Monitor functionality is not configured in the device.
*
* @note		None.
*
******************************************************************************/
int XMpmc_CfgInitialize(XMpmc * InstancePtr, XMpmc_Config * ConfigPtr,
			u32 EffectiveAddr)
{
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(ConfigPtr != NULL);

	/*
	 * Set some default values.
	 */
	InstancePtr->IsReady = FALSE;

	/*
	 * Initialize the instance structure with
	 * device configuration data.
	 */
	InstancePtr->ConfigPtr.BaseAddress = EffectiveAddr;
	InstancePtr->ConfigPtr.EccSupportPresent =
				ConfigPtr->EccSupportPresent;
	InstancePtr->ConfigPtr.StaticPhyPresent =
				ConfigPtr->StaticPhyPresent;
	InstancePtr->ConfigPtr.PerfMonitorEnable =
				ConfigPtr->PerfMonitorEnable;
	InstancePtr->ConfigPtr.DeviceId = ConfigPtr->DeviceId;
	InstancePtr->ConfigPtr.MemBaseAddress = ConfigPtr->MemBaseAddress;
	InstancePtr->ConfigPtr.MemHighAddress = ConfigPtr->MemHighAddress;
	InstancePtr->ConfigPtr.MemDataWidth = ConfigPtr->MemDataWidth;
	InstancePtr->ConfigPtr.MemBankBits = ConfigPtr->MemBankBits;
	InstancePtr->ConfigPtr.MemRowBits = ConfigPtr->MemRowBits;
	InstancePtr->ConfigPtr.MemColBits = ConfigPtr->MemColBits;
	InstancePtr->ConfigPtr.MemDqsWidth = ConfigPtr->MemDqsWidth;
	InstancePtr->ConfigPtr.Clk0PeriodPs = ConfigPtr->Clk0PeriodPs;

	InstancePtr->IsReady = XIL_COMPONENT_IS_READY;

	return XST_SUCCESS;
}

/****************************************************************************/
/**
*
* Enable the ECC mode for both read and write operations in the MPMC device.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XMpmc_EnableEcc(XMpmc * InstancePtr)
{
	u32 RegData;

	/*
	 * Assert arguments.
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr->ConfigPtr.EccSupportPresent == TRUE);



	/* Set the bits to enable both the read and write ECC operations without
	 * altering any other bits of the register.
	 */
	RegData = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_ECCCR_OFFSET);
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress, XMPMC_ECCCR_OFFSET,
			RegData | (XMPMC_ECCCR_RE_MASK | XMPMC_ECCCR_WE_MASK));
}

/****************************************************************************/
/**
*
* Disable the ECC mode for both read and write operations in the MPMC device.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XMpmc_DisableEcc(XMpmc * InstancePtr)
{
	u32 RegData;

	/*
	 * Assert arguments.
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr->ConfigPtr.EccSupportPresent == TRUE);
	/*
	 * Clear the bits to disable both the read and write ECC operations
	 * without altering any other bits of the register.
	 */
	RegData = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_ECCCR_OFFSET);
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress, XMPMC_ECCCR_OFFSET,
			RegData & ~(XMPMC_ECCCR_RE_MASK |
				     XMPMC_ECCCR_WE_MASK));
}

/****************************************************************************/
/**
*
* Set the ECC Control Register of the MPMC device to the specified value. This
* function can be used to individually enable/disable read or write ECC and
* force specific types of ECC errors to occur.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
* @param	Control contains the value to be written to the register and
*		consists of constants named XMPMC_ECCCR* for each bit field as
*		specified in xmpmc_hw.h.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XMpmc_SetControlEcc(XMpmc * InstancePtr, u32 Control)
{
	/*
	 * Assert arguments.
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr->ConfigPtr.EccSupportPresent == TRUE);
	/*
	 * Set the control register without any concern for destructiveness.
	 */
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress, XMPMC_ECCCR_OFFSET,
			Control);
}

/****************************************************************************/
/**
*
* Get the ECC Control Register contents of the MPMC device. This function can
* be used to determine which features are enabled in the device.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
*
* @return	The value read from the register which consists of constants
*		named XMPMC_ECCCR* for each bit field as specified in
*		xmpmc_hw.h.
*
* @note		None.
*
*****************************************************************************/
u32 XMpmc_GetControlEcc(XMpmc * InstancePtr)
{
	/*
	 * Assert arguments.
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertNonvoid(InstancePtr->ConfigPtr.EccSupportPresent == TRUE);

	return XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
			      XMPMC_ECCCR_OFFSET);
}

/****************************************************************************/
/**
*
* Get the ECC Status Register contents of the MPMC device. This function can
* be used to determine which errors have occurred for ECC mode.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
*
* @return	The value read from the register which consists of constants
*		named XMPMC_ECCSR* for each bit field as specified in
*		xmpmc_hw.h.
*
* @note		None.
*
*****************************************************************************/
u32 XMpmc_GetStatusEcc(XMpmc * InstancePtr)
{
	/*
	 * Assert arguments.
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertNonvoid(InstancePtr->ConfigPtr.EccSupportPresent == TRUE);

	return XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
			      XMPMC_ECCSR_OFFSET);
}

/****************************************************************************/
/**
*
* Clear the ECC Status Register contents of the MPMC device. This function can
* be used to clear errors in the status that have been processed.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XMpmc_ClearStatusEcc(XMpmc * InstancePtr)
{
	/*
	 * Assert arguments.
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr->ConfigPtr.EccSupportPresent == TRUE);

	/*
	 * Any value written causes the status to be cleared.
	 */
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress,
			XMPMC_ECCSR_OFFSET, 0);
}

/****************************************************************************/
/**
*
* Enable the Performance Monitoring for the specified ports.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
* @param 	Mask is the of the ports for which the PM is to be enabled.
*		Bit positions of 1 are enabled. The mask is formed by OR'ing
*		bits from XMPMC_PMREG_*_MASK.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XMpmc_EnablePm(XMpmc *InstancePtr, u32 Mask)
{
	u32 RegData;

	/*
	 * Assert arguments.
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr->ConfigPtr.PerfMonitorEnable == TRUE);

	/*
	 * Enable the Performance Monitoring for the specified ports.
	 */
	RegData = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_PMCTRL_OFFSET);
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress,
			XMPMC_PMCTRL_OFFSET, RegData | Mask);
}

/****************************************************************************/
/**
*
* Disable the Performance Monitoring for the specified ports.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
* @param 	Mask is the bit-mask of the ports for which the PM is to be
*		disabled.
*		Bit positions of 1 are disabled. The mask is formed by OR'ing
*		bits from XMPMC_PMREG_*_MASK.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XMpmc_DisablePm(XMpmc *InstancePtr, u32 Mask)
{
	u32 RegData;

	/*
	 * Assert arguments.
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr->ConfigPtr.PerfMonitorEnable == TRUE);

	/*
	 * Disable the Performance Monitoring for the specified ports.
	 */
	RegData = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_PMCTRL_OFFSET) &
				  XMPMC_PMREG_PM_ALL_MASK;
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress,
			XMPMC_PMCTRL_OFFSET, RegData & (~ Mask));
}

/****************************************************************************/
/**
*
* Clear the Performance Monitoring Data Bins for the specified ports.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
* @param 	Mask is the bit-mask of the ports for which the PM Data bins
*		are to be cleared.
*		Bit positions of 1 are cleared. The mask is formed by OR'ing
*		bits from XMPMC_PMREG_*_MASK.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XMpmc_ClearDataBinPm(XMpmc * InstancePtr, u32 Mask)
{
	u32 RegData;

	/*
	 * Assert arguments.
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr->ConfigPtr.PerfMonitorEnable == TRUE);

	/*
	 * Clear the Performance Monitoring Data Bins for the specified ports.
	 */
	RegData = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_PMSTATUS_OFFSET);
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress,
			XMPMC_PMCLR_OFFSET, RegData | Mask );
}


/****************************************************************************/
/**
*
* Get the Performance Monitoring Data Bin Clear Status.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
*
* @return	The Status of the Clear Operation on the Data Bins.
*
* @note		None.
*
*****************************************************************************/
u32 XMpmc_GetStatusPm(XMpmc * InstancePtr)
{
	u32 RegData;

	/*
	 * Assert arguments.
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertNonvoid(InstancePtr->ConfigPtr.PerfMonitorEnable == TRUE);

	/*
	 * Get the Performance Monitoring Data Bin Clear Status.
	 */
	RegData = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_PMSTATUS_OFFSET);

	return RegData;

}

/****************************************************************************/
/**
*
* Clears the Performance Monitoring Data Bin Clear Status for the specified
* bins.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
* @param 	Mask is the of the ports for which the PM Data bin clear status
*		bits are to be cleared. Bit positions of 1 are cleared.
*		The mask is formed by OR'ing bits from XMPMC_PMREG_*_MASK.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XMpmc_ClearStatusPm(XMpmc * InstancePtr, u32 Mask)
{

	/*
	 * Assert arguments.
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
	Xil_AssertVoid(InstancePtr->ConfigPtr.PerfMonitorEnable == TRUE);

	/*
	 * Clear the Performance Monitoring Status for the specified ports.
	 */
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_PMSTATUS_OFFSET,
				  Mask);

}


/****************************************************************************/
/**
*
* Get the Performance Monitoring Global Cycle Count.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
*
* @return	The Global Cycle Count.
*
* @note		None.
*
*****************************************************************************/
Xuint64 XMpmc_GetGlobalCycleCountPm(XMpmc * InstancePtr)
{
	Xuint64 RegData;

	/*
	 * Get the Performance Monitoring Global Cycle Count.
	 */
	RegData.Upper = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_PMGCC_OFFSET);
	RegData.Lower = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
				  XMPMC_PMGCC_OFFSET + 4);

	return RegData;

}


/****************************************************************************/
/**
*
* Get the Performance Monitoring Dead Cycle Count for the specified port.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
* @param	PortNum is the Port Number. The valid port numbers are 0 to 7.
*		Use the definitions XMPMC_PM_PORT* for specifying the port
*		number.
*
* @return	The Dead Cycle Count for the specified port.
*
* @note		The user is responsible for giving valid inputs to this
*		function. The input arguments are not checked for correctness
*		in this function.
*
*****************************************************************************/
Xuint64 XMpmc_GetDeadCycleCountPm(XMpmc * InstancePtr, u8 PortNum)
{
	u32 RegAddress;
	Xuint64 RegData;

	/*
	 * Get the Performance Monitoring Dead Cycle Count.
	 */
	RegAddress = XMPMC_PMDCC_OFFSET + (PortNum << 3);
	RegData.Upper = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
					RegAddress);
	RegData.Lower = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
					RegAddress + 4);

	return RegData;
}


/****************************************************************************/
/**
*
* Get the Performance Monitoring Data for the specified bin.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
* @param	PortNum is the Port Number. The valid port numbers are 0 to 7.
*		Use the definitions XMPMC_PM_PORT* for specifying the port
*		number.
* @param	Qualifier is the qualifier type. The valid  qualifier type
*		is 0 to 5 . Use the definitions XMPMC_PM_DATABIN_QUAL* for
*		specifying the Qualifier type.
* @param	AccessType specifies whether the Data bin is for Read or Write
*		access. Valid values are 0 to 1. Use the following definitions
*		- Read access (XMPMC_PM_DATABIN_ACCESS_READ)
*		- Write access (XMPMC_PM_DATABIN_ACCESS_WRITE)
* @param	BinNumber is the Bin Number. The valid values are 0 to 31 .
*
*
* @return	The Data Bin Count for the specified Port/Qualifier/AccessType
*		and BinNumber.
*
* @note		The user is responsible for giving valid inputs to this
*		function. The input arguments are not checked for correctness
*		in this function.
*
*****************************************************************************/
Xuint64 XMpmc_GetDataBinCountPm(XMpmc * InstancePtr, u8 PortNum , u8 Qualifier,
				u8 AccessType, u8 BinNumber)
{
	u32 RegAddress;
	Xuint64 RegData;


	/*
	 * Calculate the address of the Data bin.
	 */
	RegAddress =  XMPMC_PMDATABIN_OFFSET +
			(XMPMC_PM_DATABIN_PORT_REG_OFFSET * PortNum) +
			(XMPMC_PM_DATABIN_QUAL_REG_OFFSET * Qualifier) +
			(XMPMC_PM_DATABIN_ACCESS_REG_OFFSET * AccessType) +
			(BinNumber << 3 );

	/*
	 * Get the Performance Monitoring Data bin Count.
	 */
	RegData.Upper = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
					RegAddress);
	RegData.Lower = XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
					RegAddress + 4);


	return RegData;
}


/****************************************************************************/
/**
*
* Set the Static Phy Interface Register of the MPMC device to the specified
* value.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
* @param	Data contains the value to be written to the register. and
*		Use the definitions XMPMC_SPIR_* in xmpmc_hw.h for specifying
*		the value.
*
* @return	None.
*
* @note		This function does not check whether the Static Phy in enabled
*		in the HW design or whether there is a SDRAM Phy in the HW
*		design.
*
*****************************************************************************/
void XMpmc_SetStaticPhyReg(XMpmc * InstancePtr, u32 Data)
{
	/*
	 * Assert arguments.
	 */
	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Set the control register without any concern for destructiveness.
	 */
	XMpmc_WriteReg(InstancePtr->ConfigPtr.BaseAddress, XMPMC_SPIR_OFFSET,
			Data);
}

/****************************************************************************/
/**
*
* Get the Static Phy Interface Register contents of the MPMC device.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
*
* @return	The value read from the register which consists of constants
*		Use the definitions XMPMC_SPIR_* in xmpmc_hw.h for interpreting
*		the value.
*
* @note		This function does not check whether the Static Phy in enabled
*		in the HW design or whether there is a SDRAM Phy in the HW
*		design.
*
*****************************************************************************/
u32 XMpmc_GetStaticPhyReg(XMpmc * InstancePtr)
{
	/*
	 * Assert arguments.
	 */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);


	return XMpmc_ReadReg(InstancePtr->ConfigPtr.BaseAddress,
			      XMPMC_SPIR_OFFSET);
}

