/* $Id: xv6_ddrx_hw.h,v 1.1.2.1 2011/05/07 07:10:21 sadanan Exp $ */
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
*
* @file xv6_ddrx_hw.h
*
* This header file contains identifiers and driver functions (or
* macros) that can be used to access the device.  The user should refer to the
* hardware device specification for more details of the device operation.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 2.00a sdm  05/02/11 First release
* </pre>
*
******************************************************************************/
#ifndef XV6_DDRX_HW_H		/* prevent circular inclusions */
#define XV6_DDRX_HW_H		/* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xil_types.h"
#include "xil_assert.h"
#include "xil_io.h"

/************************** Constant Definitions *****************************/

/** @name Registers
 *
 * Register offsets for this device.
 * @{
 */

#define XV6_DDRX_ECC_STATUS_OFFSET	0x0  /**< ECC status Register */
#define XV6_DDRX_ECC_EN_IRQ_OFFSET	0x4  /**< ECC intr enable Register */
#define XV6_DDRX_ECC_ON_OFF_OFFSET	0x8  /**< ECC on/off register */
#define XV6_DDRX_CE_CNT_OFFSET		0xC  /**< Correctable error counter
					       *  Register */

#define XV6_DDRX_CE_FFD_0_OFFSET	0x100 /**< Correctable error first
					        *  failing data Register, 31-0
					        */
#define XV6_DDRX_CE_FFD_1_OFFSET	0x104 /**< Correctable error first
					        *  failing data Register, 63-32
					        */
#define XV6_DDRX_CE_FFD_2_OFFSET	0x108 /**< Correctable error first
					        *  failing data Register, 95-64
					        */
#define XV6_DDRX_CE_FFD_3_OFFSET	0x10C /**< Correctable error first
					        *  failing data Register, 127-96
					        */

#define XV6_DDRX_CE_FFE_0_OFFSET	0x180 /**< Correctable error first
					        *  failing ECC Register, 31-0 */

#define XV6_DDRX_CE_FFA_0_OFFSET	0x1C0 /**< Correctable error first
					        *  failing address Register,
					        *  31-0 */
#define XV6_DDRX_CE_FFA_1_OFFSET	0x1C4 /**< Correctable error first
					        *  failing address Register,
					        *  63-32 */

#define XV6_DDRX_UE_FFD_0_OFFSET	0x200 /**< Uncorrectable error first
					        *  failing data Register, 31-0
					        */
#define XV6_DDRX_UE_FFD_1_OFFSET	0x204 /**< Uncorrectable error first
					        *  failing data Register, 63-32
					        */
#define XV6_DDRX_UE_FFD_2_OFFSET	0x208 /**< Uncorrectable error first
					        *  failing data Register, 95-64
					        */
#define XV6_DDRX_UE_FFD_3_OFFSET	0x20C /**< Uncorrectable error first
					        *  failing data Register, 127-96
					        */

#define XV6_DDRX_UE_FFE_0_OFFSET	0x280 /**< Uncorrectable error first
					        *  failing ECC Register, 31-0 */

#define XV6_DDRX_UE_FFA_0_OFFSET	0x2C0 /**< Uncorrectable error first
					        *  failing address Register,
					        *  31-0 */
#define XV6_DDRX_UE_FFA_1_OFFSET	0x2C4 /**< Uncorrectable error first
					        *  failing address Register,
					        *  63-32 */

#define XV6_DDRX_FI_D_0_OFFSET		0x300 /**< Fault injection Data
					        *  Register, 31-0 */
#define XV6_DDRX_FI_D_1_OFFSET		0x304 /**< Fault injection Data
					        *  Register, 63-32 */
#define XV6_DDRX_FI_D_2_OFFSET		0x308 /**< Fault injection Data
					        *  Register, 95-64 */
#define XV6_DDRX_FI_D_3_OFFSET		0x30C /**< Fault injection Data
					        *  Register, 127-96 */

#define XV6_DDRX_FI_ECC_0_OFFSET	0x380 /**< Fault injection ECC Register,
					        *  31-0 */

/* @} */

/** @name Interrupt Status and Enable Register bitmaps and masks
 *
 * Bit definitions for the ECC status register and ECC interrupt enable
 * register.
 * @{
 */
#define XV6_DDRX_IR_CE_MASK	0x2 /**< Mask for the correctable error */
#define XV6_DDRX_IR_UE_MASK	0x1 /**< Mask for the uncorrectable error */
#define XV6_DDRX_IR_ALL_MASK	0x3 /**< Mask of all bits */

/*@}*/

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/****************************************************************************/
/**
*
* Write a value to a V6_DDRX register. A 32 bit write is performed.
*
* @param	BaseAddress is the base address of the V6_DDRX device register.
* @param	RegOffset is the register offset from the base to write to.
* @param	Data is the data written to the register.
*
* @return	None.
*
* @note		C-style signature:
*		void XV6_Ddrx_WriteReg(u32 BaseAddress, u32 RegOffset, u32 Data)
*
****************************************************************************/
#define XV6_Ddrx_WriteReg(BaseAddress, RegOffset, Data) \
	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/****************************************************************************/
/**
*
* Read a value from a V6_DDRX register. A 32 bit read is performed.
*
* @param	BaseAddress is the base address of the V6_DDRX device registers.
* @param	RegOffset is the register offset from the base to read from.
*
* @return	Data read from the register.
*
* @note		C-style signature:
*		u32 XV6_Ddrx_ReadReg(u32 BaseAddress, u32 RegOffset)
*
****************************************************************************/
#define XV6_Ddrx_ReadReg(BaseAddress, RegOffset) \
	Xil_In32((BaseAddress) + (RegOffset))

/************************** Function Prototypes ******************************/

/************************** Variable Definitions *****************************/

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
