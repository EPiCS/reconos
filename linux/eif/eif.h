/*
 * eif.h
 *
 *  Created on: 07.12.2012
 *      Author: meise
 */

#ifndef EIF_H_
#define EIF_H_

typedef enum error_type {
	SINGLE_BIT_FLIP,
	MULTIPLE_BIT_FLIP,
	SET_VALUE,
	OR_VALUE,
	AND_VALUE
} error_t;

int  eif_add_trans(void* mem, unsigned int len, unsigned int error_cnt, unsigned int start_time, unsigned int end_time, error_t et, unsigned char ep);
int  eif_add_perma(void* mem, unsigned int len, unsigned int error_cnt, unsigned int start_time, unsigned int end_time, error_t et, unsigned char ep);
void eif_set_seed(unsigned int s);
int  eif_start();
void eif_stop();
void eif_join();

#endif /* EIF_H_ */
