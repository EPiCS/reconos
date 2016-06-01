///
/// \file sort8k.h
/// eCos thread entry function for sorting thread.
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//

#ifndef __SORT8K_H__
#define __SORT8K_H__

#ifndef cyg_addrword_t
#define cyg_addrword_t unsigned int
#endif

void bubblesort( unsigned int *array, unsigned int len );
void sort8k_entry( cyg_addrword_t data );
#ifndef USE_ECOS
void *sort8k_entry_posix( void *data );
#endif

#endif
