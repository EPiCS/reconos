/*
 * hwif_tool.c
 *
 *  Created on: Mar 24, 2014
 *      Author: meise
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include "hwif.h"

int main(int argc, char **argv) {
	int i;
	puts("Starting hwif_tool...\n");

	puts("Opening HWIF...\n");
	hwif_init();

	puts("Reading first bytes...\n");
	for (i = 0; i < 6; ++i) {
		printf("Read Byte %i: 0x%x\n",i , hwif_read(0,i));
	}

	puts("Writing to first bytes...\n");
	for (i = 0; i < 6; ++i) {
		printf("Write Byte %i to register %i\n",i , i);
		hwif_write(0,i,i);
	}

	puts("Reading first bytes...\n");
	for (i = 0; i < 6; ++i) {
		printf("Read Byte %i: 0x%x\n",i , hwif_read(0,i));
	}

	puts("Closing HWIF...\n");
	hwif_close();

	return EXIT_SUCCESS;

}
