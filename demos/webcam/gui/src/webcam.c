///
/// \file  sendvideo.c
/// Send, display and save video streams from a file or a camera.
/// 
/// This tool is able to open either a video file or other video source
/// (such as a camera), capture video data from it, and stream it over
/// a TCP/IP connection. It can open all video formats and video sources
/// that are supported by the OpenCV library it is linked against.
///
/// The image data is streamed "as is". Before the stream starts, the
/// size, bit depth, and number of channels of the video stream is
/// transmitted. This tool is supposed to be used either with the
/// 'recvvideo' tool or a eCos/ReconOS thread. See the ReconOS wiki
/// (http://www.reconos.de) for more details.
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

// INCLUDES ================================================================

#define SEND_VIDEO_FROM_PC 1

#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>                                                            // for 'basename()'

#define MAX_FRAMES 2
#define NO_VGA_FRAMEBUFFER 1
#define STORE_VIDEO 1

// header for application
//#include "../../linux/header/config.h"
// header for number of particles
//#include "../../linux/framework/header/particle_filter.h"

/* From OpenCV library */
#include "cv.h"
#include "cxcore.h"
#include "highgui.h"
#include <stdarg.h>

#include "tcp_connection.h"
#include "netimage.h"
#include "debug.h"
#include "cvutil.h"
#include "graph_utils.h"


/* default basename and extension of exported frames */
#define EXPORT_BASE "./frames/frame_"
#define EXPORT_EXTN ".png"


typedef struct params 
{
	CvPoint loc1[1];
	CvPoint loc2[1];
	IplImage* objects[1];
	char* win_name;
	IplImage* orig_img;
	IplImage* cur_img;
	int n;
} params;


#define TRUE  1
#define FALSE 0

typedef struct particle_data 
{
	volatile unsigned int x1;
	volatile unsigned int y1;
	volatile unsigned int x2;
	volatile unsigned int y2;
	volatile unsigned int best_particle;
} particle_data;




/***************************** Function Prototypes ***************************/

void mouse( int, int, int, int, void* );



// CONSTANTS ===============================================================

#define MAX_HOSTNAMELEN 256		///< maximum length of hostname string
#define MAX_FILENAMELEN 256		///< maximum length of filenames

#define SOURCE_NONE 0		///< no source specified
#define SOURCE_FILE 1		///< use video file as source
#define SOURCE_CAM  2		///< use camera as source


// GLOBAL VARIABLES ========================================================

// options
char host[MAX_HOSTNAMELEN] = "localhost";       ///< hostname to connect to
int port = 6666;                ///< port to connect to
int quiet = 0;                  ///< suppress output?
int output = 0;                 ///< write video stream to file?
char fourcc[5] = "PIM1";        ///< video format to write (default MPEG-1)
double fps = 25.0;              ///< fps to write to the video file
char infilename[MAX_FILENAMELEN];       ///< input stream file name
char outfilename[MAX_FILENAMELEN];      ///< output video file name
int camera = -1;                ///< camera number to use, '-1' for first available
int source = SOURCE_NONE;       ///< capture source to use
volatile int quit = 0;          ///< quit flag (set by signal handler)
int max_frames = 5000;         ///< max frames, can be set by parameter
const int offset = 320;
const int offset2 = -30;
float * performances;
int performance_num = 100;
const int w = 250;
const int h = 70;
const int performance_graph_height = 0;//200;
bool ethernet_support = true;

particle_data * particles_data;
int number_of_frames = 0;
int number_of_particles = 100;
int partitioning[3];
// Bounding Box of particle ist defined by two points (upper left corner, lower right corner)
CvPoint loc1, loc2;
CvFont font, font2, font3;


// FUNCTION DEFINITIONS ====================================================

///
/// Handles signals. Prints a note and sets the quit flag.
///
/// \param      sig             received signal
/*
void sig_handler( int sig )
{
	fprintf( stderr, "Received signal %d, exiting.\n", sig );
	quit = 1;
}
*/


///
/// Prints the program usage.
///
/// \param      basename        the name of this program's executable
/// 
void usage( char *basename )
{
	printf( "%s: send, display and save video streams.\n"
		"(c) 2007 Enno Luebbers (luebbers@reconos.de)\n"
		"Computer Engineering Group, University of Paderborn\n\n"
		"USAGE:\n"
		"       %s [-q] [-h] [-o <outfile>] [-f <fps>] [-F <fourcc>]\n"
		"               [-p <port>] [-i <infile>][-m <number_of_frames>] [-c [<id>]] <host>\n"
		"\n"
		"       -h                     display this help\n"
		"       -q                     be quiet (do not display video)\n"
		"       -o <outfile>           save video to <outfile> (NO EXTENSION!)\n"
		"       -f <fps>               frames per second to save (default: 25 or infile's)\n"
		"       -F <fourcc>            fourcc format to save in (default: MPEG-1)\n"
		"       -m <number_of_frames>  number of frames to track\n"
		"\n"
		"SOURCE OPTIONS:\n"
		"       -i <infile>            use <file> as video source\n"
		"       -c [<id>]              use camera with <id>, leave out for first available\n"
		"\n"
		"DESTINATION OPTIONS:\n"
		"       <host>                 host to send to\n"
		"       -p <port>              send to port <port> (default: 6666)\n"
		"\n", basename, basename );
}


///
/// Parses command line arguments using getopt() and sets the global
/// option variables.
///
/// \param      argc            number of command line arguments
/// \param      argv            pointer to array of command line argument
///                             strings
///
void parse_args( int argc, char *argv[] )
{

	int c;


	while ( 1 ) {
		c = getopt( argc, argv, "qo:f:F:i:c::p:m:sh" );

		if ( c == -1 )
			break;

		switch ( c ) {
		case 'q':
			quiet = 1;
			break;

		case 'o':
			output = 1;
			strncpy( outfilename, optarg, MAX_FILENAMELEN - 4 );
			break;

		case 'F':
			strncpy( fourcc, optarg, 4 );
			break;

		case 'f':
			fps = atof( optarg );
			break;

		case 'p':
			port = atoi( optarg );
			break;

		case 'm':
			max_frames = atoi( optarg );
			break;

		case 'i':
			source = SOURCE_FILE;
			strncpy( infilename, optarg, MAX_FILENAMELEN );
			break;

		case 's':
			ethernet_support = false;
			break;

		case 'c':
			source = SOURCE_CAM;
			if ( optarg )
			{
				camera = atoi( optarg );
			}
			break;

		case '?':

		case 'h':
		default:
		//	usage( basename( argv[0] ) );
		//	exit( 1 );
			break;
		}
	}

	if (ethernet_support)
	{
		// we need exactly one argument (the host name)
		if ( optind >= argc && !ethernet_support) 
		{
			fprintf( stderr, "no target host specified.\n" );
			usage( basename( argv[0] ) );
			exit( 1 );
		}

		if ( optind < argc - 1 ) 
		{
			fprintf( stderr, "too many arguments.\n" );
			usage( basename( argv[0] ) );
			exit( 1 );
		}
		strncpy( host, argv[optind], MAX_HOSTNAMELEN );

	}

	// set default source (camera)
	if ( source == SOURCE_NONE ) 
	{
		printf( "No source specified, using first available camera.\n"
			"Try '%s -h' for available options.\n",	basename( argv[0] ) );
			source = SOURCE_CAM;
	}
}


/*
	Exports a frame whose name and format are determined by EXPORT_BASE and
	EXPORT_EXTN, defined above.

	@param frame frame to be exported
	@param i frame number
*/
int export_frame( IplImage* frame, int i )
{
	char name[ strlen(EXPORT_BASE) + strlen(EXPORT_EXTN) + 4 ];
	char num[5];

	snprintf( num, 5, "%04d", i );
	strcpy( name, EXPORT_BASE );
	strcat( name, num );
	strcat( name, EXPORT_EXTN );
	return 0; // cvSaveImage( name, frame );
}

char * itoa(char * buf, unsigned int val, char pad, int mode)
{
	char i;
	char tmp_buf[6];

	for(i=0; val>0; val/=10)
	tmp_buf[i++] = (val % 10) + '0';
	if(i==0)
	tmp_buf[i++] = '0';

	while(i<pad)
		if (mode==1)
			tmp_buf[i++] = '0';
		else
			tmp_buf[i++] = ' '; 

	while(i>0)
		*buf++ = tmp_buf[--i];

	*buf = 0;

	return buf;
}

void ftoa(char * buf, double f, char pad)
{
	char * p;

	f = (f*100.0 + 0.5)/100.0;        // round
	p = itoa(buf,f,pad,0);
	*p++ = '.';

	f -= (unsigned int) f;
	f = f * 100.0;
	itoa(p,f,2,1);
}

void apply_dummy_filter( unsigned char *buf, int len, int width, int height)
{
	int i;
	for (i=0;i<height*width*3;i+=3)
	{
		buf[i+0] = 0;
		buf[i+1] = 0;
		buf[i+2] = buf[i+2];
	}
}


void apply_flip_filter( unsigned char *buf, int len, int width, int height)
{
	int i,j,k;
	unsigned char buf2 [width*height*3];
	for (i=0,k=((height*width*3)-3);i<height*width*3;i+=3,k-=3)
	{
		for (j=0;j<3;j++)
		{
			buf2[k+j] = buf[i+j];
		}
	}
	memcpy(buf, buf2, (width*height*3));
}


void apply_mirror_filter( unsigned char *buf, int len, int width, int height)
{
	int i,j,k,l;
	unsigned char buf2 [width*height*3];
	for (i=0;i<height*width*3;i+=(3*width))
	{
		for (k=0; k<(width*3);k+=3)
		{
			l = (3*(width-1)) - k;
			for (j=0;j<3;j++)
			{
				buf2[i+l+j] = buf[i+k+j];
			}
		}
	}
	memcpy(buf, buf2, (width*height*3));
}


int abs (int a)
{
	if (a < 0) return -a; else return a;
}

void apply_sobel_filter( unsigned char *buf, int len, int width, int height)
{
	int i,j;
	int line_offset = width*3;
	unsigned int c1;
	int c;
	int THRESH_H = 250;
	int THRESH_V = 250;
	int code = 1;
	// matrix vertical
	//  1   2   1
	//  0   0   0
	// -1  -2  -1
	// matrix horizonal
	//  1   0  -1
	//  2   0  -2
	//  1   0  -1
	unsigned char buf2 [width*height*3];
	for (i=0;i<height*width*3;i+=3)
	{
		if (i%(width*3)==0 || i%(width*3)==(width-1) || i<(width*3) || i>((height-1)*width*3))
		{
			buf[i+0] = 0;
			buf[i+1] = 0;
			buf[i+2] = 0;
		} else
		{
			// vertical
			c = 0;
			memcpy(&c1, &buf[i+code-3-line_offset-3], sizeof(unsigned int));
			c1 %= 255;
			c += c1;
			memcpy(&c1, &buf[i+code-line_offset-3], sizeof(unsigned int));
			c1 %= 255;
			c += (2*c1);
			memcpy(&c1, &buf[i+code+3-line_offset-3], sizeof(unsigned int));
			c1 %= 255;
			c += c1;
			
			memcpy(&c1, &buf[i+code-3+line_offset-3], sizeof(unsigned int));
			c1 %= 255;
			c -= c1;
			memcpy(&c1, &buf[i+code+line_offset-3], sizeof(unsigned int));
			c1 %= 255;
			c -= (2*c1);
			memcpy(&c1, &buf[i+code+3+line_offset-3], sizeof(unsigned int));
			c1 %= 255;
			c -= c1;
			for(j=0;j<3;j++)
			{
				if (c>THRESH_V)
					buf2[i+j] = 255;
				else
					buf2[i+j] = 0;
			}

			// horizontal
			c = 0;
			memcpy(&c1, &buf[i+code-3-line_offset-3], sizeof(unsigned int));
			c1 %= 255;
			c += c1;
			memcpy(&c1, &buf[i+code-3-3], sizeof(unsigned int));
			c1 %= 255;
			c += (2*c1);
			memcpy(&c1, &buf[i+code-3+line_offset-3], sizeof(unsigned int));
			c1 %= 255;
			c += c1;
			
			memcpy(&c1, &buf[i+code+3-line_offset-3], sizeof(unsigned int));
			c1 %= 255;
			c -= c1;
			memcpy(&c1, &buf[i+code+3-3], sizeof(unsigned int));
			c1 %= 255;
			c -= (2*c1);
			memcpy(&c1, &buf[i+code+3+line_offset-3], sizeof(unsigned int));
			c1 %= 255;
			c -= c1;
			for(j=0;j<3;j++)
			{
				if (c>THRESH_H)
					buf2[i+j] = 255;
			}

		} 
	}
	memcpy(buf, buf2, (width*height*3));
}


//
// insert video frame into display frame
//
void insert_video_frame( unsigned char *buf_in, unsigned char *buf_out, int len, int width, int height)
{
	int i,half_line=(3*width), line=1920;
	// height was 480 before (fixed)
	// half_line was 1920 before

	if (len>(height*half_line)-1)
	for (i=0;i<height;i++)
	{
		memcpy(&buf_out[i*line], &buf_in[i*half_line], half_line);
	}
}

void convert_to_4_channels( unsigned char *buf_in, unsigned char *buf_out, int width, int height)
{
	int x, y;
	for (y=0;y<(height*width);y+=width)
	{
		for (x=0; x<width;x++)
		{
			buf_out[((y+x)*4)+0] = buf_in[((y+x)*3)+2];
			buf_out[((y+x)*4)+1] = buf_in[((y+x)*3)+1];
			buf_out[((y+x)*4)+2] = buf_in[((y+x)*3)+0];
			buf_out[((y+x)*4)+3] = 0;
		}
	}

}

////
void convert_to_3_channels( unsigned char *buf_in, unsigned char *buf_out, int width, int height)
{
	int x, y;
	for (y=0;y<(height*width);y+=width)
	{
		for (x=0; x<width;x++)
		{
			buf_out[((y+x)*3)+0] = buf_in[((y+x)*4)+2];
			buf_out[((y+x)*3)+1] = buf_in[((y+x)*4)+1];
			buf_out[((y+x)*3)+2] = buf_in[((y+x)*4)+0];
		}
	}

}

//
// insert video frame into display frame
//
void insert_video_frame_2( unsigned char *buf_in, unsigned char *buf_out, int len, int width, int height)
{
	int i,half_line=(3*width), line=1920;
	// height was 480 before (fixed)
	// half_line was 1920 before

	if (len>(height*half_line)-1)
	for (i=0;i<height;i++)
	{
		memcpy(&buf_out[(i*line)+half_line], &buf_in[i*half_line], half_line);
	}
}

/*void drawPerformance (IplImage * frame, char * win_name, double performance)
{
	int i;
	char performance_s[8];
	ftoa(performance_s,performance,2);

	//cvRectangle( frame, cvPoint(offset+270,430), cvPoint(offset+320,235), CV_RGB(0,0,0), CV_FILLED, 8, 0);
	//cvPutText ( frame,performance_s,cvPoint(offset+280,470), &font3, CV_RGB(250,250,250));

	for (i=0;i<performance_num-1;i++)
	{
		performances[i] = performances[i+1];
	}
	i = performance_num-1;
	performances[i] = performance;
	//cvSetImageROI(frame, cvRect(frame->width-1 - w-10, 5, w+20, h+15));
	cvRectangle( frame, cvPoint(10,250), cvPoint(310,230+performance_graph_height), CV_RGB(0,0,0), CV_FILLED, 8, 0);
	cvSetImageROI(frame, cvRect(10, 250, 620, performance_graph_height-20));
	setGraphColor(0);
	drawFloatGraph(performances, performance_num, frame, 2,8, 620, performance_graph_height-20, "FPS", true);
	cvResetImageROI(frame);
}*/


////////////////////////////////////////////////////////////////////////////
// MAIN ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
///
/// Main program.
///
int main( int argc, char *argv[] )
{
	CvCapture *video;
	CvVideoWriter *writer;
	IplImage *hsv;
	char *win_name  = "EPiCS graphic filter demonstrator v0.1a";
	char key = 0;
	tcp_connection *con;
	int byte_stream_length;
	int frame_count = 0, result = 0;
	int i;
	max_frames = 5000;
	int counter = 0;
	unsigned char *byte_stream, *byte_stream_2;
	double performance = 0;
	IplImage *frame, *frame2, *frame_partitioning, *frame3, *frame4, *frame5;
	performances = malloc(performance_num*sizeof(float));
	source = SOURCE_CAM;

	for (i=0;i<performance_num;i++)
	{
		performances[i] = 0;
	}

	cvInitFont(&font,CV_FONT_HERSHEY_SIMPLEX|CV_FONT_ITALIC, 1.0,1.0,0,2,8);
	cvInitFont(&font2,CV_FONT_HERSHEY_SIMPLEX|CV_FONT_ITALIC, 0.7,0.7,0,2,8);
	cvInitFont(&font3,CV_FONT_HERSHEY_SIMPLEX|CV_FONT_ITALIC, 0.8,0.8,0,1,8);
	frame_partitioning = cvCreateImage( cvSize( (640), (240+performance_graph_height) ), 8, 3 );
	
	parse_args( argc, argv );

	// open the capture source
	switch ( source ) {
		case SOURCE_FILE:
			video = cvCreateFileCapture( infilename );
			break;
		case SOURCE_CAM:
			video = cvCreateCameraCapture( camera );
			break;
		default:
			fprintf( stderr, "strange source\n" );
			exit( 1 );
	}

	if ( !video ) 
	{
		fprintf( stderr, "unable to capture source\n" );
		exit( 1 );
	}

	frame = cvQueryFrame( video );
	if ( !frame ) 
	{
		fprintf( stderr, "unable to capture video.\n" );
		exit( 1 );
	}
	frame2 = cvCreateImage( cvSize( frame->width/2, frame->height/2 ), frame->depth, frame->nChannels );
	frame3 = cvCreateImage( cvSize( frame->width/4, frame->height/4 ), frame->depth, frame->nChannels );
	frame4 = cvCreateImage( cvSize( frame->width/4, frame->height/4 ), frame->depth, frame->nChannels );
	frame5 = cvCreateImage( cvSize( frame->width/2, frame->height/2 ), frame->depth, frame->nChannels );

	byte_stream_length = frame3->width*frame3->height*(frame3->nChannels+1);
	byte_stream = malloc (byte_stream_length);
	byte_stream_2 = malloc (byte_stream_length);

	if (ethernet_support)
	{
		// connect to remote host
		con = tcp_connection_create( host, port );
		if ( !con ) 
		{
			fprintf( stderr, "unable to connect to %s, port %d\n", host, port );
			exit( 1 );
		}
		printf( "Connected to %s, port %d.\n", host, port );
		if ( netimage_send_header( con, frame3 ) <= 0 )
		{
			fprintf( stderr, "unable to send header information.\n" );
			exit( 1 );
		}
	}

	cvShowImage( win_name, frame_partitioning );
	cvWaitKey( 2 );
	cvResize(frame, frame2,CV_INTER_LINEAR);
	insert_video_frame (frame2->imageData, frame_partitioning->imageData , frame2->imageSize, frame2->width, frame2->height );
	cvResize(frame, frame3,CV_INTER_LINEAR);
	insert_video_frame_2 (frame3->imageData, frame_partitioning->imageData , frame3->imageSize, frame3->width, frame3->height );
	cvNamedWindow( win_name, 1 );
	cvShowImage( win_name, frame_partitioning );
	
	number_of_frames++;

	printf  ( "Sending image stream (%d x %d, depth %u, %d channels (size: %d bytes)).\n"
		"Press 'q' to abort.\n", frame3->width, frame3->height,
		frame3->depth, frame3->nChannels, frame3->imageSize );

	// open capture file, if desired
	if ( output ) 
	{
		strncat( outfilename, ".mpg", MAX_FILENAMELEN );

		writer = cvCreateVideoWriter( outfilename, atofourcc( fourcc ), fps,
			cvSize( frame->width, frame->height ), frame->nChannels > 1 ? 1 : 0 );
		if ( writer == NULL ) 
		{
			fprintf( stderr, "unable to create output file '%s'\n", outfilename );
		} 
		else
		{
			printf( "Writing to output file '%s'.\n", outfilename );
		}
	}

	// for fps measurement
	struct timeval current, last;
	unsigned int diff;	// time difference in usecs
	int x0 = 0, y0 = 0, width = 0, height = 0;
	
	gettimeofday(&last, NULL);

	// 1) send other frames
	// get video data and send/store it
	while ( ( frame = cvQueryFrame( video ) ) && ( char ) key != 'q') 
	{

		
		gettimeofday(&current, NULL);
		diff = (current.tv_sec - last.tv_sec) * 1000000;
		diff += (current.tv_usec - last.tv_usec);
		cvResize(frame, frame2,CV_INTER_LINEAR);
		insert_video_frame (frame2->imageData, frame_partitioning->imageData , frame2->imageSize, frame2->width, frame2->height );
		cvResize(frame2, frame3,CV_INTER_LINEAR);

		if (ethernet_support)
		{
			// send frame
			convert_to_4_channels(frame3->imageData, byte_stream, frame3->width, frame3->height);
			result = tcp_send( con, byte_stream, byte_stream_length );
			result = tcp_receive( con, byte_stream_2, byte_stream_length);
			convert_to_3_channels(byte_stream_2, frame4->imageData, frame4->width, frame4->height);

			/*
			result = tcp_send( con, frame3->imageData, frame3->imageSize );
			// receive frame
			result = tcp_receive( con, frame4->imageData, frame4->imageSize);
			*/

			cvResize(frame4, frame5,CV_INTER_LINEAR);
		}
		else
		{
			cvResize(frame, frame5,CV_INTER_LINEAR);
			//apply_mirror_filter (frame5->imageData, frame5->imageSize, frame5->width, frame5->height );
		}

		insert_video_frame_2 (frame5->imageData, frame_partitioning->imageData , frame5->imageSize, frame5->width, frame5->height );
		fprintf(stderr, "FPS: %.2f\r", 1000000.0 / diff);
		if (counter>4)
		{
			performance = 1000000.0 / diff;
		}
		cvShowImage( win_name, frame_partitioning );
		key = cvWaitKey( 2 );
	
		last.tv_sec = current.tv_sec;
		last.tv_usec = current.tv_usec;
		number_of_frames++;
		counter++;
	}

	// clean up
	cvDestroyWindow( win_name );
	cvReleaseCapture( &video );
	if ( output )
	{
		cvReleaseVideoWriter( &writer );
	}
	if (ethernet_support)
	{
		tcp_connection_destroy( con );
	}
	free (byte_stream);
	free (byte_stream_2);
	free(performances);
	return 0;
}





