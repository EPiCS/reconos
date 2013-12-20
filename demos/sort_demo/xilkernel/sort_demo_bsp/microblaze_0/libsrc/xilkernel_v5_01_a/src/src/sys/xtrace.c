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
//! @file xtrace.c
//!
//! XMK API for tracing kernel level and custom user events. 
//! Requires trace memory in the system accessible to program.
//! @note - This feature is for internal use only.
//----------------------------------------------------------------------------------------------------//
#include <os_config.h>
#include <sys/types.h>
#include <sys/decls.h>
#include <sys/xtrace.h>

#ifdef CONFIG_XTRACE

//----------------------------------------------------------------------------------------------------//
// Declarations
//----------------------------------------------------------------------------------------------------//
const char *xtrace_event_name[] = {
    "SCHED",
    "SEM",
    "TIMER",
    "CUSTOM"
};

const char *xtrace_action_name[] = {
    "resched",
    "wait",
    "timewait",
    "wait_timeout",
    "wait_unblock",
    "acquire",
    "post",
    "post_unblock",
    "timeout",
    "tick",
    "add",
    "remove",
    "action1",
    "action2",
    "action3",
    "action4",
    "action5",
    "action6"
};

extern pid_t current_pid;

//----------------------------------------------------------------------------------------------------//
// Data
//----------------------------------------------------------------------------------------------------// 
unsigned int    xtrace_first, xtrace_last, xtrace_count;
xtrace_pkt_t    *xtracebuf    = (xtrace_pkt_t *)(CONFIG_XTRACE_MEM_START + 8);
unsigned int    xtrace_off;

//----------------------------------------------------------------------------------------------------//
// Definitions
//----------------------------------------------------------------------------------------------------//

//----------------------------------------------------------------------------------------------------//
//  @func - xtrace_log_event 
//!
//! 
//! @param
//!   - 
//! @return
//!   - Nothing
//! @note
//!   - None
//----------------------------------------------------------------------------------------------------//
void xtrace_log_event (enum xtrace_event event, enum xtrace_action action, 
                       unsigned int resource, unsigned int custom0, unsigned int custom1)
{
    if (xtrace_off)
        return;

    xtracebuf[xtrace_last].event = event;
    xtracebuf[xtrace_last].pid   = current_pid;
    xtracebuf[xtrace_last].resource = resource;
    xtracebuf[xtrace_last].action = action;
    xtracebuf[xtrace_last].custom[0] = custom0;
    xtracebuf[xtrace_last].custom[1] = custom1;
    
    if (xtrace_count != CONFIG_XTRACE_MAX_COUNT)
        xtrace_count++;
    
    xtrace_last++;
    if (xtrace_last == CONFIG_XTRACE_MAX_COUNT) 
        xtrace_last = 0;
    
    if (xtrace_last == xtrace_first) {
        xtrace_first++;
        if (xtrace_first == CONFIG_XTRACE_MAX_COUNT)
            xtrace_first = 0;
    } 
}

//----------------------------------------------------------------------------------------------------//
//  @func - xtrace_print_log 
//!
//! 
//! @param
//!   - 
//! @return
//!   - Nothing
//! @note
//!   - None
//----------------------------------------------------------------------------------------------------//
void xtrace_print_log (int count, int last)
{
    int i, start, end;
    
    DPRINTF ("XTrace Log\r\n");
    DPRINTF ("\tTotal events recorded: %d.\r\n", xtrace_count);

    if (count == 0)
        count = xtrace_count;
    
    if (last) {
        start = (xtrace_last - count - 1);
        if (start < 0)
            start = (CONFIG_XTRACE_MAX_COUNT + start);
    } else 
        start = xtrace_first;
    
    end = (start + count) % CONFIG_XTRACE_MAX_COUNT;
    
    DPRINTF ("\tDumping (%d) %s events next --\r\n", count, (last ? "trailing" : "beginning"));
    
    i = start;
    while (i != end) {
        if (xtracebuf[i].event >= XCUSTOM_EVENT) {
            DPRINTF ("E%04d: [%6s]-(%15s) PID(%03d) on (%03d). custom - [0x%x], [0x%x]\r\n",
                     i,
                     xtrace_event_name[xtracebuf[i].event],
                     xtrace_action_name[xtracebuf[i].action],
                     xtracebuf[i].pid,
                     xtracebuf[i].resource,
                     xtracebuf[i].custom[0],
                     xtracebuf[i].custom[1]);
        } else {
            DPRINTF ("E%04d: [%6s]-(%15s) PID(%03d) on (%03d).\r\n",
                     i,
                     xtrace_event_name[xtracebuf[i].event],
                     xtrace_action_name[xtracebuf[i].action],
                     xtracebuf[i].pid,
                     xtracebuf[i].resource);
        }
        
        if (++i == CONFIG_XTRACE_MAX_COUNT)
            i = 0;
    }
    
    while (1);
}
    
#endif /* CONFIG_XTRACE */

