/*
 ============================================================================
 Author      : Sebastian Meisner
 Version     :
 Copyright   : University Paderborn
 Description : address translation function from slice address range to physical addresses
 ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include "xilsem_slice2physical.h"

#define u16 uint16_t
/*
 * The following array is taken from xhwicap.c from Xilinx EDK.
 */
u16 XHI_XC6VLX240T_SKIP_COLS[] = {5, 8, 13, 16, 25, 28, 33, 36, 41, 52, 57,
				62, 65, 70, 73, 82, 85, 90, 93, 101, 102,
				0xFFFF};

/*
 * The following information is directly extracted from planaheads device view
 */
//static uint16_t slice_x_min = 0;
//static uint16_t slice_x_max = 161;
//static uint16_t slice_y_min = 0;
//static uint16_t slice_y_max = 239;
static uint16_t slice_row_height = 40;
static uint16_t slices_per_clb = 2;
static uint16_t slices_y_max_bottom_half  = 119; // bottom half runs from 0 to 110 in slice y coordinate

static uint16_t row_max = 2;

static uint8_t count_skipped_colums (uint8_t slice_x){
	uint8_t count = 0;
	while (XHI_XC6VLX240T_SKIP_COLS[count] != 0xFFFF){
		if ( ((slice_x/slices_per_clb)+1) < XHI_XC6VLX240T_SKIP_COLS[count]){
			break;
		} else {
			count ++;
			slice_x+=2;
		}
	}
	return count;
}

#define CLB_IO_CLK_TYPE 0
#define BLOCK_RAM_TYPE  1
#define CFG_CLB_TYPE    2
physical_address_t slice2physical(slice_address_t sa){
	physical_address_t pa;

	pa.type = CLB_IO_CLK_TYPE;

	// Conversion of slice x
	pa.column = (sa.x / slices_per_clb)+1+ count_skipped_colums(sa.x);

	// Conversion of slice y
	pa.half = ( sa.y <= slices_y_max_bottom_half ) ? 1 : 0;

	if (pa.half == 0){
		// top half
		pa.row  =(sa.y-slices_y_max_bottom_half)/slice_row_height;
	} else {
		// bottom half
		pa.row  = row_max-(sa.y/slice_row_height);
	}

	pa.minor = 0; // unknown up to date. Needs more experiments...
	pa.word  = 0; // word address inside one configuration frame
	pa.bit   = 0; // bit inside one word of a configuration frame

	return pa;
}

bool are_same_physical_addresses(physical_address_t a, physical_address_t b){
	if (
			(a.type == b.type) &&
			(a.half == b.half) &&
			(a.row  == b.row ) &&
			(a.column == b.column) &&
			(a.minor== b.minor) &&
			(a.word == b.word) &&
			(a.bit  == b.bit)
	){ return true;}
	else { return false; }
}

void print_physical_address(physical_address_t pa){
	printf("Type %1hhu Half %1hhu Row %1hhu Column %3hhu Minor %3hhu Word %3hhu Bit %3hhu\n",
			pa.type, pa.half, pa.row, pa.column, pa.minor, pa.word, pa.bit);
}

void print_slice_address(slice_address_t sa){
	printf("X%02hhu Y%02hhu\n", sa.x, sa.y);
}

#if 0
/*
 * Application example
 */

int main(void) {
	puts("Xilinx Virtex 6 address translation tool version 0.1");

	/*
	 * Some tests
	 */

	// Test data
	slice_address_t sa[] = {
			{53, 185}, // heater0 top right
			{30, 162}, // heater0 bottom left
			{13,119}, // heater1 top right
			{0, 80}, // heater1 bottom left
			{27,119}, // heater2 top right
			{14, 80}, // heater2 bottom left
			{23,78}, // heater3 top right
			{0,55}, // heater3 bottom left
			{27,160}, // heater4 top right
			{14,121}, // heater4 bottom left
			{13,160}, // heater5 top right
			{0,121}, // heater5 bottom left
			{255, 255} // end of list marker
	};

	// expected answers, read manually from planahead and from partial bitstreams
	// Minor address specification still unknown
	physical_address_t pa[] = {
			// Type, Half, Row, Column, Minor, Word, Bit
			{0, 0, 1, 34, 0, 0, 0}, // heater0 top right
			{0, 0, 1, 20, 0, 0, 0}, // heater0 bottom left
			{0, 1, 0, 9, 0, 0, 0}, // heater1 top right
			{0, 1, 0, 1, 0, 0, 0}, // heater1 bottom left
			{0, 1, 0, 18, 0, 0, 0}, // heater2 top right
			{0, 1, 0, 10, 0, 0, 0}, // heater2 bottom left
			{0, 1, 1, 15, 0, 0, 0}, // heater3 top right
			{0, 1, 1, 1, 0, 0, 0}, // heater3 bottom left
			{0, 0, 1, 18, 0, 0, 0}, // heater4 top right
			{0, 0, 0, 10, 0, 0, 0}, // heater4 bottom left
			{0, 0, 1, 9, 0, 0, 0}, // heater5 top right
			{0, 0, 0, 1, 0, 0, 0}, // heater5 bottom left
			{255,255,255,255,255,255,255} // end of list marker
	};

	physical_address_t pa_temp;

	puts("###################");
	int i = 0;
	while ( (sa[i].x != 255) && (sa[i].y != 255) ) {
		pa_temp = slice2physical(sa[i]);
		print_slice_address(sa[i]);
		print_physical_address(pa_temp);
		if (are_same_physical_addresses(pa_temp, pa[i])){
			printf("Result correct\n");
		} else {
			printf("Result WRONG!\n");
			print_physical_address(pa[i]);
		}
		puts("###################");
		i++;
	}

	return EXIT_SUCCESS;
}
 * xilsem_slice2physical.c
 *
 *  Created on: 26.10.2015
 *      Author: meise
 */
#endif
