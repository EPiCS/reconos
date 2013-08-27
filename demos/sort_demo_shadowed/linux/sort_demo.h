/*
 * sort_demo.h
 *
 *  Created on: 26.08.2013
 *      Author: meise
 */

#ifndef SORT_DEMO_H_
#define SORT_DEMO_H_

#define MAX_THREADS	32
#define MAX_BLOCK_SIZE_WORDS	(8192/sizeof(unsigned int)) // number of words per block

//
// Setup resources for communication with compute threads
// Maps thread number to hardware slot number.
//
struct reconos_resource res[MAX_THREADS][2];
const int shmem_slots[] = { 0, 1, 2, 3 };
const int mbox_slots[] = { 4, 5, 6, 7 };
//const int rqueue_slots[] = {8,9,10,11}; // mixed configuration
//const int rqueue_slots[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 }; //rqueue only configuration
const int rqueue_slots[] = { 7, 8, 9, 10, 11, 12, 13 };
const int workercpu_slots[] = { 0, 1, 2, 3, 4, 5, 6 };


#endif /* SORT_DEMO_H_ */
