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
	memset(func_call, 0, sizeof(func_call));

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

/**
 * @brief Checks if two os calls are the same.
 * @param a Should be the TUO's func_call_t
 * @param a Should be the Shadow Thread's func_call_t
 */
int func_call_compare(func_call_t * a, func_call_t * b) {
	FC_DEBUG("Entered func_call_compare \n");

	int retval = 0;

	// Checks...
	if (a == NULL) {
		pthread_t tid = pthread_self();
		printf("#################################################\n");
		printf("# ERROR: the func_call_t a parameter is NULL!\n");
		printf("# Thread ID %lu \n", tid);
		printf("#################################################\n");
		exit(FC_EXIT_CODE);
	}
	if (b == NULL) {
			pthread_t tid = pthread_self();
			printf("#################################################\n");
			printf("# ERROR: the func_call_t b parameter is NULL!\n");
			printf("# Thread ID %lu \n", tid);
			printf("#################################################\n");
			exit(FC_EXIT_CODE);
	}

	if (a->function == NULL) {
		struct timeval now;
		gettimeofday(&now, NULL);
		unsigned long timediff = calc_timediff_us(a->timestamp, now);
		pthread_t tid = pthread_self();

		printf("#################################################\n");
		printf("# ERROR: a->function members is NULL!\n");
		printf("# call index: %i \n",a->index);
		printf("# Detected after %lu us\n", timediff);
		printf("# Thread ID %lu \n", tid);
		printf("#################################################\n");
		exit(FC_EXIT_CODE);
	}
	if (b->function == NULL) {
		struct timeval now;
		gettimeofday(&now, NULL);
		unsigned long timediff = calc_timediff_us(a->timestamp, now);
		pthread_t tid = pthread_self();

		printf("#################################################\n");
		printf("# ERROR: b->function members is NULL!\n");
		printf("# call index: %i \n",b->index);
		printf("# Detected after %lu us\n", timediff);
		printf("# Thread ID %lu \n", tid);
		printf("#################################################\n");
		exit(FC_EXIT_CODE);
	}
	if (strcmp(a->function, b->function) != 0) {
		struct timeval now;
		gettimeofday(&now, NULL);
		unsigned long timediff = calc_timediff_us(a->timestamp, now);
		pthread_t tid = pthread_self();

		printf("#################################################\n");
		printf("# ERROR: function calls  do not match!\n");
		printf("# call index: %i , shadow call: %s , original call: %s \n",
				a->index, b->function, a->function);
		printf("# Detected after %lu us\n", timediff);
		printf("# Thread ID %lu \n", tid);
		printf("#################################################\n");
		exit(FC_EXIT_CODE);
	}
	if (memcmp(a->params, b->params, FC_PARAM_SIZE) != 0) {
		int i;
		struct timeval now;
		gettimeofday(&now, NULL);
		unsigned long timediff = calc_timediff_us(a->timestamp, now);
		pthread_t tid = pthread_self();

		printf("#################################################\n");
		printf("# ERROR: parameters of function %s , call index %i, do not match!\n",
				a->function, a->index);
		printf("# My parameters:        ");
		for (i = 0;	i < FC_PARAM_SIZE; ++i)
		{
			printf("%2.2x", a->params[i]);
		}
		printf("\n# Should be parameters: ");
		for (i = 0;	i < FC_PARAM_SIZE; ++i)
		{
			printf("%2.2x", b->params[i]);
		}
		printf("\n# Detected after %lu us\n", timediff);
		printf("# Thread ID %lu \n", tid);
		printf("\n#################################################\n");
		exit(FC_EXIT_CODE);
	}
	FC_DEBUG("Leaving func_call_compare \n");
	return retval;
}

/**
 * @brief  Print information of one func_call
 */
void shadow_func_call_dump(func_call_t * fc) {
	int i;

	printf("%5u Func: %s Params: ", fc->index, fc->function);

	for (i = 0; i < FC_PARAM_SIZE; ++i) {
		printf("%2.2hhx", fc->params[i]);
	}

	printf(" RetVal: ");
	for (i = 0; i < FC_RETVAL_SIZE; ++i) {
		printf("%2.2hhx ", fc->retval[i]);
	}

	printf(" Add. RetVal: %ui", fc->retdata_length_write);
	printf("\n");
}
