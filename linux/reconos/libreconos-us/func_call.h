/*
 * func_call.h
 *
 *  Created on: 28.02.2013
 *      Author: meise
 */

#ifndef FUNC_CALL_H_
#define FUNC_CALL_H_

//
// Other Constants
//
#define FC_PARAM_SIZE 20 // via char type of params_length limited to 255
#define FC_RETVAL_SIZE 8
#define FC_EXIT_CODE 16

#define FC_ERR_NONE   0 // In case all went fine :-)
#define FC_ERR_A_NULL 1
#define FC_ERR_B_NULL 2
#define FC_ERR_A_FUNCTION_NULL 3
#define FC_ERR_B_FUNCTION_NULL 4
#define FC_ERR_FUNCTION_MATCH  5
#define FC_ERR_PARAMS_MATCH    6
#define FC_ERR_INDEX_MATCH     7 /// @todo Not yet implemented

typedef struct func_call {
	unsigned int index;
	char *function; // not a function pointer, because it points to a __FUNCTION__ string
	char params[FC_PARAM_SIZE]; // Size arbitrarily chosen
	char params_length; // Used to automatically place severaö parameter into one array.
	char retval[FC_RETVAL_SIZE]; // Size choosen so that the biggest return value
								 // of all calls will fit in this field.
	void* retdata; // additional return data, used to store data which was transferred via parameters
	unsigned int retdata_length_write;
	unsigned int retdata_length_read;

	struct timeval timestamp; // for benchmarking error detection latency

} func_call_t;


//
// OS-Call Management
//
void func_call_new	(func_call_t * func_call, const char *function);
void func_call_free	(func_call_t * func_call);

unsigned int	func_call_add_param		(func_call_t * func_call, void * params,  unsigned int params_length);
void 			func_call_add_retval	(func_call_t * func_call, void * retval,  unsigned int retval_length);
void 			func_call_add_retdata	(func_call_t * func_call, void * retdata, unsigned int retdata_len);
unsigned int 	func_call_get_retval	(func_call_t * func_call, void * retval,  unsigned int retval_len);
unsigned int  	func_call_get_retdata	(func_call_t * func_call, void * retdata, unsigned int retdata_len);
int  			func_call_compare		(func_call_t * a, func_call_t * b);
const char* 	func_call_strerror		(int error);
unsigned long 	func_call_timediff_us	(func_call_t * a, func_call_t * b);
void 			func_call_dump			(func_call_t * fc);

#endif /* FUNC_CALL_H_ */
