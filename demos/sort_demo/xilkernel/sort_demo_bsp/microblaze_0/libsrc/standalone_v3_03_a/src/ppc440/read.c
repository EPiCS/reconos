////////////////////////////////////////////////////////////////////////////////
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
//     History Revision
//     1.0     seg     2005/07/07 - no changes made
//
// $Id: read.c,v 1.1.2.1 2011/05/17 04:37:50 sadanan Exp $
////////////////////////////////////////////////////////////////////////////////

/* read.c -- read bytes from a input device.
 */

extern char inbyte(void);

/*
 * read  -- read bytes from the serial port. Ignore fd, since
 *          we only have stdin.
 */
int
read (int fd, char* buf, int nbytes)
{
  int i = 0;

  for (i = 0; i < nbytes; i++) {
    *(buf + i) = inbyte();
    if ((*(buf + i) == '\n' || *(buf + i) == '\r')) 
        break;
  }
  
  return (i + 1);
}
