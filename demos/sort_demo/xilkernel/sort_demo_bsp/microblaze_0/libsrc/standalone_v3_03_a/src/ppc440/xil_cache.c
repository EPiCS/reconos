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
* @file xil_cache.c
*
* This contains implementation of cache related driver functions.
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

#include "xil_cache.h"
#include "xpseudo_asm.h"
#include "xreg440.h"
#include "xparameters.h"

#define DCACHE_SIZE     0x8000 // 32kB

/****************************************************************************/
/**
*
* Write to the Core-Configuration Register (CCR0)
*
* @param    Val is the value to be written to CCR0. The bit fields are defined
*           in xreg440.h
*
* @return   None.
*
* @note
*
* None.
*
****************************************************************************/
void Xil_CacheWriteCCR0(u32 Val)
{
	sync;
	isync;
	mtspr(XREG_SPR_CCR0, Val);
	sync;
	isync;
}


/****************************************************************************/
/**
*
* Enable the data cache regions.
*
* @param    Regions of memory to be marked as cachable.  Each pair of adjacent
*           bits in the regions variable stands for 256MB of memory. Setting
*           either bit in the pair will enable caching for the corresponding
*           region.
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
* @note     This function is specific to PPC440.
*
*
****************************************************************************/
void Xil_DCacheEnableRegion(u32 Regions)
{
	int I;
	int Index;
	int TlbWord;

	Xil_DCacheDisable();
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

	for(I = 15; I >= 0 && Regions != 0; I--) {
		/* all TLB entries in 4GB of memory */
		if((Regions & 0x3) > 0) {
			/* either bit in this region is set */
			Index = I + I + 1;
			/* data page indices = 1,3,5,...,15 */
			TlbWord = tlbre(Index, 2);
			sync;
			/* unset cache inhibit bit, leaves write-through bit
			 * as it is
			 */
			tlbwe(TlbWord & 0xFFFFFBFF, Index, 2);
			isync;
		}
		/* check next region */
		Regions = Regions >> 2;
	}
}

/****************************************************************************/
/**
*
* Enable the data cache.
*
* @return   None.
*
* @note
*
* This function uses a 0x80000001 for the mask. Each pair of adjacent bits
* in the mask marks 256MB as cacheable.
* The CPU driver generates a mask (XPAR_CACHEABLE_REGION_MASK) for cacheable
* regions. This mask includes memories with size less than 256MB. Using this
* mask for enabling caches could cause a problem if there are any memory mapped
* peripherals around these smaller memory regions.
*
****************************************************************************/
void Xil_DCacheEnable()
{
	Xil_DCacheEnableRegion(0x80000001);
}


/****************************************************************************/
/**
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
void Xil_DCacheDisable(void)
{
	unsigned int TlbWord;
	unsigned int I;
	unsigned int TlbIndex;
	unsigned int Address;
	unsigned int Index;
	unsigned int PagesCacheable = 0;

	for(I = 0; I < 16; I++) {
		/* all TLB entries in 4GB of memory */
		TlbIndex = I + I + 1; /* data page indices = 1,3,5...,15 */
		TlbWord = tlbre(TlbIndex, 2);
		sync;
		if((TlbWord & 0x00000400) != 0x400) {
			/* if cache inhibit bit is not set */
			if((TlbWord & 0x00000800) != 0x800) {
				/* if not write through */
				PagesCacheable++;
			}
			/* unset write-through bit and set cache inhibit bit */
			tlbwe((TlbWord & ~0x00000800) | 0x00000400, TlbIndex, 2);

			isync;
		}
	}

	/* flush dirty data cache lines */
	if (PagesCacheable) {
		for(Index = 0; Index < DCACHE_SIZE; Index += 32) {
			/* per cache line */
			sync;
			dcread(Index);
			isync;
			/* ensure dcread finishes before reading tag */
			Address = (mfspr(XREG_SPR_DCDBTRH));
			/* read tag's real address */
			if ((Address | 0xffffff7f) == 0xffffffff) {
				/* if line is valid */
				dcbf((Address & 0xFFFFFF00) | (Index & 0xff));
				/* flush if dirty */
				sync;
				/* ensure dcbf finishes */
			}
		}
	}

	Xil_DCacheInvalidate();

}

/****************************************************************************/
/**
*
* Flush a data cache line. If the byte specified by the address (Addr)
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
static void DCacheFlushLine(u32 Addr)
{
	dcbf(Addr);
	sync;
	isync;
}

/****************************************************************************/
/**
*
* Invalidate a data cache line. If the byte specified by the address (Addr)
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
static void DCacheInvalidateLine(u32 Addr)
{
	dcbi(Addr);
	sync;
	isync;
}


/****************************************************************************/
/**
* Flush the data cache for the given address range.
* If the bytes specified by the address (Addr) are cached by the data cache,
* the cacheline containing that byte is invalidated.  If the cacheline
* is modified (dirty), the written to system memory first before the
* before the line is invalidated.
*
* @param    Addr is the starting address of range to be flushed
* @param    Len is the length of range to be flushed in bytes
*
* @return   None.
*
* @note
*
* Processor must be in real mode.
****************************************************************************/
void Xil_DCacheFlushRange(u32 Addr, unsigned Len)
{
	const unsigned Cacheline = 32;
	unsigned int End;

	if (Len != 0) {
		/* Back the starting address up to the start of a cache line
		* perform cache operations until Addr+Len
		*/
		End = Addr + Len;
		Addr = Addr & ~(Cacheline - 1);

		while (Addr < End) {
			DCacheFlushLine(Addr);
			Addr += Cacheline;
		}
	}
}

/****************************************************************************/
/**
* Flush the entire data cache. If any cacheline is dirty, the cacheline will be
* written to system memory. The entire data cache will be invalidated.
*
* @return   None.
*
* @note
*
****************************************************************************/
void Xil_DCacheFlush(void)
{
	unsigned int TlbWord;
	unsigned int I;
	unsigned int TlbIndex;
	unsigned int Address;
	unsigned int Index;
	unsigned int PagesCacheable = 0;

	for(I = 0; I < 16; I++) {
		/* all TLB entries in 4GB of memory */
		TlbIndex = I + I + 1; /* data page indices = 1,3,5...,15 */
		TlbWord = tlbre(TlbIndex, 2);
		sync;
		if((TlbWord & 0x00000400) != 0x400) {
			/* if cache inhibit bit is not set */
			if((TlbWord & 0x00000800) != 0x800) {
				/* if not write through */
				PagesCacheable++;
			}

			isync;
		}
	}

	/* flush dirty data cache lines */
	if (PagesCacheable) {
		for(Index = 0; Index < DCACHE_SIZE; Index += 32) {
			/* per cache line */
			sync;
			dcread(Index);
			isync;
			/* ensure dcread finishes before reading tag */
			Address = (mfspr(XREG_SPR_DCDBTRH));
			/* read tag's real address */
			if ((Address | 0xffffff7f) == 0xffffffff) {
				/* if line is valid */
				dcbf((Address & 0xFFFFFF00) | (Index & 0xff));
				/* flush if dirty */
				sync;
				/* ensure dcbf finishes */
			}
		}
	}

	/* data cache is effectively flushed at this point */
	sync;

}

/****************************************************************************/
/**
*
* Invalidate the data cache for the given address range.
* If the bytes specified by the address (Addr) are cached by the data cache,
* the cacheline containing that byte is invalidated.  If the cacheline
* is modified (dirty), the modified contents are lost and are NOT
* written to system memory before the line is invalidated.
*
* @param    Addr is the starting address of ragne to be invalidated
* @param    Len is the length of range to be invalidated in bytes
*
* @return   None.
*
* @note
*
* Processor must be in real mode.
****************************************************************************/
void Xil_DCacheInvalidateRange(u32 Addr, unsigned Len)
{
	const unsigned Cacheline = 32;
	unsigned int End;

	if (Len != 0) {
		/* Back the starting address up to the start of a cache line
		 * perform cache operations until Addr+Len
		 */
		End = Addr + Len;
		Addr = Addr & ~(Cacheline - 1);

		while (Addr < End) {
			DCacheInvalidateLine(Addr);
			Addr += Cacheline;
		}
	}
}

/****************************************************************************/
/**
*
* Invalidate entire data cache.
*
* @param    None.
*
* @return   None.
*
* @note
*
****************************************************************************/
void Xil_DCacheInvalidate(void)
{

	sync;
	dccci(0);  /* invalidate data cache (clear all write
		    * through entries remaining.
		    * (0) = dummy argument--not used by the PPC440
		    * but needed for backward compatibility */
	isync;
}

/****************************************************************************/
/**
*
* Enable the instruction cache regions.
*
* @param    Regions to be marked as cachable. Each pair of adjacent
*           bits in the regions variable stands for 256MB of memory. Setting
*           either bit in the pair will enable caching for the corresponding
*           region.
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
* @note     This function is specific to PPC440.
*
*
****************************************************************************/
void Xil_ICacheEnableRegion(u32 Regions)
{
	int I;
	int Index;
	int TlbWord;

	Xil_ICacheDisable();
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

	for(I = 15; I >= 0 && Regions != 0; I--) {
		/* all TLB entries in 4GB of memory */
		if((Regions & 0x3) > 0) {
			/* either bit in this region is set */
			Index = I + I;
			/* instruction entry indices = 0,2,4,...,14 */
			TlbWord = tlbre(Index, 2);
			sync;
			/* unset cache inhibit bit, leave write-through bit
			 * as it is */
			tlbwe(TlbWord & 0xFFFFFBFF, Index, 2);
			isync;
		}
		Regions = Regions >> 2;
		/* check next region */
	}
}

/****************************************************************************/
/**
*
* Enable the instruction cache.
*
* @return   None.
*
* @note
*
* This function uses a 0x80000001 for the mask. Each pair of adjacent bits
* in the mask marks 256MB as cacheable.
* The CPU driver generates a mask (XPAR_CACHEABLE_REGION_MASK) for cacheable
* regions. This mask includes memories with size less than 256MB. Using this
* mask for enabling caches could cause a problem if there are any memory mapped
* peripherals around these smaller memory regions.
*
****************************************************************************/
void Xil_ICacheEnable()
{
	Xil_ICacheEnableRegion(0x80000001);
}


/****************************************************************************/
/**
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
void Xil_ICacheDisable(void)
{
	int I;
	int TwoI;
	int TlbWord;

	for(I = 0; I < 16; I++) {
		/* all TLB entries in 4GB of memory */
		TwoI = I + I;
		/* instruction entries = 0, 2,..., 14 */
		TlbWord = tlbre(TwoI, 2);
		sync;
		tlbwe(TlbWord | 0x0000400, TwoI, 2);
		/* set cache inhibit bit */
		isync;
	}
	Xil_ICacheInvalidate();
}

/****************************************************************************/
/**
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
void Xil_ICacheInvalidate(void)
{
	sync;
	iccci;
	isync;
}

/****************************************************************************/
/**
*
* Invalidate an instruction cache line.  If the instruction specified by the
* parameter Addr is cached by the instruction cache, the cacheline containing
* that instruction is invalidated.
*
* @param    Addr to be invalidated
*
* @return   None.
*
* @note
*
*
****************************************************************************/
static void ICacheInvalidateLine(u32 Addr)
{
	unsigned int OldMsr = mfmsr();
	/* copy IS bit over DS bit */
	sync;
	mtmsr( (OldMsr & 0xffffffef) | ((OldMsr >> 1) & 0x00000010));
	icbi(Addr);
	mtmsr(OldMsr); /* restore MSR */
	isync;
}

/****************************************************************************/
/**
*
* Invalidate the instruction cache for the given address range.
*
* @param    Addr is address of ragne to be invalidated.
* @param    Len is the length in bytes to be invalidated.
*
* @return   None.
*
****************************************************************************/
void Xil_ICacheInvalidateRange(u32 Addr, unsigned Len)
{
	const unsigned Cacheline = 32;
	unsigned int End;

	if (Len != 0) {
		/* Back the starting address up to the start of a cache line
		 * perform cache operations until Addr+Len
		 */
		End = Addr + Len;
		Addr = Addr & ~(Cacheline - 1);

		while (Addr < End) {
			ICacheInvalidateLine(Addr);
			Addr += Cacheline;
		}
	}
}

