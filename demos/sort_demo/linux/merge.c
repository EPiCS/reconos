///
/// \file merge.c
/// Merge functions
///
/// \author	 Enno Luebbers   <luebbers@reconos.de>
/// \date	 28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//
#include "config.h"
#include "merge.h"

//#define N 8192/sizeof(unsigned int)
#define SRC_SIZE = N/4;
#define DST_SIZE = N/2;


void simple_merge( merge_info * mi )
{
	unsigned int n = 0, l = 0, r = 0;
	unsigned int *left = mi->left;
	unsigned int *right = mi->right;
	unsigned int *result = mi->result;

	while ( n < mi->blocksize * 2 ) {
		if ( r >= mi->blocksize || ( l < mi->blocksize && *left <= *right )) 
		{
			*result = *left;
			left++;
			l++;
		}
		else 
		{
			*result = *right;
			right++;
			r++;
		}
		result++;
		n++;
	}

	// thread_exit();
}

// recursively merge data using 'mergefun'
unsigned int *recursive_merge( unsigned int *data, unsigned int *result,
	unsigned int size, unsigned int blocksize, void ( *mergefun ) ( merge_info * mi ) )
{
	int i;

	if ( size == blocksize ) 
	{
		return data;
	} 
	else 
	{
		for ( i = 0; i < size / blocksize; i += 2 ) 
		{
			merge_info mi;
			mi.left = &data[i * blocksize];
			mi.right = &data[( i + 1 ) * blocksize];
			mi.blocksize = blocksize;
			mi.result = &result[i * blocksize];
			mergefun( &mi );  // NOTE: mi exists only in this "for"'s scope!
		}
		return recursive_merge( result, data, size, blocksize * 2, mergefun );
	}
}


void merge_entry( cyg_addrword_t data )
{
	simple_merge( ( merge_info * ) data );
}

