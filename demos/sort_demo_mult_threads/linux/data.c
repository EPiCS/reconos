///
/// \file data.c
/// Data generation and verification functions
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include "data.h"


// generates an array of random values
void generate_data( unsigned int *array, unsigned int size )
{
    unsigned int i;

    //srandom( time( 0 ) );
    for ( i = 0; i < size; i++ ) {
        array[i] = 1000+(size-i-1); //( unsigned int ) random(  );
    }
}

// checks whether data is sorted
int check_data( unsigned int *data, unsigned int size )
{
    int i;
    
    for ( i = 0; i < size - 1; i++ ) {
        if ( data[i] > data[i + 1] ) {
            return -i;
        }
    }
    return 0;
}
