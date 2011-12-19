// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group 
//
// (C) Copyright University of Paderborn 2007. Permission to copy,
// use, modify, sell and distribute this software is granted provided
// this copyright notice appears in all copies. This software is
// provided "as is" without express or implied warranty, and with no
// claim as to its suitability for any purpose.
//
#ifndef __FSL_MODULE_H__
#define __FSL_MODULE_H__

// CONSTANTS ==============================================


// MACROS =================================================

#undef PDEBUG             /* undef it, just in case */
//#define PDEBUG(fmt, args...) printk( KERN_WARNING "fsl: " fmt, ## args)
#define PDEBUG(fmt, args...) 

#ifndef MIN
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#endif

int fsl_init(void);
void fsl_cleanup(void);


MODULE_AUTHOR("Andreas Agne <agne@upb.de>");
MODULE_LICENSE("GPL");

#endif  // __FSL_MODULE_H__

