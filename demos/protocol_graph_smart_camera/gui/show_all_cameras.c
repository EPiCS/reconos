#include<netinet/in.h>
#include<errno.h>
#include<netdb.h>
#include<stdio.h>                     //For standard things
#include<stdlib.h>                    //malloc
#include<string.h>                    //strlen 
#include<netinet/if_ether.h>          //For ETH_P_ALL
#include<net/ethernet.h>              //For ether_header
#include<sys/socket.h>
#include<arpa/inet.h>
#include<sys/ioctl.h>
#include<sys/time.h>
#include<sys/types.h>
#include<unistd.h>
#include <opencv2/core/core_c.h>
#include <opencv2/highgui/highgui_c.h>
#include <opencv2/imgproc/imgproc_c.h> 
#include <linux/if_packet.h>
#include <net/if.h>
#include <netinet/ether.h>


#define GUI_SCALE 1     // scale gui output
#define DIVISOR 4         // video compression factor

//#define RGB_INVERSION 1   // color correction

#define NUM_CAMS 4 // GUI will be adapted to number of cameras

#define VIDEO_WIDTH  1920   // do not change           
#define VIDEO_HEIGHT 1080   // do not change

#define FRAME_WIDTH  VIDEO_WIDTH/DIVISOR   // do not change
#define FRAME_HEIGHT VIDEO_HEIGHT/DIVISOR  // do not change



/***************************************************************************************/
/*****************************Start of Main Function***************************/ 
int main()
{
	int data_size, ret, i;
        int counter = 0;
	long int counter2 = 0;
        IplImage *frame, *frame_large;
        char c=0;
        unsigned char tmp;
        unsigned char * frame_ptr, *frame_ptr2;
        char *win_name = "EPiCS: HW/SW Platfrom - Smart Camera Demonstrator";
        unsigned int line_number, packet_size=(FRAME_WIDTH*3)+25; // + 23
        unsigned char *buffer = (unsigned char *) malloc(1512); 
	int sock_raw;
	int cam_id,cam_input;
	int offset_top=0, offset_middle=0, offset_bottom=0;
	int offset_top_pxl=40, offset_middle_pxl=100, offset_bottom_pxl=100;
	int num_cam_views = NUM_CAMS;
	if (NUM_CAMS>1 && NUM_CAMS%2==1) num_cam_views += 1;
	if(NUM_CAMS>1){
		offset_top    = offset_top_pxl    * FRAME_WIDTH*3 * (num_cam_views/2);
		offset_middle = offset_middle_pxl * FRAME_WIDTH*3 * (num_cam_views/2);
		offset_bottom = offset_bottom_pxl * FRAME_WIDTH*3 * (num_cam_views/2);
	}


        // create frame in normal size, and in adapted size
	if (NUM_CAMS>1)
        	frame = cvCreateImage( cvSize( FRAME_WIDTH*num_cam_views/2, FRAME_HEIGHT*2+offset_top_pxl+offset_middle_pxl+offset_bottom_pxl ), 8, 3 );
	else
		frame = cvCreateImage( cvSize( FRAME_WIDTH, FRAME_HEIGHT ), 8, 3 );
        frame_large = cvCreateImage( cvSize( frame->width*GUI_SCALE, frame->height*GUI_SCALE ), 8, 3 );
        // initialize frame -> black
        memset(frame->imageData,0,(3*FRAME_WIDTH*FRAME_HEIGHT*num_cam_views));
        // scale the frame (small to large)
        cvResize(frame, frame_large,CV_INTER_LINEAR);
 
        // open a window
        //cvNamedWindow( win_name, CV_WINDOW_NORMAL );
	cvNamedWindow( win_name, 1 );
        // display the large frame
        cvShowImage( win_name, frame_large );


        /***************************** Receive Packets Part ***************************/
        sock_raw = socket( AF_PACKET , SOCK_RAW , htons(ETH_P_ALL)) ;
        if(sock_raw < 0)
        {
  	      //Print the error with proper message
        	perror("Socket Error");
       		return 1;
        }
        ret = setsockopt(sock_raw , SOL_SOCKET , SO_BINDTODEVICE , "eth1" , strlen("eth1")+ 1 );
        if (ret < 0)
        {
        	perror("setsockopt");
        	return 1;
        }

        while(c!=27) 
        {
        	//Receive a packet
        	data_size = recv( sock_raw , buffer , 1512 , 0 );
        	if(data_size <0 )
        	{
           		printf("Recvfrom error , failed to get packets\n");
            		return 1;
        	}
		if (data_size == packet_size)
		{
			counter++;
			counter2++;
			counter%=(FRAME_HEIGHT*NUM_CAMS);
			cam_input = (int) buffer[11];
			switch(cam_input){
				case 1: cam_id = 1; break;
				case 2:  if (NUM_CAMS>1)  cam_id = 2; break;
				case 4:  if (NUM_CAMS>2)  cam_id = 3; break;
				case 8:  if (NUM_CAMS>3)  cam_id = 4; break;
				case 15: if (NUM_CAMS>4)  cam_id = 5; break;
				default: break;
				//case 0:  cam_id = 6; break;
				//default: if (cam_id == 6) cam_id = 1;
			}
			if (NUM_CAMS < 2) cam_id = 1;
			//printf("cam id: %d\n", cam_id);
			line_number = (int) buffer[19];
			line_number = line_number << 8;
			line_number += (int) buffer[20];
			//line_number = (int) buffer[18];
			if (line_number<=2*FRAME_HEIGHT) 
			{
				frame_ptr = frame->imageData;
				if (NUM_CAMS>1){
					if (cam_id <= num_cam_views/2){
						frame_ptr += offset_top;
						frame_ptr += (cam_id-1)*FRAME_WIDTH*3;
					} else {
						frame_ptr += offset_top + offset_middle;
						frame_ptr += (FRAME_HEIGHT*FRAME_WIDTH*3*num_cam_views)/2;
						frame_ptr += (cam_id-(num_cam_views/2)-1)*FRAME_WIDTH*3;
					}
				}
				if (NUM_CAMS>1)
					frame_ptr += (line_number-1) * FRAME_WIDTH*3 * num_cam_views/2;
				else
					frame_ptr += (line_number-1) * FRAME_WIDTH*3;
				frame_ptr2 = frame_ptr;
				//memcpy(frame_ptr,&buffer[23],FRAME_WIDTH*3);
				memcpy(frame_ptr,&buffer[25],FRAME_WIDTH*3);
				#ifdef RGB_INVERSION
				for (i=0;i<FRAME_WIDTH;i++)
				{		
					tmp = frame_ptr2[0];
					frame_ptr2[0] = frame_ptr2[2];
					frame_ptr2[2] = tmp;
					frame_ptr2+=3;
		        	}
				#endif
			}
			if (counter==0){
				cvResize(frame, frame_large,CV_INTER_LINEAR); 
				cvShowImage( win_name, frame_large );
				c = cvWaitKey( 1 );
			}
		}
           
        }
	
        close(sock_raw);
        cvReleaseImage( &frame );
        cvReleaseImage( &frame_large );
        printf("Finished (%ld)\n",counter2);
        return 0;
}




