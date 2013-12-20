////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2004 Xilinx, Inc.  All rights reserved.
//
// Xilinx, Inc.
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A
// COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
// ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
// STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
// IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
// FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
// XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
// THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
// ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
// FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE.
//
// $Id: bufmalloc.h,v 1.1.2.1 2011/08/25 12:12:51 anirudh Exp $
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------------//
//! @file bufmalloc.h
//! Declarations and defines for block memory allocation API
//----------------------------------------------------------------------------------------------------//
#ifndef _BUFMALLOC_H
#define _BUFMALLOC_H

#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

#define MEMBUF_ANY      -1

typedef int membuf_t;

int     sys_bufcreate  (membuf_t *mbuf, void *memptr, int nblks, size_t blksiz);
int     sys_bufdestroy (membuf_t mbuf);
void*   sys_bufmalloc  (membuf_t mbuf, size_t siz);
void    sys_buffree    (membuf_t mbuf, void *mem);

int     bufcreate  (membuf_t *mbuf, void *memptr, int nblks, size_t blksiz);
int     bufdestroy (membuf_t mbuf);
void*   bufmalloc  (membuf_t mbuf, size_t siz);
void    buffree    (membuf_t mbuf, void *mem);

#ifdef __cplusplus
}       
#endif 

#endif /* _BUFMALLOC_H */
