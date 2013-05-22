/*
 * workercpu.c
 *
 *  Created on: Apr 23, 2013
 *      Author: meise
 */


#include "reconos.h"
#include "fsl.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <pthread.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>

#include <mbox.h>
#include <rqueue.h>
#include <semaphore.h>

#define WORKERCPU_SLOT 0

#define REPETITIONS 1000

void reconos_slot_reset(int num, int reset);



bool test_echo(){
	uint32_t input = 1337;
	uint32_t output = 0;
	// Test communication with worker cpu
	printf("TEST_ECHO: Writing %u to slot %i.\n", input, WORKERCPU_SLOT);
	fsl_write(WORKERCPU_SLOT, input);
	output = fsl_read(WORKERCPU_SLOT);
	printf("TEST_ECHO: Read %u from slot %i.\n", output, WORKERCPU_SLOT);

	if ( output == input ){
		return true;
	} else {
		return false;
	}
}

struct mbox mb_send;
struct mbox mb_recv;
bool test_mbox(){
	uint32_t input = 1337;
	uint32_t output;
	int i;
	bool retval=true;

	printf("TEST_MBOX:putting %u into mbox and repeating %i times.\n", input, REPETITIONS);
	for ( i=0; i< REPETITIONS; i++) {
		mbox_put( &mb_send, input );
		output = mbox_get( &mb_recv );
		if ( output != input ) { retval=false; }
	}
	printf("TEST_MBOX: read %u from mbox %i times.\n", output, REPETITIONS);

	return retval;
}

rqueue rqueue_send;
rqueue rqueue_recv;
#define BUFFER_SIZE 16384
uint32_t send_buffer[BUFFER_SIZE/sizeof(uint32_t)];
uint32_t recv_buffer[BUFFER_SIZE/sizeof(uint32_t)];
bool test_rqueue(){
	memset(send_buffer, 1337, BUFFER_SIZE);
	memset(recv_buffer, 1337, BUFFER_SIZE);
	printf("TEST_RQUEUE: sending %u via rqueue.\n", send_buffer[0]);
	rq_send( &rqueue_send, send_buffer, BUFFER_SIZE );
	printf("TEST_RQUEUE: sent.\n");
	rq_receive( &rqueue_recv, recv_buffer, BUFFER_SIZE );
	printf("TEST_RQUEUE: received %u via rqueue.\n", recv_buffer[0]);

	return memcmp(send_buffer, recv_buffer, BUFFER_SIZE) == 0;

}

sem_t sem_send;
sem_t sem_recv;
bool test_sem() {
	printf("TEST_SEM: Posting semaphore, then waiting for another...\n");
	sem_post( &sem_send );
	sem_wait( &sem_recv );
	printf("TEST_SEM: Got semaphore!\n");
	return true;
}

pthread_mutex_t mutex_send;
pthread_mutex_t mutex_recv;
bool test_mutex() {
	printf("TEST_MUTEX: first unlocking mutex, then trying to lock another one.\n");
	pthread_mutex_unlock( &mutex_send );
	pthread_mutex_lock( &mutex_recv );
	printf("TEST_MUTEX: Got mutex lock!\n");
	return true;
}

pthread_cond_t cond_send;
pthread_cond_t cond_recv;
bool test_cond() {
	printf("TEST_COND: not implemented.\n");
	return true;
}

void test_init(){
	mbox_init( &mb_send, 1 );
	mbox_init( &mb_recv, 1 );

	rq_init( &rqueue_send, sizeof(uint32_t) );
	rq_init( &rqueue_recv, sizeof(uint32_t) );

	sem_init( &sem_send, 0 , 0);
	sem_init( &sem_recv, 0 , 0);

	pthread_mutex_init( &mutex_send, NULL );
	pthread_mutex_init( &mutex_recv, NULL );
	pthread_mutex_lock( &mutex_send );
	pthread_mutex_lock( &mutex_recv );


}

void test_destroy(){

	mbox_destroy( &mb_send );
	mbox_destroy( &mb_recv );

	rq_close( &rqueue_send );
	rq_close( &rqueue_recv );

	sem_close( &sem_send);
	sem_close( &sem_recv);

	pthread_mutex_destroy( &mutex_send );
	pthread_mutex_destroy( &mutex_recv );
}

typedef bool (*test_func)();
test_func test_array[] = {
		test_echo,
		test_mbox,
		test_rqueue,
		test_sem,
		test_mutex,
		test_cond,
		NULL
};

struct reconos_resource res[] = {{.type = RECONOS_TYPE_MBOX, .ptr  = &mb_send},
								{.type = RECONOS_TYPE_MBOX, .ptr  = &mb_recv},
                      			{.type = RECONOS_TYPE_RQ, .ptr  = &rqueue_send},
                      			{.type = RECONOS_TYPE_RQ, .ptr  = &rqueue_recv},
                      			{.type = RECONOS_TYPE_SEM, .ptr  = &sem_send},
                      			{.type = RECONOS_TYPE_SEM, .ptr  = &sem_recv},
                      			{.type = RECONOS_TYPE_MUTEX, .ptr  = &mutex_send},
                      			{.type = RECONOS_TYPE_MUTEX, .ptr  = &mutex_recv},
                      			{.type = RECONOS_TYPE_COND, .ptr  = &cond_send},
                      			{.type = RECONOS_TYPE_COND, .ptr  = &cond_recv}};
struct reconos_hwt hwt;

int main(int argc, char ** argv)
{
	int i = 0;
	bool passed = true;

	// init reconos and communication resources
	reconos_init_autodetect();
	// twiddle with reset signal
	reconos_slot_reset(WORKERCPU_SLOT, 1);
	reconos_slot_reset(WORKERCPU_SLOT, 0);

	printf("sizeof(res)= %lu\n", sizeof(res)/sizeof(struct reconos_resource));
    reconos_hwt_setresources(&hwt,res,sizeof(res)/sizeof(struct reconos_resource));
    reconos_hwt_create(&hwt,0,NULL);

    test_init();
	while (test_array[i] != NULL && passed == true){
		printf("Calling test %i\n", i);
		passed = test_array[i]();
		i++;
	}
	test_destroy();
	return 0;
}

