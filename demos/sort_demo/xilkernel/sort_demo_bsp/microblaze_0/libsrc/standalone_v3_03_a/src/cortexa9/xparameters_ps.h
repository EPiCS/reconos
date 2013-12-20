/* $Id: xparameters_ps.h,v 1.1.4.4 2011/11/16 04:07:06 sadanan Exp $ */
/******************************************************************************
*
* (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
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
******************************************************************************/
/*****************************************************************************/
/**
* @file xparameters_ps.h
*
* This file contains the address definitions for the hard peripherals
* attached to the ARM Cortex A9 core.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who     Date     Changes
* ----- ------- -------- ---------------------------------------------------
* 1.00a ecm/sdm 02/01/10 Initial version
* </pre>
*
* @note
*
* None.
*
******************************************************************************/

#ifndef _XPARAMETERS_PS_H_
#define _XPARAMETERS_PS_H_

#ifdef __cplusplus
extern "C" {
#endif

/************************** Constant Definitions *****************************/

/*
 * This block contains constant declarations for the peripherals
 * within the hardblock
 */

/* Canonical definitions for DDR MEMORY */
#define XPAR_DDR_MEM_BASEADDR		0x00000000
#define XPAR_DDR_MEM_HIGHADDR		0x3FFFFFFF

/* Canonical definitions for UART */
#define XPAR_XUARTPS_NUM_INSTANCES	2
#define XPAR_XUARTPS_0_DEVICE_ID	0
#define XPAR_XUARTPS_0_BASEADDR		XPS_UART0_BASEADDR
#define XPAR_XUARTPS_0_CLOCK_HZ		50000000
#define XPAR_XUARTPS_0_INTR		XPS_UART0_INT_ID
#define XPAR_XUARTPS_1_DEVICE_ID	1
#define XPAR_XUARTPS_1_BASEADDR		XPS_UART1_BASEADDR
#define XPAR_XUARTPS_1_CLOCK_HZ		50000000
#define XPAR_XUARTPS_1_INTR		XPS_UART1_INT_ID

/* Canonical definitions for USB */
#define XPAR_XUSBPS_NUM_INSTANCES	2
#define XPAR_XUSBPS_0_DEVICE_ID	0
#define XPAR_XUSBPS_0_BASEADDR		XPS_USB0_BASEADDR
#define XPAR_XUSBPS_0_INTR		XPS_USB0_INT_ID
#define XPAR_XUSBPS_1_DEVICE_ID	1
#define XPAR_XUSBPS_1_BASEADDR		XPS_USB1_BASEADDR
#define XPAR_XUSBPS_1_INTR		XPS_USB1_INT_ID

/* Canonical definitions for IIC */
#define XPAR_XIICPS_NUM_INSTANCES	2
#define XPAR_XIICPS_0_DEVICE_ID	0
#define XPAR_XIICPS_0_BASEADDR		XPS_I2C0_BASEADDR
#define XPAR_XIICPS_0_CLOCK_HZ		50000000
#define XPAR_XIICPS_0_INTR		XPS_I2C0_INT_ID
#define XPAR_XIICPS_1_DEVICE_ID	1
#define XPAR_XIICPS_1_BASEADDR		XPS_I2C1_BASEADDR
#define XPAR_XIICPS_1_CLOCK_HZ		50000000
#define XPAR_XIICPS_1_INTR		XPS_I2C1_INT_ID

/* Canonical definitions for SPI */
#define XPAR_XSPIPS_NUM_INSTANCES	2
#define XPAR_XSPIPS_0_DEVICE_ID	0
#define XPAR_XSPIPS_0_BASEADDR		XPS_SPI0_BASEADDR
#define XPAR_XSPIPS_0_CLOCK_HZ		50000000
#define XPAR_XSPIPS_0_INTR		XPS_SPI0_INT_ID
#define XPAR_XSPIPS_1_DEVICE_ID	1
#define XPAR_XSPIPS_1_BASEADDR		XPS_SPI1_BASEADDR
#define XPAR_XSPIPS_1_CLOCK_HZ		50000000
#define XPAR_XSPIPS_1_INTR		XPS_SPI1_INT_ID

/* Canonical definitions for CAN */
#define XPAR_XCANPS_NUM_INSTANCES	2
#define XPAR_XCANPS_0_DEVICE_ID	0
#define XPAR_XCANPS_0_BASEADDR		XPS_CAN0_BASEADDR
#define XPAR_XCANPS_0_INTR		XPS_CAN0_INT_ID
#define XPAR_XCANPS_1_DEVICE_ID	1
#define XPAR_XCANPS_1_BASEADDR		XPS_CAN1_BASEADDR
#define XPAR_XCANPS_1_INTR		XPS_CAN1_INT_ID

/* Canonical definitions for GPIO */
#define XPAR_XGPIOPS_NUM_INSTANCES	1
#define XPAR_XGPIOPS_0_DEVICE_ID	0
#define XPAR_XGPIOPS_0_BASEADDR		XPS_GPIO_BASEADDR
#define XPAR_XGPIOPS_0_INTR		XPS_GPIO_INT_ID

/* Canonical definitions for GEM */
#define XPAR_XEMACPS_NUM_INSTANCES	2
#define XPAR_XEMACPS_0_DEVICE_ID	0
#define XPAR_XEMACPS_0_BASEADDR		XPS_GEM0_BASEADDR
#define XPAR_XEMACPS_0_INTR		XPS_GEM0_INT_ID
#define XPAR_XEMACPS_0_WAKE_INTR	XPS_GEM0_WAKE_INT_ID
#define XPAR_XEMACPS_1_DEVICE_ID	1
#define XPAR_XEMACPS_1_BASEADDR		XPS_GEM1_BASEADDR
#define XPAR_XEMACPS_1_INTR		XPS_GEM1_INT_ID
#define XPAR_XEMACPS_1_WAKE_INTR	XPS_GEM1_WAKE_INT_ID

/* Canonical definitions for QSPI */
#define XPAR_XQSPIPS_NUM_INSTANCES	1
#define XPAR_XQSPIPS_0_DEVICE_ID	0
#define XPAR_XQSPIPS_0_BASEADDR		XPS_QSPI_BASEADDR
#define XPAR_XQSPIPS_0_CLOCK_HZ		50000000
#define XPAR_XQSPIPS_0_INTR		XPS_QSPI_INT_ID
#define XPAR_XQSPIPS_0_LINEAR_BASEADDR	XPS_QSPI_LINEAR_BASEADDR

/* Canonical definitions for Parallel Port */
#define XPAR_XPARPORTPS_CTRL_BASEADDR	XPS_PARPORT_CRTL_BASEADDR
#define XPAR_XPARPORTPS_NUM_INSTANCES	2
#define XPAR_XPARPORTPS_0_DEVICE_ID	0
#define XPAR_XPARPORTPS_0_BASEADDR	XPS_PARPORT0_BASEADDR
#define XPAR_XPARPORTPS_1_DEVICE_ID	1
#define XPAR_XPARPORTPS_1_BASEADDR	XPS_PARPORT1_BASEADDR

/* Canonical definitions for SDIO */
#define XPAR_XSDIOPS_NUM_INSTANCES	2
#define XPAR_XSDIOPS_0_DEVICE_ID	0
#define XPAR_XSDIOPS_0_BASEADDR		XPS_SDIO0_BASEADDR
#define XPAR_XSDIOPS_0_INTR		XPS_SDIO0_INT_ID
#define XPAR_XSDIOPS_1_DEVICE_ID	1
#define XPAR_XSDIOPS_1_BASEADDR		XPS_SDIO1_BASEADDR
#define XPAR_XSDIOPS_1_INTR		XPS_SDIO1_INT_ID

/* Canonical definitions for NAND */
#define XPAR_XNANDPS_NUM_INSTANCES	1
#define XPAR_XNANDPS_0_DEVICE_ID	0
#define XPAR_XNANDPS_0_BASEADDR		XPS_NAND_BASEADDR
#define XPAR_XNANDPS_0_FLASH_WIDTH	8

/* Canonical definitions for TTC */
#define XPAR_XTTCPS_NUM_INSTANCES	6
#define XPAR_XTTCPS_CLOCK_HZ		2500000

#define XPAR_XTTCPS_0_DEVICE_ID	0
#define XPAR_XTTCPS_0_BASEADDR		XPS_TTC0_BASEADDR
#define XPAR_XTTCPS_0_INTR		XPS_TTC0_0_INT_ID
#define XPAR_XTTCPS_0_CLOCK_HZ		XPAR_XTTCPS_CLOCK_HZ

#define XPAR_XTTCPS_1_DEVICE_ID	1
#define XPAR_XTTCPS_1_BASEADDR		XPS_TTC0_BASEADDR + 4
#define XPAR_XTTCPS_1_CLOCK_HZ		XPAR_XTTCPS_CLOCK_HZ
#define XPAR_XTTCPS_1_INTR		XPS_TTC0_1_INT_ID

#define XPAR_XTTCPS_2_DEVICE_ID	2
#define XPAR_XTTCPS_2_BASEADDR		XPS_TTC0_BASEADDR + 8
#define XPAR_XTTCPS_2_CLOCK_HZ		XPAR_XTTCPS_CLOCK_HZ
#define XPAR_XTTCPS_2_INTR		XPS_TTC0_2_INT_ID

#define XPAR_XTTCPS_3_DEVICE_ID	3
#define XPAR_XTTCPS_3_BASEADDR		XPS_TTC1_BASEADDR
#define XPAR_XTTCPS_3_INTR		XPS_TTC1_0_INT_ID
#define XPAR_XTTCPS_3_CLOCK_HZ		XPAR_XTTCPS_CLOCK_HZ

#define XPAR_XTTCPS_4_DEVICE_ID	4
#define XPAR_XTTCPS_4_BASEADDR		XPS_TTC1_BASEADDR + 4
#define XPAR_XTTCPS_4_CLOCK_HZ		XPAR_XTTCPS_CLOCK_HZ
#define XPAR_XTTCPS_4_INTR		XPS_TTC1_1_INT_ID

#define XPAR_XTTCPS_5_DEVICE_ID	5
#define XPAR_XTTCPS_5_BASEADDR		XPS_TTC1_BASEADDR + 8
#define XPAR_XTTCPS_5_CLOCK_HZ		XPAR_XTTCPS_CLOCK_HZ
#define XPAR_XTTCPS_5_INTR		XPS_TTC1_2_INT_ID

/* Canonical definitions for DMAC */
#define XPAR_XDMAPS_NUM_INSTANCES	1
#define XPAR_XDMAPS_0_DEVICE_ID	0
#define XPAR_XDMAPS_0_BASEADDR		XPS_DMAC0_SEC_BASEADDR
#define XPAR_XDMAPS_CHANNELS_PER_DEV	8
#define XPAR_XDMAPS_0_FAULT_INTR	XPS_DMA0_ABORT_INT_ID
#define XPAR_XDMAPS_0_DONE_INTR_0	XPS_DMA0_INT_ID
#define XPAR_XDMAPS_0_DONE_INTR_1	XPS_DMA1_INT_ID
#define XPAR_XDMAPS_0_DONE_INTR_2	XPS_DMA2_INT_ID
#define XPAR_XDMAPS_0_DONE_INTR_3	XPS_DMA3_INT_ID
#define XPAR_XDMAPS_0_DONE_INTR_4	XPS_DMA4_INT_ID
#define XPAR_XDMAPS_0_DONE_INTR_5	XPS_DMA5_INT_ID
#define XPAR_XDMAPS_0_DONE_INTR_6	XPS_DMA6_INT_ID
#define XPAR_XDMAPS_0_DONE_INTR_7	XPS_DMA7_INT_ID

/* Canonical definitions for WDT */
#define XPAR_XWDTPS_NUM_INSTANCES	1
#define XPAR_XWDTPS_0_DEVICE_ID	0
#define XPAR_XWDTPS_0_BASEADDR		XPS_WDT_BASEADDR
#define XPAR_XWDTPS_0_INTR		XPS_WDT_INT_ID

/* Canonical definitions for DCFG */
#define XPAR_XDCFG_NUM_INSTANCES	1
#define XPAR_XDCFG_0_DEVICE_ID	0
#define XPAR_XDCFG_0_BASEADDR		XPS_DEV_CFG_APB_BASEADDR
#define XPAR_XDCFG_0_INTR		XPS_DVC_INT_ID

/* Canonical definitions for SLCR */
#define XPAR_XSLCR_NUM_INSTANCES	1
#define XPAR_XSLCR_0_DEVICE_ID		0
#define XPAR_XSLCR_0_BASEADDR		XPS_SYS_CTRL_BASEADDR

/* Canonical definitions for SCU GIC */
#define XPAR_SCUGIC_NUM_INSTANCES	1
#define XPAR_SCUGIC_SINGLE_DEVICE_ID	0
#define XPAR_SCUGIC_CPU_BASEADDR	(XPS_SCU_PERIPH_BASE + 0x0100)
#define XPAR_SCUGIC_DIST_BASEADDR	(XPS_SCU_PERIPH_BASE + 0x1000)
#define XPAR_SCUGIC_ACK_BEFORE		0

/* Canonical definitions for Global Timer */
#define XPAR_GLOBAL_TMR_NUM_INSTANCES	1
#define XPAR_GLOBAL_TMR_DEVICE_ID	0
#define XPAR_GLOBAL_TMR_BASEADDR	(XPS_SCU_PERIPH_BASE + 0x200)
#define XPAR_GLOBAL_TMR_INTR		XPS_GLOBAL_TMR_INT_ID

/* Canonical definitions for SCU Timer */
#define XPAR_SCUTIMER_NUM_INSTANCES	1
#define XPAR_SCUTIMER_DEVICE_ID		0
#define XPAR_SCUTIMER_BASEADDR		(XPS_SCU_PERIPH_BASE + 0x600)
#define XPAR_SCUTIMER_INTR		XPS_SCU_TMR_INT_ID

/* Canonical definitions for SCU Watchdog timer */
#define XPAR_SCUWDT_NUM_INSTANCES	1
#define XPAR_SCUWDT_DEVICE_ID		0
#define XPAR_SCUWDT_BASEADDR		(XPS_SCU_PERIPH_BASE + 0x600)
#define XPAR_SCUWDT_INTR		XPS_SCU_WDT_INT_ID

/* Xilinx Parallel Flash Library (XilFlash) User Settings */
#define XPAR_XFL_DEVICE_FAMILY		2
#define XPAR_XFL_PART_MODE		1
#define XPAR_XFL_NUM_PARTS		1
#define XPAR_XFL_PART_WIDTH		2
#define XPAR_XFL_BASE_ADDRESS		XPAR_XPARPORTPS_0_BASEADDR
#define XPAR_XFL_PLATFORM_FLASH		0
#define XPAR_AXI_EMC

/******************************************************************/
#define XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ	10000000
/******************************************************************/

/*
 * This block contains constant declarations for the peripherals
 * within the hardblock
 */

#define XPS_PERIPHERAL_BASEADDR		0xE0000000

#define XPS_UART0_BASEADDR		0xE0000000
#define XPS_UART1_BASEADDR		0xE0001000
#define XPS_USB0_BASEADDR		0xE0002000
#define XPS_USB1_BASEADDR		0xE0003000
#define XPS_I2C0_BASEADDR		0xE0004000
#define XPS_I2C1_BASEADDR		0xE0005000
#define XPS_SPI0_BASEADDR		0xE0006000
#define XPS_SPI1_BASEADDR		0xE0007000

#define XPS_CAN0_BASEADDR		0xE0008000
#define XPS_CAN1_BASEADDR		0xE0009000
#define XPS_GPIO_BASEADDR		0xE000A000
#define XPS_GEM0_BASEADDR		0xE000B000
#define XPS_GEM1_BASEADDR		0xE000C000
#define XPS_QSPI_BASEADDR		0xE000D000
#define XPS_PARPORT_CRTL_BASEADDR	0xE000E000
#define XPS_SDIO0_BASEADDR		0xE0100000
#define XPS_SDIO1_BASEADDR		0xE0101000
#define XPS_IOU_BUS_CFG_BASEADDR	0xE0200000
#define XPS_NAND_BASEADDR		0xE1000000
#define XPS_PARPORT0_BASEADDR		0xE2000000
#define XPS_PARPORT1_BASEADDR		0xE4000000
#define XPS_QSPI_LINEAR_BASEADDR	0xFC000000

#define XPS_SYS_CTRL_BASEADDR		0xF8000000	/* AKA SLCR */

#define XPS_TTC0_BASEADDR		0xF8001000
#define XPS_TTC1_BASEADDR		0xF8002000

#define XPS_DMAC0_SEC_BASEADDR		0xF8003000
#define XPS_DMAC0_NON_SEC_BASEADDR	0xF8004000

#define XPS_WDT_BASEADDR		0xF8005000

#define XPS_DDR_CTRL_BASEADDR		0xF8006000

#define XPS_DEV_CFG_APB_BASEADDR	0xF8007000

#define XPS_AFI0_BASEADDR		0xF8008000
#define XPS_AFI1_BASEADDR		0xF8009000
#define XPS_AFI2_BASEADDR		0xF800A000
#define XPS_AFI3_BASEADDR		0xF800B000
#define XPS_OCM_BASEADDR		0xF800C000
#define XPS_EFUSE_BASEADDR		0xF800D000
#define XPS_CORESIGHT_BASEADDR		0xF8800000
#define XPS_TOP_BUS_CFG_BASEADDR	0xF8900000

#define XPS_SCU_PERIPH_BASE		0xF8F00000

#define XPS_L2CC_BASEADDR		0xF8F02000
#define XPS_SAM_RAM_BASEADDR		0xFFFC0000

#define XPS_FPGA_AXI_S0_BASEADDR	0x40000000
#define XPS_FPGA_AXI_S1_BASEADDR	0x80000000
#define XPS_IOU_S_SWITCH_BASEADDR	0xE0000000
#define XPS_PERIPH_APB_BASEADDR		0xF8000000

/* Shared Peripheral Interrupts (SPI) */
#define XPS_CORE_PARITY0_INT_ID		32
#define XPS_CORE_PARITY1_INT_ID		33
#define XPS_L2CC_INT_ID			34
#define XPS_OCMINTR_INT_ID		35
#define XPS_ECC_INT_ID			36
#define XPS_PMU0_INT_ID			37
#define XPS_PMU1_INT_ID			38
#define XPS_SYSMON_INT_ID		39
#define XPS_DVC_INT_ID			40
#define XPS_WDT_INT_ID			41
#define XPS_TTC0_0_INT_ID		42
#define XPS_TTC0_1_INT_ID		43
#define XPS_TTC0_2_INT_ID 		44
#define XPS_DMA0_ABORT_INT_ID		45
#define XPS_DMA0_INT_ID			46
#define XPS_DMA1_INT_ID			47
#define XPS_DMA2_INT_ID			48
#define XPS_DMA3_INT_ID			49
#define XPS_SMC_INT_ID			50
#define XPS_QSPI_INT_ID			51
#define XPS_GPIO_INT_ID			52
#define XPS_USB0_INT_ID			53
#define XPS_GEM0_INT_ID			54
#define XPS_GEM0_WAKE_INT_ID		55
#define XPS_SDIO0_INT_ID		56
#define XPS_I2C0_INT_ID			57
#define XPS_SPI0_INT_ID			58
#define XPS_UART0_INT_ID		59
#define XPS_CAN0_INT_ID			60
#define XPS_FPGA0_INT_ID		61
#define XPS_FPGA1_INT_ID		62
#define XPS_FPGA2_INT_ID		63
#define XPS_FPGA3_INT_ID		64
#define XPS_FPGA4_INT_ID		65
#define XPS_FPGA5_INT_ID		66
#define XPS_FPGA6_INT_ID		67
#define XPS_FPGA7_INT_ID		68
#define XPS_TTC1_0_INT_ID		69
#define XPS_TTC1_1_INT_ID		70
#define XPS_TTC1_2_INT_ID		71
#define XPS_DMA4_INT_ID			72
#define XPS_DMA5_INT_ID			73
#define XPS_DMA6_INT_ID			74
#define XPS_DMA7_INT_ID			75
#define XPS_USB1_INT_ID			76
#define XPS_GEM1_INT_ID			77
#define XPS_GEM1_WAKE_INT_ID		78
#define XPS_SDIO1_INT_ID		79
#define XPS_I2C1_INT_ID			80
#define XPS_SPI1_INT_ID			81
#define XPS_UART1_INT_ID		82
#define XPS_CAN1_INT_ID			83
#define XPS_FPGA8_INT_ID		84
#define XPS_FPGA9_INT_ID		85
#define XPS_FPGA10_INT_ID		86
#define XPS_FPGA11_INT_ID		87
#define XPS_FPGA12_INT_ID		88
#define XPS_FPGA13_INT_ID		89
#define XPS_FPGA14_INT_ID		90
#define XPS_FPGA15_INT_ID		91

/* Private Peripheral Interrupts (PPI) */
#define XPS_GLOBAL_TMR_INT_ID		27	/* SCU Global Timer interrupt */
#define XPS_FIQ_INT_ID			28	/* FIQ from FPGA fabric */
#define XPS_SCU_TMR_INT_ID		29	/* SCU Private Timer interrupt */
#define XPS_SCU_WDT_INT_ID		30	/* SCU Private WDT interrupt */
#define XPS_IRQ_INT_ID			31	/* IRQ from FPGA fabric */

/* L2CC Register Offsets */
#define XPS_L2CC_ID_OFFSET		0x0000
#define XPS_L2CC_TYPE_OFFSET		0x0004
#define XPS_L2CC_CNTRL_OFFSET		0x0100
#define XPS_L2CC_AUX_CNTRL_OFFSET	0x0104
#define XPS_L2CC_TAG_RAM_CNTRL_OFFSET	0x0108
#define XPS_L2CC_DATA_RAM_CNTRL_OFFSET	0x010C

#define XPS_L2CC_EVNT_CNTRL_OFFSET	0x0200
#define XPS_L2CC_EVNT_CNT1_CTRL_OFFSET	0x0204
#define XPS_L2CC_EVNT_CNT0_CTRL_OFFSET	0x0208
#define XPS_L2CC_EVNT_CNT1_VAL_OFFSET	0x020C
#define XPS_L2CC_EVNT_CNT0_VAL_OFFSET	0x0210

#define XPS_L2CC_IER_OFFSET		0x0214		/* Interrupt Mask */
#define XPS_L2CC_IPR_OFFSET		0x0218		/* Masked interrupt status */
#define XPS_L2CC_ISR_OFFSET		0x021C		/* Raw Interrupt Status */
#define XPS_L2CC_IAR_OFFSET		0x0220		/* Interrupt Clear */

#define XPS_L2CC_CACHE_SYNC_OFFSET		0x0730		/* Cache Sync */
#define XPS_L2CC_CACHE_INVLD_PA_OFFSET		0x0770		/* Cache Invalid by PA */
#define XPS_L2CC_CACHE_INVLD_WAY_OFFSET		0x077C		/* Cache Invalid by Way */
#define XPS_L2CC_CACHE_CLEAN_PA_OFFSET		0x07B0		/* Cache Clean by PA */
#define XPS_L2CC_CACHE_CLEAN_INDX_OFFSET	0x07B8		/* Cache Clean by Index */
#define XPS_L2CC_CACHE_CLEAN_WAY_OFFSET		0x07BC		/* Cache Clean by Way */
#define XPS_L2CC_CACHE_INV_CLN_PA_OFFSET	0x07F0		/* Cache Invalidate and Clean by PA */
#define XPS_L2CC_CACHE_INV_CLN_INDX_OFFSET	0x07F8		/* Cache Invalidate and Clean by Index */
#define XPS_L2CC_CACHE_INV_CLN_WAY_OFFSET	0x07FC		/* Cache Invalidate and Clean by Way */

#define XPS_L2CC_CACHE_DLCKDWN_0_WAY_OFFSET	0x0900		/* Cache Data Lockdown 0 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_0_WAY_OFFSET	0x0904		/* Cache Instruction Lockdown 0 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_1_WAY_OFFSET	0x0908		/* Cache Data Lockdown 1 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_1_WAY_OFFSET	0x090C		/* Cache Instruction Lockdown 1 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_2_WAY_OFFSET	0x0910		/* Cache Data Lockdown 2 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_2_WAY_OFFSET	0x0914		/* Cache Instruction Lockdown 2 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_3_WAY_OFFSET	0x0918		/* Cache Data Lockdown 3 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_3_WAY_OFFSET	0x091C		/* Cache Instruction Lockdown 3 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_4_WAY_OFFSET	0x0920		/* Cache Data Lockdown 4 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_4_WAY_OFFSET	0x0924		/* Cache Instruction Lockdown 4 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_5_WAY_OFFSET	0x0928		/* Cache Data Lockdown 5 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_5_WAY_OFFSET	0x092C		/* Cache Instruction Lockdown 5 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_6_WAY_OFFSET	0x0930		/* Cache Data Lockdown 6 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_6_WAY_OFFSET	0x0934		/* Cache Instruction Lockdown 6 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_7_WAY_OFFSET	0x0938		/* Cache Data Lockdown 7 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_7_WAY_OFFSET	0x093C		/* Cache Instruction Lockdown 7 by Way */

#define XPS_L2CC_CACHE_LCKDWN_LINE_ENABLE_OFFSET 0x0950	/* Cache Lockdown Line Enable */
#define XPS_L2CC_CACHE_UUNLOCK_ALL_WAY_OFFSET	0x0954		/* Cache Unlock All Lines by Way */

#define XPS_L2CC_ADDR_FILTER_START_OFFSET	0x0C00		/* Start of address filtering */
#define XPS_L2CC_ADDR_FILTER_END_OFFSET		0x0C04		/* Start of address filtering */

#define XPS_L2CC_DEBUG_CTRL_OFFSET		0x0F40		/* Debug Control Register */

/* XPS_L2CC_CNTRL_OFFSET bit masks */
#define XPS_L2CC_ENABLE_MASK		0x00000001	/* enables the L2CC */

/* XPS_L2CC_AUX_CNTRL_OFFSET bit masks */
#define XPS_L2CC_AUX_IPFE_MASK		0x20000000	/* Instruction Prefetch Enable */
#define XPS_L2CC_AUX_DPFE_MASK		0x10000000	/* Data Prefetch Enable */
#define XPS_L2CC_AUX_NSIC_MASK		0x08000000	/* Non-secure interrupt access control */
#define XPS_L2CC_AUX_NSLE_MASK		0x04000000	/* Non-secure lockdown enable */
#define XPS_L2CC_AUX_FWE_MASK		0x01800000	/* Force write allocate */
#define XPS_L2CC_AUX_SAOE_MASK		0x00400000	/* Shared attribute override enable */
#define XPS_L2CC_AUX_PE_MASK		0x00200000	/* Parity enable */
#define XPS_L2CC_AUX_EMBE_MASK		0x00100000	/* Event monitor bus enable */
#define XPS_L2CC_AUX_WAY_SIZE_MASK	0x000E0000	/* Way-size  - s/b b100 for DF */
#define XPS_L2CC_AUX_ASSOC_MASK		0x00010000	/* Associativity */
#define XPS_L2CC_AUX_EXCL_CACHE_MASK	0x00001000	/* Exclusive cache configuration */

#define XPS_L2CC_AUX_REG_DEFAULT_MASK	0x02020000	/* 16k*/
#define XPS_L2CC_AUX_REG_ZERO_MASK	0xFDF1FEFF	/* */

#define XPS_L2CC_TAG_RAM_DEFAULT_MASK	0x00000121	/* latency for TAG RAM */
#define XPS_L2CC_DATA_RAM_DEFAULT_MASK	0x00000121	/* latency for DATA RAM */

/* Interrupt bit masks */
#define XPS_L2CC_IXR_DECERR_MASK	0x00000100	/* DECERR from L3 */
#define XPS_L2CC_IXR_SLVERR_MASK	0x00000080	/* SLVERR from L3 */
#define XPS_L2CC_IXR_ERRRD_MASK		0x00000040	/* Error on L2 data RAM (Read) */
#define XPS_L2CC_IXR_ERRRT_MASK		0x00000020	/* Error on L2 tag RAM (Read) */
#define XPS_L2CC_IXR_ERRWD_MASK		0x00000010	/* Error on L2 data RAM (Write) */
#define XPS_L2CC_IXR_ERRWT_MASK		0x00000008	/* Error on L2 tag RAM (Write) */
#define XPS_L2CC_IXR_PARRD_MASK		0x00000004	/* Parity Error on L2 data RAM (Read) */
#define XPS_L2CC_IXR_PARRT_MASK		0x00000002	/* Parity Error on L2 tag RAM (Read) */
#define XPS_L2CC_IXR_ECNTR_MASK		0x00000001	/* Event Counter1/0 Overflow Increment */

/* Address filtering mask and enable bit */
#define XPS_L2CC_ADDR_FILTER_VALID_MASK	0xFFF00000	/* Address filtering valid bits*/
#define XPS_L2CC_ADDR_FILTER_ENABLE_MASK 0x00000001	/* Address filtering enable bit*/

/* Debug control bits */
#define XPS_L2CC_DEBUG_SPIDEN_MASK	0x00000004	/* Debug SPIDEN bit */
#define XPS_L2CC_DEBUG_DWB_MASK		0x00000002	/* Debug DWB bit, forces write through */
#define XPS_L2CC_DEBUG_DCL_MASK		0x00000002	/* Debug DCL bit, disables cache line fill */

/* REDEFINES for TEST APP */
/* Definitions for UART */
#define XPAR_PS7_UART_0_DEVICE_ID 	XPAR_XUARTPS_0_DEVICE_ID
#define XPAR_PS7_UART_0_INTR		XPS_UART0_INT_ID
#define XPAR_PS7_UART_1_DEVICE_ID 	XPAR_XUARTPS_1_DEVICE_ID
#define XPAR_PS7_UART_1_INTR		XPS_UART1_INT_ID

/* Definitions for USB */
#define XPAR_PS7_USB_0_DEVICE_ID	XPAR_XUSBPS_0_DEVICE_ID
#define XPAR_PS7_USB_0_INTR		XPS_USB0_INT_ID
#define XPAR_PS7_USB_1_DEVICE_ID	XPAR_XUSBPS_1_DEVICE_ID
#define XPAR_PS7_USB_1_INTR		XPS_USB1_INT_ID

/* Definitions for IIC */
#define XPAR_PS7_I2C_0_DEVICE_ID 	XPAR_XIICPS_0_DEVICE_ID
#define XPAR_PS7_I2C_0_INTR		XPS_I2C0_INT_ID
#define XPAR_PS7_I2C_1_DEVICE_ID	XPAR_XIICPS_1_DEVICE_ID
#define XPAR_PS7_I2C_1_INTR		XPS_I2C1_INT_ID

/* Definitions for SPI */
#define XPAR_PS7_SPI_0_DEVICE_ID 	XPAR_XSPIPS_0_DEVICE_ID
#define XPAR_PS7_SPI_0_INTR		XPS_SPI0_INT_ID
#define XPAR_PS7_SPI_1_DEVICE_ID 	XPAR_XSPIPS_1_DEVICE_ID
#define XPAR_PS7_SPI_1_INTR		XPS_SPI1_INT_ID

/* Definitions for CAN */
#define XPAR_PS7_CAN_0_DEVICE_ID 	XPAR_XCANPS_0_DEVICE_ID
#define XPAR_PS7_CAN_0_INTR		XPAR_XCANPS_0_INTR
#define XPAR_PS7_CAN_1_DEVICE_ID 	XPAR_XCANPS_1_DEVICE_ID
#define XPAR_PS7_CAN_1_INTR		XPAR_XCANPS_1_INTR


/* Definitions for GPIO */
#define XPAR_PS7_GPIO_0_DEVICE_ID 	XPAR_XGPIOPS_0_DEVICE_ID
#define XPAR_PS7_GPIO_0_INTR		XPS_GPIO_INT_ID

/* Definitions for GEM */
#define XPAR_PS7_ETHERNET_0_DEVICE_ID	XPAR_XEMACPS_0_DEVICE_ID
#define XPAR_PS7_ETHERNET_0_INTR	XPS_GEM0_INT_ID
#define XPAR_PS7_ETHERNET_0_WAKE_INTR	XPS_GEM0_WAKE_INT_ID
#define XPAR_PS7_ETHERNET_1_DEVICE_ID	XPAR_XEMACPS_1_DEVICE_ID
#define XPAR_PS7_ETHERNET_1_INTR	XPS_GEM1_INT_ID
#define XPAR_PS7_ETHERNET_1_WAKE_INTR	XPS_GEM1_WAKE_INT_ID

/* Definitions for QSPI */
#define XPAR_PS7_QSPI_0_DEVICE_ID	XPAR_XQSPIPS_0_DEVICE_ID
#define XPAR_PS7_QSPI_0_INTR		XPS_QSPI_INT_ID


/* Definitions for DMAC */
#define XPAR_PS7_DMA_0_DEVICE_ID	XPAR_XDMAPS_0_DEVICE_ID
#define XPAR_PS7_DMA_1_DEVICE_ID	XPAR_XDMAPS_0_DEVICE_ID

/* Definitions for WDT */
#define XPAR_PS7_WDT_0_DEVICE_ID	XPAR_XWDTPS_0_DEVICE_ID
#define XPAR_PS7_WDT_0_INTR		XPS_WDT_INT_ID

/* Definitions for DCFG */
#define XPAR_PS7_DEV_CFG_0_DEVICE_ID	XPAR_XDCFG_0_DEVICE_ID


/* Definitions for SCU GIC */
#define XPAR_PS7_SCUGIC_0_DEVICE_ID	XPAR_SCUGIC_SINGLE_DEVICE_ID

/* Definitions for SCU WDT */
#define XPAR_PS7_SCUWDT_0_DEVICE_ID	XPAR_SCUWDT_DEVICE_ID
#define XPAR_PS7_SCUWDT_0_INTR		XPS_SCU_WDT_INT_ID


/* Definitions for SCU Timer */
#define XPAR_PS7_SCUTIMER_0_DEVICE_ID	XPAR_SCUTIMER_DEVICE_ID
#define XPAR_PS7_SCUTIMER_0_INTR	XPS_SCU_TMR_INT_ID


#ifdef __cplusplus
}
#endif

#endif /* protection macro */
