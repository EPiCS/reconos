#include "sort8k.h"
#include "bubblesort.h"
#include "reconos.h"
#include "mbox.h"
#include "config.h"
#include "timing.h"

#ifdef SHADOWING
	#include "thread_shadowing.h"
	#include "thread_shadowing_subs.h"
#endif

#include "mbox.h"
#include "rqueue.h"
#include "eif.h"

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>

//#define BENCHMARK
//#define DEBUG 1

#ifdef DEBUG
    #define SORT_DEBUG(message) printf("SORT: " message)
    #define SORT_DEBUG1(message, arg1) printf("SORT: " message, (arg1))
    #define SORT_DEBUG2(message, arg1, arg2) printf("SORT: " message, (arg1), (arg2))
	#define SORT_DEBUG3(message, arg1, arg2, arg3) printf("SORT: " message, (arg1), (arg2), (arg3))
	#define SORT_DEBUG4(message, arg1, arg2, arg3, arg4) printf("SORT: " message, (arg1), (arg2), (arg3), (arg4))
#else
    #define SORT_DEBUG(message)
    #define SORT_DEBUG1(message, arg1)
    #define SORT_DEBUG2(message, arg1, arg2)
	#define SORT_DEBUG3(message, arg1, arg2, arg3)
	#define SORT_DEBUG4(message, arg1, arg2, arg3, arg4)
#endif

// sort thread shall behave the same as hw thread:
// - get pointer to data buffer
// - if valid address: sort data and post answer
// - if exit command: issue thread exit os call
void *sort_thread_shmem(void* data)
{
	static int call_nr = 0;
    unsigned int ret;
    unsigned int dummy = 23;
    struct reconos_resource *res  = (struct reconos_resource*) data;
    struct mbox *mb_start = res[0].ptr;
    struct mbox *mb_stop  = res[1].ptr;
#ifdef DEBUG
    pthread_t self = pthread_self();
#endif
    SORT_DEBUG4("SW Thread %lu, call %d: Started with mailbox addresses %p and %p ...\n", self, call_nr,  mb_start, mb_stop);
    while ( 1 ) {
    	SORT_DEBUG3("SW Thread %lu, call %d: getting buffer address from mailbox %p\n", self, call_nr, mb_start);
        ret = mbox_get(mb_start);
		//printf("SW Thread %lu: Got address %p from mailbox %p.\n", self, (void*)ret, mb_start);
		if (ret == UINT_MAX)
		{
		  SORT_DEBUG3("SW Thread %lu, call %d: Got exit command from mailbox %p.\n", self, call_nr, mb_start);
		  mbox_put(mb_stop, dummy);
		  pthread_exit((void*)0);
		}
		else
		{
		  SORT_DEBUG3("SW Thread %lu, call %d: starting bubblesort on pointer %p\n", self, call_nr, (unsigned int*)ret);
#ifdef BENCHMARK
		  timing_t start, stop;
		  ms_t bubblesort_time;
		  start = gettime();
#endif
		  bubblesort( (unsigned int*) ret, N);
#ifdef BENCHMARK
		  stop = gettime();
		  bubblesort_time = calc_timediff_ms(start, stop);
		  printf("bubblesort time: %lu ms\n", bubblesort_time);
#endif
		  mbox_put(mb_stop, dummy);
		}
		SORT_DEBUG3("SW Thread %lu, call %d: putting acknowledgement into mailbox %p\n", self, call_nr, mb_stop);
        call_nr++;
    }

    return (void*)0;
}

// This is a messsage based sort thread:
// - gets length of data and every data word via a message box
// - if length > 0: copy data into private buffer and start sorting it; afterwards pass data back via message box
// - if length = UINT_MAX : exit command -> issue thread exit os call
void *sort_thread_mbox(void* data)
{
	static int call_nr = 0;
	unsigned int i;
    unsigned int length;
    unsigned int  buffer[N*sizeof(unsigned int)];
    struct reconos_resource *res  = (struct reconos_resource*) data;
    struct mbox *mb_start = res[0].ptr;
    struct mbox *mb_stop  = res[1].ptr;
#ifdef DEBUG
    pthread_t self = pthread_self();
#endif
    SORT_DEBUG4("SW Thread %lu, call %d: Started with mailbox addresses %p and %p ...\n", self, call_nr,  mb_start, mb_stop);

    // error injection code
//    int leading_thread = false;
//    shadowedthread_t *sh;
//    pthread_t this = pthread_self();
//    if (is_shadowed_in_parent(this, &sh)) {
//    	leading_thread = shadow_leading_thread(sh, this);
//	}
    //

    printf("SORT8K: Address of buffer: %8p, size of buffer %ui\n", buffer, sizeof(buffer));
    //eif_add(buffer, sizeof(buffer) , 100, 0, 10, SINGLE_BIT_FLIP, 0);
    //eif_start();
    while ( 1 ) {
    	SORT_DEBUG3("SW Thread %lu, call %d: getting length from mailbox %p\n", self, call_nr, mb_start);
        length = mbox_get(mb_start);

		//printf("SW Thread %lu: Got address %p from mailbox %p.\n", self, (void*)ret, mb_start);
		if (length == UINT_MAX)
		{
		  SORT_DEBUG3("SW Thread %lu, call %d: Got exit command from mailbox %p.\n", self, call_nr, mb_start);
		  mbox_put(mb_stop, UINT_MAX);
		  //free(buffer);
		  pthread_exit((void*)0);
		}
		else
		{
		  SORT_DEBUG3("SW Thread %lu, call %d: starting bubblesort with length %i\n", self, call_nr, (unsigned int)length);
		  // read into local buffer
		  SORT_DEBUG("Reading Data Words:...\n");
		  for (i = 0; i< length; i++){
			  // Error injection:
			  //if (leading_thread && (i == 42) ){continue;}
			  //if (leading_thread && (i == 42) ){mbox_put(mb_stop, buffer[i]);}
			  //
			  buffer[i] = mbox_get(mb_start);
		  }
		  SORT_DEBUG3("First three data words read: %i %i %i\n", buffer[0],buffer[1],buffer[2]);
		  // sort local buffer
#ifdef BENCHMARK
		  timing_t start, stop;
		  ms_t bubblesort_time;
		  start = gettime();
#endif
		  bubblesort(  buffer, N); // N is number of (unsigned int*) the buffer consists of
#ifdef BENCHMARK
		  stop = gettime();
		  bubblesort_time = calc_timediff_ms(start, stop);
		  printf("bubblesort time: %lu ms\n", bubblesort_time);
#endif
		  // Error injection
		  //if (leading_thread){buffer[42]= 0x1337;}
		  //

		  // write sorted buffer into output queue
		  SORT_DEBUG("Writing Data Words...\n");
		  for (i = 0; i< length; i++){
		  	  mbox_put(mb_stop, buffer[i]);
		  }
		  SORT_DEBUG3("First three data words written: %i %i %i\n", buffer[0],buffer[1],buffer[2]);

		}
		//SORT_DEBUG3("SW Thread %lu, call %d: put acknowledgement into mailbox %p\n", self, call_nr, mb_stop);
        call_nr++;
#ifdef SHADOWING
        SORT_DEBUG("Calling pthread_yield() ...\n");
        pthread_yield();
#endif
    }

    return (void*)0;
}

// This is a reconos queue based solution.
// Sort data is communicated in 8k blocks via reconos queues.
// Protocol is:
// - First rq message is a single word containing length of data to sort
//   If it is UINT_MAX, thread will exit
// - Second rq message will contain data to sort.
// - thread sends back sorted data via rq message
void *sort_thread_rqueue(void* data)
{
	static int call_nr = 0;
    unsigned int length;
    unsigned int error=0;
    unsigned int  buffer[N*sizeof(unsigned int)];
    struct reconos_resource *res  = (struct reconos_resource*) data;
    rqueue *rq_start = res[0].ptr;
    rqueue *rq_stop  = res[1].ptr;
#ifdef DEBUG
    pthread_t self = pthread_self();
#endif
    SORT_DEBUG4("SW Thread %lu, call %d: Started with mailbox addresses %p and %p ...\n", self, call_nr,  rq_start, rq_stop);

    // error injection code
//    int leading_thread = false;
//    shadowedthread_t *sh;
//    pthread_t this = pthread_self();
//    if (is_shadowed_in_parent(this, &sh)) {
//    	leading_thread = shadow_leading_thread(sh, this);
//	}
    //


    while ( 1 ) {
    	SORT_DEBUG3("SW Thread %lu, call %d: getting length from mailbox %p\n", self, call_nr, mb_start);
        error = rq_receive(rq_start,&length, sizeof(length));
        printf("RQ_RECEIVE 1 returned %i\n", error);
        printf("RQ_RECEIVE 1 length is %i\n", length);
        if ( error != sizeof(length) )
        {
        	printf("ERROR: rq_receive 1 returned to few data. Expected: %ui bytes, returned %i bytes", sizeof(length), error);
        	exit(24);
        }
		//printf("SW Thread %lu: Got address %p from mailbox %p.\n", self, (void*)ret, mb_start);
		if (length == UINT_MAX)
		{
		  SORT_DEBUG3("SW Thread %lu, call %d: Got exit command from mailbox %p.\n", self, call_nr, mb_start);
		  rq_send(rq_stop, &length, sizeof(length));
		  //free(buffer);
		  pthread_exit((void*)0);
		}
		else
		{
		  SORT_DEBUG3("SW Thread %lu, call %d: starting bubblesort with length %i\n", self, call_nr, (unsigned int)length);
		  // read into local buffer
		  SORT_DEBUG("Reading Data Words:...\n");
		  // Error injection:
		  // if (leading_thread){length--;} // Tests parameter checking
		  //
		  error = rq_receive(rq_start, buffer, length);
		  printf("RQ_RECEIVE 2 returned %i\n", error);
		  printf("RQ_RECEIVE 2 length is %i\n", length);
		  if ( error != length )
		  {
			printf("ERROR: rq_receive 2 returned to few data. Expected: %i bytes, returned %i bytes", length, error);
			exit(24);
		  }

		  SORT_DEBUG3("First three data words read: %i %i %i\n", buffer[0],buffer[1],buffer[2]);
		  // sort local buffer
#ifdef BENCHMARK
		  timing_t start, stop;
		  ms_t bubblesort_time;
		  start = gettime();
#endif
		  bubblesort(  buffer, N); // N is number of (unsigned int*) the buffer consists of
#ifdef BENCHMARK
		  stop = gettime();
		  bubblesort_time = calc_timediff_ms(start, stop);
		  printf("bubblesort time: %lu ms\n", bubblesort_time);
#endif
		  // Error injection
		  //if (leading_thread){buffer[42]= 0x1337;}
		  //

		  // write sorted buffer into output queue
		  SORT_DEBUG("Writing Data Words...\n");
		  rq_send(rq_stop, buffer, length);
		  SORT_DEBUG3("First three data words written: %i %i %i\n", buffer[0],buffer[1],buffer[2]);

		}
		//SORT_DEBUG3("SW Thread %lu, call %d: put acknowledgement into mailbox %p\n", self, call_nr, mb_stop);
        call_nr++;
#ifdef SHADOWING
        SORT_DEBUG("Calling pthread_yield() ...\n");
        pthread_yield();
#endif
    }
    return (void*)0;
}
