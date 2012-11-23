#ifndef FSL_H
#define FSL_H

#include "xmk.h"
#include "sys/init.h"
#include "mb_interface.h"

int fsl_read(int id);
void fsl_write(int id, int val);


#endif
