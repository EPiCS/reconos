#ifndef __FILTER_H__
#define __FILTER_H__



// sobel filter
void apply_sobel_filter( unsigned int *buf, int width, int height);

// mirror frame
void apply_mirror_filter( unsigned int *buf, int width, int height);

// greyscale frame
void apply_grey_filter( unsigned int *buf, int width, int height);

#endif	 //__FILTER_H__
