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
#include <stdio.h>
#include <string.h>
#include "timing.h"

#ifdef USE_DCR_TIMEBASE
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#endif

#ifdef USE_GETTIMEOFDAY
#include <sys/time.h>
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
#elif defined USE_GETTIMEOFDAY
	timing_t now;

	gettimeofday(&now, NULL);

	return now;
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

/**
 * Similar to timersub, but handles negative results correct.
 * @return Difference a - b. If result is positive a was later in time then b. If one or both components of
 * 			timing_t are negative, b was later in time than a.
 */
void timerdiff(timing_t * a, timing_t * b, timing_t * diff){
	if(timercmp(a,b,>)){
		timersub(a,b,diff);
	}else{
		timersub(b,a,diff);
		diff->tv_sec*=-1;
		diff->tv_usec*=-1;
	}
}

/**
 * Converts a timing_t into a human readable string.
 * The string should be at least of length 18
 * @return Length of the generated string. If greater than s_len, string got truncated.
 */
int timer2string(char* s, int s_len, timing_t * t){
	return snprintf(s, s_len, "%ld sec %6ld usec", t->tv_sec, t->tv_usec);
}

/**
 * Converts a timing_t type to seconds
 * @return If LONG_MAX or LONG_MIN, over/-underflow might have happened
 */
long int timer2s(timing_t * t){
	return t->tv_sec;
}

/**
 * Converts a timing_t type to miliseconds
 * @return If LONG_MAX or LONG_MIN, over/-underflow might have happened
 */
long int timer2ms(timing_t * t){
	return t->tv_sec*1000 + t->tv_usec/1000;
}

/**
 * Converts a timing_t type to microseconds
 * @return If LONG_MAX or LONG_MIN, over/-underflow might have happened
 */
long int timer2us(timing_t * t){
	return t->tv_sec*1000000 + t->tv_usec;
}

/**
 *  Calculate difference between start and stop time
 * 	and convert to milliseconds
 * 	@warning deprecated
 */
ms_t calc_timediff_ms( timing_t start, timing_t stop )
{
#ifdef USE_GETTIMEOFDAY
  ms_t ms;
  timing_t diff;

  // calculate difference
  timersub(&stop, &start, &diff);
  // convert to miliseconds
  ms = diff.tv_sec*1000+diff.tv_usec/1000;
  // this is very dirty, but allows to print the value via printf("%lu",ms)
  return ms;
#else
	if ( start <= stop ) 
	{
	  return (ms_t)( stop - start ) / ( CLOCKS_PER_SEC / 1000 );
	} 
	else 
	{
	  return (ms_t)( ULONG_MAX - start + stop ) / ( CLOCKS_PER_SEC / 1000 );  // Milliseconds
	}
#endif
}
