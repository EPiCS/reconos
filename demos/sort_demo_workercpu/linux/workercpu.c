/*
 * workercpu.c
 *
 *  Created on: Apr 23, 2013
 *      Author: meise
 */


#include "reconos.h"
#include "fsl.h"
#include "timing.h"
#include "xutils.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <pthread.h>
#include <assert.h>
#include <signal.h>
#include <sys/ucontext.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>

#include <mbox.h>
#include <rqueue.h>
#include <semaphore.h>

#define WORKERCPU_SLOT 1

#define WORKER_BUFFER_SIZE_BYTES 56000 // Keep in sync with worker program!
#define REPETITIONS WORKER_BUFFER_SIZE_BYTES/sizeof(uint32_t)

void reconos_slot_reset(int num, int reset);

bool echo_setup(){
	return true;
}
bool echo_test(){
	printf("\n");
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
	printf ("Write Speed : Bytes: %lu, Time (ms): %li\n", REPETITIONS*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Write Speed : %f KB/s\n", ((double)REPETITIONS*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	t_start = gettime();
	for ( i=0; i< REPETITIONS; i++){
		output = fsl_read(WORKERCPU_SLOT);
	}
	t_stop = gettime();
	printf ("Read Speed : Bytes: %lu, Time (ms): %li\n", REPETITIONS*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Read Speed : %f KB/s\n", ((double)REPETITIONS*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	t_start = gettime();
	for ( i=0; i< REPETITIONS; i++){
		fsl_write(WORKERCPU_SLOT, input);
		output = fsl_read(WORKERCPU_SLOT);
	}
	t_stop = gettime();
	printf ("Echo Speed : Bytes: %lu, Time (ms): %li\n", REPETITIONS*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Echo Speed : %f KB/s\n", ((double)REPETITIONS*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));
	printf("\n");
	return true;

}
bool echo_teardown(){
	return true;
}

bool echo_block_setup(){
	return true;
}
bool echo_block_test(){
	printf("\n");
	sleep(1); // wait until workercpu sent exit command to delegate thread
	uint32_t input[REPETITIONS] = {1337};
	uint32_t output[REPETITIONS] = {0};
	timing_t t_start, t_stop;

	t_start = gettime();

	fsl_write_block(WORKERCPU_SLOT, input, REPETITIONS*sizeof(uint32_t));

	t_stop = gettime();
	printf ("Write Speed : Bytes: %lu, Time (ms): %li\n", REPETITIONS*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Write Speed : %f KB/s\n", ((double)REPETITIONS*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	t_start = gettime();

	fsl_read_block(WORKERCPU_SLOT, output, REPETITIONS*sizeof(uint32_t));

	t_stop = gettime();
	printf ("Read Speed : Bytes: %lu, Time (ms): %li\n", REPETITIONS*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Read Speed : %f KB/s\n", ((double)REPETITIONS*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	t_start = gettime();

	fsl_write_block(WORKERCPU_SLOT, input, REPETITIONS*sizeof(uint32_t));
	fsl_read_block(WORKERCPU_SLOT, output, REPETITIONS*sizeof(uint32_t));

	t_stop = gettime();
	printf ("Echo Speed : Bytes: %lu, Time (ms): %li\n", REPETITIONS*4, calc_timediff_ms( t_start, t_stop ));
	printf ("Echo Speed : %f KB/s\n", ((double)REPETITIONS*4*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));
	printf("\n");

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
	uint32_t temp=0;
	timing_t t_start, t_stop;
	int i;
	printf("\n");
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
	printf("\n");
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

	timing_t t_start, t_stop;
	int i;

	printf("\n");
	t_start = gettime();
	for ( i=0; i<REPETITIONS; i++){
		mbox_put( &mb_send, input );
	}
	t_stop = gettime();
	printf ("Host put, Slave get : Repetitions: %lu, Time (ms): %li\n", REPETITIONS, calc_timediff_ms( t_start, t_stop ));
	printf ("put/gets speed : %f per second\n", ((double)REPETITIONS*1000) / ((double)calc_timediff_ms( t_start, t_stop )));


	t_start = gettime();
	for ( i=0; i<REPETITIONS; i++){
		output = mbox_get( &mb_recv );
	}
	t_stop = gettime();
	printf ("Host get, Slave out : Repetitions: %lu, Time (ms): %li\n", REPETITIONS, calc_timediff_ms( t_start, t_stop ));
	printf ("get/puts speed : %f per second\n", ((double)REPETITIONS*1000) / ((double)calc_timediff_ms( t_start, t_stop )));
	printf("\n");

	return output == input;
}
bool mbox_teardown(){
	mbox_destroy( &mb_send );
	mbox_destroy( &mb_recv );
	return true;
}

rqueue rqueue_send;
rqueue rqueue_recv;
#define RQUEUE_BUFFER_SIZE 1024 //bytes
uint32_t send_buffer[RQUEUE_BUFFER_SIZE/sizeof(uint32_t)];
uint32_t recv_buffer[RQUEUE_BUFFER_SIZE/sizeof(uint32_t)];

bool rqueue_setup(){
	rq_init( &rqueue_send, 1 );
	rq_init( &rqueue_recv, 1 );
	return true;
}
bool rqueue_test(){
	timing_t t_start, t_stop;
	int i;

	memset(send_buffer, 1337, RQUEUE_BUFFER_SIZE);
	memset(recv_buffer, 1337, RQUEUE_BUFFER_SIZE);
	printf("\n");
	printf("Buffer size: %i\n", RQUEUE_BUFFER_SIZE);
	t_start = gettime();
	for ( i=0; i<REPETITIONS; i++){
		rq_send( &rqueue_send, send_buffer, RQUEUE_BUFFER_SIZE );
	}
	t_stop = gettime();
	printf ("Host send, Slave receive : Repetitions: %lu, Time (ms): %li\n", REPETITIONS, calc_timediff_ms( t_start, t_stop ));
	printf ("send/receives speed : %f per second\n", ((double)REPETITIONS*1000) / ((double)calc_timediff_ms( t_start, t_stop )));

	t_start = gettime();
	for ( i=0; i<REPETITIONS; i++){
		rq_receive( &rqueue_recv, recv_buffer, RQUEUE_BUFFER_SIZE );
	}
	t_stop = gettime();
	printf ("Host receive, Slave send : Repetitions: %lu, Time (ms): %li\n", REPETITIONS, calc_timediff_ms( t_start, t_stop ));
	printf ("receive/sends speed : %f per second\n", ((double)REPETITIONS*1000) / ((double)calc_timediff_ms( t_start, t_stop )));
	printf("\n");
	return memcmp(send_buffer, recv_buffer, RQUEUE_BUFFER_SIZE) == 0;
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
	timing_t t_start, t_stop;
	int i;

	printf("\n");
	t_start = gettime();
	for ( i=0; i<REPETITIONS; i++){
		sem_post( &sem_send );
/*	}
	t_stop = gettime();
	printf ("Host post, Slave wait : Repetitions: %lu, Time (ms): %li\n", REPETITIONS, calc_timediff_ms( t_start, t_stop ));
	printf ("post/wait speed : %f per second\n", ((double)REPETITIONS*1000) / ((double)calc_timediff_ms( t_start, t_stop )));

	t_start = gettime();
	for ( i=0; i<REPETITIONS; i++){
*/		sem_wait( &sem_recv );
	}
	t_stop = gettime();
	printf ("Host wait, Slave post : Repetitions: %lu, Time (ms): %li\n", REPETITIONS, calc_timediff_ms( t_start, t_stop ));
	printf ("wait/posts speed : %f per second\n", ((double)REPETITIONS*1000) / ((double)calc_timediff_ms( t_start, t_stop )));
	printf("\n");

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
	timing_t t_start, t_stop;
	int i;

	printf("\n");
	t_start = gettime();
	for ( i=0; i<REPETITIONS; i++){
		pthread_mutex_unlock( &mutex_send );
/*	}
	t_stop = gettime();
	printf ("Host unlock, Slave lock : Repetitions: %lu, Time (ms): %li\n", REPETITIONS, calc_timediff_ms( t_start, t_stop ));
	printf ("unlock/lock speed : %f per second\n", ((double)REPETITIONS*1000) / ((double)calc_timediff_ms( t_start, t_stop )));

	t_start = gettime();
	for ( i=0; i<REPETITIONS; i++){
*/		pthread_mutex_lock( &mutex_recv );
	}
	t_stop = gettime();
	printf ("Host lock, Slave unlock : Repetitions: %lu, Time (ms): %li\n", REPETITIONS, calc_timediff_ms( t_start, t_stop ));
	printf ("lock/unlock speed : %f per second\n", ((double)REPETITIONS*1000) / ((double)calc_timediff_ms( t_start, t_stop )));
	printf("\n");
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

#define MEM_READ_BUFFER_SIZE_BYTES WORKER_BUFFER_SIZE_BYTES
#define PAGE_SIZE 4096
uint32_t  mem_read_buffer[MEM_READ_BUFFER_SIZE_BYTES/sizeof(uint32_t)];

bool mem_read_setup(){
	// We reuse the mailboxes from mbox tests
	mbox_setup();
	return true;
}

bool mem_read_test() {
	timing_t t_start, t_stop;

	uint32_t result;
	printf("\n");
	uint32_t tlb_hits;
	uint32_t tlb_misses;
	uint32_t page_faults;
	reconos_mmu_stats(&tlb_hits, &tlb_misses, &page_faults);
	printf("MMU Stats Before Request: TLB Hits: %u , TLB Misses: %u , Page Faults: %u\n", tlb_hits, tlb_misses, page_faults);

	printf("Preparing buffer...\n");
	memset(mem_read_buffer, 0x42, MEM_READ_BUFFER_SIZE_BYTES);

	printf("Sending worker address of buffer: %p ...\n", mem_read_buffer);
	t_start = gettime();
	mbox_put(&mb_send, (uint32_t)mem_read_buffer);

	printf("Waiting for worker reply...\n");
	result=mbox_get(&mb_recv); // address received?

	printf("Worker received address %p. Waiting for Memory Read to finish...\n", (uint32_t*)result);
	reconos_mmu_stats(&tlb_hits, &tlb_misses, &page_faults);
	printf("MMU Stats After Request: TLB Hits: %u , TLB Misses: %u , Page Faults: %u\n", tlb_hits, tlb_misses, page_faults);
	result=mbox_get(&mb_recv); // memory read?

	t_stop = gettime();
	printf ("Memory Read : Size of read: %u, Time (ms): %li\n", (uint32_t)MEM_READ_BUFFER_SIZE_BYTES, calc_timediff_ms( t_start, t_stop ));
	printf ("Read Speed : %f KB/s per second\n", ((double)MEM_READ_BUFFER_SIZE_BYTES*1000) / ((double)calc_timediff_ms( t_start, t_stop ) * 1024));

	printf("Worker read memory from address %p. Waiting for comparison results...\n", (uint32_t*) result);
	result=mbox_get(&mb_recv);
	printf("Worker send comparison results: %u \n", result); // memory read correctly?
	return result;
}

bool mem_read_teardown(){
	mbox_teardown();
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
//		{"MBOX Test", mbox_setup, mbox_test, mbox_teardown},
//		{"RQUEUE Test", rqueue_setup, rqueue_test, rqueue_teardown},
//		{"SEM Test", sem_setup, sem_test, sem_teardown},
//		{"MUTEX Test", mutex_setup, mutex_test, mutex_teardown},
//		{"COND Test", cond_setup, cond_test, cond_teardown},
//		{"FSL Benchmark", echo_setup, echo_test, echo_teardown},
//		{"FSL Block Ops Benchmark", echo_block_setup, echo_block_test, echo_block_teardown},
//		{"Memory Access Benchmark", membench_setup, membench_test, membench_teardown},
		{"Worker Memory Read", mem_read_setup, mem_read_test, mem_read_teardown},
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

/*
 * Signal handler for SIGSEGV. Used for debugging on a microblaze processor.
 * Get as much information to help in debugging as possible!
 */
void sigsegv_handler(int sig, siginfo_t *siginfo, void * context) {
	ucontext_t* uc = (ucontext_t*) context;

	// Yeah, i know using printf in a signal context is not save.
	// But with a SIGSEGV the programm is messed up anyway, so what?
	printf(
			"SIGSEGV: Programm killed at programm address %p, tried to access %p.\n",
#ifndef HOST_COMPILE
			(void*)uc->uc_mcontext.regs.pc,
#else
			(void*) uc->uc_mcontext.gregs[14],
#endif
			(void*) siginfo->si_addr);

#ifdef SHADOWING
	// Print OS call lists for debugging
	int i;
	for (i=0; i < running_threads; i++) {
		shadow_dump(sh + i);
	}
#endif
	exit(32);
}

int main(int argc, char ** argv)
{
	bool test_success = true;
	// init reconos and communication resources
	reconos_init_autodetect();
	// twiddle with reset signal
	//reconos_slot_reset(WORKERCPU_SLOT, 1);
	//reconos_slot_reset(WORKERCPU_SLOT, 0);


	//
	// Install signal handler for segfaults
	//
	struct sigaction act = { .sa_sigaction = sigsegv_handler, .sa_flags =
			SA_SIGINFO };
	sigaction(SIGSEGV, &act, NULL);


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

