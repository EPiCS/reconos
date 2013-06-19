/* $Id: xmpmc_hw.h,v 1.1.2.1 2010/07/12 06:19:04 svemula Exp $ */
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
*
* @file xmpmc_hw.h
*
* This header file contains identifiers and basic driver functions for the
* XMpmc device driver.
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
* 3.00a sdm  12/16/08 Added support for debug registers
* 4.00a ktn  10/30/09 Updated to use HAL API's. _m is removed from all the macro
*		      definitions.
* </pre>
*
******************************************************************************/

#ifndef XMPMC_HW_H		/* prevent circular inclusions */
#define XMPMC_HW_H		/* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/
#include "xil_assert.h"
#include "xil_types.h"
#include "xil_io.h"

/************************** Constant Definitions *****************************/

/** @name Register offsets
 * @{
 */

/* ECC Registers */
#define XMPMC_ECCCR_OFFSET	0x0  /**< ECC Control Register */
#define XMPMC_ECCSR_OFFSET	0x4  /**< ECC Status Register */
#define XMPMC_ECCSEC_OFFSET	0x8  /**< ECC Single Error Count Register */
#define XMPMC_ECCDEC_OFFSET	0xC  /**< ECC Double Error Count Register */
#define XMPMC_ECCPEC_OFFSET	0x10 /**< ECC Parity Field Error Count Reg */
#define XMPMC_ECCADDR_OFFSET	0x14 /**< ECC Error Address Register */

/* Interrupt Registers */
#define XMPMC_DGIE_OFFSET	0x1C /**< Device Global Interrupt Enable Reg */
#define XMPMC_IPISR_OFFSET	0x20 /**< IP Interrupt Status Register */
#define XMPMC_IPIER_OFFSET	0x24 /**< IP Interrupt Enable Register */

/* Static Phy */
#define XMPMC_SPIR_OFFSET	0x1000  /**< Static Phy Control Register */

/* Debug Registers */
#define XMPMC_CALIB_RST_CTRL_OFFSET	0x2000  /**< Calibration Reset Control
						 * Reg */
#define XMPMC_ECC_DEBUG_OFFSET		0x2010  /**< ECC Debug Register */
#define XMPMC_ECC_READ_DATA_OFFSET	0x2014  /**< ECC Read Data Register */
#define XMPMC_ECC_WRITE_DATA_OFFSET	0x2018  /**< ECC Write Data Register */

/* S3 definitions */
#define XMPMC_S3_CALIB_REG_OFFSET	0x2040  /**< S3 Calibration Register */
#define XMPMC_S3_CALIB_STATUS_OFFSET	0x2044  /**< S3 Calibration Status
						 * Register */

/* V4 definitions */
#define XMPMC_V4_CALIB_REG_OFFSET	     0x2100  /**< V4 Calibration
						      * Register */
#define XMPMC_V4_CALIB_STATUS_OFFSET	     0x2104  /**< V4 Calib Status
						      * Register */
#define XMPMC_V4_CALIB_DQS_GROUP0_OFFSET     0x2140  /**< V4 Calibration DQS
						      * Group0 Register */
#define XMPMC_V4_CALIB_DQS_TAP_GROUP0_OFFSET 0x2180  /**< V4 Calibration DQS TAP
						      * Count0 Register */
#define XMPMC_V4_CALIB_DQ_TAP_CNT0_OFFSET    0x2200  /**< V4 Calibration DQ TAP
						      * Count0 Register */

/* V5 definitions */
#define XMPMC_V5_CALIB_REG_OFFSET	    0x2400  /**< V5 Calibration Register
						     */
#define XMPMC_V5_CALIB_STATUS_OFFSET	    0x2404  /**< V5 Calib Status
						     * Register */
#define XMPMC_V5_CALIB_DQS_GROUP0_OFFSET    0x2440  /**< V5 Calibration DQS
						     * Group0 Register */
#define XMPMC_V5_CALIB_DQS_TAP_CNT0_OFFSET  0x2480  /**< V5 Calibration DQS TAP
						     * Count0 Register */
#define XMPMC_V5_CALIB_GATE_TAP_CNT0_OFFSET 0x24C0  /**< V5 Calibration GATE TAP
						     * Count0 Register */
#define XMPMC_V5_CALIB_DQ_TAP_CNT0_OFFSET   0x2600  /**< Calibration DQ TAP
						     * Count0 Register */

/* MPMC Control/Status Register */
#define XMPMC_CTRL_STATUS_OFFSET	0x3000  /**< MPMC Control/Status Reg */

/* Performance Monitor (PM) Registers */
#define XMPMC_PMCTRL_OFFSET	0x7000  /**< PM Control Register */
#define XMPMC_PMCLR_OFFSET	0x7004  /**< PM Clear Register */
#define XMPMC_PMSTATUS_OFFSET	0x7008  /**< PM Status Register */
#define XMPMC_PMGCC_OFFSET	0x7010  /**< PM Global Cycle Counter Register */
#define XMPMC_PMDCC_OFFSET	0x7020  /**< PM Dead Cycle Counter Port 0 */
#define XMPMC_PMDATABIN_OFFSET	0x8000  /**< PM Port-0 Data Bin-0 Register */

/*@}*/

/** @name ECC Control Register bitmaps and masks
 *
 * @{
 */
#define XMPMC_ECCCR_FORCE_PE_MASK 	0x10 /**< Force parity error */
#define XMPMC_ECCCR_FORCE_DE_MASK 	0x08 /**< Force double bit error */
#define XMPMC_ECCCR_FORCE_SE_MASK 	0x04 /**< Force single bit error */
#define XMPMC_ECCCR_RE_MASK		0x02 /**< ECC read enable */
#define XMPMC_ECCCR_WE_MASK		0x01 /**< ECC write enable */

/*@}*/

/** @name ECC Status Register bitmaps and masks
 *
 * @{
 */
#define XMPMC_ECCSR_ERR_SIZE_MASK	0xF000 /**< Error Transaction Size */
#define XMPMC_ECCSR_ERR_RNW_MASK	0x0800 /**< Error Transaction Rd/Wr */
#define XMPMC_ECCSR_SE_SYND_MASK	0x07F8 /**< Single bit error syndrome */
#define XMPMC_ECCSR_PE_MASK		0x0004 /**< Parity field bit error */
#define XMPMC_ECCSR_DE_MASK		0x0002 /**< Double bit error */
#define XMPMC_ECCSR_SE_MASK		0x0001 /**< Single bit error */
#define XMPMC_ECCSR_ERR_SIZE_SHIFT	12     /**< Error Transaction shift */
#define XMPMC_ECCSR_ERR_RNW_SHIFT	11     /**< Error Transc Rd/Wr shift */
#define XMPMC_ECCSR_SE_SYND_SHIFT	3      /**< Single error synd shift */

/*@}*/

/** @name Device Global Interrupt Enable Register bitmaps and masks
 *
 * Bit definitions for the global interrupt enable register.
 * @{
 */
#define XMPMC_DGIE_GIE_MASK		0x80000000  /**< Global Intr Enable */

/*@}*/

/** @name Interrupt Status and Enable Register bitmaps and masks
 *
 * Bit definitions for the interrupt status register and interrupt enable
 * registers.
 * @{
 */
#define XMPMC_IPIXR_PE_IX_MASK		0x4 /**< Parity field error interrupt */
#define XMPMC_IPIXR_DE_IX_MASK		0x2 /**< Double bit error interrupt */
#define XMPMC_IPIXR_SE_IX_MASK		0x1 /**< Single bit error interrupt */

/*@}*/

/** @name Static PHY Interface Register bitmaps and masks.
 *
 * Bit definitions for the PHY Interface Register.
 * @{
 */
#define XMPMC_SPIR_RDEN_DELAY_MASK	 0xF0000000 /**< Read Enable Delay */
#define XMPMC_SPIR_RDDATA_CLK_SEL_MASK	 0x08000000 /**< Read Data Clk Edge */
#define XMPMC_SPIR_RDDATA_SWAP_RISE_MASK 0x04000000 /**< Read Data Clk Shift */
#define XMPMC_SPIR_FIRST_RST_DONE_MASK	 0x01000000 /**< First Reset of Phy */
#define XMPMC_SPIR_DCM_PSEN_MASK	 0x00800000 /**< DCM Phase shift */
#define XMPMC_SPIR_DCM_PSINCDEC_MASK	 0x00400000 /**< DCM Phase shift
						     * Increment/Decrement */
#define XMPMC_SPIR_DCM_DONE_MASK	 0x00200000 /**< DCM Phase shift Done */
#define XMPMC_SPIR_INIT_DONE_MASK	 0x00100000 /**< Init Done */
#define XMPMC_SPIR_DCM_TAP_VALUE_MASK	 0x000001FF /**< DCM Tap Value Mask */

#define XMPMC_SPIR_RDEN_DELAY_SHIFT	 28	    /**< Read Enable Delay */

/*@}*/

/** @name PM Control/Clear/Status Register bitmaps and masks
 *
 * @{
 */
#define XMPMC_PMREG_PM0_MASK	0x80000000 /**< PM0 Mask */
#define XMPMC_PMREG_PM1_MASK	0x40000000 /**< PM1 Mask */
#define XMPMC_PMREG_PM2_MASK	0x20000000 /**< PM2 Mask */
#define XMPMC_PMREG_PM3_MASK	0x10000000 /**< PM3 Mask */
#define XMPMC_PMREG_PM4_MASK	0x08000000 /**< PM4 Mask */
#define XMPMC_PMREG_PM5_MASK	0x04000000 /**< PM5 Mask */
#define XMPMC_PMREG_PM6_MASK	0x02000000 /**< PM6 Mask */
#define XMPMC_PMREG_PM7_MASK	0x01000000 /**< PM7 Mask */
#define XMPMC_PMREG_PM_ALL_MASK 0xFF000000 /**< PM All Mask */

/*@}*/

/** @name Calibration Reset Control Register bitmaps and masks
 *
 * @{
 */
#define XMPMC_CLB_RST_CTL_DEF_ON_RST_MASK 0x00000001 /**< Register default on
						      * reset mask */
/*@}*/

/** @name ECC Debug Register bitmaps and masks
 *
 * @{
 */
#define XMPMC_ECC_DBG_BYTE_ACC_ENB_MASK	0x80000000 /**< debug access to the ECC
						    * byte lane */

/*@}*/

/** @name ECC Read/Write Data Register bitmaps and masks
 *
 * @{
 */
#define XMPMC_ECC_RD_WR_DATA0_MASK	0xFF000000 /**< Data read from ECC byte
						    * lane on the first byte of
						    * the data in the 4 beat
						    * memory burst */
#define XMPMC_ECC_RD_WR_DATA1_MASK	0x00FF0000 /**< Data read from ECC byte
						    * lane on the second byte of
						    * the data in the 4 beat
						    * memory burst */
#define XMPMC_ECC_RD_WR_DATA2_MASK	0x0000FF00 /**< Data read from ECC byte
						    * lane on the third byte of
						    * the data in the 4 beat
						    * memory burst */
#define XMPMC_ECC_RD_WR_DATA3_MASK	0x000000FF /**< Data read from ECC byte
						    * lane on the fourth byte of
						    * the data in the 4 beat
						    * memory burst */
/*@}*/

/** @name Calibration Register bitmaps and masks
 *
 * @{
 */
/* S3 Calibration Register bitmaps and masks */
#define XMPMC_S3CR_DQS_ENB_MASK		0x01000000 /**< Enable signal for strobe
						    * tap selection */
#define XMPMC_S3CR_OUT_DQS_MASK		0x001F0000 /**< Tap values for strobes
						    */
#define XMPMC_S3CR_OUT_DQS_DIV_ENB_MASK	0x00000100 /**< Enable signal for
						    * rst_dqs_div tap selection
						    */
#define XMPMC_S3CR_OUT_DQS_DIV_MASK	0x0000001F /**< Tap values for
						    * rst_dqs_div */

/* V4 Calibration Register bitmaps and masks */
#define XMPMC_V4CR_IDLY_CTL_RDYO_MASK	0x02000000 /**< V4 Status of
						    * MPMC_Idelayctrl_Rdy_O */
#define XMPMC_V4CR_IDLY_CTL_RDY1_MASK	0x01000000 /**< V4 Status of
						    * MPMC_Idelayctrl_Rdy_I */
#define XMPMC_V4CR_FRC_INIT_DONE_MASK	0x00040000 /**< V4 MPMC INIT DONE signal
						    */
#define XMPMC_V4CR_FRC_INIT_DONE_VAL_MASK 0x00020000 /**< V$ MPMC INIT DONE val
 						      * when FORCE_INITDONE = 1
 						      */
#define XMPMC_V4CR_MIG_INIT_DONE_MASK	0x00010000 /**< V4 MIG h/w calibration
						    * initialization status */
#define XMPMC_V4CR_HW_CLB_ON_RST_MASK	0x00000001 /**< V4 Hardware calibration
						    * on MPMC reset */

/* V5 Calibration Register bitmaps and masks */
#define XMPMC_V5CR_IDLY_CTL_RDYO_MASK	0x02000000 /**< V5 Status of
						    * MPMC_Idelayctrl_Rdy_O */
#define XMPMC_V5CR_IDLY_CTL_RDY1_MASK	0x01000000 /**< V5 Status of
						    * MPMC_Idelayctrl_Rdy_I */
#define XMPMC_V5CR_FRC_INIT_DONE_MASK	0x00040000 /**< V5 MPMC INIT DONE signal
						    */
#define XMPMC_V5CR_FRC_INIT_DONE_VAL_MASK 0x00020000 /**< V5 MPMC INIT DONE val
 						      * when FORCE_INITDONE = 1
 						      */
#define XMPMC_V5CR_MIG_INIT_DONE_MASK	0x00010000 /**< V5 MIG h/w calibration
						    * initialization status */
#define XMPMC_V5CR_HW_CLB_ON_RST_MASK	0x00000001 /**< V5 Hardware calibration
						    * on MPMC reset */
/*@}*/

/** @name Calibration Status Register bitmaps and masks
 *
 * @{
 */
/* S3 Calibration Status Register bitmaps and masks */
#define XMPMC_S3CS_DBG_DEL_SEL_MASK	0x1F000000 /**< Tap value to delay the
						    * strobe and rst_dqs_div */
#define XMPMC_S3CS_DBG_PHA_CNT_MASK	0x001F0000 /**< Number of LUTs in the
						    * clock phase */
#define XMPMC_S3CS_DBG_CNT_MASK		0x00003F00 /**< Counter used in the
						    * calibration logic */
#define XMPMC_S3CS_DBG_RST_CLB_MASK	0x00000080 /**< To stop new tap_values
						    * from calibration logic to
						    * strobe and rst_dqs_div
						    * during memory read
						    * operations */
#define XMPMC_S3CS_DBG_TRANS_ONE_MASK	0x00000040 /**< Asserted when the first
						    * transition is detected */
#define XMPMC_S3CS_DBG_TRANS_TWO_MASK	0x00000020 /**< Asserted when the second
						    * transition is detected */
#define XMPMC_S3CS_DBG_ENB_TRANS_TWO_MASK 0x00000010 /**< Enable signal for
						      * dbg_trans_two detect */

/* V4 Calibration Status Register bitmaps and masks */
#define XMPMC_V4CS_SEL_DONE_MASK	0x02000000 /**< V4 Calibration process
						    * of center-aligning DQS
						    * with respect to clock */
#define XMPMC_V4CS_DONE_STS_MASK	0x01FF0000 /**< V4 tap control and
						    * pattern compare
						    * calibration completion
						    * status (1 bit per dqs bit)
						    */
#define XMPMC_V4CS_ERR_STS_MASK		0x000001FF /**< V4 Pattern compare
						    * error completion status
						    * (1 bit per dqs bit) */

/* V5 Calibration Status Register bitmaps and masks */
#define XMPMC_V5CS_BIT_ERR_INDEX_MASK	0x7F000000 /**< Calibration error index
						    */
#define XMPMC_V5CS_DONE_STS_MASK	0x000F0000 /**< V5 Calibration complete
						    * status */
#define XMPMC_V5CS_ERR_STS_MASK		0x0000000F /**< V5 4-bit calibration
						    * error status */
/*@}*/

/** @name Calibration DQS Group Register bitmaps and masks
 *
 * @{
 */
/* V4 Calibration DQS Group Register bitmaps and masks */
#define XMPMC_V4CDG_BYTE_ALIGN_MASK	0xFF000000 /**< V4 Calibration bit
						    * alignment of 8 bits within
						    * the byte */
#define XMPMC_V4CDG_RDEN_DLY_MASK	0x001F0000 /**< Number of cycles after
						    * read command until read
						    * data is valid for DQS
						    * group in V4*/
#define XMPMC_V4CDG_DLY_RD_FALL_MASK	0x00000002 /**< Relative alignment of
						    * bytes for DQS group in V4
						    */
#define XMPMC_V4CDG_RD_SEL_MASK		0x00000001 /**< Final read capture MUX
						    * set for positive or
						    * negative edge capture for
						    * DQS group in V4*/

/* V5 Calibration DQS Group Register bitmaps and masks */
#define XMPMC_V5CDG_RDEN_DLY_MASK	0x001F0000 /**< Number of cycles after
						    * read command until read
						    * data is valid for DQS
						    * group in V5*/
#define XMPMC_V5CDG_GATE_DLY_MASK	0x00001F00 /**< Number of cycles after
						    * read command until clock
						    * enable for DQ byte group
						    * is de-asserted to prevent
						    * post amble glitch for DQS
						    * group in V5*/
#define XMPMC_V5CDG_RD_SEL_MASK		0x00000001 /**< Final read capture MUX
						    * set for positive or
						    * negative edge capture for
						    * DQS group in V5 */
/*@}*/

/** @name Calibration DQS Group Count Register bitmaps and masks
 *
 * @{
 */
/* V4 Calibration DQS Group Count Register bitmaps and masks */
#define XMPMC_V4CDQSTC_TAP_CNT_INC_MASK	0x01000000 /**< IDELAY tap count inc */
#define XMPMC_V4CDQSTC_TAP_CNT_DEC_MASK	0x00010000 /**< IDELAY tap count dec */
#define XMPMC_V4CDQSTC_TAP_CNT_MASK	0x0000003F /**< IDELAY tap count */

/* V5 Calibration DQS Group Count Register bitmaps and masks */
#define XMPMC_V5CDQSTC_TAP_CNT_INC_MASK	0x01000000 /**< IDELAY tap count inc */
#define XMPMC_V5CDQSTC_TAP_CNT_DEC_MASK	0x00010000 /**< IDELAY tap count dec */
#define XMPMC_V5CDQSTC_TAP_CNT_MASK	0x0000003F /**< IDELAY tap count */

/*@}*/

/** @name Calibration DQ TAP Count Register bitmaps and masks
 *
 * @{
 */
/* V4 definitions */
#define XMPMC_V4CDQTC_TAP_CNT_INC_MASK	0x01000000 /**< IDELAY tap count inc */
#define XMPMC_V4CDQTC_TAP_CNT_DEC_MASK	0x00010000 /**< IDELAY tap count dec */
#define XMPMC_V4CDQTC_DLY_EN_MASK	0x00000100 /**< Delay enable */
#define XMPMC_V4CDQTC_TAP_CNT_MASK	0x0000003F /**< IDELAY tap count */

/* V5 definitions */
#define XMPMC_V5CDQTC_TAP_CNT_INC_MASK	0x01000000 /**< IDELAY tap count inc */
#define XMPMC_V5CDQTC_TAP_CNT_DEC_MASK	0x00010000 /**< IDELAY tap count dec */
#define XMPMC_V5CDQTC_TAP_CNT_MASK	0x0000003F /**< IDELAY tap count */

/*@}*/

/** @name Calibration Gate TAP Count Register bitmaps and masks
 *
 * @{
 */
/* V5 definitions */
#define XMPMC_V5CGTC_TAP_CNT_INC_MASK	0x01000000 /**< IDELAY tap count inc */
#define XMPMC_V5CGTC_TAP_CNT_DEC_MASK	0x00010000 /**< IDELAY tap count dec */
#define XMPMC_V5CGTC_TAP_CNT_MASK	0x0000003F /**< IDELAY tap count */

/*@}*/

/**
 * @name Definitions for the MPMC Control/Status register
 * @{
 */
#define XMPMC_CSREG_ECC_CTRL_MASK	0x80000000 /**< ECC CTRL interface
						    * status */
#define XMPMC_CSREG_PHY_CTRL_MASK	0x40000000 /**< Static PHY CTRL
						    * interface status */
#define XMPMC_CSREG_DBG_CTRL_MASK	0x20000000 /**< Debug Registers CTRL
						    * interface status */
#define XMPMC_CSREG_MPMC_CTRL_MASK	0x10000000 /**< MPMC CTRL interface
						    * status */
#define XMPMC_CSREG_PM_CTRL_MASK	0x01000000 /**< PM CTRL interface status
						    */
#define XMPMC_CSREG_MEM_TYPE_MASK	0x0000F000 /**< Memory type (SDRAM/DDR/
						    * DDR2) */
#define XMPMC_CSREG_MEM_WIDTH_MASK	0x00000F00 /**< External memory
						    * interface width */
#define XMPMC_CSREG_NUM_PORTS_MASK	0x00000070 /**< Number of ports */
#define XMPMC_CSREG_DEV_FAMILY_MASK	0x0000000F /**< Device family */

/*@}*/

/**
 * @name Definitions for the Data bins registers of Performance Monitor
 * @{
 */
#define XMPMC_PM_DATABIN_QUAL0	0  /**< Qualifier 0 - Byte to Double words */
#define XMPMC_PM_DATABIN_QUAL1	1  /**< Qualifier 1 - Cache Line 4 */
#define XMPMC_PM_DATABIN_QUAL2	2  /**< Qualifier 2 - Cache Line 8 */
#define XMPMC_PM_DATABIN_QUAL3	3  /**< Qualifier 3 - Burst 16 */
#define XMPMC_PM_DATABIN_QUAL4	4  /**< Qualifier 4 - Burst 32 */
#define XMPMC_PM_DATABIN_QUAL5	5  /**< Qualifier 5 - Burst 64 */

#define XMPMC_PM_DATABIN_ACCESS_WRITE	0  /**< Write Access */
#define XMPMC_PM_DATABIN_ACCESS_READ	1  /**< Read Access */

#define XMPMC_PM_DATABIN_NUM_MIN	0  /**< Lowest Bin Number */
#define XMPMC_PM_DATABIN_NUM_MAX	31 /**< Highest Bin Number */

#define XMPMC_PM_DATABIN_PORT_REG_OFFSET	0x1000 /**< Address Offset
							* between data bins
							* of different Ports */

#define XMPMC_PM_DATABIN_QUAL_REG_OFFSET	0x200 /**< Address Offset
						       * between data bins
						       * of different
						       * Qualifiers */
#define XMPMC_PM_DATABIN_ACCESS_REG_OFFSET	0x100 /**< Address Offset
						       * between data bins
						       * of different
						       * Access types */

/*@}*/

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/****************************************************************************/
/**
*
* Write a value to a MPMC register. A 32 bit write is performed.
*
* @param	BaseAddress is the base address of the MPMC device.
* @param	RegOffset is the register offset from the base to write to.
* @param	Data is the data written to the register.
*
* @return	None.
*
* @note		C-style signature:
*		void XMpmc_WriteReg(u32 BaseAddress, unsigned RegOffset,
					u32 Data);
*
****************************************************************************/
#define XMpmc_WriteReg(BaseAddress, RegOffset, Data) \
			(Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data)))

/****************************************************************************/
/**
*
* Read a value from a MPMC register. A 32 bit read is performed.
*
* @param	BaseAddress is the base address of the MPMC device.
* @param	RegOffset is the register offset from the base to read from.
*
* @return	The value read from the register.
*
* @note		C-style signature:
*		u32 XMpmc_ReadReg(u32 BaseAddress, unsigned RegOffset);
*
****************************************************************************/
#define XMpmc_ReadReg(BaseAddress, RegOffset) \
					(Xil_In32((BaseAddress) + (RegOffset)))

/************************** Function Prototypes ******************************/

/************************** Variable Definitions *****************************/

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
