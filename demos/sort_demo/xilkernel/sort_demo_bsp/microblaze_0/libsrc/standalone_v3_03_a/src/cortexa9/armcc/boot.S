;* $Id: boot.S,v 1.1.4.1 2011/10/24 09:35:18 sadanan Exp $
;******************************************************************************
;
; (c) Copyright 2009-2011 Xilinx, Inc. All rights reserved.
;
; This file contains confidential and proprietary information of Xilinx, Inc.
; and is protected under U.S. and international copyright and other
; intellectual property laws.
;
; DISCLAIMER
; This disclaimer is not a license and does not grant any rights to the
; materials distributed herewith. Except as otherwise provided in a valid
; license issued to you by Xilinx, and to the maximum extent permitted by
; applicable law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL
; FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS,
; IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
; MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE;
; and (2) Xilinx shall not be liable (whether in contract or tort, including
; negligence, or under any other theory of liability) for any loss or damage
; of any kind or nature related to, arising under or in connection with these
; materials, including for any direct, or any indirect, special, incidental,
; or consequential loss or damage (including loss of data, profits, goodwill,
; or any type of loss or damage suffered as a result of any action brought by
; a third party) even if such damage or loss was reasonably foreseeable or
; Xilinx had been advised of the possibility of the same.
;
; CRITICAL APPLICATIONS
; Xilinx products are not designed or intended to be fail-safe, or for use in
; any application requiring fail-safe performance, such as life-support or
; safety devices or systems, Class III medical devices, nuclear facilities,
; applications related to the deployment of airbags, or any other applications
; that could lead to death, personal injury, or severe property or
; environmental damage (individually and collectively, "Critical
; Applications"). Customer assumes the sole risk and liability of any use of
; Xilinx products in Critical Applications, subject only to applicable laws
; and regulations governing limitations on product liability.
;
; THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE
; AT ALL TIMES.
;
;****************************************************************************
;****************************************************************************
;**
; @file boot.S
;
; This file contains the initial startup code for the Cortex A9 processor
;
; <pre>
; MODIFICATION HISTORY:
;
; Ver	Who	  Date	  Changes
; ----- ------- -------- ---------------------------------------------------
; 1.00a ecm/sdm 10/20/09 Initial version
; </pre>
;
; @note
;
; None.
;
;****************************************************************************

#include "xparameters.h"

	EXPORT _prestart
	EXPORT _boot

	IMPORT |Image$$ARM_LIB_STACK$$ZI$$Limit|
	IMPORT |Image$$IRQ_STACK$$ZI$$Limit|
	;IMPORT |Image$$SPV_STACK$$ZI$$Limit|
	;IMPORT |Image$$ABORT_STACK$$ZI$$Limit|
	IMPORT MMUTable
	IMPORT __main
	IMPORT Xil_ExceptionInit
	IMPORT XSmc_NorInit
	IMPORT XSmc_SramInit

PSS_L2CC_BASE_ADDR	EQU	0xF8F02000

L2CCWay		EQU	(PSS_L2CC_BASE_ADDR + 0x077C)	;(PSS_L2CC_BASE_ADDR + PSS_L2CC_CACHE_INVLD_WAY_OFFSET)
L2CCSync	EQU	(PSS_L2CC_BASE_ADDR + 0x0730)	;(PSS_L2CC_BASE_ADDR + PSS_L2CC_CACHE_SYNC_OFFSET)
L2CCCrtl	EQU	(PSS_L2CC_BASE_ADDR + 0x0100)	;(PSS_L2CC_BASE_ADDR + PSS_L2CC_CNTRL_OFFSET)
L2CCAuxCrtl	EQU	(PSS_L2CC_BASE_ADDR + 0x0104)	;(PSS_L2CC_BASE_ADDR + XPSS_L2CC_AUX_CNTRL_OFFSET)
L2CCTAGLatReg	EQU	(PSS_L2CC_BASE_ADDR + 0x0108)	;(PSS_L2CC_BASE_ADDR + XPSS_L2CC_TAG_RAM_CNTRL_OFFSET)
L2CCDataLatReg	EQU	(PSS_L2CC_BASE_ADDR + 0x010C)	;(PSS_L2CC_BASE_ADDR + XPSS_L2CC_DATA_RAM_CNTRL_OFFSET)
L2CCIntClear	EQU	(PSS_L2CC_BASE_ADDR + 0x0220)	;(PSS_L2CC_BASE_ADDR + XPSS_L2CC_IAR_OFFSET)
L2CCIntRaw	EQU	(PSS_L2CC_BASE_ADDR + 0x021C)	;(PSS_L2CC_BASE_ADDR + XPSS_L2CC_ISR_OFFSET)

CRValMmuCac		EQU	2_01000000000101	; Enable IDC, and MMU 
CRValHiVectorAddr	EQU	2_10000000000000	; Set the Vector address to high, 0xFFFF0000 

L2CCAuxControl	EQU	0x70021400	; Enable all prefetching, Way Size (16 KB) and High Priority for SO and Dev Reads Enable 
L2CCControl	EQU	0x01		; Enable L2CC 
L2CCTAGLatency	EQU	0x0121		; 7 Cycles of latency for TAG RAM 
L2CCDataLatency	EQU	0x0121		; 7 Cycles of latency for DATA RAM 

FPEXC_EN	EQU	0x40000000	; FPU enable bit, (1 << 30) 

	AREA |.boot|, CODE
	PRESERVE8


; this initializes the various processor modes 

_prestart
_boot

#if XPAR_CPU_ID==0
; only allow cp0 through 
	mrc	p15,0,r1,c0,c0,5
	and	r1, r1, #0xf
	cmp	r1, #0
	beq	OKToRun
EndlessLoop0
	wfe
	b	EndlessLoop0

#elif XPAR_CPU_ID==1
; only allow cp1 through 
	mrc	p15,0,r1,c0,c0,5
	and	r1, r1, #0xf
	cmp	r1, #1
	beq	OKToRun
EndlessLoop1
	wfe
	b	EndlessLoop1
#endif

OKToRun
	;set scu enable bit in scu
	ldr	r7, =0xf8f00000
	ldr	r0, [r7]
	orr	r0, r0, #0x1
	str	r0, [r7]

	;invalidate scu
	ldr	r7, =0xf8f0000c
	ldr	r6, =0xffff
	str	r6, [r7]

	; Write to ACTLR 
	mrc	p15, 0,r0, c1, c0, 1		; Read ACTLR
	orr	r0, r0, #(0x01 << 6)		; SMP bit
	orr	r0, r0, #(0x01 )		; Cache/TLB maintenance broadcast 
	mcr	p15, 0,r0, c1, c0, 1		; Write ACTLR

; Invalidate caches and TLBs 
	mov	r0,#0				; r0 = 0  
	mcr	p15, 0, r0, c8, c7, 0		; invalidate TLBs 
	mcr	p15, 0, r0, c7, c5, 0		; invalidate icache 
	mcr	p15, 0, r0, c7, c5, 6		; Invalidate branch predictor array 
	bl	invalidate_dcache		; invalidate dcache 

; Invalidate L2c Cache
; For AMP, assume running on CPU1. Don't initialize L2 Cache (up to Linux)
#if USE_AMP!=1
	ldr	r0,=L2CCCrtl			; Load L2CC base address base + control register
	mov	r1, #0				; force the disable bit
	str	r1, [r0]			; disable the L2 Caches

	ldr	r0,=L2CCAuxCrtl			; Load L2CC base address base + Aux control register
	ldr	r1,[r0]				; read the register
	ldr	r2,=L2CCAuxControl		; set the default bits
	orr	r1,r1,r2
	str	r1, [r0]			; store the Aux Control Register

	ldr	r0,=L2CCTAGLatReg		; Load L2CC base address base + TAG Latency address
	ldr	r1,=L2CCTAGLatency		; set the latencies for the TAG
	str	r1, [r0]			; store the TAG Latency register Register

	ldr	r0,=L2CCDataLatReg		; Load L2CC base address base + Data Latency address
	ldr	r1,=L2CCDataLatency		; set the latencies for the Data
	str	r1, [r0]			; store the Data Latency register Register

	ldr	r0,=L2CCWay			; Load L2CC base address base + way register
	ldr	r2, =0xFFFF
	str	r2, [r0]			; force invalidate

	ldr	r0,=L2CCSync			; need to poll 0x730, PSS_L2CC_CACHE_SYNC_OFFSET
						; Load L2CC base address base + sync register
	; poll for completion
Sync	
	ldr	r1, [r0]
	cmp	r1, #0
	bne	Sync

	ldr	r0,=L2CCIntRaw			; clear pending interrupts
	ldr	r1,[r0]
	ldr	r0,=L2CCIntClear	
	str	r1,[r0]
#endif

	; Disable MMU, if enabled 
	mrc	p15, 0, r0, c1, c0, 0		; read CP15 register 1 
	bic	r0, r0, #0x1			; clear bit 0 
	mcr	p15, 0, r0, c1, c0, 0		; write value back 

#ifdef SHAREABLE_DDR
	; Mark the entire DDR memory as shareable
	ldr	r3, =0x3ff			; 1024 entries to cover 1G DDR
	ldr	r0, =TblBase			; MMU Table address in memory
	ldr	r2, =0x15c06			; S=b1 TEX=b101 AP=b11, Domain=b0, C=b1, B=b0
shareable_loop:
	str	r2, [r0]			; write the entry to MMU table
	add	r0, r0, #0x4			; next entry in the table
	add	r2, r2, #0x100000		; next section
	subs	r3, r3, #1
	bge	shareable_loop			; loop till 1G is covered
#endif

	; In case of AMP, map virtual address 0x20000000 to 0x00000000  and mark it as non-cacheable
#if USE_AMP==1
	ldr	r3, =0x1ff			; 512 entries to cover 512MB DDR
	ldr	r0, =TblBase			; MMU Table address in memory
	add	r0, r0, #0x800			; Address of entry in MMU table, for 0x20000000
	ldr	r2, =0x0c02			; S=b0 TEX=b000 AP=b11, Domain=b0, C=b0, B=b0
mmu_loop:
	str	r2, [r0]			; write the entry to MMU table
	add	r0, r0, #0x4			; next entry in the table
	add	r2, r2, #0x100000		; next section
	subs	r3, r3, #1
	bge	mmu_loop			; loop till 512MB is covered
#endif

	mrs	r0, cpsr			; get the current PSR 
	mvn	r1, #0x1f			; set up the irq stack pointer 
	and	r2, r1, r0
	orr	r2, r2, #0x12			; IRQ mode 
	msr	apsr, r2			; was cpsr, apsr is considered synonym
	ldr	r13,=|Image$$IRQ_STACK$$ZI$$Limit|	; IRQ stack pointer 

	;mrs	r0, cpsr			; get the current PSR
	;mvn	r1, #0x1f			; set up the supervisor stack pointer
	;and	r2, r1, r0
	;orr	r2, r2, #0x13			; supervisor mode
	;msr	apsr, r2			; was cpsr, apsr is considered synonym
	;ldr	r13,=|Image$$SPV_STACK$$ZI$$Limit|	; Supervisor stack pointer

	;mrs	r0, cpsr			; get the current PSR
	;mvn	r1, #0x1f			; set up the Abort  stack pointer
	;and	r2, r1, r0
	;orr	r2, r2, #0x17			; Abort mode
	;msr	apsr, r2			; was cpsr, apsr is considered synonym
	;ldr	r13,=|Image$$ABORT_STACK$$ZI$$Limit|	; Abort stack pointer

	mrs	r0, cpsr			; get the current PSR 
	mvn	r1, #0x1f			; set up the system stack pointer 
	and	r2, r1, r0
	orr	r2, r2, #0x1f			; SYS mode 
	msr	apsr, r2			 ; was cpsr, apsr is considered synonym
	ldr	r13,=|Image$$ARM_LIB_STACK$$ZI$$Limit|	; SYS stack pointer 

	; enable MMU and cache 

	mrc	p15, 0, r0, c2, c0, 2		; TTBCR 
	orr	r0, r0, #2			; set TLB size 
	mrc	p15, 0, r0, c2, c0, 2		; TTBCR 

	ldr	r0,=MMUTable			; Load MMU translation table base 
	orr	r0, r0, #0x59			; Outer-cacheable, WB 
	mcr	p15, 0, r0, c2, c0, 0		; TTB0 
	mcr	p15, 0, r0, c2, c0, 1		; TTB1 
	
	mvn	r0,#0
	mcr	p15,0,r0,c3,c0,0

	; Enable mmu, icahce and dcache
	ldr	r0,=CRValMmuCac

	mcr	p15,0,r0,c1,c0,0		; Enable cache and MMU 
	dsb					; dsb allow the MMU to start up 
	isb					; isb flush prefetch buffer 

; For AMP, assume running on CPU1. Don't initialize L2 Cache (up to Linux)
#if USE_AMP!=1
	ldr	r0,=L2CCCrtl			; Load L2CC base address base + control register
	ldr	r1,[r0]				; read the register
	mov	r2, #L2CCControl		; set the enable bit
	orr	r1,r1,r2
	str	r1, [r0]			; enable the L2 Caches
#endif

	mov	r0, r0
	mrc	p15, 0, r1, c1, c0, 2		; read cp access control register (CACR) into r1 
	orr	r1, r1, #(0xf << 20)		; enable full access for p10 & p11 
	mcr	p15, 0, r1, c1, c0, 2		; write back into CACR 

	; enable vfp 
	fmrx  r1, FPEXC				; read the exception register 
	orr	r1,r1, #FPEXC_EN		; set VFP enable bit, leave the others in orig state 
	fmxr  FPEXC, r1				; write back the exception register 

	mrc	p15, 0, r0, c1, c0, 0		; flow prediction enable 
	orr	r0, r0, #(0x01 << 11)		; #0x8000
	mcr	p15,0,r0,c1,c0,0

	mrc	p15, 0, r0, c1, c0, 1		; read Auxiliary Control Register 
	orr	r0, r0, #(0x1 << 2)		; enable Dside prefetch 
	orr	r0, r0, #(0x1 << 1)		; enable L2 prefetch 
	mcr	p15, 0, r0, c1, c0, 1		; write Auxiliary Control Register 

	;  Initialize the vector table
	;bl	 Xil_ExceptionInit

#if USE_AMP==1
; Initialize the UART 1 to 9600 Baud
	ldr	r1, =XPAR_XUARTPSS_1_BASEADDR
	mov	r2, #0x17			; enable Tx/Rx and reset Tx/Rx data path
	str	r2, [r1]
	mov	r2, #0x20			; 8 data, 1 stop, 0 parity bits
	str	r2, [r1, #0x4]			; sel_clk=uart_clk=APB clock (50Mhz)
	mov	r2, #0x100			; baud_rate=sel_clk/CD*(BDIV+1)
	orr	r2, r2, #0x45			; CD=0x100|0x45=0x145, BDIV=15(default)
	str	r2, [r1, #0x18]			; baud_rate ~= 9600
#else
; Initialize the UART to 9600 Baud 
	ldr	r1, =XPAR_XUARTPS_0_BASEADDR
	mov	r2, #0x17			; enable Tx/Rx and reset Tx/Rx data path 
	str	r2, [r1]
	mov	r2, #0x20			; 8 data, 1 stop, 0 parity bits 
	str	r2, [r1, #0x4]			; sel_clk=uart_clk=APB clock (50Mhz) 
	mov	r2, #0x100			; baud_rate=sel_clk/CD*(BDIV+1) 
	orr	r2, r2, #0x45			; CD=0x100|0x45=0x145, BDIV=15(default) 
	str	r2, [r1, #0x18]			; baud_rate ~= 9600 
#endif

; Reset and start Cycle Counter 
	mov	r2, #0x80000000			; clear overflow 
	mcr	p15, 0, r2, c9, c12, 3
	mov	r2, #0xd			; D, C, E 
	mcr	p15, 0, r2, c9, c12, 0
	mov	r2, #0x80000000			; enable cycle counter 
	mcr	p15, 0, r2, c9, c12, 1

#ifndef USE_AMP
	bl	XSmc_NorInit

	bl	XSmc_SramInit
#endif

; don't know if it helps, but maybe setting r0/r1 to zero here has an impact on argc/argv
	mov r0, #0
	mov r1, #0
	b  __main				; jump to C startup code 
	and	r0, r0, r0			; no op 
	
Ldone  b  Ldone					; Paranoia: we should never get here 


; *************************************************************************
; *
; * invalidate_dcache - invalidate the entire d-cache by set/way
; *
; * Note: for Cortex-A9, there is no cp instruction for invalidating
; * the whole D-cache. Need to invalidate each line.
; *
; *************************************************************************
 
invalidate_dcache
	mrc	p15, 1, r0, c0, c0, 1		; read CLIDR 
	ands	r3, r0, #0x7000000
	mov	r3, r3, lsr #23			; cache level value (naturally aligned) 
	beq	finished
	mov	r10, #0				; start with level 0 
loop1
	add	r2, r10, r10, lsr #1		; work out 3xcachelevel 
	mov	r1, r0, lsr r2			; bottom 3 bits are the Cache type for this level 
	and	r1, r1, #7			; get those 3 bits alone 
	cmp	r1, #2
	blt	skip				; no cache or only instruction cache at this level 
	mcr	p15, 2, r10, c0, c0, 0		; write the Cache Size selection register 
	isb					; isb to sync the change to the CacheSizeID reg 
	mrc	p15, 1, r1, c0, c0, 0		; reads current Cache Size ID register 
	and	r2, r1, #7			; extract the line length field 
	add	r2, r2, #4			; add 4 for the line length offset (log2 16 bytes) 
	ldr	r4, =0x3ff
	ands	r4, r4, r1, lsr #3		; r4 is the max number on the way size (right aligned) 
	clz	r5, r4				; r5 is the bit position of the way size increment 
	ldr	r7, =0x7fff
	ands	r7, r7, r1, lsr #13		; r7 is the max number of the index size (right aligned) 
loop2
	mov	r9, r4				; r9 working copy of the max way size (right aligned) 
loop3
	orr	r11, r10, r9, lsl r5		; factor in the way number and cache number into r11 
	orr	r11, r11, r7, lsl r2		; factor in the index number 
	mcr	p15, 0, r11, c7, c14, 2		; clean & invalidate by set/way 
	subs	r9, r9, #1			; decrement the way number 
	bge	loop3
	subs	r7, r7, #1			; decrement the index 
	bge	loop2
skip
	add	r10, r10, #2			; increment the cache number 
	cmp	r3, r10
	bgt	loop1

finished
	mov	r10, #0				; swith back to cache level 0 
	mcr	p15, 2, r10, c0, c0, 0		; select current cache level in cssr 
	isb

	bx lr

	END
