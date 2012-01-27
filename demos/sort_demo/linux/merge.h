///
/// \file merge.h
/// Data merge functions.
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//

#ifndef __MERGE_H__
#define __MERGE_H__

#ifndef cyg_addrword_t
#define cyg_addrword_t unsigned int
#endif

typedef struct {

    unsigned int *left;
    unsigned int *right;
    unsigned int blocksize;
    unsigned int *result;

} merge_info;

void simple_merge( merge_info * mi );
void merge_entry( cyg_addrword_t data );
unsigned int *recursive_merge( unsigned int *data, unsigned int *result,
                               unsigned int size, unsigned int blocksize,
                               void ( *mergefun ) ( merge_info * mi ) );

#endif                          // __MERGE_H__
