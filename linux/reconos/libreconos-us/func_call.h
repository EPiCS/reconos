/*
 * func_call.h
 *
 *  Created on: 28.02.2013
 *      Author: meise
 */

#ifndef FUNC_CALL_H_
#define FUNC_CALL_H_

#include <sys/time.h>
#include <stdint.h>
#include "timing.h"
//
// Other Constants
//
#define FC_PARAM_SIZE 20 // via char type of params_length limited to 255
#define FC_RETVAL_SIZE 8

#define FC_ERR_NONE   0 // In case all went fine :-)
#define FC_ERR_A_NULL 1
#define FC_ERR_B_NULL 2
#define FC_ERR_A_FUNCTION_NULL 3
#define FC_ERR_B_FUNCTION_NULL 4
#define FC_ERR_FUNCTION_MATCH  5
#define FC_ERR_PARAMS_MATCH    6
#define FC_ERR_INDEX_MATCH     7 /// @todo Not yet implemented

typedef struct func_call {
	uint32_t index;
	char *function; // not a function pointer, because it points to a __FUNCTION__ string
	uint8_t params[FC_PARAM_SIZE]; // Size arbitrarily chosen
	uint8_t params_length; // Used to automatically place severa�� parameter into one array.
	uint8_t retval[FC_RETVAL_SIZE]; // Size choosen so that the biggest return value
								 // of all calls will fit in this field.
	void* retdata; // additional return data, used to store data which was transferred via parameters
	uint32_t retdata_length_write;
	uint32_t retdata_length_read;

	struct timeval timestamp; // for benchmarking error detection latency

} func_call_t;

extern const char *func_call_errlist[];
extern const char* unknown_error;
//
// OS-Call Management
//
void func_call_new	(func_call_t * func_call, const char *function);
void func_call_free	(func_call_t * func_call);

uint32_t		func_call_add_param		(func_call_t * func_call, void * params,  uint32_t params_length);
void 			func_call_add_retval	(func_call_t * func_call, void * retval,  uint32_t retval_length);
void 			func_call_add_retdata	(func_call_t * func_call, void * retdata, uint32_t retdata_len);
uint32_t		func_call_get_retval	(func_call_t * func_call, void * retval,  uint32_t retval_len);
uint32_t		func_call_get_retdata	(func_call_t * func_call, void * retdata, uint32_t retdata_len);
uint32_t		func_call_compare		(func_call_t * a, func_call_t * b);
uint32_t		func_call_compare_name	(func_call_t * a, func_call_t * b);
uint32_t		func_call_compare_param	(func_call_t * a, func_call_t * b);
const char* 	func_call_strerror		(uint32_t error);
timing_t		func_call_timediff_us	(func_call_t * a, func_call_t * b);
timing_t		func_call_timediff2_us	(struct timeval * a, func_call_t * b);
void 			func_call_dump			(func_call_t * fc);

#endif /* FUNC_CALL_H_ */
