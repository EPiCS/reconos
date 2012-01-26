//#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

void apply_sobel_filter( unsigned int *buf, int width, int height)
{
	int i;
	int c;
	int THRESH_H = 50;
	int THRESH_V = 50;
	unsigned int * buf2 = malloc(sizeof(unsigned int)*width*height);

	for (i=0;i<height*width;i++)
	{
		buf2[i] = 0;
		if (i%(width)==0 || i%(width)==(width-1) || i<width || i>((height-1)*width))
		{
		} 
		else
		{
			// matrix vertical
			//  1   2   1
			//  0   0   0
			// -1  -2  -1
			c = buf[i-width-1] % 256;
			c += 2*(buf[i-width] % 256);
			c += buf[i-width+1] % 256;
			c -= buf[i+width-1] % 256;
			c -= 2*(buf[i+width] % 256);
			c -= buf[i+width+1] % 256;
			if (c>THRESH_V)
				buf2[i] = 0xFFFFFF;

			// matrix horizonal
			//  1   0  -1
			//  2   0  -2
			//  1   0  -1
			c = buf[i-width-1] % 256;
			c += 2*(buf[i-1] % 256);
			c += buf[i+width-1] % 256;
			c -= buf[i-width+1] % 256;
			c -= 2*(buf[i+1] % 256);
			c -= buf[i+width+1] % 256;
			if (c>THRESH_H)
				buf2[i] = 0xFFFFFF;

		} 
	}
	memcpy(buf, buf2, (width*height*sizeof(unsigned int)));
	free(buf2);
}

void apply_mirror_filter( unsigned int *buf, int width, int height)
{
	int i,j;
	unsigned int * buf2 = malloc(sizeof(unsigned int)*width*height);
	for (i=0;i<(height*width);i+=width)
	{
		for (j=0; j<width;j+=1)
		{
			buf2[i+(width-1)-j] = buf[i+j];
		}
	}
	memcpy(buf, buf2, (width*height*sizeof(unsigned int)));
	free(buf2);
}


