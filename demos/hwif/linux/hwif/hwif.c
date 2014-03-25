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
	uint32_t *retval_address =  hwif_base + module_nr*(1<<(C_HWIF_ADDRESS_SPACE_BITS-2))+reg_nr;
	printf ("Reading address %p ", retval_address);
	return *retval_address;
}

void hwif_write(uint32_t module_nr, uint32_t reg_nr, uint32_t value){
	uint32_t * hwif_base = (uint32_t *)(mapped_hwif + page_offset);
    uint32_t *write_address =  hwif_base + module_nr*(1<<(C_HWIF_ADDRESS_SPACE_BITS-2))+reg_nr;
    printf ("Writing to address %p ", write_address);
    *write_address = value;
}
