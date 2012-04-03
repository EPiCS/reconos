#ifndef FSL_H
#define FSL_H

#include <stdint.h>

extern void fsl_write(int num, uint32_t value);
extern uint32_t fsl_read(int num);

#endif /* FSL_H */
