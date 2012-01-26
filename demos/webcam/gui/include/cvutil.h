///
/// \file  cvutil.h
/// Utility functions for use with the OpenCV library.
/// 
/// Part of the ReconOS netimage tools to send and receive image
/// data to and from a ReconOS board. 
/// 
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       12.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group 
//
// (C) Copyright University of Paderborn 2007. Permission to copy,
// use, modify, sell and distribute this software is granted provided
// this copyright notice appears in all copies. This software is
// provided "as is" without express or implied warranty, and with no
// claim as to its suitability for any purpose.
//
// -------------------------------------------------------------------------
// Major Changes:
// 
// 12.09.2007   Enno Luebbers   File created
// 
#ifndef __CVUTIL_H__
#define __CVUTIL_H__

// INCLUDES ================================================================

/* from OpenCV */
#include "highgui.h"

// FUNCTION PROTOTYPES =====================================================

///
/// Prints the properties of a CvCapture structure.
///
/// \param      capture      the CvCapture structure to examine
///
void printCaptureProperties( CvCapture *capture );

///
/// Converts a string containing a FOURCC code to an integer.
///
/// \param    a      string to convert
///
/// \returns   the corresponding integer
///
int atofourcc(char *a);

#endif
