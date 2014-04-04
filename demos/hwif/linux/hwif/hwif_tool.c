/*
 * hwif_tool.c
 *
 *  Created on: Mar 24, 2014
 *      Author: meise
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>

#include "hwif.h"

int main(int argc, char **argv) {
	int i;
	//int j;
	uint8_t count_nr=0;
	uint8_t hwt_nr=0;
	bool reset = false;
	bool enable = false;
	bool disable = false;
	bool read_counters = false;

	int opt;
	/*
	 * Parse command line
	 */
    while ((opt = getopt(argc, argv, "redc")) != -1) {
        switch (opt) {
        case 'r':
            reset = true;
            break;
        case 'e':
            enable = true;
            break;
        case 'd':
			disable = true;
			break;
        case 'c':
			read_counters = true;
			break;
        default: /* '?' */
            fprintf(stderr, "Usage: %s [-r] [-e|-d] [-c] perfmon_index\n",
                    argv[0]);
            exit(EXIT_FAILURE);
        }
    }
    if (optind >= argc) {
        fprintf(stderr, "Expected perfmon index after options\n");
        exit(EXIT_FAILURE);
    }


	puts("Starting hwif_tool...\n");
	puts("Opening HWIF...\n");
	hwif_init();

    hwt_nr = atoi(argv[optind]);
    printf("Accessing perfmon %2i.\n", hwt_nr);
    count_nr = hwif_perfmon_get_number_of_counters(hwt_nr);
    printf("Perfmon %2i has %3i counters. \n", hwt_nr, count_nr);

	if (reset){
		printf("Resetting perfmon %2i...\n", hwt_nr);
		hwif_perfmon_reset(hwt_nr);
	}

	if (enable){
		printf("Activating perfmon %2i...\n", hwt_nr);
		hwif_perfmon_activate(hwt_nr);
	}

	if (disable){
		printf("Deactivating perfmon %2i...\n", hwt_nr);
		hwif_perfmon_deactivate(hwt_nr);
	}

	if (read_counters){
		printf("Reading counters from perfmon %2i...\n", hwt_nr);
		for (i = 0; i < count_nr; ++i) {
			printf("%10i " ,hwif_perfmon_read_counter(hwt_nr, i) );
		}
		printf("\n");
	}

//	puts("Reading number of counters from every perfmon...");
//	for (i = 0; i<MAX; i++){
//		count_nr = hwif_perfmon_get_number_of_counters(i);
//		printf("Perfmon %2i, Counter Number: %10i\n" , i, count_nr );
//	}
//
//	puts("Debug print mmap area of perfmons...");
//	for (i = 0; i<MAX; i++){
//		printf("Perfmon %i\n",i);
//		hwif_perfmon_debug_print(i);
//	}


//	puts("Deactivating perfmons...");
//	for (i = 0; i<MAX; i++){
//		hwif_perfmon_deactivate(i);
//	}
//
//	puts("Debug print mmap area of perfmons...");
//	for (i = 0; i<MAX; i++){
//		printf("Perfmon %i\n",i);
//		hwif_perfmon_debug_print(i);
//	}

//	puts("Reading counters from every perfmon...");
//	for (i = 0; i<MAX; i++){
//		printf("Perfmon %2i Counters ",i);
//		for (j = 0; j < count_nr; ++j) {
//			printf("%10i " ,hwif_perfmon_read_counter(i, j) );
//		}
//		printf("\n");
//	}
//	puts("Reseting perfmons...");
//	for (i = 0; i<MAX; i++){
//		hwif_perfmon_reset(i);
//	}
//	puts("Reading first counter from every perfmon...");
//	for (i = 0; i<MAX; i++){
//		printf("Perfmon %2i, Counter 0: %10i\n" , i, hwif_perfmon_read_counter(i, 0) );
//	}
	puts("Closing HWIF...\n");
	hwif_close();

	return EXIT_SUCCESS;

}
