/*
 * xilsem_slice2physical.h
 *
 *  Created on: 26.10.2015
 *      Author: meise
 */

#ifndef XILSEM_SLICE2PHYSICAL_H_
#define XILSEM_SLICE2PHYSICAL_H_

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

typedef struct {
	uint8_t type;
	uint8_t half;
	uint8_t row;
	uint8_t column;
	uint8_t minor;
	uint8_t word;
	uint8_t bit;
} physical_address_t;

typedef struct {
	uint8_t x;
	uint8_t y;
} slice_address_t;

physical_address_t slice2physical(slice_address_t sa);

bool are_same_physical_addresses(physical_address_t a, physical_address_t b);
void print_physical_address(physical_address_t pa);
void print_slice_address(slice_address_t sa);

#endif /* XILSEM_SLICE2PHYSICAL_H_ */
