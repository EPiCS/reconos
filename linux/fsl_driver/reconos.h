///
/// \file reconos.h
///
/// OSIF device driver for supporting ReconOS on Linux 2.6.
/// 
/// This driver provides character devices (e.g. /dev/osifnnn) for
/// accessing ReconOS OSIF registers from user space, in particular
/// from a delegate thread.
/// 
/// \author     Enno Luebbers <enno.luebbers@upb.de>
/// \date       15.01.2008
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
// 15.01.2008   Enno Luebbers   File created
// 22.08.2010   Andreas Agne    Adapted File to new driver structure.
//

#ifndef __OSIF_MODULE_H__
#define __OSIF_MODULE_H__

// open firmware
#include <linux/of_device.h>
#include <linux/of_platform.h>

#define OSIF_DEBUG 1


// CONSTANTS ==============================================

#define OSIF_NUMSLOTS 8    // maximum number of slots
                           // corresponds to the number of minors requested
#define TLB_NUMTLBS   1

#define OSIF_MAJOR  0       // dynamic major by default
#define TLB_MAJOR   0       // dynamic major by default

#define OSIF_DCR_WRITESIZE 3     // number of OSIF DCR registers (writable)
#define OSIF_DCR_READSIZE  8     // numberof OSIF DCR registers (readable)

#define OSIF_CMD_MMU_SETPGD    0x0A000000


// MACROS =================================================

#undef PDEBUG             /* undef it, just in case */
#ifdef OSIF_DEBUG
#  ifdef __KERNEL__
     // This one if debugging is on, and kernel space
#    define PDEBUG(fmt, args...) printk( KERN_WARNING "reconos.ko: " fmt, ## args)
#  else
     // This one for user space 
#    define PDEBUG(fmt, args...) fprintf(stderr, fmt, ## args)
#  endif
#else
#  define PDEBUG(fmt, args...) 0      // not debugging: nothing
#endif

#undef PDEBUG
#define PDEBUG(fmt, args...) printk( KERN_WARNING "osif: " fmt, ## args)

// for debugging
#define DCR_ADDR(dcrhost) (dcrhost.type == DCR_HOST_MMIO ? \
                           dcrhost.host.mmio.base :        \
                           dcrhost.host.native.base)

#ifndef MIN
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#endif

//struct of_device;
//struct of_device_id;

extern int tlb_major;
extern int tlb_minor;
extern int tlb_numtlbs;

int tlb_of_probe( struct of_device *ofdev, const struct of_device_id *match);
int tlb_of_remove( struct of_device *ofdev );

extern int reconos_tlb_dcrn;

extern int osif_major;
extern int osif_minor;
extern int osif_numslots;

int osif_of_probe( struct of_device *ofdev, const struct of_device_id *match);
int osif_of_remove( struct of_device *ofdev );

int reconos_init(void);
void reconos_cleanup(void);


MODULE_AUTHOR("Enno Luebbers <enno.luebbers@upb.de>");
MODULE_LICENSE("GPL");

#endif  // __OSIF_MODULE_H__

