/*
 * slot_map.h
 *
 *  Created on: Mar 18, 2015
 *      Author: meise
 */

#ifndef SLOT_MAP_H_
#define SLOT_MAP_H_

#include <stdio.h>
#include <string.h>

extern char * actual_slot_map[];

int slot_map_find(char * const  map[], const char * hwt_type, int nth);
void slot_map_print(char * const  map[]);

#endif /* SLOT_MAP_H_ */
