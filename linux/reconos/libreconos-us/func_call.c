/*
 * func_call.c
 *
 *  Created on: 28.02.2013
 *      Author: meise
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>
#include <sys/time.h>
#include <pthread.h>
#include "func_call.h"

// #define DEBUG 1

#ifdef DEBUG
#define FC_DEBUG(message) printf("FC: " message)
#define FC_DEBUG1(message, arg1) printf("FC: " message, (arg1))
#define FC_DEBUG2(message, arg1, arg2) printf("FC: " message, (arg1), (arg2))
#else
#define FC_DEBUG(message)
#define FC_DEBUG1(message, arg1)
#define FC_DEBUG2(message, arg1, arg2)
#endif

/**
 * @brief  Helper function for benchmarking thread shadowing
 */
static unsigned long calc_timediff_us(struct timeval start, struct timeval stop) {
	unsigned long us;
	struct timeval diff;

	// calculate difference
	timersub(&stop, &start, &diff);
	// convert to miliseconds
	us = diff.tv_sec * 1000000 + diff.tv_usec;
	// this is very dirty, but allows to print the value via printf("%lu",ms)
	return us;
}

/**
 * @brief  Does the first part out of two of initalizing the func_call structure.
 * @note Called only by the leading thread!
 */
void func_call_new(func_call_t * func_call, const char *function) {
	FC_DEBUG("Entered func_call_new\n");
	assert(func_call);
	assert(function);

	// Clear it
	memset(func_call, 0, sizeof(func_call_t));

	func_call->function = (char *) function; // we accept to loose the 'const' qualifier

	// for benchmarking error detection latency
	gettimeofday(&func_call->timestamp, NULL);

	FC_DEBUG("Leaving func_call_new\n");
}

/*
 * @brief Releases all memory and other objects a func_call_t object might have acquired.
 */
void func_call_free(func_call_t * func_call){
	FC_DEBUG("Entered func_call_free\n");
	assert (func_call);
	if ( func_call->retdata )
	{
		free(func_call->retdata);
	}

	FC_DEBUG("Leaving func_call_new\n");
}

/**
 * @brief Add parameter data to the function call.
 *
 * This function can be repeatedly called until the preallocated parameter buffer is full.
 * There is no getter function, because we just want to compare the parameters of two function calls.
 * @return indicates how many data was stored to buffer.
 */
unsigned int func_call_add_param(func_call_t * func_call,void *params, unsigned int params_length){
	FC_DEBUG("Entered func_call_add_param\n");
	assert(func_call);
	assert(params);
	assert(params_length);
	unsigned int len = FC_PARAM_SIZE > params_length + func_call->params_length ?
						params_length :
						FC_PARAM_SIZE - func_call->params_length;
	if ( len > 0 )
	{
		memcpy(func_call->params + func_call->params_length, params, len);
		func_call->params_length += len;
	}
	FC_DEBUG("Leaving func_call_add_param\n");
	return len;
}

/**
 *  @brief Saves the function's return value to the func_call structure.
 *  The data pointed to by retval gets copied into an internal FC_RETVAL_SIZE-sized array.
 *  This function shall be called only once per func_call_t.
 */
void func_call_add_retval(func_call_t * func_call, void * retval, unsigned int retval_length) {
	FC_DEBUG("Entered func_call_add_retdata1\n");
	assert(func_call);
	assert(retval);
	memcpy(func_call->retval, retval,
			FC_RETVAL_SIZE > retval_length ? retval_length : FC_RETVAL_SIZE);
	FC_DEBUG("Leaving func_call_add_retdata1\n");
}

/**
 * @brief Adds additional return data to the func_call. Additional return data is returned via pointers in the function parameter list.
 * For additional return data, memory will be allocated via realloc.
 * This function may be called several times to store several pieces of additional return values.
 * For retrieving the data you will have to call func_call_add_retdata2 with the same sequence of length parameters.
 */
void func_call_add_retdata(func_call_t * func_call , void *retdata, unsigned int retdata_len){
	FC_DEBUG("Entered func_call_add_retdata2\n");
	assert(func_call);
	assert(retdata);
	void * temp_ptr;

	temp_ptr = realloc(func_call->retdata,func_call->retdata_length_write + retdata_len);
	assert(temp_ptr);
	func_call->retdata = temp_ptr;

	//printf("SUBS: realloc returned: %8p, for size %8i\n", retdata, retdata_idx+msg_size);
	memcpy(func_call->retdata + func_call->retdata_length_write, retdata, retdata_len);
	//printf("SUBS: memcpy succeded\n");
	func_call->retdata_length_write += retdata_len;

	FC_DEBUG("Leaving func_call_add_retdata2\n");
}


/**
 * @brief  Copies the function's return value into the buffer pointed to by retdata.
 * This function shall be called only once per func_call_t.
 * @return
 */
unsigned int func_call_get_retval(func_call_t * func_call , void * retval, unsigned int retval_len){
	FC_DEBUG("Entered func_call_get_retdata1\n");
	assert(func_call);
	unsigned int len = FC_RETVAL_SIZE > retval_len ? retval_len : FC_RETVAL_SIZE;
	memcpy(retval, func_call->retval, len);
	FC_DEBUG("Leaving func_call_get_retdata1\n");
	return len;
}

/**
 * @brief  Returns pointer via retdata pointing to additional return data.
 *
 * If you request to much data, you will get as much as is in the buffer.
 * Return value gives amount of copied data.
 */
unsigned int func_call_get_retdata(func_call_t * func_call , void * retdata, unsigned int retdata_len){
	FC_DEBUG("Entered func_call_get_retdata2\n");
	assert(func_call);
	assert(retdata);
	unsigned int len = func_call->retdata_length_write > func_call->retdata_length_read + retdata_len ?
						retdata_len:
						func_call->retdata_length_write - func_call->retdata_length_write;

	memcpy(retdata, func_call->retdata + func_call->retdata_length_read, retdata_len);
	func_call->retdata_length_read += retdata_len;

	FC_DEBUG("Leaving func_call_get_retdata2\n");
	return len;
}

const char *func_call_errlist[]=
		{
				"All went fine",
				"Argument a was NULL!",
				"Argument b was NULL!",
				"a->function was NULL!",
				"b->function was NULL!",
				"Function calls do not match!",
				"Parameters do not match!",
				"Indices of function calls do not match!"
		};

const char* func_call_strerror(int error)
{
	static char* unknown = "Unkown error occured";
	if (error >= 0 && error < sizeof(func_call_errlist))
	{
		return func_call_errlist[error];
	} else {
		return unknown;
	}
}

unsigned long func_call_timediff_us(func_call_t * a, func_call_t * b)
{
	if(a && b)
	{
		return  calc_timediff_us(a->timestamp, b->timestamp);
	} else {
		return 0;
	}
}
unsigned long func_call_timediff2_us(func_call_t * a, struct timeval * b)
{
	if(a && b)
	{
		return  calc_timediff_us( a->timestamp, *b);
	} else {
		return 0;
	}
}

/**
 * @brief Checks if two os calls are the same.
 * @param a Should be the TUO's func_call_t
 * @param a Should be the Shadow Thread's func_call_t
 * @retval Returns 0 if function calls match, else Return error code inidcating the type of error. See FC_ERR_*.
 *
 * @todo: Split comparison and reaction to not matching function calls.
 */
int func_call_compare(func_call_t * a, func_call_t * b) {
	FC_DEBUG("Entered func_call_compare \n");
	// Checks...
	if (a == NULL) {
		return FC_ERR_A_NULL;
	}
	if (b == NULL) {
		return FC_ERR_B_NULL;
	}
	if (a->function == NULL) {
		return FC_ERR_A_FUNCTION_NULL;
	}
	if (b->function == NULL) {
		return FC_ERR_B_FUNCTION_NULL;
	}
	if (strcmp(a->function, b->function) != 0) {
		return FC_ERR_FUNCTION_MATCH;
	}
	if (memcmp(a->params, b->params, FC_PARAM_SIZE) != 0) {
		return FC_ERR_PARAMS_MATCH;
	}
#if 0 /// @todo: maybe implement index checking. But does it have any use?
	if (a->index != b->index){
		return FC_ERR_INDEX_MATCH;
	}
#endif
	FC_DEBUG("Leaving func_call_compare \n");
	return FC_ERR_NONE;
}

/**
 * @brief  Print information of one func_call
 */
void func_call_dump(func_call_t * fc) {
	int i;
	if ( fc ) {
		printf("Idx: %10u Func: %s ", fc->index, fc->function);
		printf("Time: %10lu s %10lu us ", (unsigned long int)fc->timestamp.tv_sec,(unsigned long int)fc->timestamp.tv_usec);
		printf("Params Length :%2hhi Params: ", fc->params_length);
		for (i = 0; i < FC_PARAM_SIZE; ++i) {
			printf("%2.2hhx ", fc->params[i]);
		}
		printf(" RetVal: ");
		for (i = 0; i < FC_RETVAL_SIZE; ++i) {
			printf("%2.2hhx ", fc->retval[i]);
		}
		printf(" Add. RetVal: %ui", fc->retdata_length_write);
		printf("\n");
	}
}
