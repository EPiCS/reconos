/****************************************************************************/
/**
*
* @file sem_core.h
*
* This header file contains identifiers and low-level driver functions
* that can be used to access the 'Soft Error Mitigation' device.
*
*
*****************************************************************************/

#ifndef _SEM_CORE_H_
#define _SEM_CORE_H_

#include <stdio.h>
#include <stdint.h>

#define XILSEM_BASE            (0x86000000UL)
#define XILSEM_BASE_OFFSET     (0x00)
#define XILSEM_IPIF_RST_OFFSET (0x40)
#define XILSEM_CMD_OFFSET      (0x00)
#define XILSEM_STATUS_OFFSET   (0x01)
#define XILSEM_ADDR1_OFFSET    (0x02)
#define XILSEM_ADDR2_OFFSET    (0x03)

#define XILSEM_STATUS_READY 31 //0
#define XILSEM_STATUS_BUSY  30 //1
#define XILSEM_STATUS_IDLE_ACK_FLAG 27 //4
#define XILSEM_STATUS_INJ_ACK_FLAG  26 //5
#define XILSEM_STATUS_OBS_ACK_FLAG  25 //6

#define XILSEM_INJ_ACK_MASK                    26//0b00000100000000000000000000000000
#define XILSEM_HB_STATUS_MASK                  24//0b00000001000000000000000000000000

// This value in HW CMD register execute No Operation Command,
#define XILSEM_NOP_EXE 		0x00000000

// This value in HW CMD register execute IDLE Command,
#define XILSEM_IDLE_EXE 		0x20000000

// This value in HW CMD register execute OBS Command,
#define XILSEM_OBS_EXE 		0x08000000

// This value in HW CMD register execute INJ Command,
#define XILSEM_INJ_EXE 		0x40000000

// This value in HW CMD register execute SEM IP RESET Command,
#define XILSEM_RESET_EXE 		0x10000000

// This value in IPIF_RESET register executes HW RESET
#define XILSEM_IPIF_RESET_EXE 	0x0000000A

uint32_t xilsem_read_status();

void xilsem_init();
void xilsem_debug(int flag);
void xilsem_exit();
void xilsem_inj_addr(uint32_t addr1, uint32_t addr2);
void xilsem_ipif_reset();
void xilsem_nop();
void xilsem_reset();
void xilsem_idle();
void xilsem_inj();
void xilsem_obs();
void xilsem_status();
void xilsem_inject_error(uint32_t addr1, uint32_t addr2);
void xilsem_print_regs();

#endif
