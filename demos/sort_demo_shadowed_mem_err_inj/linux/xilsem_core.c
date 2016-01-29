/*
 * sem_core.c
 *
 *  Created on: Dec 8, 2014
 *      Author: umair
 */

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include "xilsem_core.h"


static char* dev_file_name = "/dev/mem";
static  int   dev_file;
static volatile uint32_t * mapped_sem =NULL;
static  size_t mapped_size = 0;
static unsigned int page_addr;
static unsigned int page_offset;
static unsigned int page_size;
static int xilsem_debug_flag = 0; // default is off, == 1 is on

void xilsem_debug(int flag){
	xilsem_debug_flag = flag;
}

void xilsem_init(){

	/* Open /dev/mem file */
	dev_file = open (dev_file_name, O_RDWR);
	if (dev_file < 1) {
		perror("SEM INIT: ERROR FILE OPEN");
		exit( EXIT_FAILURE);
	}

	/* calculate size of mapped area */
	mapped_size = sysconf(_SC_PAGESIZE);

	/* mmap the device into memory */
	page_addr = (XILSEM_BASE & (~(page_size-1)));
	page_offset = XILSEM_BASE - page_addr;
	mapped_sem = mmap(NULL, mapped_size, PROT_READ|PROT_WRITE, MAP_SHARED, dev_file, XILSEM_BASE);
	if (mapped_sem == MAP_FAILED){
		perror("SEM INIT: ERROR MAPPING");
		exit( EXIT_FAILURE);
	} else if(xilsem_debug_flag){
		printf("Mapped physical address 0x%lx to virtual address %p with length %zi .\n", XILSEM_BASE, mapped_sem, mapped_size);
	}
}

void xilsem_exit(){
	munmap(mapped_sem, mapped_size);
}

// Puts the injection addresses into HW registers
// A complete injection address is only 36 bit wide
// addr1 forms lower 32 bits, addr2 lower 4 bits are only used
void xilsem_inj_addr(uint32_t addr1, uint32_t addr2)
{
	*(mapped_sem + XILSEM_ADDR1_OFFSET) = addr1;
	*(mapped_sem + XILSEM_ADDR2_OFFSET) = addr2;
}

// Return system Status from slvreg1
uint32_t xilsem_read_status()
{
	return  *(mapped_sem + XILSEM_STATUS_OFFSET);
}

// Reset from IPIF interface to HW. Complete HW reset but not SEM IP reset
void xilsem_ipif_reset()
{
	*(mapped_sem + XILSEM_IPIF_RST_OFFSET) = XILSEM_IPIF_RESET_EXE;
}


// This function resets the HW counters that is necessary after every other command
void xilsem_nop()
{
	//*(SEM_BASE + SEM_CMD_REG_OFFSET) = NOP_EXE;
	*(mapped_sem + XILSEM_CMD_OFFSET) = XILSEM_NOP_EXE;
}

// SEM IP  will execute a Soft reset and re-initializes
void xilsem_reset()
{
	*(mapped_sem + XILSEM_CMD_OFFSET) = XILSEM_RESET_EXE;
}

// This puts the SEM IP into Idle mode necessary for error injection
void xilsem_idle()
{
	*(mapped_sem + XILSEM_CMD_OFFSET) = XILSEM_IDLE_EXE;

}

// SEM IP will perform error injection command on specified addresses
// in HW Address registers (using sem_inj_addr() function )
void xilsem_inj()
{
	*(mapped_sem + XILSEM_CMD_OFFSET) = XILSEM_INJ_EXE;
}

// This puts the SEM IP into Observation mode to detect errors
void xilsem_obs()
{
	*(mapped_sem + XILSEM_CMD_OFFSET) =XILSEM_OBS_EXE;
}

// This commands the SEM IP to give its status over its monitor interface
// Not usable because monitor interface of SEM IP is not used in this version
void xilsem_status()
{
	*(mapped_sem + XILSEM_CMD_OFFSET) = 0x80000000;
}

void xilsem_inject_error(uint32_t addr1, uint32_t addr2)
{	xilsem_nop();
	xilsem_idle();
	xilsem_nop();
	xilsem_inj_addr(addr1, addr2);
	xilsem_nop();
	xilsem_inj();
}

void xilsem_print_regs(){
	printf("CMD REG Address: %p , Value: 0x%x\n\r",(mapped_sem + XILSEM_CMD_OFFSET), *((volatile uint32_t*)mapped_sem + XILSEM_CMD_OFFSET));
	printf("STATUS REG Address: %p , Value: 0x%x\n\r",(mapped_sem + XILSEM_STATUS_OFFSET), *((volatile uint32_t*)mapped_sem + XILSEM_STATUS_OFFSET));
	printf("\tSTATUS REG Ready: %s\n\r", *((volatile uint32_t*)mapped_sem + XILSEM_STATUS_OFFSET) & (1 << XILSEM_STATUS_READY) ? "yes" : "no");
	printf("\tSTATUS REG Busy: %s\n\r", *((volatile uint32_t*)mapped_sem + XILSEM_STATUS_OFFSET) & (1 << XILSEM_STATUS_BUSY) ? "yes" : "no");
	printf("\tSTATUS REG IDLE_ACK_FLAG: %s\n\r", *((volatile uint32_t*)mapped_sem + XILSEM_STATUS_OFFSET) & (1 << XILSEM_STATUS_IDLE_ACK_FLAG) ? "on" : "off");
	printf("\tSTATUS REG INJ_ACK_FLAG: %s\n\r", *((volatile uint32_t*)mapped_sem + XILSEM_STATUS_OFFSET) & (1 << XILSEM_STATUS_INJ_ACK_FLAG) ? "on" : "off");
	printf("\tSTATUS REG OBS_ACK_FLAG: %s\n\r", *((volatile uint32_t*)mapped_sem + XILSEM_STATUS_OFFSET) & (1 << XILSEM_STATUS_OBS_ACK_FLAG) ? "on" : "off");
	printf("ADDR1 REG Address: %p , Value: 0x%x\n\r",(mapped_sem + XILSEM_ADDR1_OFFSET), *((volatile uint32_t*)mapped_sem + XILSEM_ADDR1_OFFSET));
	printf("ADDR2 REG Address: %p , Value: 0x%x\n\r",(mapped_sem + XILSEM_ADDR2_OFFSET), *((volatile uint32_t*)mapped_sem + XILSEM_ADDR2_OFFSET));
}
