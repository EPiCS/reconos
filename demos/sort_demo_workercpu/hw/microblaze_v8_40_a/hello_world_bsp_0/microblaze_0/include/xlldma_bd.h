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
 * @file xlldma_bd.h
 *
 * This header provides operations to manage buffer descriptors (BD) in support
 * of Local-Link scatter-gather DMA (see xlldma.h).
 *
 * The API exported by this header defines abstracted macros that allow the
 * application to read/write specific BD fields.
 *
 * <b>Buffer Descriptors</b>
 *
 * A buffer descriptor defines a DMA transaction (see "Transaction"
 * section in xlldma.h). The macros defined by this header file allow access
 * to most fields within a BD to tailor a DMA transaction according to
 * application and hardware requirements.  See the hardware IP DMA spec for
 * more information on BD fields and how they affect transfers.
 *
 * The XLlDma_Bd structure defines a BD. The organization of this structure is
 * driven mainly by the hardware for use in scatter-gather DMA transfers.
 *
 * <b>Accessor Macros</b>
 *
 * Most of the BD attributes can be accessed through macro functions defined
 * here in this API. Words such as XLLDMA_BD_USR1_OFFSET (see xlldma_hw.h)
 * should be accessed using XLlDma_BdRead() and XLlDma_BdWrite() as defined
 * in xlldma_hw.h. The USR words are implementation dependent. For example,
 * they may implement checksum offloading fields for Ethernet devices. Accessor
 * macros may be defined in the device specific API to get at this data.
 *
 * <b>Performance</b>
 *
 * BDs are typically in a non-cached memory space. Limiting I/O to BDs can
 * improve overall performance of the DMA channel.
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- ---- -------- -------------------------------------------------------
 * 1.00a xd   12/21/06 First release
 * 1.00b xd   10/21/08 Updated comments for XLlDma_BdSetLength() and
 *                     XLlDma_BdGetLength().
* 2.00a jz   12/04/09  Hal phase 1 support, changed _m to _ from macro API 
 * </pre>
 *
 *****************************************************************************/

#ifndef XLLDMA_BD_H		/* prevent circular inclusions */
#define XLLDMA_BD_H		/* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xenv.h"
#include "xlldma_hw.h"

/************************** Constant Definitions *****************************/

/**************************** Type Definitions *******************************/

/**
 * The XLlDma_Bd is the type for buffer descriptors (BDs).
 */
typedef u32 XLlDma_Bd[XLLDMA_BD_NUM_WORDS];


/***************** Macros (Inline Functions) Definitions *********************/

/*****************************************************************************/
/**
*
* Read the given Buffer Descriptor word.
*
* @param    BaseAddress is the base address of the BD to read
* @param    Offset is the word offset to be read
*
* @return   The 32-bit value of the field
*
* @note
* C-style signature:
*    u32 XLlDma_BdRead(u32 BaseAddress, u32 Offset)
*
******************************************************************************/
#define XLlDma_BdRead(BaseAddress, Offset)				\
	(*(u32*)((u32)(BaseAddress) + (u32)(Offset)))


/*****************************************************************************/
/**
*
* Write the given Buffer Descriptor word.
*
* @param    BaseAddress is the base address of the BD to write
* @param    Offset is the word offset to be written
* @param    Data is the 32-bit value to write to the field
*
* @return   None.
*
* @note
* C-style signature:
*    void XLlDma_BdWrite(u32 BaseAddress, u32 RegOffset, u32 Data)
*
******************************************************************************/
#define XLlDma_BdWrite(BaseAddress, Offset, Data)			\
	(*(u32*)((u32)(BaseAddress) + (u32)(Offset)) = (Data))


/*****************************************************************************/
/**
 * Zero out all BD fields
 *
 * @param  BdPtr is the BD to operate on
 *
 * @return Nothing
 *
 * @note
 * C-style signature:
 *    void XLlDma_BdClear(XLlDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XLlDma_BdClear(BdPtr)                    \
	memset((BdPtr), 0, sizeof(XLlDma_Bd))


/*****************************************************************************/
/**
 * Set the BD's STS/CTRL field. The word containing STS/CTRL also contains the
 * USR0 field. USR0 will not be modified. This operation requires a read-
 * modify-write operation. If it is wished to set both STS/CTRL and USR0 with
 * a single write operation, then use XLlDma_BdWrite(BdPtr,
 * XLLDMA_BD_STSCTRL_USR0_OFFSET, Data).
 *
 * @param  BdPtr is the BD to operate on
 * @param  Data is the value to write to STS/CTRL. Or 0 or more
 *         XLLDMA_BD_STSCTRL_*** values defined in xlldma_hw.h to create a
 *         valid value for this parameter
 *
 * @note
 * C-style signature:
 *    u32 XLlDma_BdSetStsCtrl(XLlDma_Bd* BdPtr, u32 Data)
 *
 *****************************************************************************/
#define XLlDma_BdSetStsCtrl(BdPtr, Data)                                   \
	XLlDma_BdWrite((BdPtr), XLLDMA_BD_STSCTRL_USR0_OFFSET,             \
		(XLlDma_BdRead((BdPtr), XLLDMA_BD_STSCTRL_USR0_OFFSET)     \
		& XLLDMA_BD_STSCTRL_USR0_MASK) |			    \
		((Data) & XLLDMA_BD_STSCTRL_MASK))


/*****************************************************************************/
/**
 * Retrieve the word containing the BD's STS/CTRL field. This word also
 * contains the USR0 field.
 *
 * @param  BdPtr is the BD to operate on
 *
 * @return Word at offset XLLDMA_BD_DMASR_OFFSET. Use XLLDMA_BD_STSCTRL_***
 *         values defined in xlldma_hw.h to interpret this returned value
 *
 * @note
 * C-style signature:
 *    u32 XLlDma_BdGetStsCtrl(XLlDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XLlDma_BdGetStsCtrl(BdPtr)              \
	XLlDma_BdRead((BdPtr), XLLDMA_BD_STSCTRL_USR0_OFFSET)


/*****************************************************************************/
/**
 * Set the length field for the given BD. The length must be set each time
 * before a BD is submitted to hardware.
 *
 * For TX channels, the value passed in should be the number of bytes to
 * transmit from the TX buffer associated with the given BD.
 *
 * For RX channels, the value passed in should be the size of the RX buffer
 * associated with the given BD in bytes. This is to notify the RX channel
 * the capability of the RX buffer to avoid buffer overflow. The real length of
 * the received data could be equal to or smaller than this value. The real
 * RX length in bytes will be updated into a USER field in the BD chosen by the
 * User IP cores, like Xilinx LLTEMAC, after the data is received and stored
 * into the RX buffer. Note that different User IP cores could choose different
 * USER fields to store the length of the received data. See the specification
 * of the User IP core currently used with the LLDMA for details.
 *
 * @param  BdPtr is the BD to operate on.
 * @param  LenBytes is the number of bytes to transfer for TX channel or the
 *         size of receive buffer in bytes for RX channel.
 *
 * @note
 * C-style signature:
 *    void XLlDma_BdSetLength(XLlDma_Bd* BdPtr, u32 LenBytes)
 *
 *****************************************************************************/
#define XLlDma_BdSetLength(BdPtr, LenBytes)                            \
	XLlDma_BdWrite((BdPtr), XLLDMA_BD_BUFL_OFFSET, (LenBytes))


/*****************************************************************************/
/**
 * Retrieve the length field value from the given BD.  The returned value is
 * the same as what was written with XLlDma_BdSetLength(). Note that in RX
 * channel case this value does not reflect the real length of received data.
 * See XLlDma_BdSetLength() for more details.
 *
 * @param  BdPtr is the BD to operate on.
 *
 * @return The BD length field value set by XLlDma_BdSetLength().
 *
 * @note
 * C-style signature:
 *    u32 XLlDma_BdGetLength(XLlDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XLlDma_BdGetLength(BdPtr)                      \
	XLlDma_BdRead((BdPtr), XLLDMA_BD_BUFL_OFFSET)


/*****************************************************************************/
/**
 * Set the ID field of the given BD. The ID is an arbitrary piece of data the
 * application can associate with a specific BD.
 *
 * @param  BdPtr is the BD to operate on
 * @param  Id is a 32 bit quantity to set in the BD
 *
 * @note
 * C-style signature:
 *    void XLlDma_BdSetId(XLlDma_Bd* BdPtr, void Id)
 *
 *****************************************************************************/
#define XLlDma_BdSetId(BdPtr, Id)                                      \
	(XLlDma_BdWrite((BdPtr), XLLDMA_BD_ID_OFFSET, (u32)(Id)))


/*****************************************************************************/
/**
 * Retrieve the ID field of the given BD previously set with XLlDma_BdSetId.
 *
 * @param  BdPtr is the BD to operate on
 *
 * @note
 * C-style signature:
 *    u32 XLlDma_BdGetId(XLlDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XLlDma_BdGetId(BdPtr) (XLlDma_BdRead((BdPtr), XLLDMA_BD_ID_OFFSET))


/*****************************************************************************/
/**
 * Set the BD's buffer address.
 *
 * @param  BdPtr is the BD to operate on
 * @param  Addr is the address to set
 *
 * @note
 * C-style signature:
 *    void XLlDma_BdSetBufAddr(XLlDma_Bd* BdPtr, u32 Addr)
 *
 *****************************************************************************/
#define XLlDma_BdSetBufAddr(BdPtr, Addr)                               \
	(XLlDma_BdWrite((BdPtr), XLLDMA_BD_BUFA_OFFSET, (u32)(Addr)))


/*****************************************************************************/
/**
 * Get the BD's buffer address
 *
 * @param  BdPtr is the BD to operate on
 *
 * @note
 * C-style signature:
 *    u32 XLlDma_BdGetBufAddrLow(XLlDma_Bd* BdPtr)
 *
 *****************************************************************************/
#define XLlDma_BdGetBufAddr(BdPtr)                     \
	(XLlDma_BdRead((BdPtr), XLLDMA_BD_BUFA_OFFSET))


/************************** Function Prototypes ******************************/

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
