/*
 * hwif.c
 *
 *  Created on: Mar 24, 2014
 *      Author: meise
 */

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>

#include "hwif.h"

char* dev_file_name = "/dev/mem";
int   dev_file;
uint32_t * mapped_hwif =NULL;
size_t mapped_size = 0;
unsigned int page_addr;
unsigned int page_offset;
unsigned int page_size;

size_t calc_mapped_size(){
	page_size = sysconf(_SC_PAGESIZE);
	size_t retval = C_HWIF_IF_COUNT * (1<< C_HWIF_ADDRESS_SPACE_BITS);

	/* check if requested size of mapping is a multiple of a page size,
	 * otherwise round up to page size
	 */
	if (retval % page_size){
		unsigned int pages= retval / page_size;
		pages ++;
		retval = pages * page_size;
	}
	return retval;
}

void hwif_init(){


	/* Open /dev/mem file */
	dev_file = open (dev_file_name, O_RDWR);
	if (dev_file < 1) {
		perror("HWIF");
		exit( EXIT_FAILURE);
	}

	/* calculate size of mapped area */
	mapped_size = calc_mapped_size();

	/* mmap the device into memory */
	page_addr = (C_HWIF_BASE_ADDRESS & (~(page_size-1)));
	page_offset = C_HWIF_BASE_ADDRESS - page_addr;
	mapped_hwif = mmap(NULL, mapped_size, PROT_READ|PROT_WRITE, MAP_SHARED, dev_file, page_addr);
	printf("Mapped physical address 0x%x to virtual address %p with length %zi .\n", page_addr, mapped_hwif, mapped_size);
	if (mapped_hwif == MAP_FAILED){
		perror("HWIF");
		exit( EXIT_FAILURE);
	}
}

void hwif_close(){
	munmap(mapped_hwif, mapped_size);
}


uint32_t hwif_read(uint32_t module_nr, uint32_t reg_nr){
	uint32_t * hwif_base = (uint32_t *)(mapped_hwif + page_offset);
	volatile uint32_t *retval_address =  hwif_base + module_nr*(1<<(C_HWIF_ADDRESS_SPACE_BITS-2))+reg_nr;
	//printf ("Reading address %p \n", retval_address);
	return *retval_address;
}

void hwif_write(uint32_t module_nr, uint32_t reg_nr, uint32_t value){
	uint32_t * hwif_base = (uint32_t *)(mapped_hwif + page_offset);
    volatile uint32_t *write_address =  hwif_base + module_nr*(1<<(C_HWIF_ADDRESS_SPACE_BITS-2))+reg_nr;
    //printf ("Writing to address %p \n", write_address);
    *write_address = value;
}


uint32_t perfmon_base_offset = 8; // in register, not byte offset
#define PERFMON_ID_REG_OFFSET    0
#define PERFMON_LEN_REG_OFFSET    1
#define PERFMON_CONF_REG_OFFSET  2
#define PERFMON_COUNT_REG_OFFSET    3

void hwif_perfmon_debug_print(uint32_t module_nr){
	int i;
	int mmap_length = hwif_read(module_nr,perfmon_base_offset+PERFMON_LEN_REG_OFFSET);
	for (i = 0; i < mmap_length/4; ++i) {
		printf("0x%08X ", hwif_read(module_nr,perfmon_base_offset+i));
		if (i%7 == 6){printf("\n");}
	}
	printf("\n");
}

void hwif_perfmon_reset(uint32_t module_nr){
	hwif_write(module_nr, perfmon_base_offset+PERFMON_CONF_REG_OFFSET, 0x1);
}

void hwif_perfmon_activate(uint32_t module_nr){
	uint32_t temp;
	printf("Activating perfmon %i\n",module_nr);
	temp = hwif_read(module_nr,perfmon_base_offset+PERFMON_CONF_REG_OFFSET);
	temp |= 0x2; // set enable bit;
	hwif_write(module_nr, perfmon_base_offset+PERFMON_CONF_REG_OFFSET, temp);
}

void hwif_perfmon_deactivate(uint32_t module_nr){
	uint32_t temp;
	temp = hwif_read(module_nr,perfmon_base_offset+PERFMON_CONF_REG_OFFSET);
	temp &= ~(0x2); // delete enable bit;
	hwif_write(module_nr, perfmon_base_offset+PERFMON_CONF_REG_OFFSET, temp);
}

uint8_t hwif_perfmon_get_number_of_counters(uint32_t module_nr){
	uint32_t temp;
	temp = hwif_read(module_nr,perfmon_base_offset+PERFMON_CONF_REG_OFFSET);
	temp >>= 24;
	return temp;
}

uint32_t hwif_perfmon_read_counter(uint32_t module_nr, uint8_t counter_nr){
	return hwif_read(module_nr,perfmon_base_offset+PERFMON_COUNT_REG_OFFSET+counter_nr);
}
