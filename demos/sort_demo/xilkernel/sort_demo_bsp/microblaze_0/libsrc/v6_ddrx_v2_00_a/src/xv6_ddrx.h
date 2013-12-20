/* $Id: xv6_ddrx.h,v 1.1.2.2 2011/05/07 07:35:49 sadanan Exp $ */
/******************************************************************************
*
* (c) Copyright 2006-2011 Xilinx, Inc. All rights reserved.
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
* @file xv6_ddrx.h
*
* If ECC is not enabled, this driver exists only to allow the tools to
* create a memory test application and to populate xparameters.h with memory
* range constants. In this case there is no source code.
*
* If ECC is enabled, this file contains the software API definition of the
* Xilinx V6_DDRX Interface Controller (XV6_Ddrx) device driver.
*
* The Xilinx V6_DDRX controller is a soft IP core designed for Xilinx
* FPGAs and contains the following general features:
*   - LMB v2.0 bus interfaces with byte enable support
*   - Used in conjunction with v6_ddrx_block peripheral to provide fast V6_DDRX
*     memory solution for MicroBlaze ILMB and DLMB ports
*   - Supports byte, half-word, and word transfers
*   - Supports optional V6_DDRX error correction and detection.
*
* The driver provides interrupt management functions. Implementation of
* interrupt handlers is left to the user. Refer to the provided interrupt
* example in the examples directory for details.
*
* This driver is intended to be RTOS and processor independent. Any needs for
* dynamic memory management, threads or thread mutual exclusion, virtual
* memory, or cache control must be satisfied by the layer above this driver.
*
* <b>Initialization & Configuration</b>
*
* The XV6_Ddrx_Config structure is used by the driver to configure
* itself. This configuration structure is typically created by the tool-chain
* based on HW build properties.
*
* To support multiple runtime loading and initialization strategies employed
* by various operating systems, the driver instance can be initialized as
* follows:
*
*   - XV6_Ddrx_CfgInitialize(InstancePtr, CfgPtr, EffectiveAddr) -
*     Uses a configuration structure provided by the caller. If running in a
*     system with address translation, the provided virtual memory base address
*     replaces the physical address present in the configuration structure.
*
* @note
*
* This API utilizes 32 bit I/O to the V6_DDRX registers. With less
* than 32 bits, the unused bits from registers are read as zero and written as
* don't cares.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 2.00a sdm  05/02/11 Added ECC support
* </pre>
*****************************************************************************/
#ifndef XV6_DDRX_H		/* prevent circular inclusions */
#define XV6_DDRX_H		/* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files ********************************/

#include "xil_types.h"
#include "xil_assert.h"
#include "xstatus.h"
#include "xv6_ddrx_hw.h"

/************************** Constant Definitions ****************************/


/**************************** Type Definitions ******************************/

/**
 * This typedef contains configuration information for the device.
 */
typedef struct {
	u16 DeviceId;			   /**< Unique ID  of device */
	u32 MemBaseAddress;		   /**< Device memory base address */
	u32 MemHighAddress;		   /**< Device memory high address */
	u32 CtrlBaseAddress;		   /**< Device register base address.*/
	u32 CtrlHighAddress;		   /**< Device register base address.*/
	int EccPresent;			   /**< Is ECC supported in H/W */
	int EccTestPresent;		   /**< Is Fault Injection
					     *  supported in H/W */
	int EccOnOffRegister;		   /**< Is ECC on/off register supported
					     *  in h/w */
} XV6_Ddrx_Config;

/**
 * The XV6_Ddrx driver instance data. The user is required to
 * allocate a variable of this type for every V6_DDRX device in the
 * system. A pointer to a variable of this type is then passed to the driver
 * API functions.
 */
typedef struct {
	XV6_Ddrx_Config  Config;	/* V6_DDRX config structure */
	u32 IsReady;			/* Device is initialized and ready */
} XV6_Ddrx;

/***************** Macros (Inline Functions) Definitions ********************/


/************************** Function Prototypes *****************************/

/*
 * Functions in xv6_ddrx_sinit.c
 */
XV6_Ddrx_Config *XV6_Ddrx_LookupConfig(u16 DeviceId);

/*
 * Functions implemented in xv6_ddrx.c
 */
int XV6_Ddrx_CfgInitialize(XV6_Ddrx *InstancePtr, XV6_Ddrx_Config *Config,
			u32 EffectiveAddr);

/*
 * Functions implemented in xv6_ddrx_selftest.c
 */
int XV6_Ddrx_SelfTest(XV6_Ddrx *InstancePtr);

/*
 * Functions implemented in xv6_ddrx_intr.c
 */
void XV6_Ddrx_InterruptEnable(XV6_Ddrx *InstancePtr, u32 Mask);
void XV6_Ddrx_InterruptDisable(XV6_Ddrx *InstancePtr, u32 Mask);
void XV6_Ddrx_InterruptClear(XV6_Ddrx *InstancePtr, u32 Mask);
u32 XV6_Ddrx_InterruptGetEnabled(XV6_Ddrx *InstancePtr);
u32 XV6_Ddrx_InterruptGetStatus(XV6_Ddrx *InstancePtr);

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
