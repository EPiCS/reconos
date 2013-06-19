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

void entry (void) {
	int i;
	uint32_t prog_size = 0;
	uint32_t * prog_dest = (uint32_t*)PROG_DESTINATION;
	uint32_t prog_word = 0;

	putfsl(OSIF_CMD_THREAD_LOAD_PROGRAM, OSIF_FSL );
	getfsl(prog_size, OSIF_FSL );
	for ( i=0; i < ((prog_size/sizeof(uint32_t))); i++){
		getfsl(prog_word, OSIF_FSL);
		*prog_dest = prog_word;
		//putfsl(prog_dest, OSIF_FSL);
		prog_dest ++;
	}
	//putfsl(0xDEADBEEF, OSIF_FSL);
	prog_entry = (void*)PROG_DESTINATION;
	//putfsl(prog_entry, OSIF_FSL);
	prog_entry();
}

void null_handler(){
	while (1){};
}
