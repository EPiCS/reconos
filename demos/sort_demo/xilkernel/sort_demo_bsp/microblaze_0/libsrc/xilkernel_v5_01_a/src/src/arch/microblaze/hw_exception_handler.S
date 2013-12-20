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
/*
 * Microblaze HW Exception Handler
 * - Non self-modifying exception handler for the following exception conditions
 *   - Unalignment
 *   - Instruction bus error
 *   - Data bus error
 *   - Illegal instruction opcode
 *   - Divide-by-zero
 */

#include "xparameters.h"
#include "microblaze_exceptions_g.h"
        
/* Helpful Macros */
#define EX_HANDLER_STACK_SIZ            (4*19)
#define RMSR_OFFSET                     0       
#define REG_OFFSET(regnum)              (4*regnum)
#define NUM_TO_REG(num)                 r ## num

#define R3_TO_STACK(regnum)             swi     r3, r1, REG_OFFSET(regnum)
#define R3_FROM_STACK(regnum)           lwi     r3, r1, REG_OFFSET(regnum)      

#define PUSH_REG(regnum)                swi     NUM_TO_REG(regnum), r1, REG_OFFSET(regnum)
#define POP_REG(regnum)                 lwi     NUM_TO_REG(regnum), r1, REG_OFFSET(regnum)
        
/* Uses r5 */
#define PUSH_MSR                                                                \
        mfs     r5, rmsr;                                                       \
        swi     r5, r1, RMSR_OFFSET;

#define PUSH_MSR_AND_ENABLE_EXC                                                 \
        mfs     r5, rmsr;                                                       \
        swi     r5, r1, RMSR_OFFSET;                                            \
        ori     r5, r5, 0x100;                          /* Turn ON the EE bit*/ \
        mts     rmsr, r5;
        
/* Uses r5 */
#define POP_MSR                                                                 \
        lwi     r5, r1, RMSR_OFFSET;                                            \
        mts     rmsr, r5;       

#define LWREG_NOP                                                               \
        bri     ex_handler_unhandled;                                           \
        nop;

#define SWREG_NOP                                                               \
        bri     ex_handler_unhandled;                                           \
        nop;        
        
/* r3 is the source */
#define R3_TO_LWREG_V(regnum)                                                   \
        R3_TO_STACK (regnum);                                                   \
        bri     ex_handler_done; 

/* r3 is the source */
#define R3_TO_LWREG(regnum)                                                     \
        or      NUM_TO_REG (regnum), r0, r3;                                    \
        bri     ex_handler_done;                        

/* r3 is the target */          
#define SWREG_TO_R3_V(regnum)                                                   \
        R3_FROM_STACK (regnum);                                                 \
        bri     ex_sw_tail;                                                     
                
/* r3 is the target */  
#define SWREG_TO_R3(regnum)                                                     \
        or      r3, r0, NUM_TO_REG (regnum);                                    \
        bri     ex_sw_tail; 

/* regnum is the source */  
#define FP_EX_OPB_SAVE(regnum)                                                  \
        swi     NUM_TO_REG (regnum), r0, mb_fpex_op_b;                          \
        nop;                                                                    \
        bri     handle_fp_ex_opa; 

/* regnum is the source */  
#define FP_EX_OPB_SAVE_V(regnum)                                                \
        R3_FROM_STACK (regnum);                                                 \
        swi     r3, r0, mb_fpex_op_b;                                           \
        bri     handle_fp_ex_opa; 
        
/* regnum is the source */  
#define FP_EX_OPA_SAVE(regnum)                                                  \
        swi     NUM_TO_REG (regnum), r0, mb_fpex_op_a;                          \
        nop;                                                                    \
        bri     handle_fp_ex_done; 
    
/* regnum is the source */  
#define FP_EX_OPA_SAVE_V(regnum)                                                \
        R3_FROM_STACK (regnum);                                                 \
        swi     r3, r0, mb_fpex_op_a;                                           \
        bri     handle_fp_ex_done; 

#define FP_EX_UNHANDLED                                                         \
        bri     fp_ex_unhandled;                                                \
        nop;                                                                    \
        nop;

/* ESR masks */    
#define ESR_EXC_MASK            0x0000001F
#define ESR_REG_MASK            0x000003E0
#define ESR_LW_SW_MASK          0x00000400
#define ESR_WORD_MASK           0x00000800
#define ESR_DS_MASK             0x00001000
#define ESR_MMU_MASK            0x00000010        

#ifdef MICROBLAZE_EXCEPTIONS_ENABLED                    /* If exceptions are enabled in the processor */
                
/* 
 * hw_exception_handler - Handler for unaligned exceptions
 * Exception handler notes:     
 * - Does not handle exceptions other than unaligned exceptions
 * - Does not handle exceptions during load into r17, r1, r0.
 * - Does not handle exceptions during store from r17 (cannot be done) and r1 (slows down common case)
 *
 *  Relevant register structures
 *        
 *  EAR - |----|----|----|----|----|----|----|----|      
 *      - <  ##   32 bit faulting address     ##  >      
 *       
 *  ESR - |----|----|----|----|----| - | - |-----|-----| 
 *      -                            W   S   REG   EXC
 *
 *        
 * STACK FRAME STRUCTURE
 * ---------------------
 *
 *      +-------------+         + 0
 *      |     MSR     |
 *      +-------------+         + 4                
 *      |     r1      |
 *      |      .      |
 *      |      .      |
 *      |      .      |
 *      |      .      |
 *      |     r18     |
 *      +-------------+         + 76
 *      |      .      |
 *      |      .      |        
 */        

         
.global _hw_exception_handler                               
.section .text                                          
.align 2
.ent _hw_exception_handler
_hw_exception_handler:   

#if (XPAR_MICROBLAZE_USE_STACK_PROTECTION == 1)

	/* Immediately halt for stack protection violation exception without using any stack       */
	swi	r3, r0, mb_sp_save_r3;			/* Save temporary register                 */
	mfs	r3, resr;				/* Extract ESR[DS]                         */
	andi	r3, r3, ESR_EXC_MASK;
	xori	r3, r3, 0x7;				/* Check for stack protection violation    */
	bnei	r3, ex_handler_not_sp_violation;
ex_handler_sp_violation:
	bri	0;					/* Halt here if stack protection violation */
ex_handler_not_sp_violation:
	lwi	r3, r0, mb_sp_save_r3;			/* Restore temporary register              */
#endif /* defined(XPAR_MICROBLAZE_USE_STACK_PROTECTION) && (XPAR_MICROBLAZE_USE_STACK_PROTECTION == 1) */

        addik   r1, r1, -(EX_HANDLER_STACK_SIZ);        /* Create stack frame */
        PUSH_REG(3);              
        PUSH_REG(4);              
        PUSH_REG(5);              
        PUSH_REG(6);
#ifdef MICROBLAZE_CAN_HANDLE_EXCEPTIONS_IN_DELAY_SLOTS
        mfs     r6, resr;
        andi    r6, r6, ESR_DS_MASK;
        beqi    r6, ex_handler_no_ds;
        mfs     r17, rbtr;
ex_handler_no_ds:       
#endif
        PUSH_REG(17);
        PUSH_MSR_AND_ENABLE_EXC;                        /* Exceptions enabled here. This will allow nested exceptions */
                
        mfs     r3, resr;    
        andi    r5, r3, ESR_EXC_MASK;                   /* Extract ESR[EXC]                     */
    
#if (XPAR_MICROBLAZE_USE_MMU >= 2) && !defined (XILKERNEL_MB_MPU_DISABLE)
        andi   r6, r5, ESR_MMU_MASK;                   /* >= 0b10000 = MMU exception */
        bnei   r6, xilkernel_process_mmu_exception;    /* Jump to MMU exception handler*/
#endif /* (XPAR_MICROBLAZE_USE_MMU >= 2) && !defined (XILKERNEL_MB_MPU_DISABLE)) */

#ifdef XPAR_MICROBLAZE_UNALIGNED_EXCEPTIONS
        xori    r6, r5, 1;                              /* 00001 = Unaligned Exception          */
        beqi    r6, handle_unaligned_ex ;               /* Jump to unalignment exception handler*/
#endif  /* XPAR_MICROBLAZE_UNALIGNED_EXCEPTIONS */
    
handle_other_ex:                                        /* Handle Other exceptions here         */        
        bri     xilkernel_process_exception;            /* Complete exception handling          */        

#ifdef XPAR_MICROBLAZE_UNALIGNED_EXCEPTIONS    
handle_unaligned_ex:    
        andi    r6, r3, ESR_REG_MASK;                   /* Mask and extract the register operand */
        srl     r6, r6;                                 /* r6 >> 5 */
        srl     r6, r6;
        srl     r6, r6;
        srl     r6, r6;
        srl     r6, r6;
        sbi     r6, r0, ex_reg_op;                      /* Store the register operand in a temporary location */
        mfs     r4, rear;                              
        andi    r6, r3, ESR_LW_SW_MASK;                 /* Extract ESR[S]               */
        bnei    r6, ex_sw;
ex_lw:  
        andi    r6, r3, ESR_WORD_MASK;                  /* Extract ESR[W]               */
        beqi    r6, ex_lhw;
        lbui    r5, r4, 0;                              /* Exception address in r4      */
        sbi     r5, r0, ex_tmp_data_loc_0;              /* Load a word, byte-by-byte from destination address and save it in tmp space  */              
        lbui    r5, r4, 1;
        sbi     r5, r0, ex_tmp_data_loc_1;
        lbui    r5, r4, 2;
        sbi     r5, r0, ex_tmp_data_loc_2;
        lbui    r5, r4, 3;
        sbi     r5, r0, ex_tmp_data_loc_3;
        lwi     r3, r0, ex_tmp_data_loc_0;              /* Get the destination register value into r3   */
        bri     ex_lw_tail;      
ex_lhw: 
        lbui    r5, r4, 0;                              /* Exception address in r4                      */
        sbi     r5, r0, ex_tmp_data_loc_0;              /* Load a half-word, byte-by-byte from destination address and save it in tmp space */  
        lbui    r5, r4, 1;                               
        sbi     r5, r0, ex_tmp_data_loc_1;
        lhui    r3, r0, ex_tmp_data_loc_0;              /* Get the destination register value into r3   */
ex_lw_tail:
        lbui    r5, r0, ex_reg_op;                      /* Get the destination register number into r5  */
        la      r6, r0, lw_table;                       /* Form load_word jump table offset (lw_table + (8 * regnum)) */
        addk    r5, r5, r5;                              
        addk    r5, r5, r5;
        addk    r5, r5, r5;
        addk    r5, r5, r6;
        bra     r5;
ex_lw_end:                                              /* Exception handling of load word, ends */
ex_sw:          
        lbui    r5, r0, ex_reg_op;                      /* Get the destination register number into r5 */
        la      r6, r0, sw_table;                       /* Form store_word jump table offset (sw_table + (8 * regnum)) */
        add     r5, r5, r5;                             
        add     r5, r5, r5;
        add     r5, r5, r5;
        add     r5, r5, r6;
        bra     r5;
ex_sw_tail:             
        mfs     r6, resr;                               
        andi    r6, r6, ESR_WORD_MASK;                  /* Extract ESR[W]       */
        beqi    r6, ex_shw;
        swi     r3, r0, ex_tmp_data_loc_0;
        lbui    r3, r0, ex_tmp_data_loc_0;              /* Store the word, byte-by-byte into destination address                */
        sbi     r3, r4, 0;
        lbui    r3, r0, ex_tmp_data_loc_1;
        sbi     r3, r4, 1;
        lbui    r3, r0, ex_tmp_data_loc_2;
        sbi     r3, r4, 2;       
        lbui    r3, r0, ex_tmp_data_loc_3;
        sbi     r3, r4, 3;                      
        bri     ex_handler_done;
ex_shw:         
        swi     r3, r0, ex_tmp_data_loc_0;              /* Store the lower half-word, byte-by-byte into destination address      */
#ifdef __LITTLE_ENDIAN__
        lbui    r3, r0, ex_tmp_data_loc_0;
#else
        lbui    r3, r0, ex_tmp_data_loc_2;
#endif
        sbi     r3, r4, 0;
#ifdef __LITTLE_ENDIAN__
        lbui    r3, r0, ex_tmp_data_loc_1;
#else
        lbui    r3, r0, ex_tmp_data_loc_3;
#endif
        sbi     r3, r4, 1;
ex_sw_end:                                              /* Exception handling of store word, ends. */
        bri     ex_handler_done; 
#endif  /* XPAR_MICROBLAZE_UNALIGNED_EXCEPTIONS */
                   
ex_handler_done:
        POP_REG(17);     
        POP_MSR;
        POP_REG(3);               
        POP_REG(4);               
        POP_REG(5);               
        POP_REG(6); 

        rted    r17, 0
        addik   r1, r1, (EX_HANDLER_STACK_SIZ);         /* Restore stack frame  */        
ex_handler_unhandled:   
        bri 0                                           /* UNHANDLED. TRAP HERE */
.end _hw_exception_handler  

#ifdef XPAR_MICROBLAZE_UNALIGNED_EXCEPTIONS        

/* 
 * hw_exception_handler Jump Table
 * - Contains code snippets for each register that caused the unaligned exception.
 * - Hence exception handler is NOT self-modifying
 * - Separate table for load exceptions and store exceptions.
 * - Each table is of size:   (8 * 32) = 256 bytes
 */
                
.section .text
.align  4
lw_table:
lw_r0:  R3_TO_LWREG   (0); 
lw_r1:  LWREG_NOP;
lw_r2:  R3_TO_LWREG   (2);
lw_r3:  R3_TO_LWREG_V (3);
lw_r4:  R3_TO_LWREG_V (4);
lw_r5:  R3_TO_LWREG_V (5);
lw_r6:  R3_TO_LWREG_V (6);
lw_r7:  R3_TO_LWREG   (7);
lw_r8:  R3_TO_LWREG   (8);
lw_r9:  R3_TO_LWREG   (9);
lw_r10: R3_TO_LWREG   (10);
lw_r11: R3_TO_LWREG   (11);                             
lw_r12: R3_TO_LWREG   (12);
lw_r13: R3_TO_LWREG   (13);
lw_r14: R3_TO_LWREG   (14);                                                     
lw_r15: R3_TO_LWREG   (15);                                                     
lw_r16: R3_TO_LWREG   (16);                                                     
lw_r17: LWREG_NOP;
lw_r18: R3_TO_LWREG   (18);                                                     
lw_r19: R3_TO_LWREG   (19);                                                     
lw_r20: R3_TO_LWREG   (20);                                                     
lw_r21: R3_TO_LWREG   (21);
lw_r22: R3_TO_LWREG   (22);
lw_r23: R3_TO_LWREG   (23);                                                     
lw_r24: R3_TO_LWREG   (24);                                                     
lw_r25: R3_TO_LWREG   (25);                                                     
lw_r26: R3_TO_LWREG   (26);                                                     
lw_r27: R3_TO_LWREG   (27);                                                     
lw_r28: R3_TO_LWREG   (28);                                                     
lw_r29: R3_TO_LWREG   (29);                                                     
lw_r30: R3_TO_LWREG   (30);
lw_r31: R3_TO_LWREG   (31);

sw_table:
sw_r0:  SWREG_TO_R3   (0); 
sw_r1:  SWREG_NOP;
sw_r2:  SWREG_TO_R3   (2);
sw_r3:  SWREG_TO_R3_V (3);
sw_r4:  SWREG_TO_R3_V (4);
sw_r5:  SWREG_TO_R3_V (5);
sw_r6:  SWREG_TO_R3_V (6);
sw_r7:  SWREG_TO_R3   (7);
sw_r8:  SWREG_TO_R3   (8);
sw_r9:  SWREG_TO_R3   (9);
sw_r10: SWREG_TO_R3   (10);
sw_r11: SWREG_TO_R3   (11);                             
sw_r12: SWREG_TO_R3   (12);
sw_r13: SWREG_TO_R3   (13);
sw_r14: SWREG_TO_R3   (14);                                                     
sw_r15: SWREG_TO_R3   (15);                                                     
sw_r16: SWREG_TO_R3   (16);                                                     
sw_r17: SWREG_NOP; 
sw_r18: SWREG_TO_R3   (18);                                                     
sw_r19: SWREG_TO_R3   (19);                                                     
sw_r20: SWREG_TO_R3   (20);                                                     
sw_r21: SWREG_TO_R3   (21);
sw_r22: SWREG_TO_R3   (22);
sw_r23: SWREG_TO_R3   (23);                                                     
sw_r24: SWREG_TO_R3   (24);                                                     
sw_r25: SWREG_TO_R3   (25);                                                     
sw_r26: SWREG_TO_R3   (26);                                                     
sw_r27: SWREG_TO_R3   (27);                                                     
sw_r28: SWREG_TO_R3   (28);                                                     
sw_r29: SWREG_TO_R3   (29);                                                     
sw_r30: SWREG_TO_R3   (30);
sw_r31: SWREG_TO_R3   (31);

/* Temporary data structures used in the handler */
.section .data
.align 2
ex_tmp_data_loc_0:      
        .byte 0
ex_tmp_data_loc_1:      
        .byte 0
ex_tmp_data_loc_2:      
        .byte 0
ex_tmp_data_loc_3:      
        .byte 0                 
ex_reg_op:
        .byte 0
    
#endif /* (XPAR_MICROBLAZE_UNALIGNED_EXCEPTIONS) */

#if (XPAR_MICROBLAZE_USE_STACK_PROTECTION == 1)
/* This is where we store the register used to check which exception occurred */
	.section .data
	.align 2
mb_sp_save_r3:
        .long 0
#endif /* defined(XPAR_MICROBLAZE_USE_STACK_PROTECTION) && (XPAR_MICROBLAZE_USE_STACK_PROTECTION == 1) */

/* The exception vector table */
.section .data
.align 2
.global MB_ExceptionVectorTable
MB_ExceptionVectorTable:
    .long XNullHandler
    .long 0                                 /* --          FSL Exception         -- */
    .long XNullHandler
    .long 1                                 /* -- Unaligned Access Exception     -- */
    .long XNullHandler
    .long 2                                 /* --   Illegal Opcode Exception     -- */
    .long XNullHandler
    .long 3                                 /* --         IOPB Exception         -- */
    .long XNullHandler
    .long 4                                 /* --         DOPB Exception         -- */
    .long XNullHandler
    .long 5                                 /* --       Div-by-0 Exception       -- */
    .long XNullHandler
    .long 6                                 /* --         FPU  Exception         -- */
    .long XNullHandler
    .long 7                                 /* --         MMU  Exceptions        -- */    
    
#else                                                   /* Dummy exception handler, in case exceptions are not present in the processor */

.global _hw_exception_handler                               
.section .text                                          
.align 2
.ent _hw_exception_handler
_hw_exception_handler:
        bri     0; 
.end _hw_exception_handler        
                                
#endif  /* MICROBLAZE_EXCEPTIONS_ENABLED */
