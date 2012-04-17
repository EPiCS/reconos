/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef ATOMIC_H
#define ATOMIC_H

static inline unsigned short atomic_preincrement_ushort(unsigned short x)
{
	return __sync_add_and_fetch(&x, 1);
}

static inline unsigned int atomic_preincrement_uint(unsigned int x)
{
	return __sync_add_and_fetch(&x, 1);
}

static inline unsigned short atomic_predecrement_ushort(unsigned short x)
{
	return __sync_sub_and_fetch(&x, 1);
}

static inline unsigned int atomic_predecrement_uint(unsigned int x)
{
	return __sync_sub_and_fetch(&x, 1);
}

#endif /* ATOMIC_H */
