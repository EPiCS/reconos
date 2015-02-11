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
#include "timing.h"
#include "func_call.h"
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
	func_call_t func_call_tuo;\
	func_call_t func_call_sh;\
	timing_t t_start, t_stop, t_duration;\
	bool is_shadowed = false; \
	bool is_leading = false;\
	shadow_state_t status = TS_INACTIVE;\
	SUBS_DEBUG2("Thread %8lu %s() START \n", this, __FUNCTION__); \
	is_shadowed = is_shadowed_in_parent(this, &sh); \
	if( is_shadowed ){ \
        SUBS_DEBUG2("Thread %8lu %s() is shadowed\n", this,__FUNCTION__); \
		is_leading = is_leading_thread(sh, this);\
		SUBS_DEBUG3("Thread %8lu %s() is %s\n", this,__FUNCTION__, is_leading?"TUO":"SHADOW"); \
		status = shadow_get_state(sh);\
	}else{\
		SUBS_DEBUG2("Thread %8lu %s() is not shadowed \n", this, __FUNCTION__); \
	}\
    if( is_shadowed ){ \
    	func_call_new(&func_call_tuo, __FUNCTION__);\
    	/*t_start = gettime();*/\
    	/*printf("Thread %lu called function %s at %ld s %ld us\n", (unsigned long)this, __FUNCTION__, t_start.tv_sec, t_start.tv_usec);*/ \
    	/* func_call_tuo is not initialized, because we get a valid one via shadow_func_call_pop. */\
    }\

//
// Tell the Shadow Layer about parameters you want to be checked.
//
#define SHADOW_ADD_PARAM(name) \
	if (is_shadowed){\
		func_call_add_param(&func_call_tuo, &(name), sizeof((name)));\
	}\

//
// Shadow Layer Prologue
//
#define SHADOW_PROLOGUE \
    if( is_shadowed && !is_leading ) { \
    		SUBS_DEBUG2("Thread %8lu %s() popping from fifo: \n", this, __FUNCTION__); \
    		t_start = gettime();\
    		shadow_func_call_pop(sh, &func_call_sh);\
    		t_stop = gettime();\
    		timerdiff(&t_stop, &t_start, &t_duration);\
    		SUBS_DEBUG2("Thread %8lu %s() popped from fifo: \n", this, __FUNCTION__); \
    		/*func_call_dump(&func_call_sh)*/;\
    		timing_t diff = func_call_timediff_us(&func_call_sh, &func_call_tuo );\
    		printf("Shadow %lu of thread %lu Latency of function %s : %ld s %ld us, waited for func_call_pop: %ld s %ld us\n", (unsigned long)this, sh->threads[0] ,__FUNCTION__, diff.tv_sec, diff.tv_usec, t_duration.tv_sec, t_duration.tv_usec); \
    		if (strcmp(__FUNCTION__, "ts_yield") != 0){\
    			if ( timercmp(&diff,&sh->max_error_detection_latency, >)) { sh->max_error_detection_latency = diff;}\
    			if ( timercmp(&diff,&sh->min_error_detection_latency, <)) { sh->min_error_detection_latency = diff;}\
    			timeradd(&sh->sum_error_detection_latency, &diff, &sh->sum_error_detection_latency);\
    			sh->cnt_error_detection_latency++;\
    		}\
    		int error = func_call_compare(&func_call_tuo, &func_call_sh);\
    		if( error != FC_ERR_NONE) {\
    			shadow_error(sh, error, &func_call_tuo, &func_call_sh);\
    		}\
			goto Epilogue; /* jumps to SHADOW_EPILOGUE */ \
    }\

//
// Shadow Layer Epilogue
//
#define SHADOW_EPILOGUE(blocking)\
    Epilogue: \
    if((blocking) && is_shadowed && !is_leading){\
    		SUBS_DEBUG1("Thread %8lu getting sleep semaphore...\n", pthread_self());\
    		sem_wait(&sh->sh_wait_sem); /* sem_post is done in shadow_schedule()*/ \
    		SUBS_DEBUG1("Thread %8lu passed sleep semaphore...\n", pthread_self());\
    }\
    if ( is_shadowed && !is_leading) {\
    	/* We are the shadow thread. Get the os call from the fifo.  */\
		SUBS_DEBUG2("Thread %8lu %s() restoring return value\n", this,__FUNCTION__);\
		func_call_get_retval(&func_call_sh,(void*) &retval, sizeof(retval));\
    }\
    if ( is_shadowed && is_leading && status == TS_ACTIVE){ \
    	/* If we came here we are the leading thread and have to push the os call into the fifo.*/\
        SUBS_DEBUG1("Thread %8lu saving return value.\n", this); \
        func_call_add_retval(&func_call_tuo , (void*) &retval, sizeof(retval) ); \
    } \

//
// Tell the Shadow Layer about additional return data. This is data communicated via parameters and return values. Example is
// a data structure, to which only a pointer was given.
//
#define SHADOW_ADD_RETDATA(data, length) \
	if ( is_shadowed && is_leading && status == TS_ACTIVE ){\
		func_call_add_retdata(&func_call_tuo , (data), (length));\
	}\
	if ( is_shadowed && !is_leading){\
		func_call_get_retdata(&func_call_sh , (void*)(data), (length));\
	}\

//
// Shadow Layer End
//
#define SHADOW_END\
	if ( is_shadowed && !is_leading) { \
		/* free the os-call only after shadow thread processed it */\
		func_call_free(&func_call_sh);\
	}\
	if ( is_shadowed && is_leading && status == TS_ACTIVE){ \
		SUBS_DEBUG2("Thread %8lu %s() pushing into fifo: ", this, __FUNCTION__); \
		/*func_call_dump(&func_call_tuo)*/;\
		shadow_func_call_push(sh, &func_call_tuo); \
	}\
	SUBS_DEBUG2("Thread %8lu %s() END \n", this, __FUNCTION__); \
\


//
// Thread management calls
//

/**
 * @brief Threads call this function to indicate zero internal state
 *
 * Shadowing system uses this information to (de-)activate shadow threads.
 */
void ts_yield(){
	int retval;

	SHADOW_INIT;
	SHADOW_PROLOGUE;
	SUBS_DEBUG1("Thread %8lu calling function pthread_yield()\n", pthread_self());

	if(is_shadowed && is_leading ){ /* Warning: Reusing variables from SHADOW_PROLOGUE */
		ts_lock();
		shadow_schedule( sh,  SCHED_FLAG_NONE );
		ts_unlock();
		status = shadow_get_state(sh); // Schedule may have altered our status. Update local variable.
	}

	SHADOW_EPILOGUE(BLOCKING);
	SHADOW_END;
}

void   ts_exit(void *retval){
    pthread_t this = pthread_self();
    shadowedthread_t *sh;
    //os_call_t os_call;
    bool is_shadowed = false;
    bool is_leading = false;

 	SUBS_DEBUG2("Thread %8lu %s() START \n", this, __FUNCTION__);
    is_shadowed = is_shadowed_in_parent(this, &sh);
    if( is_shadowed ){
        SUBS_DEBUG2("Thread %8lu %s() is shadowed\n", this,__FUNCTION__);
        is_leading = is_leading_thread(sh, this);
        if ( is_leading ) {
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
    SHADOW_END;
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
    SHADOW_END;
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
    SHADOW_END;
}

uint32 ts_mbox_get(struct mbox * mb){
    uint32 retval;
    
    SHADOW_INIT;
    SHADOW_ADD_PARAM(mb);
    SHADOW_PROLOGUE;
    SUBS_DEBUG2("Thread %8lu calling function mbox_get(%p)\n", pthread_self(), mb);
    retval = mbox_get(mb);
    SHADOW_EPILOGUE(NONBLOCKING);
    SHADOW_END;
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
	SHADOW_END;
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
	SHADOW_END;
}

/*
 * Parameter msg is of outgoing type: data will be written to that address.
 * Therefore we have to provide that data to the shadow thread too.
 */
int  ts_rq_receive(rqueue * rq, uint32* msg, uint32 msg_size){
	int retval=0;

	SHADOW_INIT;
	SHADOW_ADD_PARAM(rq);
	// msg parameter will be different for every thread, as this is a pointer to a stack variable
	//SHADOW_ADD_PARAM(msg);
	SHADOW_ADD_PARAM(msg_size);
	SHADOW_PROLOGUE;
	SUBS_DEBUG4("Thread %8lu calling function rq_receive(%p, %p, %i)\n", pthread_self(), rq, msg, msg_size);

	retval = rq_receive(rq, msg, msg_size);

	SHADOW_EPILOGUE(NONBLOCKING);
	SHADOW_ADD_RETDATA(msg, msg_size)
	SUBS_DEBUG2("Thread %8lu returning %i\n", pthread_self(), retval);
	SHADOW_END;
	return retval;
}

void ts_rq_send(rqueue * rq, uint32* msg, uint32 msg_size){
	int retval=0; //Dummy

	SHADOW_INIT;
	SHADOW_ADD_PARAM(rq);
	// msg parameter will be different for every thread, as this is a pointer to a stack variable
	//SHADOW_ADD_PARAM(msg);
	SHADOW_ADD_PARAM(msg_size);
	SHADOW_PROLOGUE;
	SUBS_DEBUG4("Thread %8lu calling function rq_send(%p, %p, %i)\n", pthread_self(), rq, msg, msg_size);
	rq_send(rq, msg, msg_size);
	SHADOW_EPILOGUE(NONBLOCKING);
	SHADOW_END;
}
