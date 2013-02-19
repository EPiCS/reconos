///
/// \file check_intervals.c
/// Implementation file of functions to calculate the intervals of maximum covering
/// out of a given set of intervals.
/// \author     Sebastian Meisner   <sebastian.meisner@upb.de>
/// \date       11.07.2011
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2011.
//


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "max_covering_intervals.h"

#define DEBUG 1

#ifdef DEBUG
    #define MCI_DEBUG(message) printf("MCI: " message)
    #define MCI_DEBUG1(message, arg1) printf("MCI: " message, (arg1))
    #define MCI_DEBUG2(message, arg1, arg2) printf("MCI: " message, (arg1), (arg2))
    #define MCI_DEBUG3(message, arg1, arg2, arg3) printf("MCI: " message, (arg1), (arg2), (arg3))
    #define MCI_DEBUG4(message, arg1, arg2, arg3, arg4) printf("MCI: " message, (arg1), (arg2), (arg3), (arg4))
#else
    #define MCI_DEBUG(message)
    #define MCI_DEBUG1(message, arg1)
    #define MCI_DEBUG2(message, arg1, arg2)
    #define MCI_DEBUG3(message, arg1, arg2, arg3)
    #define MCI_DEBUG4(message, arg1, arg2, arg3, arg4)
#endif

static int uint_compare(const void *a, const void *b){

	// Why not just return a-b? Because 0-UINT_MAX overflows a signed integer.

	if (*((unsigned int*)a) < *((unsigned int*)b)){
		return -1;
	}else if (*((unsigned int*)a) > *((unsigned int*)b)){
		return 1;
	}else {
		return 0;
	}
}

// Assumptions:
// - the borders array contain the intervals pairwise, e.g. {l1, h1, l2, h2, ...}
// - the length of the borders array therefore is always even
// - it has to hold: l_i <= h_i
// - to get recognized as a member, its interval has to fully enclose the low and high borders.
static unsigned int calc_members(unsigned int * intervals,
								 unsigned int length, // of borders array
								 unsigned int low,
								 unsigned int high)
{
	unsigned int members=0;
	unsigned int i;
	MCI_DEBUG2("calc_members intervals: intervals:%p length: %u\n", intervals, length);
	if(intervals && (length % 2 == 0)){
		for ( i = 0; i < length; i+=2){
			MCI_DEBUG4("calc_members intervals: %u %u borders: %u %u\n", intervals[i], intervals[i+1], low, high);
			if( intervals[i] <= low && intervals[i+1] >= high ){
				members += (1<<(i/2));
			}
		}
		return members;
	} else {
		return 0;
	}

}


// An input field of length n, results in an output field of length n-1
// Return value of 1 indicates success, return value of -1 indicates an error in parameter list
int calc_max_covering_intervals(unsigned int * input_intervals,
						  unsigned int  input_length,
						  interval_t * max_covering_intervals,
						  unsigned int max_covering_intervals_length)
{
	int i;
	unsigned int sorted_borders[input_length];
	if(input_intervals && max_covering_intervals && input_length == max_covering_intervals_length+1){
		// Prepare sorted borders array and sort it
		memcpy(sorted_borders, input_intervals, sizeof(sorted_borders));
		qsort(sorted_borders, input_length, sizeof(unsigned int), uint_compare);

		// Fill intervals array
		for ( i = 0; i< max_covering_intervals_length; i++){
			if (sorted_borders[i] == sorted_borders[i+1]){
				// Skip empty intervals
				max_covering_intervals[i].low = 0;
				max_covering_intervals[i].high = 0;
				max_covering_intervals[i].members = 0;
			}else {
				max_covering_intervals[i].low  = sorted_borders[i];
				max_covering_intervals[i].high = sorted_borders[i+1];
				max_covering_intervals[i].members = calc_members(input_intervals, input_length, max_covering_intervals[i].low, max_covering_intervals[i].high);
			}
		}
		return 1;
	} else {
		return -1;
	}

}

void print_check_intervals(interval_t * intervals, unsigned int length){
	int i,j;
	unsigned int members;

	for(i = 0; i < length; i++){
		printf("Interval: %d - %d, Members: ", intervals[i].low, intervals[i].high);
		members = intervals[i].members;

		// for every bit in an unsigned int
		for ( j = 0; j < sizeof(unsigned int)*8; j++){
			if (members & 1){printf("%d ", j);}
			members >>= 1;
		}
		printf("\n");
	}

}
