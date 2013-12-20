/*-----------------------------------------------------------------------------
//
//         XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"
//         SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR
//         XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION
//         AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION
//         OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS
//         IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,
//         AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE
//         FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY
//         WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE
//         IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
//         REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF
//         INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//         FOR A PARTICULAR PURPOSE.
//         
//         (c) Copyright 2006 Xilinx, Inc.
//         All rights reserved.
//
//      Revision History:
//      1.0     seg  2005/07/07  no changes from 405
//
//---------------------------------------------------------------------------*/

#include <sys/stat.h>

/*
 * fstat -- Since we have no file system, we just return an error.
 */
int fstat(int fd, struct stat *buf)
{
  buf->st_mode = S_IFCHR; /* Always pretend to be a tty */

  return (0);
}
