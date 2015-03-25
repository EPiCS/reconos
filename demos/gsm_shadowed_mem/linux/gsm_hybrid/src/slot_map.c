/*
 * slot_map.c
 *
 *  Created on: Mar 18, 2015
 *      Author: meise
 */

#include "slot_map.h"

char * actual_slot_map[] = {
		"SLOT_GSM", "SLOT_GSM",
		NULL};


// nth starts with 0!
int slot_map_find(char * const  map[], const char * hwt_type, int nth){
	int found_at_index=-1;
	for (int i = 0; map[i] != NULL ; i++){
		if (strcmp(map[i],hwt_type) == 0){nth--;}
		if (nth == -1){found_at_index = i; break;}
	}
	return found_at_index;
}

void slot_map_print(char * const  map[]){
	printf("Slot Map:");
	for (int i = 0; map[i] != NULL ; i++){
		printf(" %s", map[i]);
	}
	printf("\n");
}
