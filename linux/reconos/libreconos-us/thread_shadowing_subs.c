///
/// \file thread_shadowing.h
/// Thread shadowing framework. Substitutions of OS-Operation for 
/// thread shadowing integration.
///
/// \author     Sebastian Meisner   <sebastian.meisner@upb.de>
/// \date       22.02.2012
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2012.
//


//
// Do not include thread_shadowing_subs.h or we won't be able to call the original functions!
//
#include <assert.h>
#include <stdbool.h>
#include <pthread.h>
#include <semaphore.h>
#include <stdio.h>

#include "mbox.h"
#include "rqueue.h"
#include "thread_shadowing_schedule.h"
#include "thread_shadowing.h"

extern shadowedthread_t *shadow_list_head;


//
// Debugging
//
#define DEBUG 1

#ifdef DEBUG
    #define SUBS_DEBUG(message) printf("SUBS: " message)
    #define SUBS_DEBUG1(message, arg1) printf("SUBS: " message, (arg1))
    #define SUBS_DEBUG2(message, arg1, arg2) printf("SUBS: " message, (arg1), (arg2))
    #define SUBS_DEBUG3(message, arg1, arg2, arg3) printf("SUBS: " message, (arg1), (arg2), (arg3))
    #define SUBS_DEBUG4(message, arg1, arg2, arg3, arg4) printf("SUBS: " message, (arg1), (arg2), (arg3), (arg4))
#else
    #define SUBS_DEBUG(message)
    #define SUBS_DEBUG1(message, arg1)
    #define SUBS_DEBUG2(message, arg1, arg2)
    #define SUBS_DEBUG3(message, arg1, arg2, arg3)
    #define SUBS_DEBUG4(message, arg1, arg2, arg3, arg4)
#endif

#define NONBLOCKING 0
#define BLOCKING 	 1

//
// Shadow Layer initialization function
//
#define SHADOW_INIT \
	pthread_t this = pthread_self(); \
	shadowedthread_t *sh; \
	os_call_t os_call;\
	bool is_shadowed = false; \
	bool is_leading_thread = false;\
	shadow_state_t status = TS_INACTIVE;\
	char params[TS_PARAM_SIZE];\
	unsigned int params_idx=0;\
	SUBS_DEBUG2("Thread %8lu %s() START \n", this, __FUNCTION__); \
	is_shadowed = is_shadowed_in_parent(this, &sh); \

//
// Tell the Shadow Layer about parameters you want to be checked.
//
#define SHADOW_ADD_PARAM(name) \
	if (is_shadowed && (params_idx < TS_PARAM_SIZE)){\
		memcpy(params+params_idx,&(name), sizeof((name))< TS_PARAM_SIZE-params_idx ? sizeof((name)) : TS_PARAM_SIZE-params_idx);\
		if( sizeof((name))< TS_PARAM_SIZE-params_idx ){\
			params_idx += sizeof((name));\
		}else {\
			params_idx = TS_PARAM_SIZE ;\
		}\
	}\


//
// Tell the Shadow Layer about side effect data. this is data not communicated via parameters and return values. Example is
// a data structure, to which only a pointer was given.
//
#define SHADOW_ADD_RETDATA(data, length) \


//
// Shadow Layer Prologue
//
#define SHADOW_PROLOGUE \
    if( is_shadowed ){ \
    	SUBS_DEBUG1("Thread %8lu LOCK.\n", this); \
		/*sh_lock(sh);*/ \
		\
        SUBS_DEBUG2("Thread %8lu %s() is shadowed\n", this,__FUNCTION__); \
        status = shadow_get_state(sh);\
        is_leading_thread = shadow_leading_thread(sh, this);\
        if ( is_leading_thread ) { \
			/* We're the leading thread, so push the function call into the fifo */ \
			SUBS_DEBUG2("Thread %8lu %s() is leading thread\n", this,__FUNCTION__); \
			if ( status == TS_ACTIVE ) {shadow_os_call_new(sh, &os_call, __FUNCTION__, params, sizeof(params) );}\
		} else { \
			/* We are the shadow thread. Get the os call from the fifo.  */\
			SUBS_DEBUG2("Thread %8lu %s() is shadow thread\n", this,__FUNCTION__);\
			shadow_os_call_get_retval( sh, &retval, (sizeof(retval) < TS_RETVAL_SIZE?sizeof(retval):TS_RETVAL_SIZE), __FUNCTION__, NULL, 0  );\
			goto Epilogue; /* should directly jump to "return retval" */ \
		} \
    } else { \
        SUBS_DEBUG2("Thread %8lu %s() is not shadowed \n", this, __FUNCTION__); \
    } \
\

//
// Shadow Layer Epilogue
//
#define SHADOW_EPILOGUE(blocking)\
    Epilogue: \
    if((blocking) && is_shadowed && !is_leading_thread){\
    		SUBS_DEBUG1("Thread %8lu getting sleep semaphore...\n", pthread_self());\
    		sem_wait(&sh->sh_wait_sem); /* sem_post is done in shadow_schedule()*/ \
    		SUBS_DEBUG1("Thread %8lu passed sleep semaphore...\n", pthread_self());\
    }\
    if ( is_shadowed && is_leading_thread && status == TS_ACTIVE){ \
    	/* If we came here we are the leading thread and have to push the os call into the fifo.*/\
        SUBS_DEBUG1("Thread %8lu saving return value to shadow structure.\n", this); \
        shadow_os_call_finish(sh, &os_call , (char*) &retval, (sizeof(retval) < TS_RETVAL_SIZE?sizeof(retval):TS_RETVAL_SIZE)); \
        SUBS_DEBUG1("Thread %8lu UNLOCK.\n", this); \
        /*sh_unlock(sh);*/ \
    } \
    SUBS_DEBUG2("Thread %8lu %s() END \n", this, __FUNCTION__); \
\


//
// Service functions
//

int shadow_leading_thread(shadowedthread_t *sh, pthread_t this){
	return sh->threads[0] == this;
}

int shadow_get_thread_index(shadowedthread_t *sh, pthread_t this) {
    int i;
    for( i = 0; i < TS_MAX_REDUNDANT_THREADS; i++){
      if ( sh->threads[i] == this ) {return i;}   
    }
    return -1;
} 

//
// Thread management calls
//

// Threads call this function to indicate zero internal state
// Shadowing system uses this information to (de-)activate shadow threads.
void ts_yield(){
	int retval;

	SHADOW_INIT;
	SHADOW_PROLOGUE;
	SUBS_DEBUG1("Thread %8lu calling function pthread_yield()\n", pthread_self());

	if(is_shadowed && is_leading_thread ){ /* Warning: Reusing variables from SHADOW_PROLOGUE */
		shadow_schedule( sh,  SCHED_FLAG_NONE );
	}

	SHADOW_EPILOGUE(BLOCKING);
}

void   ts_exit(void *retval){
    pthread_t this = pthread_self();
    shadowedthread_t *sh;
    //os_call_t os_call;
    bool is_shadowed = false;
    bool is_leading_thread = false;

 	SUBS_DEBUG2("Thread %8lu %s() START \n", this, __FUNCTION__);
    is_shadowed = is_shadowed_in_parent(this, &sh);
    if( is_shadowed ){
        SUBS_DEBUG2("Thread %8lu %s() is shadowed\n", this,__FUNCTION__);
        is_leading_thread = shadow_leading_thread(sh, this);
        if ( is_leading_thread ) {
        	// kill shadow thread
        	pthread_cancel(sh->threads[1]);
        	sem_post(&sh->sh_wait_sem);
        	// exit us
        	SUBS_DEBUG2("Thread %8lu %s() is exiting\n", this,__FUNCTION__);
        	pthread_exit(retval);
		} else {
			/* We are the shadow thread. */
			// exit us
			SUBS_DEBUG2("Thread %8lu %s() is exiting\n", this,__FUNCTION__);
			pthread_exit(retval);
		}
    }

    // Non shadowed threads should exit too!
    pthread_exit(retval);
}

//
// Mailbox Calls
//
int    ts_mbox_init(struct mbox * mb, int size){

    int retval;
    
    SHADOW_INIT;
    SHADOW_ADD_PARAM(mb);
    SHADOW_ADD_PARAM(size);
    SHADOW_PROLOGUE;
    SUBS_DEBUG3("Thread %8lu calling function mbox_init(%p, %d)\n", pthread_self(), mb, size);
    retval = mbox_init(mb, size);
    SHADOW_EPILOGUE(NONBLOCKING);

    return retval;
}

void   ts_mbox_destroy(struct mbox * mb){

    int retval=0; //DUMMY

    SHADOW_INIT;
    SHADOW_ADD_PARAM(mb);
    SHADOW_PROLOGUE;
    SUBS_DEBUG2("Thread %8lu calling function mbox_destroy(%p)\n", pthread_self(), mb);
    mbox_destroy(mb);
    SHADOW_EPILOGUE(NONBLOCKING);
}

void   ts_mbox_put(struct mbox * mb, uint32 msg){

    int retval=0; //DUMMY

    SHADOW_INIT;
    SHADOW_ADD_PARAM(mb);
    SHADOW_ADD_PARAM(msg);
    SHADOW_PROLOGUE;

    SUBS_DEBUG3("Thread %8lu calling function mbox_put(%p,%d)\n", pthread_self(), mb, msg);
    mbox_put(mb, msg);

    SHADOW_EPILOGUE(NONBLOCKING);
}

uint32 ts_mbox_get(struct mbox * mb){
    uint32 retval;
    
    SHADOW_INIT;
    SHADOW_ADD_PARAM(mb);
    SHADOW_PROLOGUE;
    SUBS_DEBUG2("Thread %8lu calling function mbox_get(%p)\n", pthread_self(), mb);
    retval = mbox_get(mb);
    SHADOW_EPILOGUE(NONBLOCKING);

    return retval;
}

int  ts_rq_init(rqueue * rq, int size){
	int retval;
	SHADOW_INIT;
	SHADOW_ADD_PARAM(rq);
	SHADOW_ADD_PARAM(size);
	SHADOW_PROLOGUE;
	SUBS_DEBUG3("Thread %8lu calling function rq_init(%p, %i)\n", pthread_self(), rq, size);
	retval = rq_init(rq, size);
	SHADOW_EPILOGUE(NONBLOCKING);
	return retval;
}

void ts_rq_close(rqueue * rq){
	int retval=0; //dummy
	SHADOW_INIT;
	SHADOW_ADD_PARAM(rq);
	SHADOW_PROLOGUE;
	SUBS_DEBUG2("Thread %8lu calling function rq_close(%p)\n", pthread_self(), rq);
	rq_close(rq);
	SHADOW_EPILOGUE(NONBLOCKING);
}

/*
 * Parameter msg is of outgoing type: data will be written to that address.
 * Therefore we have to provide that data to the shadow thread too.
 */
int  ts_rq_receive(rqueue * rq, uint32* msg, uint32 msg_size){
	int retval=0;

	char* retdata = NULL;
	unsigned int retdata_idx=0;
	unsigned int retdata_len=0;

	SHADOW_INIT;
	SHADOW_ADD_PARAM(rq);
	SHADOW_ADD_PARAM(msg);
	SHADOW_ADD_PARAM(msg_size);
	SHADOW_PROLOGUE;
	SUBS_DEBUG4("Thread %8lu calling function rq_receive(%p, %p, %i)\n", pthread_self(), rq, msg, msg_size);
	retval = rq_receive(rq, msg, msg_size);

	/// SHADOW_ADD_RETVAL
	if ( is_shadowed && is_leading_thread && status == TS_ACTIVE ){
		retdata = realloc(retdata,retdata_idx+msg_size);
		//printf("SUBS: realloc returned: %8p, for size %8i\n", retdata, retdata_idx+msg_size);
		memcpy(retdata+retdata_idx,msg, msg_size);
		//printf("SUBS: memcpy succeded\n");
		retdata_idx += msg_size;
	}

	/// EPILOGUE
	if ( is_shadowed && is_leading_thread && status == TS_ACTIVE ){
		if (retdata_idx != 0) {
			shadow_os_call_add_retdata(sh, &os_call , retdata, retdata_idx);
		}
	}

	SHADOW_EPILOGUE(NONBLOCKING);

	/// SHADOW_ADD_RETVAL
	if ( is_shadowed && !is_leading_thread ){
		shadow_os_call_get_retdata(sh, &os_call , (void*)&retdata, &retdata_len);
		memcpy(msg,retdata+retdata_idx, msg_size);
		retdata_idx += msg_size;
	}


	/// EPILOGUE
	if ( is_shadowed && !is_leading_thread ){
		if ( retdata ) { free(retdata); }
	}
	/// ----
	SUBS_DEBUG2("Thread %8lu returning %i\n", pthread_self(), retval);
	return retval;
}

void ts_rq_send(rqueue * rq, uint32* msg, uint32 msg_size){
	int retval=0; //Dummy

	void* retdata = NULL;
	unsigned int retdata_idx=0;

	SHADOW_INIT;
	SHADOW_ADD_PARAM(rq);
	SHADOW_ADD_PARAM(msg);
	SHADOW_ADD_PARAM(msg_size);


	if ( is_shadowed ){
		retdata = realloc(retdata,retdata_idx+msg_size);
		//memcpy(retdata+retdata_idx,&(msg), msg_size);
		retdata_idx += msg_size;
	}

	SHADOW_PROLOGUE;
	SUBS_DEBUG4("Thread %8lu calling function rq_send(%p, %p, %i)\n", pthread_self(), rq, msg, msg_size);
	rq_send(rq, msg, msg_size);
	SHADOW_EPILOGUE(NONBLOCKING);
}
