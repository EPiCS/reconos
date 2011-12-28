///
/// \file data.h
/// Data generation and verification functions.
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//

#ifndef __DATA_H__
#define __DATA_H__

// generates an array of random values
void generate_data( unsigned int *array, unsigned int size );

// checks whether data is sorted
int check_data( unsigned int *data, unsigned int size );

#endif                          //__DATA_H__
