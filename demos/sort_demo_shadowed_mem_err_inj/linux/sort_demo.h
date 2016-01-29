/*
 * sort_demo.h
 *
 *  Created on: 26.08.2013
 *      Author: meise
 */

#ifndef SORT_DEMO_H_
#define SORT_DEMO_H_

#define MAX_THREADS	32
#define MAX_RESOURCES 8
#define MAX_BLOCK_SIZE_WORDS	(8192/sizeof(unsigned int)) // number of words per block
#define PAGE_SIZE 1024 //4096 // In bytes, needed for correct memory alignment

#define TO_WORDS(x) ((x)/4)
#define TO_BLOCKS(buffer_size_bytes, block_size_bytes) ((buffer_size_bytes)/(block_size_bytes))

//
// Setup resources for communication with compute threads
// Maps thread number to hardware slot number.
//

//struct reconos_resource res[MAX_THREADS][2];

#define SLOT_END -1
#define SLOT_EMPTY 0
#define SLOT_WORKERCPU 1
#define SLOT_SORT_SHMEM 2
#define SLOT_SORT_MBOX  3
#define SLOT_SORT_RQ 	4

extern char *  actual_slot_map[];

#define EXIT_SUCCESS 0
#define EXIT_CMD_LINE_PARSE 1
#define EXIT_MALLOC 2
#define EXIT_FAULTY_RESULT 4
#define EXIT_FAULTY_RQ_RECV 24
#define EXIT_SEGFAULT 32

#endif /* SORT_DEMO_H_ */
