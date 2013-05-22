/*
 * workerreset.c
 *
 *  Created on: Apr 24, 2013
 *      Author: meise
 */


#include "reconos.h"
#include "fsl.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>

#define WORKERCPU_SLOT 0

void reconos_slot_reset(int num, int reset);

int main(int argc, char ** argv)
{
	if (argc != 2){
		printf("No arguments given!\n");
		return 1;
	}

	int i=0;
	for (i = 0; i<16; i++){
		reconos_slot_reset(i, atoi(argv[1]));
	}


	return 0;
}

