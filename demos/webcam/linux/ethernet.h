#ifndef __ETHERNET_H__
#define __ETHERNET_H__

#include "config.h"
#include "frame_size.h"
#include <semaphore.h>


/*! \file ethernet.h 
 * \brief uses ethernet to establish a connection and to receive frames
 */

//! struct for image parameters
typedef struct image_params_t
{
	int nChannels;	         ///< number of channels
	int depth;		///< image depth per channel
	int width;		///< image width
	int height;		///< image height
}image_params_t;


unsigned int * framebuffer;

/**
	copies next frame to specific ram
*/
void read_frame( void );


/**
	sends frame from ram to tcp server
*/
void write_frame( void );


/**
	creates a server socket and waits for incomming connection.
	@param port: listen port for new data/frames
	@return returns a valid file descriptor on success. returns -1 on error.
*/
int accept_connection(int port);


/**
	establishes connection to ethernet
	@param port: port number for videotransfer
	@param params: pointer to image parameter struct
	@return returns '0' if connection is established, else '1'
*/
int establish_connection(int port, image_params_t * params);

#endif	 //__ETHERNET_H__
