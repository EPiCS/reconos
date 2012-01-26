///
/// \file  debug.h
/// Debugging macros.
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
#ifndef __DEBUG_H__
#define __DEBUG_H__

// CONSTANTS ===============================================================

// Debug levels
#define DEBUG_NONE	  0 	///< no debugging output
#define DEBUG_NOTE	  1		///< important messages
#define DEBUG_INFO	  2		///< informational messages
#define DEBUG_TRACE	  4		///< trace information
#define DEBUG_ALL	  7		///< all debugging messages

#ifndef DEBUG
#define DEBUG DEBUG_NONE    ///< no debug is the default
#endif

/// prefix for debugging messages
#define DEBUG_PREFIX ":: "

// Macros
#if DEBUG > 0

/// standard printf
#define _PRINTF printf

/// print a debug message with level
#define DEBUG_PRINT(l, x)\
			if (DEBUG & l) _PRINTF(DEBUG_PREFIX __FILE__ ":%d: " x "\n", __LINE__);

// FIXME: we don't need an argument (see assert.h)
/// print an entry message 
#define DEBUG_ENTRY(x)\
			if (DEBUG & DEBUG_TRACE)\
            	_PRINTF(DEBUG_PREFIX __FILE__ ":%d: entering " x "\n", __LINE__);

// FIXME: we don't need an argument (see assert.h)
/// print an exit message
#define DEBUG_EXIT(x)\
	if (DEBUG & DEBUG_TRACE)\
		_PRINTF(DEBUG_PREFIX __FILE__ ":%d: exiting " x "\n", __LINE__);
#else
#define DEBUG_PRINT(l, x)  ///< no debug, no messages
#define DEBUG_ENTRY(x) ///< no debug, no entry message
#define DEBUG_EXIT(x)  ///< no debug, no exit message
#endif

#endif
