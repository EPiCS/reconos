/////////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2004 Xilinx, Inc. All Rights Reserved.
//
// You may copy and modify these files for your own internal use solely with
// Xilinx programmable logic devices and  Xilinx EDK system or create IP
// modules solely for Xilinx programmable logic devices and Xilinx EDK system.
// No rights are granted to distribute any files unless they are distributed in
// Xilinx programmable logic devices.
//
/////////////////////////////////////////////////////////////////////////////////
#ifndef BL_PORTAB_H
#define BL_PORTAB_H

typedef unsigned char   uint8_t;
typedef unsigned short  uint16_t;
typedef unsigned int    uint32_t;

typedef char   int8_t;
typedef short  int16_t;
typedef int    int32_t;



/* An anonymous union allows the compiler to report typedef errors automatically */
/* Does not work with gcc. Might work only for g++ */

/* static union */
/* { */
/*     char int8_t_incorrect   [sizeof(  int8_t) == 1]; */
/*     char uint8_t_incorrect  [sizeof( uint8_t) == 1]; */
/*     char int16_t_incorrect  [sizeof( int16_t) == 2]; */
/*     char uint16_t_incorrect [sizeof(uint16_t) == 2]; */
/*     char int32_t_incorrect  [sizeof( int32_t) == 4]; */
/*     char uint32_t_incorrect [sizeof(uint32_t) == 4]; */
/* }; */



#endif /* BL_PORTTAB_H */
