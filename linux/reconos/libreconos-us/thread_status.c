/*
 * thread_status.c
 *
 *  Created on: 19.01.2017
 *      Author: meise
 */

#include "thread_status.h"
#include <inttypes.h>
#include <sys/types.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>

#define OUTPUT stderr
#define MAX_THREADS 32
static threadstats_t threadstats[MAX_THREADS];

static threadstats_t  thread_status_parse(FILE * f){
	threadstats_t ts;
	int ret;
	rewind(f);
	ret = fscanf(f, "%d %31s %c %d %d %*d %*d %*d %*u %*u"
					"%*u %*u %*u %*u %*u %*d %*d %*d %*d %d"
					"%*d %*u %*u %*d %*u %u %u %u %u %u",
					&ts.pid, ts.comm, &ts.state, &ts.ppid, &ts.pgrp,
					&ts.num_threads, &ts.startcode,
					&ts.endcode, &ts.startstack, &ts.kstkesp, &ts.kstkeip);
	if (ret !=11){
		fprintf(OUTPUT, "THREAD_STATUS ERROR: Could only parse %d elements of stats file!\n", ret);
		perror("THREAD_STATUS ERROR");
		exit(EXIT_FAILURE);
	}
	return ts;
}

/*
 * This function reads status information from the /proc filesystem and
 * reads it into a global variable to fetch details from later on.
 *
 * This version assumes old/embedded linux versions, where threads are treated
 * like processes, so every threads has its stats file under /proc/<pid>.
 */
static void thread_status_fetch_shallow(uint32_t * num_of_threads){
	int dir_count = 0;
	struct dirent* dent;
	DIR* srcdir;
	struct stat st;
	char stat_path[16+10+5+1];
	FILE* stat_file;

	threadstats_t threadstats_own;

	// Get own stat information -> we gain executable name and process group id
	stat_file = fopen("/proc/self/stat", "r");
	if (stat_file == NULL) { perror("thread_status error:"); exit(-1); }
	threadstats_own = thread_status_parse(stat_file);
	fclose(stat_file);

	// Scan all processes stat files and keep only that with the same exe name and process group
	srcdir = opendir("/proc/");
	if (srcdir == NULL)	{perror("opendir");	exit(-1);}

	// open  /proc/*/stat files
	while((dent = readdir(srcdir)) != NULL) {
		// skip local and parent directory entries
		if(strcmp(dent->d_name, ".")    == 0 ||
		   strcmp(dent->d_name, "..")   == 0 ||
		   strcmp(dent->d_name, "self") == 0 ||
		   strcmp(dent->d_name, "thread-self") == 0){
			continue;
		}

		// is current directory entry a directory?
		snprintf(stat_path, sizeof(stat_path),"/proc/%s",dent->d_name);
		if (stat(stat_path, &st) < 0) {
			perror(dent->d_name);
			continue;
		}
		// file is directory -> try open file stats under it and parse it
		if (S_ISDIR(st.st_mode)){
			snprintf(stat_path, sizeof(stat_path),"/proc/%s/stat",dent->d_name);
			if (stat(stat_path, &st) < 0) {
				//perror(dent->d_name);
				continue;
			}
			if (S_ISREG(st.st_mode)){
				stat_file = fopen(stat_path, "r");
				if (stat_file == NULL) { continue; }
				threadstats[dir_count] = thread_status_parse(stat_file);
				fclose(stat_file);

				// compare read stats with ourself, and only keep it if same
				// executable name and process group
				if ( (strncmp(threadstats_own.comm,threadstats[dir_count].comm,32) == 0) &&
					 (threadstats_own.pgrp == threadstats[dir_count].pgrp)){
					dir_count++;
				}
			}
		}
	}
	closedir(srcdir);
	if (num_of_threads != NULL){ *num_of_threads = dir_count;}
}

/*
 * This function reads status information from the /proc filesystem and
 * reads it into a global variable to fetch details from later on.
 *
 * This version assumes modern Linuy Kernel Versions, where threads have
 * their stats file under the process' proc directory in /proc/self/task/<tid>.
 */
static void thread_status_fetch_deep(uint32_t * num_of_threads){
	int dir_count = 0;
	struct dirent* dent;
	DIR* srcdir;
	struct stat st;
	char stat_path[16+10+5+1];
	FILE* stat_file;

	// open /proc/self/task/ directory
	srcdir = opendir("/proc/self/task/");
	if (srcdir == NULL)	{
		perror("opendir");
		exit(-1);
	}
	// open  /proc/self/task/*/stat files
	while((dent = readdir(srcdir)) != NULL)
	{
		// skip local and parent directory entries
		if(strcmp(dent->d_name, ".") == 0 || strcmp(dent->d_name, "..") == 0)
			continue;

		// is current directory entry a directory?
		snprintf(stat_path, sizeof(stat_path),"/proc/self/task/%s",dent->d_name);
		if (stat(stat_path, &st) < 0)
		{
			perror(dent->d_name);
			continue;
		}
		if (S_ISDIR(st.st_mode)){
			// file is directory -> try open file stats under it and parse it
			snprintf(stat_path, sizeof(stat_path),"/proc/self/task/%s/stat",dent->d_name);
			stat_file = fopen(stat_path, "r");
			if (stat_file == NULL) { continue; }
			threadstats[dir_count] = thread_status_parse(stat_file);
			fclose(stat_file);
			dir_count++;
		}
	}
	closedir(srcdir);

	if (num_of_threads != NULL){ *num_of_threads = dir_count;}
}

void thread_status_get(uint32_t thread_num, threadstats_t *ts){
	if (thread_num < MAX_THREADS){
		*ts = threadstats[thread_num];
	}
}

void thread_status_print(const threadstats_t *ts){
	fprintf(OUTPUT,"THREAD_STATUS: PID %8d, EXE %s,  STATE %c, PPID %d, PGRP %d, NUM_THREADS %d, "
			"STARTCODE 0x%x, ENDCODE 0x%x, STARTSTACK 0x%x, STACKPOINTER 0x%x,"
			"INSTRUCTIONPOINTER 0x%x\n",
			ts->pid, ts->comm, ts->state, ts->ppid, ts->pgrp, ts->num_threads, ts->startcode, ts->endcode,
			ts->startstack, ts->kstkesp, ts->kstkeip);
}

void thread_status_print_all(){
	uint32_t num_threads;
	uint32_t i;

	thread_status_fetch_shallow(&num_threads);
	for ( i=0; i< num_threads; ++i ) {
		thread_status_print(&threadstats[i]);
	}
}


#ifdef TESTING

#include <pthread.h>
#include <semaphore.h>

sem_t sem;


void* testthread(void* v){
	printf("Thread %lu started, trying to lock semaphore...\n", pthread_self());
	for(volatile uint32_t i =1 ; i!=0; ++i){

	}
	sem_wait(&sem);
	printf("Thread %lu locked semaphore, exiting now...\n", pthread_self());
	pthread_exit(0);
}

int main(int argc, char **argv) {
	pthread_t threads[10];
	uint32_t i;

	printf("THREAD_STATUS test program\n");
	sem_init(&sem,0,0);
	for(i=0; i<10; ++i){
		pthread_create(&threads[i], NULL,testthread, NULL);
	}

	sleep(1);
	thread_status_print_all();

	for(i=0; i<5; ++i){
		sem_post(&sem);
	}
	sleep(1);
	thread_status_print_all();

	for(i=0; i<5; ++i){
		sem_post(&sem);
	}

	thread_status_print_all();

	for(i=0; i<10; ++i){
		pthread_join(threads[i], NULL);
	}
}
#endif
