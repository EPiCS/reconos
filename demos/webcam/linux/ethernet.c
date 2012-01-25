//#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "ethernet.h"


#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
//#include <network.h>
#include <unistd.h>

image_params_t img_param;

//! valid  file descriptor
static int fd;


/**
	creates a server socket and waits for incomming connection.

	@param port: listen port for new data/frames
	@return returns a valid file descriptor on success. returns -1 on error.
*/
int accept_connection(int port)
{
	struct sockaddr_in local_addr;
	struct sockaddr_in remote_addr;
	
	bzero(&local_addr,0);       
	bzero(&remote_addr,0);
	
	int sockfd = socket( AF_INET, SOCK_STREAM, 0 );
	if(sockfd < 0)
	{
		printf("socket creation failed\n");
		return -1; 
	}
	
	local_addr.sin_family = AF_INET;
	local_addr.sin_addr.s_addr = INADDR_ANY;
	local_addr.sin_port = htons(port);
	  
	int result = bind(sockfd, (struct sockaddr *) &local_addr, sizeof local_addr);
	if(result < 0)
	{
		printf("bind socket failed\n");
		return -1;
	}
	
	listen(sockfd,0);
 
	printf ("\nNow accept the connection");

	socklen_t addrlen;
	int fd = accept(sockfd, (struct sockaddr *) &remote_addr, &addrlen);
	if(fd < 0)
	{
		printf("accept failed\n");
		return -1;
	}

	printf("\nAcception completed");
	return fd;
}



/**
  reads 'len' bytes from 'sockfd' into 'buf'. Block until all data is read or an read error occurs.
  
  @param fd: valid file descriptor
  @param buf: buffer, where the data is stored
  @param len: number of bytes, which should be read 

  @return returns 1 on success, 0 otherwise.
*/

int tcp_read_2(int fd, void *buf, size_t len)
{
	uint8_t * p = buf;
	int result;
	while(len > 0)
	{
		result = read(fd, p, len);
		if(result == -1)
		{
			return 0;
		}		
		p += result;
		len -= result;
	}
	return 1;
}



/**
  write 'len' bytes from 'sockfd' into 'buf'. Block until all data is written or an read error occurs.
  
  @param fd: valid file descriptor
  @param buf: buffer, where the data is stored
  @param len: number of bytes, which should be written

  @return returns 1 on success, 0 otherwise.
*/
int tcp_write_2(int fd, void *buf, size_t len)
{
	uint8_t * p = buf;
	int result;
	while(len != 0)
	{
		result = write(fd, p, len);
		if(result == -1) return 0;
		
		p += result;
		len -= result;
	}
	return 1;
}



/**
	 receives image stream header information.

	 @param fd: valid file descriptor
	 @param ip: image parameters, including channels, depth, width and height
	 @return returns 1 on success, 1 on error
*/

int recv_header(int fd, image_params_t * ip)
{
	if(!tcp_read_2(fd, ip, sizeof(image_params_t))) return 0;
	
	//ip->nChannels = ntohl(ip->nChannels);
	ip->nChannels = ip->nChannels;
	ip->depth = ip->depth;		///< image depth per channel
	ip->width = ip->width;		///< image width
	ip->height = ip->height;		///< image height
	return 1;
}




/**
	establishes connection to ethernet

	@param port: port number for videotransfer
	@param region: pointer to image parameters
	@return returns '0' if connection is established, else '1'
*/
int establish_connection(int port, image_params_t * params)
{
	int i,i_end;
	// *** init network interfaces ******************************************	
	printf("\n\n");
	printf("########################################\n");
	printf("#       START TO RECEIVE FRAMES        #\n");
	printf("########################################\n");
	printf("\n\n");
	
	// *** tcp/ip connect ****************************************************
	printf("waiting for connection...\n");
	fd = accept_connection(port);
	if(fd < 0){
		printf("connection failed\naborting\n");
		return 1;
	}
	printf("connection established\n");
	
	if(!recv_header(fd, &img_param)){
		printf("failed reading image parameters (header)\n");
		return 1;
	}

	memcpy(params,&img_param,sizeof(image_params_t));
	
	printf("\n");
	printf("Image stream header:  width = %u\n", (unsigned int) img_param.width);
	printf("                     height = %u\n", (unsigned int) img_param.height);
	printf("                        bpc = %u\n", (unsigned int) img_param.depth);
	printf("                   channels = %u\n", (unsigned int) img_param.nChannels);

	// set height and width of frames to maximum x and y values
	SIZE_X = MIN ( params->width, MAX_SIZE_X);
	SIZE_Y = MIN ( params->height, MAX_SIZE_Y);

	framebuffer = malloc((params->width*params->height*(params->depth/8)*(params->nChannels+1)) + 4096);
	framebuffer = (unsigned int *)((((unsigned int)framebuffer) / 4096) * 4096);
	i_end = ((params->width*params->height*(params->depth/8)*(params->nChannels+1)) + 4096)/4096;
	for (i=0; i<i_end;i++ )
  	{
		framebuffer[i*1024] = 0;
	}
	return 0;
}


/**
	sends frame from ram to tcp server
*/
void write_frame( void )
{		
	int frame_size = img_param.width * img_param.height * (img_param.depth/8) * (img_param.nChannels+1);
	tcp_write_2(fd, framebuffer, frame_size);
	/*int i;
	int frame_size = img_param.width * img_param.height * (img_param.depth/8) * (img_param.nChannels);
	//tcp_write_2(fd, framebuffer, frame_size);
	uint8_t *  frame = malloc(frame_size);
	uint8_t * p = malloc(sizeof(unsigned int));
	for (i=0;i<img_param.width * img_param.height;i++)
	{
		memcpy(p,&framebuffer[i],sizeof(unsigned int));
		frame[(i*3)+0] = p[3];
		frame[(i*3)+1] = p[2];
		frame[(i*3)+2] = p[1];
	}
	tcp_write_2(fd, frame, frame_size);
	free(frame);
	free(p);*/
		 
}

/**
  copies next frame from ethernet and writes next frame to specific ram

*/
void read_frame(  )
{	
	int frame_size = img_param.width * img_param.height * (img_param.depth/8) * (img_param.nChannels+1);
	tcp_read_2(fd, framebuffer, frame_size);

	/*int x,y;
	int frame_size = img_param.width * img_param.height * (img_param.depth/8) * (img_param.nChannels);
	uint8_t *  frame = malloc(frame_size);
	uint8_t * p;
	uint32_t * fb_pos = (uint32_t*)framebuffer;
	tcp_read_2(fd, frame, frame_size);
	p = frame;
	for(y = 0; y < img_param.height; y++)
	{	
		for(x = 0; x < img_param.width; x++)
		{
			// write pixel to framebuffer
			*fb_pos = p[0] | (p[1] << 8) | (p[2] << 16);
			// next pixel
			p += 3;
			fb_pos++;
		}
	}
	free(frame);*/	 
}




