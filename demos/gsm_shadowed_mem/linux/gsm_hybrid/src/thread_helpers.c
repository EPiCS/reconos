/*
 * thread_helpers.c
 *
 *  Created on: Mar 18, 2015
 *      Author: meise
 */

#include "thread_helpers.h"

//#ifdef SHADOWING
/*
args_info.hwt_arg
args_info.swt_arg
args_info.shadow_schedule_arg
sh
res
worker_progname
actual_sort_thread
*/
void prepare_threads_shadowing(int thread_count,
								struct reconos_resource * res,
								int reconos_resource_count,
								shadowedthread_t * sh,
								const char* worker_progname,
								void *(*actual_sort_thread)(void* data),
								int shadow_schedule,
								uint8_t level)
{
	//
	// Configure Threads
	//
	printf("Configuring %i shadowed threads: ", thread_count);
	for (int i = 0; i < thread_count; i++) {
		shadow_init( sh+i );
		shadow_set_level(sh+i, level);
		shadow_set_resources( sh+i, res+i*reconos_resource_count, reconos_resource_count );
		shadow_set_program( sh+i , worker_progname);
		shadow_set_swthread( sh+i, actual_sort_thread );
		if(shadow_schedule==0) {shadow_set_options(sh+i, TS_MANUAL_SCHEDULE);}
	}
}

void start_threads_shadowing_hw(int hwt_count,
								shadowedthread_t * sh,
								unsigned int * sh_free_idx,
								char * const actual_slot_map[],
								char * hwt_type,
								int shadow_flag,
								int shadow_transmodal_flag)
{
	reconos_init_autodetect();

	printf("Creating %i shadowed hw-threads: ", hwt_count);
	fflush(stdout);
	for (int i = *sh_free_idx; i < hwt_count+*sh_free_idx; i++)
	{
		printf(" %i",i);fflush(stdout);
		shadow_set_threadcount(sh+i, (shadow_flag+1), 0);
		for (int j=0; j< (shadow_flag+1); j++)
		{
			int slot_number;
			char * hardware;
			if ( j == 1 && shadow_transmodal_flag == 1) {
				hardware = "SLOT_WORKERCPU";
			} else {
				hardware = hwt_type;
			}
			slot_number = slot_map_find(actual_slot_map, hardware , (i*(shadow_flag+1))+j);
			if(slot_number == -1){printf("Warning: Requested HWT Type not found: %s\n", hardware);}
			shadow_set_hwslots(sh+i, j, slot_number);
			printf("Set thread %d.%d to slot %d\n", i,j, slot_number);
		}
		shadow_thread_create(sh+i);
	}
	*sh_free_idx += hwt_count;
	printf("\n");
}

void start_threads_shadowing_sw(int swt_count,
								shadowedthread_t * sh,
								unsigned int * sh_free_idx,
								char * const actual_slot_map[],
								char * hwt_type,
								int shadow_flag,
								int shadow_transmodal_flag)
{
	printf("Creating %i shadowed sw-threads: ",swt_count);
	fflush(stdout);

	for (int i = *sh_free_idx; i < *sh_free_idx+swt_count; i++)
	{
		printf(" %i",i-*sh_free_idx);fflush(stdout);
		shadow_set_threadcount(sh+i, (shadow_flag+1), 0);
		for (int j=0; j< (shadow_flag+1); j++)
		{
			int slot_number;
			char * hardware;
			if ( j == 1 && shadow_transmodal_flag == 1) {
				hardware = hwt_type;
			} else {
				hardware = "SLOT_WORKERCPU";
			}
			slot_number = slot_map_find(actual_slot_map, hardware , ((i-*sh_free_idx)*(shadow_flag+1))+j);
			if(slot_number == -1){printf("Warning: Requested HWT Type not found: %s\n", hardware);}
			shadow_set_hwslots(sh+i, j, slot_number);
			printf("Set thread %d.%d to slot %d\n", i,j, slot_number);
		}
		shadow_thread_create(sh+i);

	}
	*sh_free_idx += swt_count;
	printf("\n");
}

void start_threads_shadowing_host(int mt_count,
								shadowedthread_t * sh,
								unsigned int * sh_free_idx,
								char * const actual_slot_map[],
								char * hwt_type,
								int shadow_flag,
								int shadow_transmodal_flag)
{
	printf("Creating %i shadowed host-threads: ",mt_count);
	fflush(stdout);

	for (int i = *sh_free_idx; i < *sh_free_idx+mt_count; i++)
	{
		printf(" %i",i-*sh_free_idx);fflush(stdout);
		shadow_set_threadcount(sh+i,  0, (shadow_flag+1));
		for (int j=0; j< (shadow_flag+1); j++)
		{
			int slot_number;
			char * hardware;
			if ( j == 1 && shadow_transmodal_flag == 1) {
				hardware = hwt_type;
			} else {
				hardware = "SLOT_WORKERCPU";
			}
			slot_number = slot_map_find(actual_slot_map, hardware , ((i-*sh_free_idx)*(shadow_flag+1))+j);
			if(slot_number == -1){printf("Warning: Requested HWT Type not found: %s\n", hardware);}
			shadow_set_hwslots(sh+i, j, slot_number);
			printf("Set thread %d.%d to slot %d\n", i,j, slot_number);
		}
		shadow_thread_create(sh+i);

	}
	*sh_free_idx += mt_count;
	printf("\n");
}


void join_threads_shadowing(shadowedthread_t * sh, unsigned int running_threads){
	for (int i=0; i<running_threads; i++)
	{
		shadow_join(sh+i, NULL);
	}
}

//#endif //SHADOWING

/*
args_info.hwt_arg
res
hwt
worker_progname
actual_slot_map
 */
void start_threads_hw(int hwt_count,
						struct reconos_resource * res,
						int reconos_resource_count,
						struct reconos_hwt * hwt,
						char * hwt_type,
						char * const actual_slot_map[])
{
	// init reconos and communication resources
	reconos_init_autodetect();

	printf("Creating %i hw-threads: ", hwt_count);
	fflush(stdout);
	for (int i = 0; i < hwt_count; i++)
	{
		printf(" %i",i);fflush(stdout);
		reconos_hwt_setresources(&(hwt[i]),res+i*reconos_resource_count, reconos_resource_count);
		int slot_number = slot_map_find(actual_slot_map, hwt_type, i);
		if(slot_number == -1){
			printf("Warning: Requested HWT Type not found: %s\n", hwt_type);
			slot_map_print(actual_slot_map);
		}
		reconos_hwt_create(&(hwt[i]),
				slot_number,
				NULL);
	}
	printf("\n");
}

/*
args_info.swt_arg
res
hwt
worker_progname
workercpu_slots
 */
void start_threads_sw(int swt_count,
						struct reconos_resource * res,
						int reconos_resource_count,
						struct reconos_hwt * hwt_worker,
						const char* worker_progname,
						char * const actual_slot_map[])
{
	// init software threads
	printf("Creating %i sw-threads: ", swt_count);
	fflush(stdout);
	for (int i = 0; i < swt_count;i++) {
		printf(" %i", i);
		fflush(stdout);
		reconos_hwt_setresources(&(hwt_worker[i]), res+i*reconos_resource_count, reconos_resource_count);
		reconos_hwt_setprogram(&(hwt_worker[i]), worker_progname);
		int slot_number = slot_map_find(actual_slot_map, "SLOT_WORKERCPU", i);
		if(slot_number == -1){printf("Warning: Requested HWT Type not found: %s\n", "SLOT_WORKERCPU");}
		reconos_hwt_create(&(hwt_worker[i]),
				slot_number,
				NULL);
	}
}

void start_threads_host(int mt_count,
						struct reconos_resource * res,
						int reconos_resource_count,
						pthread_t * swt,
						pthread_attr_t * swt_attr,
						void *(*actual_sort_thread)(void* data))
{
	printf("Creating %i main-threads: ", mt_count);
	fflush(stdout);
	for (int i = 0; i < mt_count; i++) {
	 printf(" %i", i);
	 fflush(stdout);
	 pthread_attr_init(&swt_attr[i]);
	 pthread_create(&swt[i], &swt_attr[i], actual_sort_thread,(void*) (res+i*reconos_resource_count));
	 }
	printf("\n");
}


void join_threads(unsigned int num_sw_threads, pthread_t * swt,
				unsigned int num_hw_threads, struct reconos_hwt * hwt)
{
	for (int i = 0; i < num_hw_threads; i++) {
		pthread_join(hwt[i].delegate, NULL);
	}

	for (int i = 0; i < num_sw_threads; i++) {
		pthread_join(swt[i], NULL);
	}

/* @BUG: Join commands in non shadowed mode are mixed up!
	for (i = 0; i < args_info.mt_arg; i++) {
		pthread_join(swt[i], NULL);
	}
*/
}

