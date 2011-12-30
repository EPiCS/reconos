///
/// \file config.h
/// Configuration constants
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//

#ifndef __CONFIG_H__
#define __CONFIG_H__

//
// Common options for all implementations
//
/// number of words per block
#define N (8192/sizeof(unsigned int)) //(8192/sizeof(unsigned int))
/// total number of words to sort
#define SIZE N//(128*N)
//#define SIZE (10*N)


#endif
