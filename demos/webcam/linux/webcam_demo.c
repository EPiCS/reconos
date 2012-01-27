#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <math.h>

// ReconOS
#include "reconos.h"
#include "mbox.h"

// Application Header
#include "config.h"
#include "ethernet.h"
#include "filter.h"
#include "frame_size.h"

//! main pthread
pthread_t ethernet_thread; 
pthread_attr_t ethernet_thread_attr;

//! sw threads for graphical filter threads
pthread_t filter_thread_1; 
pthread_attr_t filter_thread_1_attr;

pthread_t filter_thread_2; 
pthread_attr_t filter_thread_2_attr;

// hw threads
struct reconos_hwt hwt_filter_1;
struct reconos_hwt hwt_filter_2;

struct reconos_resource res_1[2];
struct reconos_resource res_2[2];

// image parameters
image_params_t  image_params;

// message boxes
struct mbox  mb_start_filter_1, mb_start_filter_2, mb_done_filtering;

unsigned int * init_data;
int fd;




/**
 * This SW thread that filters an image (no. 1)
 *
 * @param data: entry data for thread (e.g. an address)
 */
void * filter_1_function(void * data)
{
	unsigned int ret;

	while (42)
	{
		ret = mbox_get( &mb_start_filter_1);
		apply_mirror_filter( (unsigned int *)ret, SIZE_X, SIZE_Y);
		mbox_put( &mb_start_filter_2, ( uint32 ) ret );
	}
	return NULL;
}


/**
 * This SW thread that filters an image (no. 2)
 *
 * @param data: entry data for thread (e.g. an address)
 */
void * filter_2_function(void * data)
{
	unsigned int ret;

	while (42)
	{
		ret = mbox_get( &mb_start_filter_2);
		apply_sobel_filter( (unsigned int *)ret, SIZE_X, SIZE_Y);
		mbox_put( &mb_done_filtering, ( uint32 ) ret );
	}
	return NULL;
}




/**
 * This SW thread that receives and sends frames from/to a TCP server
 *
 * @param data: entry data for thread (e.g. an address)
 */
void * ethernet_function(void * data)
{
	unsigned int ret = (unsigned int) framebuffer;
	while (42)
	{
		read_frame();
		cache_flush();
		mbox_put( &mb_start_filter_1, ( uint32 ) framebuffer );
		ret = mbox_get( &mb_done_filtering);
		cache_flush();
		write_frame();
	}
	return NULL;
}



// MAIN ////////////////////////////////////////////////////////////////////
/**
 * Main thread of the Particle Filter Object Tracker Application. 
 * SW Threads for creating & starting the particle filter, receiving hw measurements
 * and receiving a new frame are instanciated and started
 *
 * @param argc: number of parameters (here: not needed)
 * @param argv: parameter array (here: not needed)
 */
int main(int argc, char *argv[])
{
	unsigned int result = 1;

	printf( "-------------------------------------------------------\n"
		    "GRAPHICAL_FILTER DEMONSTRATOR\n"
		    "(" __FILE__ ")\n"
		    "Compiled on " __DATE__ ", " __TIME__ ".\n"
		    "-------------------------------------------------------\n\n" );

	// establish tcp connection
	while (result == 1)
	{
		result = establish_connection(6666, &image_params);
	}
	
	mbox_init(&mb_start_filter_1,3);
	mbox_init(&mb_start_filter_2,3);
	mbox_init(&mb_done_filtering,3);

	
	/*// create filter sw thread no. 1
	pthread_attr_init(&filter_thread_1_attr);
	pthread_attr_setstacksize(&filter_thread_1_attr, STACK_SIZE);
	pthread_create(&filter_thread_1, &filter_thread_1_attr, filter_1_function, 0);
	
	// create filter sw thread no. 1
	pthread_attr_init(&filter_thread_2_attr);
	pthread_attr_setstacksize(&filter_thread_2_attr, STACK_SIZE);
	pthread_create(&filter_thread_2, &filter_thread_2_attr, filter_2_function, 0);*/
	

	reconos_init(0,3);

	res_1[0].type = RECONOS_TYPE_MBOX;
	res_1[0].ptr  = &mb_start_filter_1;
	res_1[1].type = RECONOS_TYPE_MBOX;
	res_1[1].ptr  = &mb_start_filter_2;

	res_2[0].type = RECONOS_TYPE_MBOX;
	res_2[0].ptr  = &mb_start_filter_2;
	res_2[1].type = RECONOS_TYPE_MBOX;
	res_2[1].ptr  = &mb_done_filtering;

	// init data for hw threads
	init_data = malloc(2*sizeof(unsigned int));
	init_data[0] = SIZE_X;
	init_data[1] = SIZE_Y;

	//printf("frame size (%dx%d)\r\n", SIZE_X, SIZE_Y);

	// create filter hardware thread no. 1
	reconos_hwt_setresources(&hwt_filter_1,res_1,2);
	reconos_hwt_setinitdata(&hwt_filter_1, (void *)init_data);
	reconos_hwt_create(&hwt_filter_1,1,NULL);

	// create filter hardware thread no. 2
	reconos_hwt_setresources(&hwt_filter_2,res_2,2);
	reconos_hwt_setinitdata(&hwt_filter_2, (void *)init_data);
	reconos_hwt_create(&hwt_filter_2,2,NULL);

	// create ethernet sw thread
	pthread_attr_init(&ethernet_thread_attr);
	pthread_attr_setstacksize(&ethernet_thread_attr, STACK_SIZE);
	pthread_create(&ethernet_thread, &ethernet_thread_attr, ethernet_function, 0);

	//while(42){}
	pthread_join(hwt_filter_1.delegate,NULL);
	pthread_join(hwt_filter_2.delegate,NULL);
	free(init_data);
	return 0;

}




