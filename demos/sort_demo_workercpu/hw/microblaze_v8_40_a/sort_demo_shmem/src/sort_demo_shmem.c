/*
 * Copyright (c) 2009 Xilinx, Inc.  All rights reserved.
 *
 * Xilinx, Inc.
 * XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A
 * COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
 * ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
 * STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
 * IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
 * FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
 * XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
 * THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
 * ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
 * FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.
 *
 */

/*
 * helloworld.c: simple test application
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <limits.h>
#include <mb_interface.h>
#include "reconos.h"
#include "bubblesort.h"

void print(char *str);

struct mbox mbox_recv = {0};
struct mbox mbox_send = {1};

#define BUFFER_SIZE_WORDS 2048
unsigned int buffer[BUFFER_SIZE_WORDS];

uint32_t data_size_words;
unsigned int * data_address;
uint32_t dummy= 23;

int main() {
	while (1) {
		pthread_yield();
		data_size_words = mbox_get(&mbox_recv);

		if ( data_size_words == UINT_MAX) {
			mbox_put(&mbox_send, dummy);
			pthread_exit(NULL);
		}

		data_address = (unsigned int*) mbox_get(&mbox_recv);
		memif_read(data_address, buffer, data_size_words*sizeof(uint32_t));

		bubblesort(buffer, data_size_words);
		//int i;
		//for(i=0; i < BUFFER_SIZE_WORDS; i++){
		//	buffer[i] = 0x1337;
		//}

		memif_write(buffer, data_address, data_size_words*sizeof(uint32_t));
		mbox_put(&mbox_send, dummy);
	}

	return 0;
}
