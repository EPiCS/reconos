/*
 * bootloader.c
 *
 *  Created on: May 24, 2013
 *      Author: meise
 */
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <mb_interface.h>
#include <reconos.h>

#define PROG_DESTINATION 0x800
#define MEMORY_END 0xFFFF
int (*prog_entry)();

/*
 * Sends download request for software to main processor, downloads it
 * via FSL and jumps to it.
 *
 * @warning: The bootloader is designed to live in the first 2kB of
 * MicroBlaze memory. Stack size is limited to 256 bytes. See linker
 * script for details and if you want to change things.
 */
int main (void) {
	int i;
	uint32_t prog_size = 0;
	uint32_t * prog_dest = (uint32_t*)PROG_DESTINATION;
	uint32_t prog_word = 0;

	putfsl(OSIF_CMD_THREAD_LOAD_PROGRAM, OSIF_FSL );
	getfsl(prog_size, OSIF_FSL );
	for ( i=0; i < ((prog_size/sizeof(uint32_t))); i++){
		getfsl(prog_word, OSIF_FSL);
		*prog_dest = prog_word;
		prog_dest ++;
	}
	prog_entry = (void*)PROG_DESTINATION;
	prog_entry(); // should not return
	return 0;
}

void null_handler(){
	while (1){};
}
