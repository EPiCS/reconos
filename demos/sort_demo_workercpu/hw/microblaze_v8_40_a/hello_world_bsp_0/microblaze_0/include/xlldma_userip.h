/* $Id: */
/******************************************************************************
*
* (c) Copyright 2007-2009 Xilinx, Inc. All rights reserved.
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
* @file xlldma_userip.h
*
* This file is for the User-IP core (like Local-Link TEMAC) to define constants
* that are the User-IP core specific. DMA driver requires the constants to work
* correctly. Two constants must be defined in this file:
*
*   - XLLDMA_USR_APPWORD_OFFSET:
*
*     This constant defines a user word the User-IP always updates in the RX
*     Buffer Descriptors (BD) during any Receive transaction.
*
*     The DMA driver initializes this chosen user word of any RX BD to the
*     pre-defined value (see XLLDMA_USR_APPWORD_INITVALUE below) before
*     giving it to the RX channel. The DMA relies on its updation (by the
*     User-IP) to ensure the BD has been completed by the RX channel besides
*     checking the COMPLETE bit in XLLDMA_BD_STSCTRL_USR0_OFFSET field (see
*     xlldma_hw.h).
*
*     The only valid options for this constant are XLLDMA_BD_USR1_OFFSET,
*     XLLDMA_BD_USR2_OFFSET, XLLDMA_BD_USR3_OFFSET and XLLDMA_BD_USR4_OFFSET.
*
*     If the User-IP does not update any of the option fields above, the DMA
*     driver will not work properly.
*
*   - XLLDMA_USR_APPWORD_INITVALUE:
*
*     This constant defines the value the DMA driver uses to populate the
*     XLLDMA_USR_APPWORD_OFFSET field (see above) in any RX BD before giving
*     the BD to the RX channel for receive transaction.
*
*     It must be ensured that the User-IP will always populates a different
*     value from this constant into the XLLDMA_USR_APPWORD_OFFSET field at
*     the end of any receive transaction. Failing to do so will cause the
*     DMA driver to work improperly.
*
* If the User-IP uses different setting, the correct setting must be defined
* in the xparameters.h or as compiler options used in the Makefile. In either
* case the default definition of the constants in this file will be discarded.
*
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a xd   02/21/07 First release
* 2.00a jz   12/04/09  Hal phase 1 support, changed _m to _ from macro API 
* </pre>
*
******************************************************************************/

#ifndef XLLDMA_USERIP_H		/* prevent circular inclusions */
#define XLLDMA_USERIP_H		/* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xlldma_hw.h"

/************************** Constant Definitions *****************************/

#ifndef XLLDMA_USERIP_APPWORD_OFFSET
#define XLLDMA_USERIP_APPWORD_OFFSET    XLLDMA_BD_USR4_OFFSET
#endif

#ifndef XLLDMA_USERIP_APPWORD_INITVALUE
#define XLLDMA_USERIP_APPWORD_INITVALUE 0xFFFFFFFF
#endif

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/************************** Function Prototypes ******************************/

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
