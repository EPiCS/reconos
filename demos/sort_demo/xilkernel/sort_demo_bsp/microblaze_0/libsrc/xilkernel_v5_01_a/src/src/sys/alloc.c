/******************************************************************************
*
* (c) Copyright 2010 Xilinx, Inc. All rights reserved.
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

//----------------------------------------------------------------------------------------------------//
//! @file alloc.c
//! Kernel data structures to be allocated in the BSS section.
//----------------------------------------------------------------------------------------------------//

#include <os_config.h>
#include <config/config_param.h>
#include <sys/arch.h>

#if PTHREAD_STACK_SIZE < 1024
#define KERNEL_IRQ_STACKSZ 1024
#else
#define KERNEL_IRQ_STACKSZ PTHREAD_STACK_SIZE
#endif

//! kernel_irq_stack - Stack to be used on IRQs
char kernel_irq_stack[KERNEL_IRQ_STACKSZ] __attribute__ ((aligned (STACK_ALIGN)));
const char *kernel_irq_stack_ptr = (const char *)(kernel_irq_stack + KERNEL_IRQ_STACKSZ + SSTACK_PTR_ADJUST);
const char *kernel_irq_stack_ptr_end = (const char *)(kernel_irq_stack + SSTACK_PTR_ADJUST);

#ifdef CONFIG_ELF_PROCESS
//! process_startup_stack - Temporary initial stack to be used by processes
//! before their own elf stacks are setup. This is potentially dangerous
char process_startup_stack[PROCESS_STARTUP_STACKSZ] __attribute__ ((aligned (STACK_ALIGN)));
#endif

