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
* @file xlldma.c
*
* This file implements initialization and control related functions. For more
* information on this driver, see xlldma.h.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a xd   12/21/06 First release
* 1.00b xd   09/05/08 a) Fixed XLlDma_Pause() to loop until all commands are
*                        flushed.
*                     b) Changed XLlDma_BdRingFree() function to clear all
*                        control/status bits (like SOP/EOP) of each BD. Note
*                        the USR0 field is not touched.
*                     c) Changed XLlDma_BdRingToHw() to clear SOP/EOP in each
*                        RX BD before committing it to DMA RX channel. This
*                        change is required to support RX packet spanning on
*                        multiple BDs. See CR#472838 for details
* 1.00b sdm  12/11/08 a) Updated the notes for XLlDma_Pause(), XLlDma_Resume()
*                     b) Changed the XLlDma_BdRingToHw() to stop returning a
*                        failure if SOP/EOP bits are not set for RX BDs
* 1.00b wsy  01/20/09 XLlDma_Pause() polls XLLDMA_IRQ_WRQ_EMPTY_MASK to make
*                     sure Command Queue is empty. This is correct way to pause
*                     gracefully. Unfortunately, this bit is only valid in
*                     HDMA. We will temporarily not poll this bit until either
*                     split the drivers or make SDMA close to HDMA.
*                     CR#504331 addressed this.
* 1.01a sdm  03/09/09 Modified the XLlDma_Pause()and XLlDma_Resume() functions
*                     to wait on the WriteQEmpty bit only when the driver is
*                     used with HDMA
* 1.01a sdm  07/18/09 Moved the declaration of the variable RegValue to the
*                     beginning of functions XLlDma_Pause() and XLlDma_Resume()
*                     to fix compilation errors with new diab compiler
* 2.00a jz   12/04/09  Hal phase 1 support, changed _m to _ from macro API 
* </pre>
******************************************************************************/

/***************************** Include Files *********************************/

#include "xlldma.h"
#include "xenv.h"

/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/


/************************** Variable Definitions *****************************/


/*****************************************************************************/
/**
 * This function initializes a DMA engine.  This function must be called
 * prior to using a DMA engine. Initialization of a engine includes setting
 * up the register base address, setting up the instance data, and ensuring the
 * hardware is in a quiescent state.
 *
 * @param  InstancePtr is a pointer to the DMA engine instance to be worked on.
 * @param  BaseAddress is where the registers for this engine can be found.
 *         If address translation is being used, then this parameter must
 *         reflect the virtual base address.
 * @return None.
 *
 *****************************************************************************/
void XLlDma_Initialize(XLlDma * InstancePtr, u32 BaseAddress)
{
	/* Setup the instance */
	memset(InstancePtr, 0, sizeof(XLlDma));
	InstancePtr->RegBase = BaseAddress;

	/* Initialize the ring structures */
	InstancePtr->TxBdRing.RunState = XST_DMA_SG_IS_STOPPED;
	InstancePtr->TxBdRing.ChanBase = BaseAddress + XLLDMA_TX_OFFSET;
	InstancePtr->TxBdRing.IsRxChannel = 0;
	InstancePtr->RxBdRing.RunState = XST_DMA_SG_IS_STOPPED;
	InstancePtr->RxBdRing.ChanBase = BaseAddress + XLLDMA_RX_OFFSET;
	InstancePtr->RxBdRing.IsRxChannel = 1;

	/* Reset the device and return */
	XLlDma_Reset(InstancePtr);
}

/*****************************************************************************/
/**
* Reset both TX and RX channels of a DMA engine.
*
* Any DMA transaction in progress aborts immediately. The DMA engine is in
* stop state after the reset.
*
* @param  InstancePtr is a pointer to the DMA engine instance to be worked on.
*
* @return None.
*
* @note
*         - If the hardware is not working properly, this function will enter
*           infinite loop and never return.
*         - After the reset, the Normal mode is enabled, and the overflow error
*           for both TX/RX channels are disabled.
*         - After the reset, the DMA engine is no longer in pausing state, if
*           the DMA engine is paused before the reset operation.
*         - After the reset, the coalescing count value and the delay timeout
*           value are both set to 1 for TX and RX channels.
*         - After the reset, all interrupts are disabled.
*
******************************************************************************/
void XLlDma_Reset(XLlDma * InstancePtr)
{
	u32 IrqStatus;
	XLlDma_BdRing *TxRingPtr, *RxRingPtr;

	TxRingPtr = &XLlDma_GetTxRing(InstancePtr);
	RxRingPtr = &XLlDma_GetRxRing(InstancePtr);

	/* Save the locations of current BDs both rings are working on
	 * before the reset so later we can resume the rings smoothly.
	 */
	XLlDma_BdRingSnapShotCurrBd(TxRingPtr);
	XLlDma_BdRingSnapShotCurrBd(RxRingPtr);

	/* Start reset process then wait for completion */
	XLlDma_SetCr(InstancePtr, XLLDMA_DMACR_SW_RESET_MASK);

	/* Loop until the reset is done */
	while ((XLlDma_GetCr(InstancePtr) & XLLDMA_DMACR_SW_RESET_MASK)) {
	}

	/* Disable all interrupts after issue software reset */
	XLlDma_BdRingIntDisable(TxRingPtr, XLLDMA_CR_IRQ_ALL_EN_MASK);
	XLlDma_BdRingIntDisable(RxRingPtr, XLLDMA_CR_IRQ_ALL_EN_MASK);

	/* Clear Interrupt registers of both channels, as the software reset
	 * does not clear any register values. Not doing so will cause
	 * interrupts asserted after the software reset if there is any
	 * interrupt left over before.
	 */
	IrqStatus = XLlDma_BdRingGetIrq(TxRingPtr);
	XLlDma_BdRingAckIrq(TxRingPtr, IrqStatus);
	IrqStatus = XLlDma_BdRingGetIrq(RxRingPtr);
	XLlDma_BdRingAckIrq(RxRingPtr, IrqStatus);

	/* Enable Normal mode, and disable overflow errors for both channels */
	XLlDma_SetCr(InstancePtr, XLLDMA_DMACR_TAIL_PTR_EN_MASK |
		      XLLDMA_DMACR_RX_OVERFLOW_ERR_DIS_MASK |
		      XLLDMA_DMACR_TX_OVERFLOW_ERR_DIS_MASK);

	/* Set TX/RX Channel coalescing setting */
	XLlDma_BdRingSetCoalesce(TxRingPtr, 1, 1);
	XLlDma_BdRingSetCoalesce(RxRingPtr, 1, 1);

	TxRingPtr->RunState = XST_DMA_SG_IS_STOPPED;
	RxRingPtr->RunState = XST_DMA_SG_IS_STOPPED;
}

/*****************************************************************************/
/**
* Pause DMA transactions on both channels. The DMA enters the pausing state
* immediately. So if a DMA transaction is in progress, it will be left
* unfinished and will be continued once the DMA engine is resumed
* (see XLlDma_Resume()).
*
* @param  InstancePtr is a pointer to the DMA engine instance to be worked on.
*
* @return None.
*
* @note
*       - If the hardware is not working properly, this function will enter
*         infinite loop and never return.
*       - After the DMA is paused, DMA channels still could accept more BDs
*         from software (see XLlDma_BdRingToHw()), but new BDs will not be
*         processed until the DMA is resumed (see XLlDma_Resume()).
*       - SDMA core does NOT support Pause function. This function just updates
*         the RunState of Tx and Rx channels when the driver is used with SDMA.
*
*****************************************************************************/
void XLlDma_Pause(XLlDma * InstancePtr)
{
	XLlDma_BdRing *TxRingPtr, *RxRingPtr;
#if XLLDMA_DEVICE == XLLDMA_HDMA
	u32 RegValue;
#endif

	TxRingPtr = &XLlDma_GetTxRing(InstancePtr);
	RxRingPtr = &XLlDma_GetRxRing(InstancePtr);

	/* Do nothing if both channels already stopped */
	if ((TxRingPtr->RunState == XST_DMA_SG_IS_STOPPED) &&
	    (RxRingPtr->RunState == XST_DMA_SG_IS_STOPPED)) {
		return;
	}

	/* Pause and WriteQEmpty bits are valid only in HDMA. Current driver
	 * supports both HDMA and SDMA; XLLDMA_DEVICE constant defines
	 * whether the driver is being used with HDMA or SDMA.
	 */
#if XLLDMA_DEVICE == XLLDMA_HDMA

	/* Enable pause bits for both TX/ RX channels */
	RegValue = XLlDma_GetCr(InstancePtr);
	XLlDma_SetCr(InstancePtr, RegValue | XLLDMA_DMACR_TX_PAUSE_MASK |
		      XLLDMA_DMACR_RX_PAUSE_MASK);

	/* Loop until Write Command Queue of RX channel is empty, which
	 * indicates that all the write data associated with the pending
	 * commands has been flushed.
	 */
	while (!(XLlDma_BdRingGetIrq(RxRingPtr) & XLLDMA_IRQ_WRQ_EMPTY_MASK));
#endif

	TxRingPtr->RunState = XST_DMA_SG_IS_STOPPED;
	RxRingPtr->RunState = XST_DMA_SG_IS_STOPPED;
}

/*****************************************************************************/
/**
* Resume DMA transactions on both channels. Any interrupted DMA transaction
* caused by DMA pause operation (see XLlDma_Pause()) and all committed
* transactions after DMA is paused will be continued upon the return of this
* function.
*
* @param  InstancePtr is a pointer to the DMA engine instance to be worked on.
*
* @return None.
*
* @note   SDMA core does NOT support Resume function. This function just updates
*         the RunState of Tx and Rx channels when the driver is used with SDMA.
*
*****************************************************************************/
void XLlDma_Resume(XLlDma * InstancePtr)
{
	XLlDma_BdRing *TxRingPtr, *RxRingPtr;
#if XLLDMA_DEVICE == XLLDMA_HDMA
	u32 RegValue;
#endif

	TxRingPtr = &XLlDma_GetTxRing(InstancePtr);
	RxRingPtr = &XLlDma_GetRxRing(InstancePtr);

	/* Do nothing if both channels already started */
	if ((TxRingPtr->RunState == XST_DMA_SG_IS_STARTED) &&
	    (RxRingPtr->RunState == XST_DMA_SG_IS_STARTED)) {
		return;
	}

	/* Pause bit is valid only in HDMA. Current driver supports both HDMA
	 * and SDMA; XLLDMA_DEVICE constant defines whether the driver is
	 * being used with HDMA or SDMA.
	 */
#if XLLDMA_DEVICE == XLLDMA_HDMA

	/* Clear pause bits for both TX/ RX channels */
	RegValue = XLlDma_GetCr(InstancePtr);
	XLlDma_SetCr(InstancePtr, RegValue & ~(XLLDMA_DMACR_TX_PAUSE_MASK |
						XLLDMA_DMACR_RX_PAUSE_MASK));
#endif
	TxRingPtr->RunState = XST_DMA_SG_IS_STARTED;
	RxRingPtr->RunState = XST_DMA_SG_IS_STARTED;
}
