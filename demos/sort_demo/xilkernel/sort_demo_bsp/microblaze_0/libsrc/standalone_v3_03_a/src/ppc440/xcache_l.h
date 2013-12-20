/*-----------------------------------------------------------------------------
//     $Date: 2011/05/17 04:37:51 $
//     $RCSfile: xcache_l.h,v $
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
//---------------------------------------------------------------------------
// Design Notes: 
//  - DisableDCache makes assumptions about tlb entry mappings.
//  - DisableICache makes assumptions about tlb entry mappings.
//  - each bit in the regions variable stands for 256MB of memory:
//      regions    --> cached address range
//      -------------|--------------------------------------------------
//      0x4000_0000  |               
//      0x8000_0000  | [0, 0x0FFF_FFFF]
//      0xC000_0000  |               
//                   | 
//      0x0000_0001  |                         
//      0x0000_0002  | [0xF000_0000, 0xFFFF_FFFF]
//      0x0000_0003  |                         
//                   |                         
//      0x4000_0001  | 
//      0x4000_0002  | 
//      0x4000_0003  | 
//      0x8000_0001  | 
//      0x8000_0002  | [0, 0x0FFF_FFFF],[0xF000_0000, 0xFFFF_FFFF]
//      0x8000_0003  |                                        
//      0xC000_0001  |                                        
//      0xC000_0002  | 
//      0xC000_0003  | 
//    
//---------------------------------------------------------------------------*/

#ifndef CACHE_H
#define CACHE_H

#ifdef PPC440_CHECK_PPC405COMPATIBILITY
#warning XCache_EnableDCache(), XCache_DisableDCache(), XCache_EnableDCache(), 
#warning XCache_DisableDCache() for the PPC440 is different from that for the PPC405.
#endif

#ifdef __cplusplus
extern "C" {
#endif

void XCache_WriteCCR0(unsigned int val);

void XCache_EnableDCache(unsigned int regions);
void XCache_DisableDCache(void);
void XCache_FlushDCacheLine(unsigned int adr);
void XCache_InvalidateDCacheLine(unsigned int adr); 
void XCache_StoreDCacheLine(unsigned int adr);
void XCache_InvalidateDCacheRange(unsigned int adr, unsigned len);
void XCache_FlushDCacheRange(unsigned int adr, unsigned len);

void XCache_EnableICache(unsigned int regions);
void XCache_DisableICache(void);
void XCache_InvalidateICache(void);
void XCache_InvalidateICacheLine(unsigned int adr);
void XCache_TouchICacheBlock(unsigned int adr);


#ifdef __cplusplus
}
#endif

#endif
