/*-----------------------------------------------------------------------------
//     $Date: 2011/05/17 04:37:54 $
//     $RCSfile: xtime_l.h,v $
//-----------------------------------------------------------------------------
//
// Copyright (c) 2004 Xilinx, Inc.  All rights reserved. 
// 
// Xilinx, Inc. 
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
// COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS 
// ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
// STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
// IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
// FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION. 
// XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
// THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
// ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
// FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
// AND FITNESS FOR A PARTICULAR PURPOSE.
//
//---------------------------------------------------------------------------*/

#ifndef XTIME_H
#define XTIME_H

#ifdef PPC440_CHECK_PPC405COMPATIBILITY
#warning The Programmable Interval Timer (PIT) is renamed the Decrementer (DEC) in the PPC440.
#warning DEC functionality and API remains the same as that for the PIT.
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned long long XTime;

void XTime_SetTime(XTime Xtime);

void XTime_GetTime(XTime *Xtime);

void XTime_TSRClearStatusBits(unsigned long Bitmask);

void XTime_DECSetInterval(unsigned long Interval);

void XTime_DECEnableInterrupt(void);

void XTime_DECDisableInterrupt(void);

void XTime_DECEnableAutoReload(void);

void XTime_DECDisableAutoReload(void);

void XTime_DECClearInterrupt(void);

void XTime_FITSetPeriod(unsigned long Period);

void XTime_FITEnableInterrupt(void);

void XTime_FITDisableInterrupt(void);

void XTime_FITClearInterrupt(void);

void XTime_WDTSetPeriod(unsigned long Period);

void XTime_WDTEnableInterrupt(void);

void XTime_WDTDisableInterrupt(void);

void XTime_WDTClearInterrupt(void);

void XTime_WDTClearResetStatus(void);

void XTime_WDTEnableNextWatchdog(void);

void XTime_WDTResetControl(unsigned long ControlVal);


#ifdef __cplusplus
}
#endif

#endif

