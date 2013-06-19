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
#include <mb_interface.h>
#include "reconos.h"
#include "bubblesort.h"

void print(char *str);

rqueue rqueue_recv = 0;
rqueue rqueue_send = 1;

#define BUFFER_SIZE_WORDS 2048
unsigned int buffer[BUFFER_SIZE_WORDS];

int main()
{

	while (1){
		(void) rq_receive(&rqueue_recv, (uint32_t*) buffer, BUFFER_SIZE_WORDS*sizeof(unsigned int));

		bubblesort( (unsigned int*) buffer, BUFFER_SIZE_WORDS);

		rq_send(&rqueue_send, (uint32_t*) buffer, BUFFER_SIZE_WORDS*sizeof(unsigned int));

	}


    return 0;
}
