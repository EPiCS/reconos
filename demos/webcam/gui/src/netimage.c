///
/// \file  netimage.c
/// Utility functions for transferring OpenCV images across a TCP/IP
/// connection.
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

#include "netimage.h"
#include "debug.h"


// FUNCTION DEFINITIONS ====================================================

//
// Transmits parts of an IplImage header across a tcp_connection.
//
// The transmitted info consists of image resolution, depth, and
// number of channels.
//
int netimage_send_header( tcp_connection * con, IplImage * img )
{
	image_params p;
	int result;

	DEBUG_ENTRY( "netimage_send_header()" )
	assert( con != NULL );
	assert( img != NULL );

	p.nChannels = htonl(img->nChannels);
	p.depth = htonl(img->depth);
	p.width = htonl(img->width);
	p.height = htonl(img->height);

	result = tcp_send( con, (unsigned char*)&p, sizeof( p ) );

	DEBUG_EXIT( "netimage_send_header()" )

	return result;
}


//
// Receives parts of an IplImage header across a tcp_connection.
//
// The transmitted info consists of image resolution, depth, and
// number of channels.
//
int netimage_recv_header( tcp_connection * con, image_params * params, size_t len )
{

	int result;

	DEBUG_ENTRY( "netimage_recv_header()" )
	assert( con != NULL );
	assert( params != NULL );
	assert( len == sizeof( image_params ) );

	result = tcp_receive( con, ( unsigned char * ) params, len );

	DEBUG_EXIT( "netimage_recv_header()" )

	return result;

}


//
// Allocate a new IplImage from received header information
//
// Uses cvCreateImage(). The image needs to be deallocated after use
// via cvReleaseImage().
//
IplImage *netimage_CreateImageFromHeader( image_params * params )
{
	IplImage *result;
	DEBUG_ENTRY( "netimage_CreateImageFromHeader()" )
	assert( params != NULL );
	result = cvCreateImage( cvSize( htonl(params->width), htonl(params->height) ),
		htonl(params->depth), htonl(params->nChannels) );
	DEBUG_EXIT( "netimage_CreateImageFromHeader()" )
	return result;
}

//
// Allocate a new IplImage from received header information (FPGA replacement)
//
// Uses cvCreateImage(). The image needs to be deallocated after use
// via cvReleaseImage().
//
IplImage *netimage_CreateImageFromHeader2( image_params * params )
{
	IplImage *result;
	DEBUG_ENTRY( "netimage_CreateImageFromHeader()" )
	assert( params != NULL );
	result = cvCreateImage( cvSize( htonl(params->width), htonl(params->height) ),
		htonl(params->depth), htonl(params->nChannels) );
	DEBUG_EXIT( "netimage_CreateImageFromHeader()" )
	return result;
}



