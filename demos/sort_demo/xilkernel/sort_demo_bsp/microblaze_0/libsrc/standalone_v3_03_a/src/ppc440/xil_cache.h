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
* @file xil_cache.h
*
* This header file contains cache related driver functions (or
* macros) that can be used to access the device.  The user should refer to the
* hardware device specification for more details of the device operation.
* The functions in this header file can be used across all Xilinx supported
* processors. For CPU specific cache related API, please use xil_mach_cache.h.
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

#ifndef XIL_CACHE_H
#define XIL_CACHE_H

#if defined XENV_VXWORKS
/* VxWorks environment */
#include "xil_cache_vxworks.h"

#elif defined XENV_LINUX
/* Linux environment */
#include "xil_cache_linux"

#else
/* standalone environment */

#include "xil_types.h"

#ifdef __cplusplus
extern "C" {
#endif

extern void Xil_DCacheDisable(void);
extern void Xil_DCacheInvalidate(void);
extern void Xil_DCacheInvalidateRange(u32 Addr, unsigned Len);
extern void Xil_DCacheFlushRange(u32 Addr, unsigned Len);
extern void Xil_DCacheEnable(void);
extern void Xil_DCacheFlush(void);

extern void Xil_ICacheDisable(void);
extern void Xil_ICacheInvalidateRange(u32 Addr, unsigned Len);
extern void Xil_ICacheInvalidate(void);
extern void Xil_ICacheEnable(void);


extern void Xil_CacheWriteCCR0(u32 Val);
extern void Xil_DCacheEnableRegion(u32 Regions);
extern void Xil_ICacheEnableRegion(u32 Regions);


#ifdef __cplusplus
}
#endif

#endif

#endif
