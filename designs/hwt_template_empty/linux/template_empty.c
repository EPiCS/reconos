#include "reconos.h"
#include "mbox.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>


#define HWT_SLOT_NR 0

// software thread
pthread_t swt;
pthread_attr_t swt_attr;

// hardware threads
struct reconos_resource res[2];
struct reconos_hwt hwt;

// mailboxes
struct mbox mb_put;
struct mbox mb_get;

// sort thread shall behave the same as hw thread:
// - get pointer to data buffer
// - if valid address: sort data and post answer
// - if exit command: issue thread exit os call
void *echo_thread(void* data)
{
    unsigned int word;
    struct reconos_resource *res  = (struct reconos_resource*) data;
    struct mbox *mb_put = res[0].ptr;
    struct mbox *mb_get  = res[1].ptr;

    while ( 1 ) {
        word = mbox_get(mb_put);
	    if (word == UINT_MAX)
	    {
	      pthread_exit((void*)0);
	    }
	    else
	    {
	        mbox_put(mb_get, word);  
	    }
    }

    return (void*)0;
}

/*
 * Starts one sw-thread and one hw-thread, and puts two words into the 'put' mailbox.
 * Then it waits for the answers in the 'get' mailbox
 */
int main(int argc, char ** argv)
{
	// init mailboxes
	mbox_init(&mb_put, 2);
    mbox_init(&mb_get, 2);

	// init reconos and communication resources
	reconos_init(14,15);

	printf("Creating hw-thread.\n");
	res[0].type = RECONOS_TYPE_MBOX;
	res[0].ptr  = &mb_put;	  	
    res[1].type = RECONOS_TYPE_MBOX;
	res[1].ptr  = &mb_get;

    reconos_hwt_setresources(&hwt,res,2);
	reconos_hwt_create(&hwt,HWT_SLOT_NR,NULL);

	// init software threads
	printf("Creating sw-thread.\n");
    pthread_attr_init(&swt_attr);
	pthread_create(&swt, &swt_attr, echo_thread, (void*)res);


	// Put some data into the mailbox
	printf("Putting 0xDEADBEEF into mailbox twice...\n");
    mbox_put(&mb_put,(unsigned int)0xDEADBEEF);
    mbox_put(&mb_put,(unsigned int)0xDEADBEEF);

	// Wait for results
	printf("Reading data from mailbox...\n");
    printf("First  word is: %x n", mbox_get(&mb_get));
    printf("Second word is: %x n", mbox_get(&mb_get));


	// terminate all threads
	printf("Sending terminate message to sw and hw thread.\n");
    mbox_put(&mb_put,UINT_MAX);
    mbox_put(&mb_put,UINT_MAX);


	printf("Waiting for termination...\n");
    pthread_join(hwt.delegate,NULL);
	pthread_join(swt,NULL);
	
	return 0;
}

