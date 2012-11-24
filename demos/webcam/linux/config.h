/*! \file config.h 
 * \brief offers configuration constants
 */

#ifndef __CONFIG_H__
#define __CONFIG_H__

#define STACK_SIZE 65536
//#define STACK_SIZE 131072

//! no ethernet needed
//#define NO_ETHERNET 1


/*-***************************** Defs and macros *****************************/

#ifndef TRUE
//! defines integer value for true
#define TRUE 1
#endif
#ifndef FALSE
//! defines integer value for false
#define FALSE 0
#endif
#ifndef MIN
//! defines min-function with two values
#define MIN(x,y) ( ( x < y )? x : y )
#endif
#ifndef MAX
//! defines max-function with two values
#define MAX(x,y) ( ( x > y )? x : y )
#endif
#ifndef ABS
//! defines absolute-value-function
#define ABS(x) ( ( x < 0 )? -x : x )
#endif



#endif
