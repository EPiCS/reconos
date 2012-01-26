///
/// \file  recvvideo.c
/// Receive, display and save video streams from a network connection.
/// 
/// This tool is able to receive video data over a TCP/IP connection,
/// display and store it.
///
/// The image data is streamed "as is". Before the stream starts, the
/// size, bit depth, and number of channels of the video stream is
/// transmitted. This tool is supposed to be used either with the
/// 'sendvideo' tool or a eCos/ReconOS thread. See the ReconOS wiki
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

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>                                                            // for 'getopt()'
#include <signal.h>
#include <libgen.h>                                                            // for 'basename()'

/* From OpenCV library */
#include "cv.h"
#include "cxcore.h"
#include "highgui.h"

#include "debug.h"
#include "tcp_connection.h"
#include "netimage.h"
#include "cvutil.h"

// CONSTANTS ===============================================================

#define MAX_FILENAMELEN 256	///< maximum length of filenames

volatile int quit = 0;			///< quit flag, set by signal handler

// options
int repeat = 0;                 ///< whether to wait for new connections after a transfer
int port = 6666;                ///< post to listen on
int quiet = 0;                  ///< quiet mode (no video display)
int output = 0;                 ///< output received video to a file?
char fourcc[5] = "PIM1";        ///< output video file format default to MPEG-1
double fps = 25.0;              ///< output video file frame rate
char filename[MAX_FILENAMELEN]; ///< output filename
char filename_count[MAX_FILENAMELEN];   ///< temp buffer for output filename
CvFont font, font2, font3;  // new
const int offset = 640; //640;
const int offset2 = -30;
int performance_num = 100;
float performances[100];
const int w = 250;
const int h = 70;
const int performance_graph_height = 200;


// FUNCTION DEFINITIONS ====================================================

///
/// Handles signals. Prints a note and sets the quit flag.
///
/// \param      sig             received signal
/// 
void sig_handler( int sig )
{

    fprintf( stderr, "Received signal %d, exiting.\n", sig );
    // quit = 1;
    exit(1);
}


///
/// Prints the program usage.
///
/// \param      basename        the name of this program's executable
/// 
void usage( char *basename )
{
    printf( "%s: receive, display and save video streams.\n"
            "(c) 2007 Enno Luebbers (luebbers@reconos.de)\n"
            "Computer Engineering Group, University of Paderborn\n\n"
            "USAGE:\n"
            "       %s [-r] [-h] [-q] [-o <outfile>] [-f <fps] [-F <fourcc>]\n"
            "               [-p <port>]\n"
            "\n"
            "       -h                  display this help\n"
            "       -r                  repeatedly listen for connections\n"
            "       -q                  be quiet (do not display video)\n"
            "       -o <outfile>        save video to <outfile> (NO EXTENSION!)\n"
            "       -f <fps>            frames per second to save (default: 25)\n"
            "       -F <fourcc>         fourcc format to save in (default: MPEG-1)\n"
            "       -p <port>           listen on port <port> (default 6666)\n"
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
int parse_args( int argc, char *argv[] )
{

    int c;


    while ( 1 ) {
        c = getopt( argc, argv, "ro:qp:f:F:h" );

        if ( c == -1 )
            break;

        switch ( c ) {
        case 'r':
            repeat = 1;
            break;

        case 'q':
            quiet = 1;
            break;

        case 'o':
            output = 1;
            strncpy( filename, optarg, MAX_FILENAMELEN - 4 );
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

        case '?':
        case 'h':
        default:
            usage( basename( argv[0] ) );
            exit( 1 );
            break;
        }
    }

}


char * itoa(char * buf, unsigned int val, char pad, int mode) {
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


/*
void convert_to_3_channels( unsigned char *buf_in, unsigned char *buf_out, int width, int height)
{
	int x, y;
	for (y=0;y<(height*width);y+=width)
	{
		for (x=0; x<width;x++)
		{
			buf_out[((y+x)*3)+0] = buf_in[((y+x)*4)+3];
			buf_out[((y+x)*3)+1] = buf_in[((y+x)*4)+2];
			buf_out[((y+x)*3)+2] = buf_in[((y+x)*4)+1];
		}
	}

}*/

/////////////////
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
    IplImage *frame, *frame2;
    IplImage *test; // new
    char *win_name = "Received Frame";
    char *win_test_name = "EPiCS dummy application: receive and send video"; // new
    char key = 0;
    tcp_server *server;
    tcp_connection *con;
    int result, frame_count = 0, freeze = 0, con_count = 0;
    char hostname[256];
    int w = 250;
    int h = 70;
    int i;
    int counter = 0;
    image_params params;
    unsigned char *byte_stream, *byte_stream_2;
    int byte_stream_length;
    fd_set fds;
    // for fps measurement
    struct timeval current, last;
    double performance = 0;
    CvRect region;
    unsigned int diff;	// time difference in usecs
    cvInitFont(&font,CV_FONT_HERSHEY_SIMPLEX|CV_FONT_ITALIC, 1.0,1.0,0,2,8);  // new
    cvInitFont(&font2,CV_FONT_HERSHEY_SIMPLEX|CV_FONT_ITALIC, 0.7,0.7,0,2,8); // new
    cvInitFont(&font3,CV_FONT_HERSHEY_SIMPLEX|CV_FONT_ITALIC, 0.8,0.8,0,1,8); // new
    // register signal handlers for SIGINT (CTRL+C)
    DEBUG_PRINT( DEBUG_NOTE, "registering signal" )
        if ( signal( SIGINT, sig_handler ) == SIG_ERR ) {
        fprintf( stderr, "failed to register signal handler.\n" );
        exit( 1 );
    }
    srand(12345);
    // parse command line arguments and set options
    parse_args( argc, argv );
    gettimeofday(&last, NULL); 


     for (i=0;i<performance_num;i++){
          performances[i] = 0; //2 + 0.01*(rand()%600);
     }
    
    // start listening
    DEBUG_PRINT( DEBUG_NOTE, "creating server" );
    server = tcp_server_create( port, 2 );
    if ( !server ) {
        fprintf( stderr, "unable to open socket\n" );
        exit( 1 );
    }
    cvNamedWindow( win_name, 1 );
    do {
        // use select() to trigger an accept call, so that
        // the signal handler can still intercept a SIGINT
        printf
            ( "Waiting for connection on port %d. Press CTRL+C to quit.\n",
              port );
        fflush( stdout );
        FD_ZERO( &fds );
        FD_SET( server->sockfd, &fds );

        if ( select( server->sockfd + 1, &fds, NULL, NULL, NULL ) > 0 ) {

            con = tcp_accept( server );
            if ( !con ) {
                fprintf( stderr,
                         "unable to accept incoming connection.\n" );
                exit( 1 );
            }
            con_count++;
            printf( "Incoming connection from %s.\n",
                    sockaddr2hostname( &con->addr, hostname,
                                       sizeof( hostname ) ) );

            // receive image header
            if ( netimage_recv_header( con, &params, sizeof( params ) ) <=
                 0 ) {
                fprintf( stderr, "unable to receive image parameters.\n" );
                tcp_connection_destroy( con );
                break;
            }
            // Allocate image
            if ( ( frame =
                   netimage_CreateImageFromHeader( &params ) ) == NULL ) {
                fprintf( stderr, "unable to allocate image.\n" );
                tcp_connection_destroy( con );
                break;
            }

            printf
                ( "Receiving image stream (%d x %d, depth %u, %d channels (size: %d bytes)).\n",
                  frame->width, frame->height, frame->depth,
                  frame->nChannels, frame->imageSize );

            frame2 = cvCreateImage( cvSize( frame->width, frame->height ), frame->depth, frame->nChannels );

            byte_stream_length = frame2->width*frame2->height*(frame->nChannels+1);

            byte_stream = malloc (byte_stream_length);
            byte_stream_2 = malloc (byte_stream_length);

            if ( !quiet ){
                printf( "Press 'q' to abort, 'f' to freeze.\n" );
           }

            // open video file to save received data, if required
            if ( output ) {

                if ( repeat )
                    snprintf( filename_count, MAX_FILENAMELEN,
                              "%s_%03d.mpg", filename, con_count );
                else
                    snprintf( filename_count, MAX_FILENAMELEN, "%s.mpg",
                              filename, con_count );

                writer =
                    cvCreateVideoWriter( filename_count,
                                         atofourcc( fourcc ), fps,
                                         cvSize( params.width,
                                                 params.height ),
                                         params.nChannels > 1 ? 1 : 0 );
                if ( writer == NULL ) {
                    fprintf( stderr, "unable to create output file.\n" );
                    tcp_connection_destroy( con );
                    cvReleaseImage( &frame );
                    break;
                }
                printf( "Writing to output file '%s'.\n", filename_count );
            }
            // receive and display image data (frame by frame)
            key = 0;
            result = 1;
            freeze = 0;
            while ( ( char ) key != 'q' && result > 0 ) {
                result = tcp_receive( con, frame->imageData, frame->imageSize );
		//result = tcp_receive( con, byte_stream, byte_stream_length );
                if ( result > 0 ) {

                    //convert_to_3_channels(byte_stream, frame->imageData, frame->width, frame->height);
                    // change video frame
                    cvResize(frame, frame2,CV_INTER_LINEAR);
                    apply_mirror_filter (frame2->imageData, frame2->imageSize, frame2->width, frame2->height );
                    //convert_to_4_channels(frame2->imageData, byte_stream_2, frame2->width, frame2->height);

                    counter++;
                    // display video
                    if ( !quiet ) {
                        if ( key == 'f' )
                            freeze = !freeze;
                        if ( !freeze ){
                            cvShowImage( win_name, frame2 );
			}
                        key = cvWaitKey( 2 );
                    }
                    // write video to file
                    if ( output )
                        cvWriteFrame( writer, frame2 );
                    // send frame back
                    result = tcp_send( con, frame2->imageData, frame2->imageSize );
                    //result = tcp_send( con, byte_stream_2, byte_stream_length );
                }

		if (counter%2==0){
		     gettimeofday(&current, NULL);
		     diff = (current.tv_sec - last.tv_sec) * 1000000;
		     diff += (current.tv_usec - last.tv_usec);
		     performance = 1000000.0 / diff;
                     performance *= 2;
		     fprintf(stderr, "FPS: %.2f\r", performance);	
		     last.tv_sec = current.tv_sec;
		     last.tv_usec = current.tv_usec;
                }
            }

            // clean up
            cvReleaseImage( &frame );
            cvReleaseImage( &frame2 );
            tcp_connection_destroy( con );
            free(byte_stream);
            free(byte_stream_2);
            if ( output )
                cvReleaseVideoWriter( &writer );
        }

    } while ( !quit && repeat );

    // clean up
    cvDestroyWindow( win_name );
    cvReleaseImage( &test );
    cvReleaseImage( &frame );
    DEBUG_PRINT( DEBUG_NOTE, "destroying server" )
        tcp_server_destroy( server );
    cvDestroyWindow( win_test_name );

    return 0;
}
