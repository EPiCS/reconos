/*-----------------------------------------------------------------------------
  
      XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"
      SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR
      XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION
      AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION
      OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS
      IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,
      AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE
      FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY
      WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE
      IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
      REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF
      INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
      FOR A PARTICULAR PURPOSE.
      
      (c) Copyright 2006 Xilinx, Inc.
      All rights reserved.

-----------------------------------------------------------------------------*/
#include "xcache_l.h"
#include "xpseudo_asm.h"
#include "xreg440.h"

#define DCACHE_SIZE     0x8000 // 32kB

/****************************************************************************
*
* Write to the Core-Configuration Register (CCR0)
*
* @param    Value to be written to CCR0.  The bit fields are defined 
*           in xreg440.h
*
* @return   None.
*
* @note     
*
* None.
*
****************************************************************************/

/* special registers */
void XCache_WriteCCR0(unsigned int val)
{
  sync;
  isync;
  mtspr(XREG_SPR_CCR0, val);
  sync;
  isync;
}


/****************************************************************************
*
* Enable the data cache. 
*
* @param    Memory regions to be marked as cachable.  Each pair of adjacent
*           bits in the regions variable stands for 256MB of memory. Setting
*           either bit in the pair will enable caching for the corresponding 
*           region
*
*           regions    --> cached address range
*           -------------|--------------------------------------------------
*           0x4000_0000  |               
*           0x8000_0000  | [0, 0x0FFF_FFFF]
*           0xC000_0000  |               
*                        | 
*           0x0000_0001  |                         
*           0x0000_0002  | [0xF000_0000, 0xFFFF_FFFF]
*           0x0000_0003  |                         
*                        |                         
*           0x4000_0001  | 
*           0x4000_0002  | 
*           0x4000_0003  | 
*           0x8000_0001  | 
*           0x8000_0002  | [0, 0x0FFF_FFFF],[0xF000_0000, 0xFFFF_FFFF]
*           0x8000_0003  |                                        
*           0xC000_0001  |                                        
*           0xC000_0002  | 
*           0xC000_0003  | 
*    
* @return   None.
*
* @note     
*
*
****************************************************************************/

void XCache_EnableDCache(unsigned int regions)
{
  int i;
  int index;
  int tlbword;

  XCache_DisableDCache(); 
  /* at this point the data cache is disabled and invalidated */
  mtspr(XREG_SPR_DVLIM,0); /* set DVLIM to 0 */
  mtspr(XREG_SPR_DNV0,0);  /* Set DNV0-3 */
  mtspr(XREG_SPR_DNV1,0);
  mtspr(XREG_SPR_DNV2,0);
  mtspr(XREG_SPR_DNV3,0);
  mtspr(XREG_SPR_DTV0,0);  /* Set DTV0-3 */
  mtspr(XREG_SPR_DTV1,0);
  mtspr(XREG_SPR_DTV2,0);
  mtspr(XREG_SPR_DTV3,0);

  for(i=15; i>=0 && regions !=0; i--) {   /* all TLB entries in 4GB of memory */
    if((regions & 0x3) > 0) {             /* either bit in this region is set */
      index = i+i+1;                      /* data page indices = 1,3,5,...,15 */
      tlbword = tlbre(index, 2);
      sync;
      /* unset cache inhibit bit, leaves write-through bit as it is */
      tlbwe(tlbword & 0xFFFFFBFF, index, 2);
      isync;
    }
    regions = regions >> 2;                  /* check next region */
  }
}

/****************************************************************************
*
* Disable the data cache. 
*
* @param    None
*    
* @return   None.
*
* @note     
*
*
****************************************************************************/
void XCache_DisableDCache(void)
{
  unsigned int tlbword;
  unsigned int i;
  unsigned int tlbIndex;
  unsigned int address;
  unsigned int index;
  unsigned int pagesCacheable = 0;

  for(i=0; i<16; i++)             /* all TLB entries in 4GB of memory */
  {
    tlbIndex = i+i+1;             /* data page indices = 1,3,5...,15 */
    tlbword = tlbre(tlbIndex, 2);
    sync;
    if((tlbword & 0x00000400) != 0x400)    /* if cache inhibit bit is not set */
    {  
      if((tlbword & 0x00000800) != 0x800){ /* if not write through */
	pagesCacheable++;
      }
      tlbwe((tlbword & ~0x00000800) | 0x00000400, tlbIndex, 2);  /* unset write-through bit and set cache inhibit bit */
      isync;
    }
  }
  /* flush dirty data cache lines */
  if(pagesCacheable)
  {
    for(index=0; index<DCACHE_SIZE; index+=32) /* per cache line */
      {
	sync;
	dcread(index);
	isync;                   /* ensure dcread finishes before reading tag */
	address = (mfspr(XREG_SPR_DCDBTRH));  /* read tag's real address */
	if( (address | 0xffffff7f) == 0xffffffff ) {  /* if line is valid */
          dcbf((address & 0xFFFFFF00)|(index & 0xff));  /* flush if dirty */
	  sync;                        /* ensure dcbf finishes */
	}
      }
  }
  
  /* data cache is effectively flushed at this point */
  sync; 
  dccci(0);  /* invalidate data cache (clear all write 
              * through entries remaining.
	      * (0) = dummy argument--not used by the PPC440
	      * but needed for backward compatibility */
  isync;

}

/****************************************************************************
*
* Flush a data cache line. If the byte specified by the address (adr) 
* is cached by the data cache, the cacheline containing that byte is 
* invalidated.  If the cacheline is modified (dirty), the entire 
* contents of the cacheline are written to system memory before the 
* line is invalidated.
*
* @param    Address to be flushed
*    
* @return   None.
*
* @note     
*
*
****************************************************************************/

void XCache_FlushDCacheLine(unsigned int adr)
{
  dcbf(adr);
  sync;
  isync;
}

/****************************************************************************
*
* Invalidate a data cache line. If the byte specified by the address (adr) 
* is cached by the data cache, the cacheline containing that byte is 
* invalidated.  If the cacheline is modified (dirty), the modified contents  
* are lost and are NOT written to system memory before the line is 
* invalidated.
*
* @param    Address to be flushed
*    
* @return   None.
*
* @note     
*
*
****************************************************************************/

void XCache_InvalidateDCacheLine(unsigned int adr)
{
  dcbi(adr);
  sync;
  isync;
}

/****************************************************************************
*
* Store a data cache line. If the byte specified by the address (adr) 
* is cached by the data cache and the cacheline is modified (dirty), 
* the entire contents of the cacheline are written to system memory.  
* After the store completes, the cacheline is marked as unmodified 
* (not dirty).
*
* @param    Address to be stored
*    
* @return   None.
*
* @note     
*
*
****************************************************************************/

void XCache_StoreDCacheLine(unsigned int adr)
{
  dcbst(adr);
  sync;
  isync;
}

/****************************************************************************
* Flush the data cache for the given address range.
* If the bytes specified by the address (adr) are cached by the data cache, 
* the cacheline containing that byte is invalidated.  If the cacheline 
* is modified (dirty), the written to system memory first before the 
* before the line is invalidated.
*
* @param    Start address of range to be flushed
* @param    Length of range to be flushed in bytes
*    
* @return   None.
*
* @note     
*
* Processor must be in real mode.
****************************************************************************/
void XCache_FlushDCacheRange(unsigned int adr, unsigned len)
{
  const unsigned cacheline = 32;
  unsigned int end;

  if (len != 0)
  {
    /* Back the starting address up to the start of a cache line
     * perform cache operations until adr+len
     */
    end = adr + len;
    adr = adr & ~(cacheline - 1);

    while (adr < end)
    {
      XCache_FlushDCacheLine(adr);
      adr += cacheline;
    }
  }
}

/****************************************************************************
*
* Invalidate the data cache for the given address range.
* If the bytes specified by the address (adr) are cached by the data cache, 
* the cacheline containing that byte is invalidated.  If the cacheline 
* is modified (dirty), the modified contents are lost and are NOT 
* written to system memory before the line is invalidated.
*
* @param    Start address of ragne to be invalidated
* @param    Length of range to be invalidated in bytes
*    
* @return   None.
*
* @note     
*
* Processor must be in real mode.
****************************************************************************/
void XCache_InvalidateDCacheRange(unsigned int adr, unsigned len)
{
  const unsigned cacheline = 32;
  unsigned int end;

  if (len != 0)
  {
    /* Back the starting address up to the start of a cache line
     * perform cache operations until adr+len
     */
    end = adr + len;
    adr = adr & ~(cacheline - 1);

    while (adr < end)
    {
      XCache_InvalidateDCacheLine(adr);
      adr += cacheline;
    }
  }
}

/****************************************************************************
*
* Enable the instruction cache. 
*
* @param    Memory regions to be marked as cachable. Each pair of adjacent
*           bits in the regions variable stands for 256MB of memory. Setting
*           either bit in the pair will enable caching for the corresponding 
*           region
*
*           regions    --> cached address range
*           -------------|--------------------------------------------------
*           0x4000_0000  |               
*           0x8000_0000  | [0, 0x0FFF_FFFF]
*           0xC000_0000  |               
*                        | 
*           0x0000_0001  |                         
*           0x0000_0002  | [0xF000_0000, 0xFFFF_FFFF]
*           0x0000_0003  |                         
*                        |                         
*           0x4000_0001  | 
*           0x4000_0002  | 
*           0x4000_0003  | 
*           0x8000_0001  | 
*           0x8000_0002  | [0, 0x0FFF_FFFF],[0xF000_0000, 0xFFFF_FFFF]
*           0x8000_0003  |                                        
*           0xC000_0001  |                                        
*           0xC000_0002  | 
*           0xC000_0003  | 
*    
* @return   None.
*
* @note     
*
*
****************************************************************************/

void XCache_EnableICache(unsigned int regions)
{
  int i;
  int index;
  int tlbword;

  XCache_DisableICache();
  /* at this point the instruction cache is disabled and invalidated */
  mtspr(XREG_SPR_IVLIM,0); /* set IVLIM to 0 */
  mtspr(XREG_SPR_INV0,0);  /* Set INV0-3 */
  mtspr(XREG_SPR_INV1,0);
  mtspr(XREG_SPR_INV2,0);
  mtspr(XREG_SPR_INV3,0);
  mtspr(XREG_SPR_ITV0,0);  /* Set ITV0-3 */
  mtspr(XREG_SPR_ITV1,0);
  mtspr(XREG_SPR_ITV2,0);
  mtspr(XREG_SPR_ITV3,0);

  for(i=15; i>=0 && regions != 0; i--) {  /* all TLB entries in 4GB of memory */
    if((regions & 0x3) > 0) {            /* either bit in this region is set */
      index = i+i;                /* instruction entry indices = 0,2,4,...,14 */
      tlbword = tlbre(index, 2);
      sync;
      /* unset cache inhibit bit, leave write-through bit as it is */
      tlbwe(tlbword & 0xFFFFFBFF, index, 2);
      isync;
    }
    regions = regions >> 2;                  /* check next region */
  }
}

/****************************************************************************
*
* Disable the instruction cache. 
*
* @param    None
*    
* @return   None.
*
* @note     
*
*
****************************************************************************/

void XCache_DisableICache(void)
{
  int i;
  int twoI;
  int tlbword;
  
  for(i=0; i<16; i++) {        /* all TLB entries in 4GB of memory */
    twoI = i+i;                /* instruction entries = 0, 2,..., 14 */
    tlbword = tlbre(twoI, 2);
    sync;
    tlbwe(tlbword | 0x0000400, twoI, 2);  /* set cache inhibit bit */
    isync;
  }
  XCache_InvalidateICache();
}

/****************************************************************************
*
* Invalidate the entire instruction cache. 
*
* @param    None
*    
* @return   None.
*
* @note     
*
*
****************************************************************************/

void XCache_InvalidateICache(void)
{
  sync;
  iccci;
  isync;
}

/****************************************************************************
*
* Invalidate an instruction cache line.  If the instruction specified by the
* parameter adr is cached by the instruction cache, the cacheline containing
* that instruction is invalidated.
*
* @param    None
*    
* @return   None.
*
* @note     
*
*
****************************************************************************/

void XCache_InvalidateICacheLine(unsigned int adr)
{
  unsigned int oldMSR = mfmsr();
  /* copy IS bit over DS bit */
  sync;
  mtmsr( (oldMSR & 0xffffffef) | ((oldMSR >> 1) & 0x00000010));
  icbi(adr);
  mtmsr(oldMSR); /* restore MSR */
  isync;
}

/****************************************************************************
*
* Fetches an instruction cache block(line) into the cache, if the input
* address points to a cacheable instruction region.
*
* @param    None
*    
* @return   None.
*
* @note     
*
*
****************************************************************************/

void XCache_TouchICacheBlock(unsigned int adr)
{
  unsigned int oldMSR = mfmsr();
  /* copy IS bit over DS bit */
  sync;
  mtmsr( (oldMSR & 0xffffffef) | ((oldMSR >> 1) & 0x00000010));
  icbt(adr);
  mtmsr(oldMSR); /* restore MSR */
  isync;
}
