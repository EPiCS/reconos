/******************************************************************************
*
* (c) Copyright 2009 Xilinx, Inc. All rights reserved.
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
* @file xil_exception.c
*
* This file contains implementation of exception related driver functions.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00  hbm  07/28/09 Initial release
*
* </pre>
*
* @note
*
* None.
*
******************************************************************************/


/***************************** Include Files ********************************/

#include "xil_types.h"
#include "xil_exception.h"
#include "xpseudo_asm.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

extern void * _vectorbase(void);

typedef struct
{
        Xil_ExceptionHandler Handler;
        void *Data;
        void *ReadOnlySDA;
        void *ReadWriteSDA;
} Xil_ExceptionVectorTableEntry;

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Function Prototypes *****************************/

/************************** Variable Definitions *****************************/

/*
 * Exception vector table to store handlers for each exception vector.
 */
extern Xil_ExceptionVectorTableEntry XExc_VectorTable[XIL_EXCEPTION_ID_LAST + 1];

/*****************************************************************************/

/****************************************************************************/
/**
*
* This function is a stub handler that is the default handler that gets called
* if the application has not setup a handler for a specific  exception. The 
* function interface has to match the interface specified for a handler even 
* though none of the arguments are used.
*
* @param    data is unused by this function.
*
* @return
*
* None.
*
* @note
*
* None.
*
*****************************************************************************/
static void Xil_ExceptionNullHandler(void *Data)
{
}

/****************************************************************************/
/**
*
* Initialize exception handling for the PowerPC. The exception vector table
* is setup with the stub handler for all exceptions.
*
* @param    None.
*
* @return   None.
*
* @note     
*
* None.
*
*****************************************************************************/
void Xil_ExceptionInit(void)
{
	unsigned short Index;
	void (*Vectorbase)() = (void (*)()) _vectorbase;
	/*
	 * Store the offset of the beginning of the exception handling code
	 * (xvectors.S) in the IVPR register (Interrupt Vector Prefix Register).
	 * Also uses inline assembly defined in "xpseudo_asm.h".
	 */
	mtivpr(Vectorbase);

	/* 
	 * Initialize interrupt vector offset registers to vectorbase + 0x10,
	 * 0x20, ... 0xf0. Each offset is 16 bytes apart.
	 */
	mtivor0(Vectorbase);
	mtivor1(Vectorbase + 0x10);
	mtivor2(Vectorbase + 0x20);
	mtivor3(Vectorbase + 0x30);
	mtivor4(Vectorbase + 0x40);
	mtivor5(Vectorbase + 0x50);
	mtivor6(Vectorbase + 0x60);
	mtivor7(Vectorbase + 0x70);
	mtivor8(Vectorbase + 0x80);
	mtivor9(Vectorbase + 0x90);
	mtivor10(Vectorbase + 0xa0);
	mtivor11(Vectorbase + 0xb0);
	mtivor12(Vectorbase + 0xc0);
	mtivor13(Vectorbase + 0xd0);
	mtivor14(Vectorbase + 0xe0);
	mtivor15(Vectorbase + 0xf0);

	/*
	 * Initialize the vector table. Register the stub handler for each
	 * exception initialize the IVOR registers
	 */
	for (Index = XIL_EXCEPTION_ID_FIRST;
	    Index <= XIL_EXCEPTION_ID_LAST;
	    Index++) {
		Xil_ExceptionRegisterHandler(Index,
					     Xil_ExceptionNullHandler,
					     NULL);
	}
}

/*****************************************************************************/
/**
 *
 * Makes the connection between the Id of the exception source and the
 * associated handler that is to run when the exception is recognized. The
 * argument provided in this call as the DataPtr is used as the argument
 * for the handler when it is called.
 *
 * @param    Id contains the ID of the exception source and should 
 *           be in the range of 0 to XIL_EXCEPTION_LAST. See 
 *	     xil_exception.h for further information.
 * @param    Handler to the handler for that exception.
 * @param    Data is a reference to data that will be passed to the handler
 *           when it gets called.
 *
 * @return   None.
 *
 * @note
 *
 * None.
 *
 ****************************************************************************/
void Xil_ExceptionRegisterHandler(u32 Id,
				  Xil_ExceptionHandler Handler,
				  void *Data)
{
	XExc_VectorTable[Id].Handler = Handler;
	XExc_VectorTable[Id].Data = Data;
	XExc_VectorTable[Id].ReadOnlySDA = (void *)mfgpr(XREG_GPR2);
	XExc_VectorTable[Id].ReadWriteSDA = (void *)mfgpr(XREG_GPR13);
}

/*****************************************************************************/
/**
 *
 * Removes the handler for a specific exception Id. The stub handler is then
 * registered for this exception Id.
 *
 * @param    Id contains the ID of the exception source and should 
 *           be in the range of 0 to XIL_EXCEPTION_LAST. See
 *	     xil_exception.h for further information.
 *
 * @return   None.
 *
 * @note
 *
 * None.
 *
 ****************************************************************************/
void Xil_ExceptionRemoveHandler(u32 Id)
{
	Xil_ExceptionRegisterHandler(Id,
				     Xil_ExceptionNullHandler,
				     NULL);
}
