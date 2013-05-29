/*
 * workercpu.c
 *
 *  Created on: Apr 23, 2013
 *      Author: meise
 */


#include "reconos.h"
#include "fsl.h"
#include "timing.h"
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

#define REPETITIONS 8192

void reconos_slot_reset(int num, int reset);

bool echo_setup(){
	return true;
}
bool echo_test(){
	printf("\nBeginning Benchmark...\n");
	sleep(1); // wait until workercpu sent exit command to delegate thread
	uint32_t input = 1337;
	uint32_t output = 0;
	timing_t t_start, t_stop;
	int i;

	t_start = gettime();
	for ( i=0; i< REPETITIONS; i++){
		fsl_write(WORKERCPU_SLOT, input);
		//output = fsl_read(WORKERCPU_SLOT);
	}
	t_stop = gettime();
	printf ("Write Speed : Bytes: %i, Time (ms): %li\n", REPETITIONS*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Write Speed : %f KB/s\n", ((double)REPETITIONS*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	t_start = gettime();
	for ( i=0; i< REPETITIONS; i++){
		output = fsl_read(WORKERCPU_SLOT);
	}
	t_stop = gettime();
	printf ("Read Speed : Bytes: %i, Time (ms): %li\n", REPETITIONS*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Read Speed : %f KB/s\n", ((double)REPETITIONS*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	t_start = gettime();
	for ( i=0; i< REPETITIONS; i++){
		fsl_write(WORKERCPU_SLOT, input);
		output = fsl_read(WORKERCPU_SLOT);
	}
	t_stop = gettime();
	printf ("Echo Speed : Bytes: %i, Time (ms): %li\n", REPETITIONS*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Echo Speed : %f KB/s\n", ((double)REPETITIONS*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	return true;

}
bool echo_teardown(){
	return true;
}

bool echo_block_setup(){
	return true;
}
bool echo_block_test(){
	printf("\nBeginning Benchmark...\n");
	sleep(1); // wait until workercpu sent exit command to delegate thread
	uint32_t input[REPETITIONS] = {1337};
	uint32_t output[REPETITIONS] = {0};
	timing_t t_start, t_stop;

	t_start = gettime();

	fsl_write_block(WORKERCPU_SLOT, input, REPETITIONS*sizeof(uint32_t));

	t_stop = gettime();
	printf ("Write Speed : Bytes: %i, Time (ms): %li\n", REPETITIONS*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Write Speed : %f KB/s\n", ((double)REPETITIONS*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	t_start = gettime();

	fsl_read_block(WORKERCPU_SLOT, output, REPETITIONS*sizeof(uint32_t));

	t_stop = gettime();
	printf ("Read Speed : Bytes: %i, Time (ms): %li\n", REPETITIONS*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Read Speed : %f KB/s\n", ((double)REPETITIONS*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	t_start = gettime();

	fsl_write_block(WORKERCPU_SLOT, input, REPETITIONS*sizeof(uint32_t));
	fsl_read_block(WORKERCPU_SLOT, output, REPETITIONS*sizeof(uint32_t));

	t_stop = gettime();
	printf ("Echo Speed : Bytes: %i, Time (ms): %li\n", REPETITIONS*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Echo Speed : %f KB/s\n", ((double)REPETITIONS*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	return true;

}
bool echo_block_teardown(){
	return true;
}

#define MEMBENCH_WORD_COUNT 4194304 // 16MB
uint32_t * membench_input;
uint32_t * membench_output;
bool membench_setup(){

	membench_input = malloc(MEMBENCH_WORD_COUNT*sizeof(uint32_t));
	membench_output = malloc(MEMBENCH_WORD_COUNT*sizeof(uint32_t));
	return membench_input && membench_output;
}

bool membench_test(){
	printf("\nBeginning Benchmark...\n");


	uint32_t temp=0;
	timing_t t_start, t_stop;
	int i;

	t_start = gettime();
	memset(membench_output, 1337, MEMBENCH_WORD_COUNT*sizeof(uint32_t));
	t_stop = gettime();
	printf ("Write Speed : Bytes: %i, Time (ms): %li\n", MEMBENCH_WORD_COUNT*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Write Speed : %f KB/s\n", ((double)MEMBENCH_WORD_COUNT*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	t_start = gettime();
	for ( i=0; i< MEMBENCH_WORD_COUNT; i++){
		temp ^= membench_input[i];
	}
	t_stop = gettime();
	printf("XORed temp: %u\n", temp);
	printf ("Read Speed : Bytes: %i, Time (ms): %li\n", MEMBENCH_WORD_COUNT*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Read Speed : %f KB/s\n", ((double)MEMBENCH_WORD_COUNT*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	t_start = gettime();
	memcpy(membench_output, membench_input, MEMBENCH_WORD_COUNT*sizeof(uint32_t));
	t_stop = gettime();
	printf ("Copy Speed : Bytes: %i, Time (ms): %li\n", MEMBENCH_WORD_COUNT*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Copy Speed : %f KB/s\n", ((double)MEMBENCH_WORD_COUNT*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	return true;
#undef MEMBENCH_WORD_COUNT
}

bool membench_teardown(){
	free(membench_input);
	free(membench_output);
	return true;
}

struct mbox mb_send;
struct mbox mb_recv;
bool mbox_setup(){
	mbox_init( &mb_send, 1 );
	mbox_init( &mb_recv, 1 );
	return true;
}
bool mbox_test(){
	uint32_t input = 1337;
	uint32_t output;

	printf("TEST_MBOX: putting %u into mbox.\n", input);

	mbox_put( &mb_send, input );
	printf("TEST_MBOX:  in between...\n");
	output = mbox_get( &mb_recv );
	printf("TEST_MBOX: read %u from mbox.\n", output);

	return output == input;
}
bool mbox_teardown(){
	mbox_destroy( &mb_send );
	mbox_destroy( &mb_recv );
	return true;
}

rqueue rqueue_send;
rqueue rqueue_recv;
#define BUFFER_SIZE REPETITIONS*sizeof(uint32_t)
uint32_t send_buffer[BUFFER_SIZE/sizeof(uint32_t)];
uint32_t recv_buffer[BUFFER_SIZE/sizeof(uint32_t)];

bool rqueue_setup(){
	rq_init( &rqueue_send, 1 );
	rq_init( &rqueue_recv, 1 );
	return true;
}
bool rqueue_test(){
	memset(send_buffer, 1337, BUFFER_SIZE);
	memset(recv_buffer, 1337, BUFFER_SIZE);
	//printf("TEST_RQUEUE: sending %u via rqueue.\n", send_buffer[0]);
	rq_send( &rqueue_send, send_buffer, BUFFER_SIZE );
	//printf("TEST_RQUEUE: sent.\n");
	rq_receive( &rqueue_recv, recv_buffer, BUFFER_SIZE );
	//printf("TEST_RQUEUE: received %u via rqueue.\n", recv_buffer[0]);

	return memcmp(send_buffer, recv_buffer, BUFFER_SIZE) == 0;
}
bool rqueue_teardown(){
	rq_close( &rqueue_send );
	rq_close( &rqueue_recv );
	return true;
}

sem_t sem_send;
sem_t sem_recv;
bool sem_setup(){
	sem_init( &sem_send, 0 , 0);
	sem_init( &sem_recv, 0 , 0);
	return true;
}
bool sem_test() {
	//printf("TEST_SEM: Posting semaphore, then waiting for another...\n");
	sem_post( &sem_send );
	sem_wait( &sem_recv );
	//printf("TEST_SEM: Got semaphore!\n");
	return true;
}
bool sem_teardown(){
	sem_close( &sem_send);
	sem_close( &sem_recv);
	return true;
}

pthread_mutex_t mutex_send;
pthread_mutex_t mutex_recv;
bool mutex_setup(){
	pthread_mutex_init( &mutex_send, NULL );
	pthread_mutex_init( &mutex_recv, NULL );
	pthread_mutex_lock( &mutex_send );
	pthread_mutex_lock( &mutex_recv );
	return true;
}
bool mutex_test() {
	//printf("TEST_MUTEX: first unlocking mutex, then trying to lock another one.\n");
	pthread_mutex_unlock( &mutex_send );
	pthread_mutex_lock( &mutex_recv );
	//printf("TEST_MUTEX: Got mutex lock!\n");
	return true;
}
bool mutex_teardown(){
	pthread_mutex_destroy( &mutex_send );
	pthread_mutex_destroy( &mutex_recv );
	return true;
}

pthread_cond_t cond_send;
pthread_cond_t cond_recv;
bool cond_setup(){
	return true;
}
bool cond_test() {
	printf("TEST_COND: not implemented.\n");
	return true;
}
bool cond_teardown(){
	return true;
}

typedef struct test {
	char * test_name;
	bool (* test_setup)();
	bool (* test_run)();
	bool (* test_teardown)();
} test_t;

bool test_setup(test_t  tests[]){
	bool setup_succeded;
	int i;
	printf("Setting up tests ... ");
	for ( i=0; tests[i].test_name != NULL; i++){
		setup_succeded = tests[i].test_setup();
		if (!setup_succeded){
			printf("setup of %s failed!\n", tests[i].test_name);
			return false;
		}
	}
	printf("done \n");
	return true;
}

bool test_run(test_t  tests[]){
	bool run_succeded;
	int i;
	for ( i=0; tests[i].test_name != NULL; i++){
		printf("Running test %s ", tests[i].test_name);
		run_succeded = tests[i].test_run();
		if (!run_succeded){
			printf("failed!\n");
			return false;
		} else {
			printf(" succeeded! \n");
		}
	}
	return true;
}

bool test_teardown(test_t tests[]){
	bool teardown_succeded;
	int i;
	printf("Tearing down tests ... ");
	for ( i=0; tests[i].test_name != NULL; i++){
		teardown_succeded = tests[i].test_teardown();
		if (!teardown_succeded){
			printf("setup of %s failed!\n", tests[i].test_name);
			return false;
		}
	}
	printf("done \n");
	return true;
}

test_t workercpu_tests[] = {
		{"MBOX Test", mbox_setup, mbox_test, mbox_teardown},
		{"RQUEUE Test", rqueue_setup, rqueue_test, rqueue_teardown},
		{"SEM Test", sem_setup, sem_test, sem_teardown},
		{"MUTEX Test", mutex_setup, mutex_test, mutex_teardown},
		{"COND Test", cond_setup, cond_test, cond_teardown},
		{"FSL Benchmark", echo_setup, echo_test, echo_teardown},
		{"FSL Block Ops Benchmark", echo_block_setup, echo_block_test, echo_block_teardown},
		{"Memory Access Benchmark", membench_setup, membench_test, membench_teardown},
		{NULL}
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
	bool test_success = true;
	// init reconos and communication resources
	reconos_init_autodetect();
	// twiddle with reset signal
	//reconos_slot_reset(WORKERCPU_SLOT, 1);
	//reconos_slot_reset(WORKERCPU_SLOT, 0);

	printf("sizeof(res)= %lu\n", sizeof(res)/sizeof(struct reconos_resource));
    reconos_hwt_setresources(&hwt,res,sizeof(res)/sizeof(struct reconos_resource));
    reconos_hwt_setprogram(&hwt, "sort_demo_workercpu.bin");
    reconos_hwt_create(&hwt,WORKERCPU_SLOT,NULL);


    printf("HWT created, starting tests ...\n");
    test_success =
    test_setup(workercpu_tests) &&
	test_run(workercpu_tests) &&
	test_teardown(workercpu_tests);

//    sleep(1000000);
    return !test_success;
}

