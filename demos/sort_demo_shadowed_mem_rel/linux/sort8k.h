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

void *sort_thread(void* data);
void *sort_thread_messages(void* data);

#endif
