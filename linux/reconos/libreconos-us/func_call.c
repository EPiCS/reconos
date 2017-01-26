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
#include "timing.h"
#include "func_call.h"

//#define DEBUG 1
#define OUTPUT stderr

#ifdef DEBUG
#define FC_DEBUG(message) fprintf(OUTPUT, "FC: " message)
#define FC_DEBUG1(message, arg1) fprintf(OUTPUT, "FC: " message, (arg1))
#define FC_DEBUG2(message, arg1, arg2) fprintf(OUTPUT, "FC: " message, (arg1), (arg2))
#else
#define FC_DEBUG(message)
#define FC_DEBUG1(message, arg1)
#define FC_DEBUG2(message, arg1, arg2)
#endif

/**
 * @brief  Does the first part out of two of initalizing the func_call structure.
 * @note Called only by the leading thread!
 */
void func_call_new(func_call_t * func_call, const char *function) {
	FC_DEBUG("Entered func_call_new\n");
	assert(func_call != NULL);
	assert(function != NULL);

	// Clear it
	memset(func_call, 0, sizeof(func_call_t));

	func_call->function = (char *) function; // we accept to loose the 'const' qualifier

	// for benchmarking error detection latency
	func_call->timestamp = gettime();

	FC_DEBUG("Leaving func_call_new\n");
}

/*
 * @brief Releases all memory and other objects a func_call_t object might have acquired.
 */
void func_call_free(func_call_t * func_call){
	FC_DEBUG("Entered func_call_free\n");
	assert (func_call != NULL);
	if ( func_call->retdata != NULL )
	{
		free(func_call->retdata);
		func_call->retdata = NULL;
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
uint32_t func_call_add_param(func_call_t * func_call,void *params, uint32_t params_length){
	uint32_t len;
	FC_DEBUG("Entered func_call_add_param\n");
	assert(func_call != NULL);
	assert(params != NULL);
	assert(params_length != 0);

	len = (FC_PARAM_SIZE > (params_length + func_call->params_length) ) ?
						(params_length) :
						(FC_PARAM_SIZE - func_call->params_length);
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
void func_call_add_retval(func_call_t * func_call, void * retval, uint32_t retval_length) {
	FC_DEBUG("Entered func_call_add_retdata1\n");
	assert(func_call != NULL);
	assert(retval != NULL);
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
void func_call_add_retdata(func_call_t * func_call , void *retdata, uint32_t retdata_len){
	void * temp_ptr;
	FC_DEBUG("Entered func_call_add_retdata2\n");
	assert(func_call != NULL);
	assert(retdata != NULL);

	temp_ptr = realloc(func_call->retdata,func_call->retdata_length_write + retdata_len);
	assert(temp_ptr != NULL);
	func_call->retdata = temp_ptr;

	//fprintf(OUTPUT, "SUBS: realloc returned: %8p, for size %8i\n", retdata, retdata_idx+msg_size);
	memcpy(func_call->retdata + func_call->retdata_length_write, retdata, retdata_len);
	//fprintf(OUTPUT, "SUBS: memcpy succeded\n");
	func_call->retdata_length_write += retdata_len;

	FC_DEBUG("Leaving func_call_add_retdata2\n");
}


/**
 * @brief  Copies the function's return value into the buffer pointed to by retdata.
 * This function shall be called only once per func_call_t.
 * @return
 */
uint32_t func_call_get_retval(func_call_t * func_call , void * retval, uint32_t retval_len){
	uint32_t len;
	FC_DEBUG("Entered func_call_get_retdata1\n");
	assert(func_call != NULL);
	len = (FC_RETVAL_SIZE > retval_len) ? retval_len : FC_RETVAL_SIZE;
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
uint32_t func_call_get_retdata(func_call_t * func_call , void * retdata, uint32_t retdata_len){
	uint32_t len;
	FC_DEBUG("Entered func_call_get_retdata2\n");
	assert(func_call != NULL);
	assert(retdata != NULL);
	len = func_call->retdata_length_write > func_call->retdata_length_read + retdata_len ?
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
const char* unknown_error = "Unkown error occured";

const char* func_call_strerror(uint32_t  error)
{
	if ( error < sizeof(func_call_errlist) )
	{
		return func_call_errlist[error];
	} else {
		return unknown_error;
	}
}

timing_t func_call_timediff_us(func_call_t * a, func_call_t * b)
{
	timing_t diff;
	assert(a != NULL);
	assert(b != NULL);

	timerdiff(&a->timestamp, &b->timestamp, &diff);
	return diff;

}
timing_t func_call_timediff2_us(struct timeval * a, func_call_t * b)
{
	timing_t diff;
	assert(a != NULL);
	assert(b != NULL);

	timerdiff(a, &b->timestamp, &diff);
	return diff;
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
	int check_result;
	FC_DEBUG("Entered func_call_compare \n");
	// Checks...
	check_result = func_call_compare_name(a,b);
	if ( check_result != FC_ERR_NONE ){ return check_result; }

	check_result = func_call_compare_param(a,b);
	if ( check_result != FC_ERR_NONE ){ return check_result; }

#if 0 /// @todo: maybe implement index checking. But does it have any use?
	if (a->index != b->index){
		return FC_ERR_INDEX_MATCH;
	}
#endif
	FC_DEBUG("Leaving func_call_compare \n");
	return FC_ERR_NONE;
}

int func_call_compare_name(func_call_t * a, func_call_t * b) {
	FC_DEBUG("Entered func_call_compare_name \n");
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
	FC_DEBUG("Leaving func_call_compare_name \n");
	return FC_ERR_NONE;
}

int func_call_compare_param(func_call_t * a, func_call_t * b) {
	FC_DEBUG("Entered func_call_compare_param \n");
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
	if (memcmp(a->params, b->params, FC_PARAM_SIZE) != 0) {
		return FC_ERR_PARAMS_MATCH;
	}
	FC_DEBUG("Leaving func_call_compare_param \n");
	return FC_ERR_NONE;
}

/**
 * @brief  Print information of one func_call
 */
void func_call_dump(func_call_t * fc) {
	int i;
	if ( fc ) {
		fprintf(OUTPUT, "Idx: %10u Func: %s ", fc->index, fc->function);
		fprintf(OUTPUT, "Time: %10lu s %10lu us ", (unsigned long int)fc->timestamp.tv_sec,(unsigned long int)fc->timestamp.tv_usec);
		fprintf(OUTPUT, "Params Length :%2hhi Params: ", fc->params_length);
		for (i = 0; i < FC_PARAM_SIZE; ++i) {
			fprintf(OUTPUT, "%2.2hhx ", fc->params[i]);
		}
		fprintf(OUTPUT, " RetVal: ");
		for (i = 0; i < FC_RETVAL_SIZE; ++i) {
			fprintf(OUTPUT, "%2.2hhx ", fc->retval[i]);
		}
		fprintf(OUTPUT, " Add. RetVal: %ui", fc->retdata_length_write);
		fprintf(OUTPUT, "\n");
	}
}
