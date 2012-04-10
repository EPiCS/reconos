/*
 * Copyright 2012 Andreas Agne <agne@upb.de>
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef FSL_H
#define FSL_H

#include <stdint.h>
#include "reconos.h"

#define FSL_MAX		SLOTS_MAX
#define FSL_PATH_MAX	256

extern void fsl_write(int num, uint32_t value);
extern uint32_t fsl_read(int num);

#endif /* FSL_H */
