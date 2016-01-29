/*
 * cpuusage.c
 *
 *  Created on: Aug 6, 2015
 *      Author: meise
 */
#include "cpuusage.h"

static cpustats_t initial_stats;
#define OUTPUT stderr

static cpustats_t cpustats_parse(FILE * f){
	cpustats_t c;
	int ret;
	// parse the data. After cpu keyword data columns follow:
	// user mode, user mode low prio(nice), system mode, idle task, iowait, irq time, softirq time, steal(virtualized), guest (virtual cpu)
	rewind(f);
	ret = fscanf(f, "cpu  %u %u %u %u %u %u %u", &c.user, &c.nice, &c.system, &c.idle, &c.iowait, &c.irq, &c.softirq);
	if (ret != 7){
		fprintf(OUTPUT, "CPUSTATS ERROR: Could not parse /proc/cpustats!\n");
		exit(1);
	}
	return c;
}

cpustats_t cpustats_get(){
	FILE * cpustats_file = NULL;
	cpustats_t c;

	cpustats_file = fopen("/proc/stat","r");
	if (cpustats_file == NULL){
		fprintf(OUTPUT, "CPUSTATS ERROR: Could not open /proc/stat!\n");
		exit(1);
	}

	c = cpustats_parse(cpustats_file);
	fclose(cpustats_file);

	return c;
}

void cpuusage_init(){
	// open and parse the file
	initial_stats = cpustats_get();
}

double cpuusage_average(){

	cpustats_t current_stats;
	uint32_t busy_initial, busy_current, idle_initial, idle_current;
	uint32_t busy, idle;

	current_stats = cpustats_get();

	// Calc busy time and idle time of inital and current stats
	busy_initial = initial_stats.user + initial_stats.system + initial_stats.nice + initial_stats.irq + initial_stats.softirq;
	busy_current = current_stats.user + current_stats.system + current_stats.nice + current_stats.irq + current_stats.softirq;

	idle_initial = initial_stats.idle + initial_stats.iowait;
	idle_current = current_stats.idle + current_stats.iowait;

	// subtract inital and current stats
	busy = busy_current - busy_initial;
	idle = idle_current - idle_initial;

	// calculate relation: that is our busy time
	//printf("busy: %u  idle: %u\n", busy, idle);

	if ( (busy == 0) && (idle == 0) ){ return (double)0; }
	else { return (double)(busy) / (double) (busy+idle); }
}
