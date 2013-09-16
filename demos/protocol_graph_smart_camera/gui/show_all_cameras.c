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

#define NUM_CAMS 3  // GUI will be adapted to number of cameras (maximum 6 camera views supported)
#define GUI_SCALE 1 //0.69     // scale gui output
#define RGB_INVERSION 1   // color correction

//////////////////////////////////////////////////////////////////////////////////////////////////

#define DIVISOR 4         // video compression factor

#define VIDEO_WIDTH  1920   // do not change           
#define VIDEO_HEIGHT 1080   // do not change

#define FRAME_WIDTH  VIDEO_WIDTH/DIVISOR   // do not change
#define FRAME_HEIGHT VIDEO_HEIGHT/DIVISOR  // do not change

#define ETHERNET_ON 1 // should be enabled
#define ETH_INTERFACE "eth1"

#define STORE_VIDEO 1
#define BUF_SIZE 100

#define CMD_TRACKING_START    2
#define CMD_TRACKING_STOP     3
#define CMD_TRACKING_HANDOVER 4

#define MAX_FILENAMELEN 256

typedef struct cam_view_t 
{
	CvPoint screen_loc1;
	CvPoint screen_loc2;	
	CvPoint stop_button_loc1;
	CvPoint stop_button_loc2;
	CvPoint handover_buttons_loc1[NUM_CAMS-1];
	CvPoint handover_buttons_loc2[NUM_CAMS-1];
	
} cam_view_t;

typedef struct params 
{
	CvPoint loc1;
	CvPoint loc2;
	char* win_name;
	IplImage* orig_img;
	IplImage* cur_img;
} params;

int num_cam_views;
IplImage *frame, *frame_scaled, *frame_writer;
char *win_name = "EPiCS: HW/SW Platfrom - Smart Camera Demonstrator";

CvFont font,font2;
#ifdef STORE_VIDEO
CvPoint video_start_loc1, video_start_loc2, video_stop_loc1, video_stop_loc2;
int offset_top_pxl=40;
#else
int offset_top_pxl=10;
#endif
int offset_middle_pxl=100, offset_bottom_pxl=100;
int offset_left_pxl=10, offset_center_pxl=10, offset_right_pxl=10, offset_horizontal_pxl=0;
cam_view_t views[NUM_CAMS];
int pressed_left_button = 0;
CvPoint selection_loc1,selection_loc2;
int selected_cam=0;
char sendbuf[BUF_SIZE];
int sock_send;
struct ifreq if_idx;
struct ifreq if_mac;
struct sockaddr_ll socket_address;
struct ether_header *eh = (struct ether_header *) sendbuf;
//struct iphdr *iph = (struct iphdr *) (sendbuf + sizeof(struct ether_header));
int send_handover_id = 0;
int send_selection[8];
params p;
int capture_video = 0;

CvVideoWriter *writer = NULL;
char fourcc[5] = "PIM1";        ///< output video file format default to MPEG-1
double fps = 25.0;              ///< output video file frame rate
char filename[MAX_FILENAMELEN] = "output"; ///< output filename
char filename_count[MAX_FILENAMELEN];   ///< temp buffer for output filename

//! draw button for single camera
void draw_button_one_cam(int offset_x, int offset_y, int cam_id){

	int i,button_width,handover_id, button_height=30;
	char cam_name[] = "cam1";
	char stop_name[] = "stop";
	char handover_name[] = "->1";
	if (num_cam_views<7) 
		button_width=(FRAME_WIDTH/(NUM_CAMS+2)); 
	else 
		button_width=(FRAME_WIDTH/(NUM_CAMS+3));
	for (i=0;i<NUM_CAMS;i++){
		//cvRectangle(frame,cvPoint(offset_x+button_width+(i*(button_width+10))+8,offset_y+8),
		//	cvPoint(offset_x+i*(button_width+10)+2*button_width+8,offset_y+button_height+8),CV_RGB(0xE0,0xE1,0xE2),CV_FILLED,8,0);
		cvRectangle(frame,cvPoint(offset_x+button_width+(i*(button_width+10))+8,offset_y+8),
			cvPoint(offset_x+i*(button_width+10)+2*button_width+8,offset_y+button_height+8),CV_RGB(0xC4,0xC0,0xB8),CV_FILLED,8,0);
		if (i==0){
			cvPutText(frame,stop_name, cvPoint(offset_x+button_width+(i*(button_width+10))+13,offset_y+30),&font,CV_RGB(0x00,0x00,0x00));
			views[cam_id-1].stop_button_loc1.x = offset_x+button_width+(i*(button_width+10))+8;
			views[cam_id-1].stop_button_loc1.y = offset_y+8;
			views[cam_id-1].stop_button_loc2.x = offset_x+i*(button_width+10)+2*button_width+8;
			views[cam_id-1].stop_button_loc2.y = offset_y+button_height+8;
			cvRectangle(frame,views[cam_id-1].stop_button_loc1,views[cam_id-1].stop_button_loc2,CV_RGB(0x00,0x00,0x00),1,8,0);
		}
		else {
			handover_id = i;
			if (cam_id <= handover_id) handover_id++;
			handover_name[2] = (char)handover_id+48;
			cvPutText(frame,handover_name, cvPoint(offset_x+button_width+(i*(button_width+10))+13,offset_y+30),&font,CV_RGB(0x00,0x00,0x00));
			views[cam_id-1].handover_buttons_loc1[i-1].x = offset_x+button_width+(i*(button_width+10))+8;
			views[cam_id-1].handover_buttons_loc1[i-1].y = offset_y+8;
			views[cam_id-1].handover_buttons_loc2[i-1].x = offset_x+i*(button_width+10)+2*button_width+8;
			views[cam_id-1].handover_buttons_loc2[i-1].y = offset_y+button_height+8;
			cvRectangle(frame,views[cam_id-1].handover_buttons_loc1[i-1],views[cam_id-1].handover_buttons_loc2[i-1],CV_RGB(0x00,0x00,0x00),1,8,0);
		}
	}
	cam_name[3] = (char)cam_id+48;
	cvPutText(frame,cam_name, cvPoint(offset_x+2,offset_y+30),&font2,CV_RGB(0xFF,0x00,0x00));
}

//! draw buttons for all cameras
void draw_buttons_all_cams(){
	int i,j,tmp_offset_x=0, tmp_offset_y=offset_top_pxl+FRAME_HEIGHT+10;
	#ifdef STORE_VIDEO
	video_start_loc1.x = frame->width-160;
	video_start_loc1.y = 5;
	video_start_loc2.x = frame->width-90;
	video_start_loc2.y = 35;
	video_stop_loc1.x = frame->width-80;
	video_stop_loc1.y = 5;
	video_stop_loc2.x = frame->width-10;
	video_stop_loc2.y = 35;
	cvRectangle(frame,video_start_loc1,video_start_loc2,CV_RGB(0xC4,0xC0,0xB8),CV_FILLED,8,0);
	cvRectangle(frame,video_stop_loc1,video_stop_loc2,CV_RGB(0xC4,0xC0,0xB8),CV_FILLED,8,0);
	//cvRectangle(frame,video_start_loc1,video_start_loc2,CV_RGB(0xE0,0xE1,0xE2),CV_FILLED,8,0);
	//cvRectangle(frame,video_stop_loc1,video_stop_loc2,CV_RGB(0xE0,0xE1,0xE2),CV_FILLED,8,0);
	cvRectangle(frame,video_start_loc1,video_start_loc2,CV_RGB(0x00,0x00,0x00),1,8,0);
	cvRectangle(frame,video_stop_loc1,video_stop_loc2,CV_RGB(0x00,0x00,0x00),1,8,0);
	cvPutText(frame,"start",cvPoint(frame->width-150,28),&font,CV_RGB(0x00,0x00,0x00));
	cvPutText(frame,"stop",cvPoint(frame->width-70,28),&font,CV_RGB(0x00,0x00,0x00));
	cvPutText(frame,"capture video file",cvPoint(frame->width-370,28),&font2,CV_RGB(0x00,0x00,0x00));
	#endif
	if (NUM_CAMS < 2) {
		draw_button_one_cam(tmp_offset_x,tmp_offset_y,1);
		return;
	}
	for (i=0;i<num_cam_views/2;i++){
		tmp_offset_x = i*FRAME_WIDTH+offset_left_pxl + i*offset_center_pxl;
		tmp_offset_y = offset_top_pxl+FRAME_HEIGHT+10;
		draw_button_one_cam(tmp_offset_x,tmp_offset_y,i+1);
				
	}
	for (i=num_cam_views/2;i<NUM_CAMS;i++){
		j = i-num_cam_views/2;
		tmp_offset_x = j*FRAME_WIDTH+offset_left_pxl + j*offset_center_pxl;
		tmp_offset_y = offset_top_pxl+FRAME_HEIGHT+offset_middle_pxl+FRAME_HEIGHT+10;
		draw_button_one_cam(tmp_offset_x,tmp_offset_y,i+1);			
	}
}

//! init camera views
void init_cam_views(void){
	int i,j;
	if (NUM_CAMS < 2){
		views[0].screen_loc1.x = 0;
		views[0].screen_loc1.y = offset_top_pxl;
		views[0].screen_loc2.x = FRAME_WIDTH-1;
		views[0].screen_loc2.y = FRAME_HEIGHT-1+offset_top_pxl;
		cvRectangle(frame,views[0].screen_loc1, views[0].screen_loc2, CV_RGB(0x0,0x0,0x0), CV_FILLED, 8, 0 );
	} else {
		for (i=0;i<num_cam_views/2;i++){
			views[i].screen_loc1.x = i*FRAME_WIDTH+offset_left_pxl + i*offset_center_pxl;
			views[i].screen_loc1.y = offset_top_pxl;
			views[i].screen_loc2.x = views[i].screen_loc1.x+FRAME_WIDTH-1;
			views[i].screen_loc2.y = views[i].screen_loc1.y+FRAME_HEIGHT-1;
			cvRectangle(frame,views[i].screen_loc1,views[i].screen_loc2,CV_RGB(0x0,0x0,0x0),CV_FILLED,8,0);
		}
		for (i=num_cam_views/2;i<NUM_CAMS;i++){
			j = i-num_cam_views/2;
			views[i].screen_loc1.x = j*FRAME_WIDTH+offset_left_pxl + j*offset_center_pxl;
			views[i].screen_loc1.y = offset_top_pxl+FRAME_HEIGHT+offset_middle_pxl;
			views[i].screen_loc2.x = views[i].screen_loc1.x+FRAME_WIDTH-1;
			views[i].screen_loc2.y = views[i].screen_loc1.y+FRAME_HEIGHT-1;
			cvRectangle(frame,views[i].screen_loc1,views[i].screen_loc2,CV_RGB(0x0,0x0,0x0),CV_FILLED,8,0);
		}
	}

}


void print_packet(int packet_num, char * buffer, int packet_size){

	int i,j;
	if (packet_num>0 || packet_size < 32) return;
	//printf("print received frame data (size=%d):\n###################################\n",packet_size);
	for (i=0;i<32;i++){
		printf("%08x ",(int)buffer[i]);
		if ((i+1)%4==0) printf("\n");
	}
	printf("\n    .....\n\n");
	for (i=packet_size-8,j=0;i<packet_size;i++,j++){
		printf("%08x ",(int)buffer[i]);
		if ((j+1)%4==0) printf("\n");
	}
	printf("\n");
}

void print_packet2(int packet_num, char * buffer, int packet_size){

	int i;
	for (i=0;i<packet_size;i++){
		printf("%08x ",(int)buffer[i]);
		if ((i+1)%4==0) printf("\n");
	}
	printf("\n");
}

//! Converts a string containing a FOURCC code to an integer.
int atofourcc( char *a )
{
	return CV_FOURCC( a[0], a[1], a[2], a[3] );
}

//! mouse-over
void mouse( int, int, int, int, void* );

//! main function
int main()
{
	int data_size, ret, i, j,tmp_offset_x=0,tmp_offset_y=0;
        int counter = 0;
	long int counter2 = 0;
        //IplImage *frame, *frame_scaled;
        char c=0;
        unsigned char tmp;
        unsigned char * frame_ptr, *frame_ptr2;
        unsigned int line_number, packet_size=(FRAME_WIDTH*3)+25; // + 23
        unsigned char *buffer = (unsigned char *) malloc(1514); 
	int sock_recv;
	int cam_id=1,cam_input;
	int offset_top=0, offset_middle=0, offset_bottom=0;
	p.win_name = win_name;
	p.cur_img = NULL;
	//int offset_top_pxl=40, offset_middle_pxl=100, offset_bottom_pxl=100;
	//int offset_left_pxl=10, offset_center_pxl=10, offset_right_pxl=10, offset_horizontal_pxl=0;
	num_cam_views = NUM_CAMS;
	if (NUM_CAMS>1 && NUM_CAMS%2==1) {num_cam_views += 1; }
	offset_top    = offset_top_pxl    * FRAME_WIDTH*3;
	offset_bottom = offset_bottom_pxl * FRAME_WIDTH*3;
	if(NUM_CAMS>1){
		if ((num_cam_views/2)%2==0){  // some hack (#pixels per line (frame->width) has to be multiple of 4)
			offset_left_pxl  = 15;
			offset_right_pxl = 15;
		}
		offset_horizontal_pxl = ((num_cam_views/2)-1)*offset_center_pxl + offset_left_pxl + offset_right_pxl;
		//offset_top    = offset_top_pxl    * FRAME_WIDTH*3 * (num_cam_views/2) + offset_left_pxl;
		//offset_middle = offset_middle_pxl * FRAME_WIDTH*3 * (num_cam_views/2);
		//offset_bottom = offset_bottom_pxl * FRAME_WIDTH*3 * (num_cam_views/2);
		offset_top    = offset_top_pxl    * (((num_cam_views/2)*FRAME_WIDTH)+offset_horizontal_pxl)*3;
		offset_middle = offset_middle_pxl * (((num_cam_views/2)*FRAME_WIDTH)+offset_horizontal_pxl)*3;
		offset_bottom = offset_bottom_pxl * (((num_cam_views/2)*FRAME_WIDTH)+offset_horizontal_pxl)*3;
	}
	if(NUM_CAMS>6) {
		cvInitFont(&font,CV_FONT_HERSHEY_SIMPLEX, 0.5,0.5,0,1,8);
		cvInitFont(&font2,CV_FONT_HERSHEY_SIMPLEX, 0.5,0.5,0,1,8);
	}
	else {
		cvInitFont(&font,CV_FONT_HERSHEY_SIMPLEX, 0.7,0.7,0,1,8);
		cvInitFont(&font2,CV_FONT_HERSHEY_COMPLEX_SMALL, 0.9,0.9,0,1,8);
	}

        // create frame in normal size, and in adapted size
	if (NUM_CAMS>1)
        	frame = cvCreateImage( cvSize( ((FRAME_WIDTH*num_cam_views/2)+offset_horizontal_pxl), ((FRAME_HEIGHT*2)+(offset_top_pxl+offset_middle_pxl+offset_bottom_pxl)) ), 8, 3 );
	else
		frame = cvCreateImage( cvSize( FRAME_WIDTH, FRAME_HEIGHT+offset_top_pxl+offset_bottom_pxl ), 8, 3 );
	#ifdef STORE_VIDEO
		frame_writer = cvCreateImage( cvSize( frame->width, frame->height ), 8, 3 );
	#endif
        frame_scaled = cvCreateImage( cvSize( frame->width*GUI_SCALE, frame->height*GUI_SCALE ), 8, 3 );
        // initialize frame -> gray
        //memset(frame->imageData,0xF0,(frame->width*frame->height*3));
	//cvRectangle(frame,cvPoint(0,0), cvPoint(frame->width-1,frame->height-1), CV_RGB(0xF0,0xF1,0xF2), CV_FILLED, 8, 0 );
	cvRectangle(frame,cvPoint(0,0), cvPoint(frame->width-1,frame->height-1), CV_RGB(0xD4,0xD0,0xC8), CV_FILLED, 8, 0 );
        // scale the frame (small to large)
        cvResize(frame, frame_scaled,CV_INTER_LINEAR);
 
        // open a window
        //cvNamedWindow( win_name, CV_WINDOW_NORMAL );
	cvNamedWindow( win_name, 1 );
        // display the large frame
        cvShowImage( win_name, frame_scaled );

	#ifdef ETHERNET_ON
        //Receive Packets Part 
        sock_recv = socket( AF_PACKET , SOCK_RAW , htons(ETH_P_ALL)) ;
        if(sock_recv < 0)
        {
  	      //Print the error with proper message
        	perror("Socket Error");
       		return 1;
        }
        ret = setsockopt(sock_recv , SOL_SOCKET , SO_BINDTODEVICE , ETH_INTERFACE , strlen("eth1")+ 1 );
        if (ret < 0)
        {
        	perror("setsockopt");
        	return 1;
        }

	// socket to send packets /////////////////////////////////////////////////////////////
	// Open RAW socket to send on
	if ((sock_send = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW)) == -1) {
		perror("socket");
	}
	// Get the index of the interface to send on
	memset(&if_idx, 0, sizeof(struct ifreq));
	strncpy(if_idx.ifr_name, ETH_INTERFACE, IFNAMSIZ-1);
	if (ioctl(sock_send, SIOCGIFINDEX, &if_idx) < 0)
		perror("SIOCGIFINDEX");
	// Get the MAC address of the interface to send on
	memset(&if_mac, 0, sizeof(struct ifreq));
	strncpy(if_mac.ifr_name, ETH_INTERFACE, IFNAMSIZ-1);
	if (ioctl(sock_send, SIOCGIFHWADDR, &if_mac) < 0)
		perror("SIOCGIFHWADDR");

	memset(sendbuf, 0, BUF_SIZE);

	// Index of the network device
	socket_address.sll_ifindex = if_idx.ifr_ifindex;
	// Address length
	socket_address.sll_halen = ETH_ALEN;
	// Destination MAC (here: broadcast address = ff:ff:ff:ff:ff:ff)
	memset(socket_address.sll_addr,0xFF,6);
	// Ethernet header
	memcpy(eh->ether_shost,&if_mac.ifr_hwaddr.sa_data,6);
	memset(eh->ether_dhost,0xFF,6);
	// Ethertype field
	eh->ether_type = htons(0xACDC); //htons(ETH_P_IP);
	#endif
	//cvRectangle(frame,cvPoint(0,0), cvPoint(frame->width-1,frame->height-1), CV_RGB(0xF0,0xF1,0xF2), CV_FILLED, 8, 0 );
	//memset(frame->imageData,0xF0,(3*frame->width*frame->height));
	init_cam_views();
	draw_buttons_all_cams();
	cvResize(frame, frame_scaled,CV_INTER_LINEAR);

	p.orig_img = cvClone( frame_scaled );
	cvSetMouseCallback( win_name, &mouse, &p );

        while(c!=27) 
        {

		#ifdef ETHERNET_ON
        	//Receive a packet
        	//if (counter2<30)
		data_size = recv( sock_recv , buffer , 1512 , 0 );
        	if(data_size <0 )
        	{
           		printf("Recvfrom error , failed to get packets\n");
            		return 1;
        	}
		if (data_size < packet_size-1 && data_size > 20 && buffer[7]==0xFF && buffer[8]==0xFF){
			printf("received packet from FPGA\n");
			print_packet2(0,buffer,data_size);
		}
		//printf("received packet of size: %d (expected size: %d)\n",data_size,packet_size);
		if (data_size == packet_size-1 || data_size == packet_size)
		{
			//print_packet(counter2,buffer,data_size);
			//printf("received packet of correct size (%d)\n", data_size);
			counter++;
			counter2++;
			counter%=(FRAME_HEIGHT*NUM_CAMS);
			if (data_size == packet_size)
				cam_input = (int) buffer[11];
			else
				cam_input = (int) buffer[11];
			switch(cam_input){
				case 1: cam_id = 1; break;
				case 2:  if (NUM_CAMS>1)  cam_id = 2; break;
				case 4:  if (NUM_CAMS>2)  cam_id = 3; break;
				case 8:  if (NUM_CAMS>3)  cam_id = 4; break;
				case 15: if (NUM_CAMS>4)  cam_id = 5; break;
				default: break;
			}
			if (NUM_CAMS < 2) cam_id = 1;
			line_number = (int) buffer[19];
			line_number = line_number << 8;
			line_number += (int) buffer[20];
			//printf("received line no. %d\n", line_number);
			//line_number = (int) buffer[18];
			if (line_number<=FRAME_HEIGHT) 
			{
				frame_ptr = frame->imageData;
				if (NUM_CAMS>1){
					if (cam_id <= num_cam_views/2){
						frame_ptr += offset_top_pxl*frame->width*3;
						frame_ptr += 3*((cam_id-1)*offset_center_pxl + offset_left_pxl);
						frame_ptr += (cam_id-1)*FRAME_WIDTH*3;
					} else {
						frame_ptr += offset_top + offset_middle;
						frame_ptr += 3*((cam_id-1-(num_cam_views/2))*offset_center_pxl + offset_left_pxl);
						frame_ptr += (FRAME_HEIGHT*(offset_horizontal_pxl+((FRAME_WIDTH*num_cam_views)/2))*3);
						frame_ptr += (cam_id-(num_cam_views/2)-1)*FRAME_WIDTH*3;
					}
				} else {
					frame_ptr += offset_top;
				}
				frame_ptr += (line_number-1) * 3*frame->width;
				memcpy(frame_ptr,&buffer[25],FRAME_WIDTH*3);
				//memcpy(frame_ptr,&buffer[23],FRAME_WIDTH*3);
				//printf("cam code in ETH header: %d %d, packet length: %d\n", (int)buffer[10], (int)buffer[11],data_size);
				frame_ptr2 = frame_ptr;
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
				//printf("show frame (cam id=%d)\n", cam_id);
				draw_buttons_all_cams();
				cvResize(frame, frame_scaled,CV_INTER_LINEAR);
				if (p.orig_img) cvReleaseImage( &(p.orig_img) ); 
				p.orig_img = cvClone( frame_scaled ); 
				cvShowImage( win_name, frame_scaled );
				#ifdef STORE_VIDEO
				if (capture_video && writer!=NULL){
					cvResize(frame_scaled,frame_writer,CV_INTER_LINEAR);
					cvWriteFrame( writer, frame_writer );
				}
				#endif
				if (pressed_left_button)
					c = cvWaitKey( 0 );
				else
					c = cvWaitKey( 1 );
			}
		}
		#else
		cvResize(frame, frame_scaled,CV_INTER_LINEAR);
		if (p.orig_img) cvReleaseImage( &(p.orig_img) ); 
		p.orig_img = cvClone( frame_scaled ); 
		cvShowImage( win_name, frame_scaled );
		if (pressed_left_button==1)
			c = cvWaitKey( 0 );
		else {
			c = cvWaitKey( 1 );
			#ifdef STORE_VIDEO
			if (capture_video && writer!=NULL){
				cvResize(frame_scaled,frame_writer,CV_INTER_LINEAR);
				cvWriteFrame( writer, frame_writer );
			}
			#endif
		}
		#endif
           
        }
	#ifdef ETHERNET_ON
        close(sock_recv);
	close(sock_send);
	#endif
	#ifdef STORE_VIDEO
	if (writer!=NULL)
		cvReleaseVideoWriter( &writer );
	cvReleaseImage( &frame_writer );
	#endif
	cvReleaseImage( &frame );
	cvReleaseImage( &frame_scaled );
	printf("Finished (%ld)\n",counter2);
	return 0;
}

//! send a command (cmd) to camera (cam_id) with the parameters given in (paramter)
// cmd => 2: start tracking, 3: stop tracking, 4: tracking handover  
void send_packet( int cam_id, int cmd, int parameter_num, int * parameter){
	#ifdef ETHERNET_ON
	int i,tx_len = sizeof(struct ether_header);
	int cam_code = 1;
	char byte = 0;
	int tmp;

	switch(cam_id){
		case 1:  cam_code =  1; break;
		case 2:  cam_code =  2; break;
		case 3:  cam_code =  4; break;
		case 4:  cam_code =  8; break;
		case 5:  cam_code = 15; break;
		default: cam_code =  1; break;
	}
	 
	// do not change the Ethernet header
	memset(&sendbuf[tx_len], 0, BUF_SIZE-tx_len);
	// set internal header (as part of the payload)
	sendbuf[tx_len++] = cam_code; 
	sendbuf[tx_len++] = 0xf0; 
	sendbuf[tx_len++] = cmd;
	sendbuf[tx_len++] = parameter_num/0x100;
	sendbuf[tx_len++] = parameter_num%0x100;
	// set parameter
	for (i=0;i<parameter_num;i++){
		sendbuf[tx_len++] = (char) parameter[i];
	}
	// send packet
	if (sendto(sock_send, sendbuf, tx_len, 0, (struct sockaddr*)&socket_address, sizeof(struct sockaddr_ll)) < 0)
		printf("error: send packet failed (cmd: %d, cam_id %d)\n", cmd, cam_id);

	// print packet
	printf("print packet: ");
	for (i=0;i<tx_len;i++){
		byte = sendbuf[i];
		tmp = (int)byte;
		printf("%08x ",tmp);
		if ((i+1)%4==0) printf("\n              ");
	}
	printf("\n");
	#endif
}

//! start video capture
void start_video_capture(void){
	#ifdef STORE_VIDEO
	if (writer!=NULL) cvReleaseVideoWriter( &writer );
	snprintf( filename_count, MAX_FILENAMELEN, "%s.mpg",filename, 0 );
	writer = cvCreateVideoWriter( filename_count,atofourcc( fourcc ), fps,cvSize( frame->width, frame->height ),1 );
	if ( writer == NULL ) {
		fprintf( stderr, "unable to create output file.\n" );
	} else {
		printf( "Writing to output file '%s'.\n", filename_count );
	}
	capture_video = 1;
	#endif
}

//! stop video capture
void stop_video_capture(void){
	#ifdef STORE_VIDEO
	capture_video = 0;
	if (writer!=NULL)
		cvReleaseVideoWriter( &writer );
	writer = NULL;
	#endif
}

//! check if left mouse buttons has been clicked on one of the buttons (returns yes: 1, no: 0)
int check_buttons_hit(int x, int y){

	int cam_id,j,handover_id;
	int x1 = x/GUI_SCALE;
	int y1 = y/GUI_SCALE;
	for (cam_id=1;cam_id<=NUM_CAMS;cam_id++){

		if (views[cam_id-1].stop_button_loc1.x <= x1 && x1 <= views[cam_id-1].stop_button_loc2.x 
			&& views[cam_id-1].stop_button_loc1.y <= y1 && y1 <= views[cam_id-1].stop_button_loc2.y)
		{
			printf("cam no. %d: pressed stop button\n",cam_id);
			send_packet( cam_id, CMD_TRACKING_STOP, 0, 0);
			#ifndef ETHERNET_ON
			cvRectangle(p.orig_img,cvPoint(views[cam_id-1].screen_loc1.x*GUI_SCALE,views[cam_id-1].screen_loc1.y*GUI_SCALE),
				cvPoint(views[cam_id-1].screen_loc2.x*GUI_SCALE,views[cam_id-1].screen_loc2.y*GUI_SCALE),CV_RGB(0x0,0x0,0x0),CV_FILLED,8,0);
			cvResize(p.orig_img, frame_scaled,CV_INTER_LINEAR);
			cvShowImage( p.win_name, frame_scaled );
			#endif
			return 1;
		}
		for (j=0;j<NUM_CAMS;j++){
			handover_id = j+1;
			if (cam_id <= handover_id) 
				handover_id++;
			if (views[cam_id-1].handover_buttons_loc1[j].x <= x1 && x1 <= views[cam_id-1].handover_buttons_loc2[j].x 
				&& views[cam_id-1].handover_buttons_loc1[j].y <= y1 && y1 <= views[cam_id-1].handover_buttons_loc2[j].y){
				//send_handover_id = handover_id;
				switch(handover_id){
					case 1:  send_handover_id =  1; break;
					case 2:  send_handover_id =  2; break;
					case 3:  send_handover_id =  4; break;
					case 4:  send_handover_id =  8; break;
					case 5:  send_handover_id = 15; break;
					default: send_handover_id =  1; break;
				}
				printf("cam no. %d: pressed handover button (to cam no. %d, FPGA config. = %d)\n",cam_id,handover_id,send_handover_id);
				send_packet( cam_id, CMD_TRACKING_HANDOVER, 1, &send_handover_id);
				return 1;
			}
		}
	}
	#ifdef STORE_VIDEO
		if (video_start_loc1.x <= x1 && x1 <= video_start_loc2.x && video_start_loc1.y <= y1 && y1 <= video_start_loc2.y){
			start_video_capture();
			printf("start capturing video\n");
		}
		if (video_stop_loc1.x <= x1 && x1 <= video_stop_loc2.x && video_stop_loc1.y <= y1 && y1 <= video_stop_loc2.y){
			stop_video_capture();
			printf("stop capturing video\n");
		}
	#endif
	return 0;
}

//! check if left mouse buttons has been clicked inside a video frame of a smart camera (returns yes: cam_id, no: 0)
int check_screens_hit(int x, int y){

	int cam_id;
	int x1 = x/GUI_SCALE;
	int y1 = y/GUI_SCALE;
	for (cam_id=1;cam_id<=NUM_CAMS;cam_id++){
		if (views[cam_id-1].screen_loc1.x <= x1 && x1 <= views[cam_id-1].screen_loc2.x && views[cam_id-1].screen_loc1.y <= y1 && y1 <= views[cam_id-1].screen_loc2.y)
			return cam_id;
	}
	return 0;
}

//! mouse-over
void mouse( int event, int x, int y, int flags, void* param ){

	int ret=0,x1,x2,y1,y2;
	IplImage* tmp;
	params* p = (params*)param;
	
	if( event == CV_EVENT_LBUTTONDOWN ){
		pressed_left_button = 0;
		ret = check_buttons_hit(x,y);
		if (ret==0) ret = check_screens_hit(x,y);	
		if (ret>0) {
			selected_cam = ret;
			selection_loc1.x = x;
			selection_loc1.y = y;
			//printf("left button down\n");
			pressed_left_button = 1;
			#ifndef ETHERNET_ON
			cvRectangle(p->orig_img,cvPoint(views[selected_cam-1].screen_loc1.x*GUI_SCALE,views[selected_cam-1].screen_loc1.y*GUI_SCALE),
				cvPoint(views[selected_cam-1].screen_loc2.x*GUI_SCALE,views[selected_cam-1].screen_loc2.y*GUI_SCALE),CV_RGB(0x0,0x0,0x0),CV_FILLED,8,0);
			cvResize(p->orig_img, frame_scaled,CV_INTER_LINEAR);
			cvShowImage( p->win_name, frame_scaled );
			#endif
		}
	}
	else if( event == CV_EVENT_LBUTTONUP && pressed_left_button){
		// selected an object -> send it to camera
		pressed_left_button = 0;
		ret = check_screens_hit(x,y);
		if (ret==selected_cam){
			selection_loc2.x = MAX(x,selection_loc1.x);
			selection_loc2.y = MAX(y,selection_loc1.y);
			selection_loc1.x = MIN(x,selection_loc1.x);
			selection_loc1.y = MIN(y,selection_loc1.y);
			cvReleaseImage( &(p->cur_img) );
			p->cur_img = NULL;
			if (selection_loc1.x<selection_loc2.x && selection_loc1.y < selection_loc2.y){
				//printf("# draw rectangle (%d,%d)->(%d,%d)\n",selection_loc1.x,selection_loc1.y,selection_loc2.x,selection_loc2.y);
				cvRectangle(p->orig_img,selection_loc1,selection_loc2,CV_RGB(0xFF,0x00,0x00),2,8,0);
				cvResize(p->orig_img, frame_scaled,CV_INTER_LINEAR);
				cvShowImage( p->win_name, frame_scaled );
				//printf("left button up\n");
				x1 = selection_loc1.x/GUI_SCALE;
				y1 = selection_loc1.y/GUI_SCALE;
				x2 = selection_loc2.x/GUI_SCALE;
				y2 = selection_loc2.y/GUI_SCALE;
				x1 -= views[selected_cam-1].screen_loc1.x;
				x2 -= views[selected_cam-1].screen_loc1.x;	
				y1 -= views[selected_cam-1].screen_loc1.y;
				y2 -= views[selected_cam-1].screen_loc1.y;	
				printf("cam no. %d: send selection (%d,%d)->(%d,%d)\n",selected_cam,x1,y1,x2,y2);		
				send_selection[0] = x1/0x100;
				send_selection[1] = x1%0x100;
				send_selection[2] = y1/0x100;
				send_selection[3] = y1%0x100;
				send_selection[4] = x2/0x100;
				send_selection[5] = x2%0x100;
				send_selection[6] = y2/0x100;
				send_selection[7] = y2%0x100;
				send_packet( selected_cam, CMD_TRACKING_START, 8, send_selection);
			}
		} else {
			cvReleaseImage( &(p->cur_img) );
			p->cur_img = NULL;
			cvResize(p->orig_img, frame_scaled,CV_INTER_LINEAR);
			cvShowImage( p->win_name, frame_scaled );
		}
	}
	else if( event == CV_EVENT_MOUSEMOVE  &&  flags & CV_EVENT_FLAG_LBUTTON  && pressed_left_button){
		//printf("moving mouse (left button down)\n");
		// currently selecting an object: draw rectangle
		selection_loc2.x = x;
		selection_loc2.y = y;
		tmp = cvClone( p->orig_img );
		//printf("- draw rectangle (%d,%d)->(%d,%d)\n",selection_loc1.x,selection_loc1.y,selection_loc2.x,selection_loc2.y);
		cvRectangle(tmp,selection_loc1,selection_loc2,CV_RGB(0xFF,0xFF,0xFF),1,8,0);
		cvResize(tmp, frame_scaled,CV_INTER_LINEAR);
		cvShowImage( p->win_name, frame_scaled );
		if( p->cur_img )
			cvReleaseImage( &(p->cur_img) );
		p->cur_img = tmp;
	}
}

