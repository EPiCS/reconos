/*
 * fault_injection.c
 *
 *  Created on: 15.03.2013
 *      Author: meise
 */


#include "reconos.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#define  _GNU_SOURCE
#include <string.h>


int main (int argc, char ** argv){
	reconos_init_autodetect();
	reconos_faultinject(0, 0x00000000, 0x00000000);
	reconos_faultinject(1, 0x00000000, 0x00000000);
	return 0;
}
