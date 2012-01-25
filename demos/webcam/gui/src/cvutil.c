///
/// \file  cvutil.c
/// Utility functions for use with the OpenCV library.
/// 
/// Part of the ReconOS netimage tools to send and receive image
/// data to and from a ReconOS board. 
/// 
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       12.09.2007
//
// For detailed documentation of the functions, see the associated header
// file or the documentation.
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

// INCLUDES ================================================================

#include <assert.h>
#include <stdio.h>

#include "cvutil.h"


// FUNCTION DEFINITIONS ====================================================

//
// Prints the properties of a CvCapture structure.
//
void printCaptureProperties( CvCapture * capture )
{

	assert( capture != NULL );

	printf( "Capture properties of CvCapture at 0x%08lX:\n"
		"CV_CAP_PROP_POS_MSEC     : %f\n"
		"CV_CAP_PROP_POS_FRAMES   : %f\n"
		"CV_CAP_PROP_POS_AVI_RATIO: %f\n"
		"CV_CAP_PROP_FRAME_WIDTH  : %f\n"
		"CV_CAP_PROP_FRAME_HEIGHT : %f\n"
		"CV_CAP_PROP_FPS          : %f\n"
		"CV_CAP_PROP_FOURCC       : %f\n"
		"CV_CAP_PROP_FRAME_COUNT  : %f\n",
		//( unsigned int ) capture,
		( uint64 ) capture,
		cvGetCaptureProperty( capture, CV_CAP_PROP_POS_MSEC ),
		cvGetCaptureProperty( capture, CV_CAP_PROP_POS_FRAMES ),
		cvGetCaptureProperty( capture, CV_CAP_PROP_POS_AVI_RATIO ),
		cvGetCaptureProperty( capture, CV_CAP_PROP_FRAME_WIDTH ),
		cvGetCaptureProperty( capture, CV_CAP_PROP_FRAME_HEIGHT ),
		cvGetCaptureProperty( capture, CV_CAP_PROP_FPS ),
		cvGetCaptureProperty( capture, CV_CAP_PROP_FOURCC ),
		cvGetCaptureProperty( capture, CV_CAP_PROP_FRAME_COUNT ) );
}

//
// Converts a string containing a FOURCC code to an integer.
//
int atofourcc( char *a )
{
	return CV_FOURCC( a[0], a[1], a[2], a[3] );
}
