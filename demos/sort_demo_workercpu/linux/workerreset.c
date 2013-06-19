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
	if (argc != 3){
		printf("Too few arguments given! workerreset <slot> <resetstate>\n");
		return 1;
	}
	printf ("Setting slot %i to %i\n", atoi(argv[1]), atoi(argv[2]));
	reconos_init_autodetect();
	reconos_slot_reset(atoi(argv[1]), atoi(argv[2]));

	return 0;
}

