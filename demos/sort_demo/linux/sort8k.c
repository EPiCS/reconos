///
/// \file sort8k.c
/// eCos thread entry function for sorting
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//


#include "mbox.h"
#include "config.h"
#include "bubblesort.h"
#include "sort8k.h"

#include <stdio.h>

extern struct mbox_t hw2sw,sw2hw;



#ifndef USE_ECOS
void* sort8k_entry( void * arg ) {
	void *ptr;
	unsigned int dummy = 23;

	while ( 1 ) {
		ptr = mbox_get(mb_start, (void*)&ptr, sizeof(ptr), 0);
		//fprintf(stderr, "*");
		bubblesort( (unsigned int*) ptr, N);
		mbox_put(ptr);
	}
}
#endif

