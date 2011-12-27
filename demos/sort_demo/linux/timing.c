///
/// \file timing.c
/// Implementation of timing functions.
///
/// \author	 Enno Luebbers   <luebbers@reconos.de>
/// \date	   28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//

#include <time.h>
#include <limits.h>
#include "timing.h"

#ifdef USE_DCR_TIMEBASE
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#endif

// fix for multithreaded linux: clock() only measures time spent in the current thread!
#ifdef USE_DCR_TIMEBASE 
#undef CLOCKS_PER_SEC
#define CLOCKS_PER_SEC 100000000
int timebase_fd;
#endif

// get system timer value
timing_t gettime(  )
{
#ifdef USE_DCR_TIMEBASE
	unsigned int buf;

	if (read(timebase_fd, &buf, sizeof(buf)) != sizeof(buf)) {
		perror("error while reading data from timebase");
	}

	//fprintf(stderr, "read time: %d\n", buf);

	return buf;
#else
	return clock(  );
#endif
}

#ifdef USE_DCR_TIMEBASE
int init_timebase() {
	timebase_fd = open("/dev/timebase", O_RDWR);
	if (timebase_fd < 0) 
	{
		perror("error while opening timebase device");
		return -1;
	}
	return 0;
}

void close_timebase() 
{
	close(timebase_fd);
}
#endif


// calculate difference between start and stop time
// and convert to milliseconds
timing_t calc_timediff_ms( timing_t start, timing_t stop )
{

	if ( start <= stop ) 
	{
		return ( stop - start ) / ( CLOCKS_PER_SEC / 1000 );
	} 
	else 
	{
		return ( ULONG_MAX - start + stop ) / ( CLOCKS_PER_SEC / 1000 );  // Milliseconds
	}
}
