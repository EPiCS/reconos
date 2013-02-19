///
/// \file check_intervals.h
/// Header file of functions to calculate the intervals of maximum covering
/// out of a given set of intervals.
/// \author     Sebastian Meisner   <sebastian.meisner@upb.de>
/// \date       11.07.2011
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2011.
//


#ifndef MAX_COVERING_INTERVALS_H_
#define MAX_COVERING_INTERVALS_H_

typedef struct interval {
    unsigned int low;
    unsigned int high;
    unsigned int members; // Bitmask
} interval_t;

int calc_max_covering_intervals(unsigned int * input_intervals,
		  unsigned int  input_length,
		  interval_t * max_covering_intervals,
		  unsigned int max_covering_intervals_length);

void print_check_intervals(interval_t * intervals, unsigned int length);

#endif /* MAX_COVERING_INTERVALS_H_ */
