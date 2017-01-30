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
#include <sys/time.h>

#include "mbox.h"
#include "rqueue.h"
#include "timing.h"
#include "func_call.h"
#include "thread_shadowing_schedule.h"
#include "thread_shadowing_error_handler.h"
#include "thread_shadowing.h"


//
// Debugging
//
//#define DEBUG 1
#define OUTPUT stdout

#ifdef DEBUG
    #define SUBS_DEBUG(message) fprintf(OUTPUT, "SUBS: " message)
    #define SUBS_DEBUG1(message, arg1) fprintf(OUTPUT, "SUBS: " message, (arg1))
    #define SUBS_DEBUG2(message, arg1, arg2) fprintf(OUTPUT, "SUBS: " message, (arg1), (arg2))
    #define SUBS_DEBUG3(message, arg1, arg2, arg3) fprintf(OUTPUT, "SUBS: " message, (arg1), (arg2), (arg3))
    #define SUBS_DEBUG4(message, arg1, arg2, arg3, arg4) fprintf(OUTPUT, "SUBS: " message, (arg1), (arg2), (arg3), (arg4))
	#define SUBS_DEBUG7(message, arg1, arg2, arg3, arg4, arg5, arg6, arg7) fprintf(OUTPUT, "SUBS: " message, (arg1), (arg2), (arg3), (arg4), (arg5), (arg6), (arg7))
#else
    #define SUBS_DEBUG(message)
    #define SUBS_DEBUG1(message, arg1)
    #define SUBS_DEBUG2(message, arg1, arg2)
    #define SUBS_DEBUG3(message, arg1, arg2, arg3)
    #define SUBS_DEBUG4(message, arg1, arg2, arg3, arg4)
	#define SUBS_DEBUG7(message, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
#endif

#define NONBLOCKING 0
#define BLOCKING 	1

void shadow_sfs_dump(shadowed_function_state* sfs){
	fprintf(stderr, "## shadow_sfs_dump start #######################################\n");
	//shadow_dump(sfs->sh);
	fprintf(stderr, "Function Name: %s\n", sfs->function_name);
	func_call_dump(&sfs->func_call_tuo);
	func_call_dump(&sfs->func_call_sh);
	fprintf(stderr, "Timing data skipped\n");
	fprintf(stderr, "is_shadowed: %s\n", sfs->is_shadowed?"true":"false");
	fprintf(stderr, "is_leading: %s\n", sfs->is_leading?"true":"false");
	fprintf(stderr, "shadow_state: %d\n", sfs->status);
	fprintf(stderr, "error: %u\n", sfs->error);
	fprintf(stderr, "this: %lu\n", sfs->this);
	fprintf(stderr, "## shadow_sfs_dump end   #######################################\n");
}

void shadow_init_f(shadowed_function_state* sfs, const char* function_name, uint32_t idx){

	sfs->is_shadowed = false;
	sfs->is_leading  = false;
	sfs->status = TS_INACTIVE;
	sfs->error = FC_ERR_NONE;
	sfs->this = pthread_self();
	sfs->function_name = function_name;
	SUBS_DEBUG2("Thread %8lu %s() START \n", sfs->this, function_name);

	ts_lock();
	sfs->is_shadowed = is_shadowed_in_parent(sfs->this, &sfs->sh);
	shadow_func_stat_inc_i(idx);
	if( sfs->is_shadowed ){
        SUBS_DEBUG2("Thread %8lu %s() is shadowed\n", sfs->this,function_name);
        shadow_func_stat_inc_s(idx);
        sfs->is_leading = is_leading_thread(sfs->sh, sfs->this);
		SUBS_DEBUG3("Thread %8lu %s() is %s\n", sfs->this,function_name, sfs->is_leading?"TUO":"SHADOW");
//		fprintf(stderr,"Thread %8lu %s() is %s 1\n", sfs->this,function_name, sfs->is_leading?"TUO":"SHADOW");

		sfs->status = shadow_get_state(sfs->sh);
		func_call_new(&sfs->func_call_tuo, function_name);
		// We deposit a pointer to our local shadowed_function_state* sfs in the global shadow structure.
		// At the end of this function we will NULL it again, so that the pointer will only live as long
		// as the structure itself on the stack.
		if ( sfs->is_leading ) { sfs->sh->sfs[0] = sfs; }
		else                   { sfs->sh->sfs[1] = sfs; }
//		if( (strcmp(sfs->function_name,"ts_yield")== 0) && !sfs->is_leading ){
//					fprintf(stderr,"Thread %8lu %s() is %s 2\n", sfs->this,function_name, sfs->is_leading?"TUO":"SHADOW");
//				}
	}else{
		SUBS_DEBUG2("Thread %8lu %s() is not shadowed \n", sfs->this, function_name);
	}
	ts_unlock();
}

void shadow_add_param_f(shadowed_function_state* sfs, void* param_name, size_t param_size){
	if (sfs->is_shadowed && (sfs->sh->level > 1) ){
		SUBS_DEBUG2("Thread %8lu %s() adding parameter... \n", sfs->this, sfs->function_name);
		if(func_call_add_param(&sfs->func_call_tuo, param_name, param_size) != param_size){
			fprintf(stderr, "THREAD_SAHDOWING_SUBS: Parameter storage insufficient!\n");
			exit(-1);
		}
//		if( (strcmp(sfs->function_name,"ts_yield")== 0) && !sfs->is_leading ){
//			fprintf(stderr,"Thread %8lu %s() is %s 3\n", sfs->this,sfs->function_name, sfs->is_leading?"TUO":"SHADOW");
//		}
	}
}

bool shadow_prologue_f(shadowed_function_state* sfs){
    if( sfs->is_shadowed && !sfs->is_leading ) {
//    	if( (strcmp(sfs->function_name,"ts_yield")== 0) && !sfs->is_leading ){
//			fprintf(stderr,"Thread %8lu %s() is %s 4\n", sfs->this,sfs->function_name, sfs->is_leading?"TUO":"SHADOW");
//		}

		SUBS_DEBUG2("Thread %8lu %s() popping from fifo: \n", sfs->this, sfs->function_name);
		sfs->t_start = gettime();
		shadow_func_call_pop(sfs->sh, &sfs->func_call_sh);
		sfs->t_stop = gettime();

//		if( (strcmp(sfs->function_name,"ts_yield")== 0) && !sfs->is_leading ){
//			fprintf(stderr,"Thread %8lu %s() is %s 5\n", sfs->this,sfs->function_name, sfs->is_leading?"TUO":"SHADOW");
//		}

		timerdiff(&sfs->t_stop, &sfs->t_start, &sfs->t_duration);
		SUBS_DEBUG2("Thread %8lu %s() popped from fifo: \n", sfs->this, sfs->function_name);

		sfs->diff = func_call_timediff_us(&sfs->func_call_sh, &sfs->func_call_tuo );
		SUBS_DEBUG7("Shadow %lu of thread %lu Latency of function %s : %ld s %ld us, waited for func_call_pop: %ld s %ld us\n", (unsigned long)sfs->this, sfs->sh->threads[0] ,sfs->function_name, sfs->diff.tv_sec, sfs->diff.tv_usec, sfs->t_duration.tv_sec, sfs->t_duration.tv_usec);

		ts_lock();
//		if( (strcmp(sfs->function_name,"ts_yield")== 0) && !sfs->is_leading ){
//			fprintf(stderr,"Thread %8lu %s() is %s 6\n", sfs->this,sfs->function_name, sfs->is_leading?"TUO":"SHADOW");
//		}
		if (strcmp(sfs->function_name, "ts_yield") != 0){
			if ( timercmp(&sfs->diff,&sfs->sh->max_error_detection_latency, >)) { sfs->sh->max_error_detection_latency = sfs->diff;}
			if ( timercmp(&sfs->diff,&sfs->sh->min_error_detection_latency, <)) { sfs->sh->min_error_detection_latency = sfs->diff;}
			timeradd(&sfs->sh->sum_error_detection_latency, &sfs->diff, &sfs->sh->sum_error_detection_latency);
			sfs->sh->cnt_error_detection_latency++;
		}
		switch (sfs->sh->level){
			case 1: sfs->error = func_call_compare_name(&sfs->func_call_tuo, &sfs->func_call_sh);break;
			case 2:
			case 3: sfs->error = func_call_compare(&sfs->func_call_tuo, &sfs->func_call_sh);break;
		}
		ts_unlock();
//		if( (strcmp(sfs->function_name,"ts_yield")== 0) && !sfs->is_leading ){
//			fprintf(stderr,"Thread %8lu %s() is %s 7\n", sfs->this,sfs->function_name, sfs->is_leading?"TUO":"SHADOW");
//		}

		if( sfs->error != FC_ERR_NONE) {
			sh_func_error_handler(sfs->error, &sfs->func_call_tuo, &sfs->func_call_sh);
		}
		return false; /* jumps to SHADOW_EPILOGUE */
    }
    return true;
}

void shadow_epilogue_f(shadowed_function_state* sfs, bool blocking, void* retval, size_t retval_size){
    if((blocking) && sfs->is_shadowed && !sfs->is_leading){
    		SUBS_DEBUG1("Thread %8lu getting sleep semaphore...\n", sfs->this);
    		sem_wait(&sfs->sh->sh_wait_sem); /* sem_post is done in shadow_schedule()*/
    		SUBS_DEBUG1("Thread %8lu passed sleep semaphore...\n", sfs->this);
    }
    if ( sfs->is_shadowed && !sfs->is_leading) {
//    	if( (strcmp(sfs->function_name,"ts_yield")== 0) && !sfs->is_leading ){
//			fprintf(stderr,"Thread %8lu %s() is %s 8\n", sfs->this,sfs->function_name, sfs->is_leading?"TUO":"SHADOW");
//		}

    	/* We are the shadow thread. Get the os call from the fifo.  */
		SUBS_DEBUG2("Thread %8lu %s() restoring return value\n", sfs->this, sfs->function_name);
		if(func_call_get_retval(&sfs->func_call_sh, retval, retval_size) != retval_size){
			fprintf(stderr, "THREAD_SAHDOWING_SUBS: Short retval read! Maybe you requested too much?\n");
			exit(-1);
		}

//		if( (strcmp(sfs->function_name,"ts_yield")== 0) && !sfs->is_leading ){
//			fprintf(stderr,"Thread %8lu %s() is %s 9\n", sfs->this,sfs->function_name, sfs->is_leading?"TUO":"SHADOW");
//		}
    }
    if ( sfs->is_shadowed && sfs->is_leading && (sfs->status == TS_ACTIVE) ){
    	/* If we came here we are the leading thread and have to push the os call into the fifo.*/
        SUBS_DEBUG1("Thread %8lu saving return value.\n", sfs->this);
        func_call_add_retval(&sfs->func_call_tuo , retval, retval_size );
    }
}

void shadow_add_retdata_f(shadowed_function_state* sfs, void* data, size_t data_size){
	if ( sfs->is_shadowed && sfs->is_leading && (sfs->status == TS_ACTIVE) ){
		SUBS_DEBUG2("Thread %8lu %s() adding return data\n", sfs->this, sfs->function_name);
		func_call_add_retdata(&sfs->func_call_tuo , data, data_size);
	}
	if ( sfs->is_shadowed && !sfs->is_leading){
		SUBS_DEBUG2("Thread %8lu %s() restoring return data\n", sfs->this, sfs->function_name);
		if( func_call_get_retdata(&sfs->func_call_sh , data, data_size) != data_size ){
			fprintf(stderr, "THREAD_SAHDOWING_SUBS: Short retdata read! Maybe you requested too much?\n");
			exit(-1);
		}
	}
}

void shadow_end_f(shadowed_function_state* sfs){
	if ( sfs->is_shadowed && !sfs->is_leading) {
//		if( (strcmp(sfs->function_name,"ts_yield")== 0) && !sfs->is_leading ){
//					fprintf(stderr,"Thread %8lu %s() is %s 10\n", sfs->this,sfs->function_name, sfs->is_leading?"TUO":"SHADOW");
//				}

		/* free the os-call only after shadow thread processed it */
		func_call_free(&sfs->func_call_sh);
//		if( (strcmp(sfs->function_name,"ts_yield")== 0) && !sfs->is_leading ){
//					fprintf(stderr,"Thread %8lu %s() is %s 11\n", sfs->this,sfs->function_name, sfs->is_leading?"TUO":"SHADOW" );
//				}
	}
	if ( sfs->is_shadowed && sfs->is_leading && (sfs->status == TS_ACTIVE) ){
		SUBS_DEBUG2("Thread %8lu %s() pushing into fifo...\n", sfs->this, sfs->function_name);
		shadow_func_call_push(sfs->sh, &sfs->func_call_tuo);
	}
	if ( sfs->is_shadowed ){
			if ( sfs->is_leading ) { sfs->sh->sfs[0] = NULL; }
			else                   { sfs->sh->sfs[1] = NULL; }
	}
	SUBS_DEBUG2("Thread %8lu %s() END \n", sfs->this, sfs->function_name);
}

//
// Thread management calls
//

/**
 * @brief Threads call this function to indicate zero internal state
 *
 * Shadowing system uses this information to (de-)activate shadow threads.
 */
void ts_yield(){

	int retval = 0; //DUMMY
	shadowed_function_state sfs;

	shadow_init_f(&sfs, __FUNCTION__, IDX_TS_YIELD);

	if(shadow_prologue_f(&sfs)){
		SUBS_DEBUG1("Thread %8lu calling function pthread_yield()\n", pthread_self());
		if(sfs.is_shadowed && sfs.is_leading ){
			ts_lock();
			//shadow_schedule( sfs.sh,  SCHED_FLAG_NONE );
			sfs.status = shadow_get_state(sfs.sh); // Schedule may have altered our status. Update local variable.
			ts_unlock();
		}
	}

    shadow_epilogue_f(&sfs, NONBLOCKING, &retval, sizeof(retval));
    shadow_end_f(&sfs);

//    if(sfs.is_shadowed && !sfs.is_leading){
//    	fprintf(stderr,"Thread %8lu %s() Return address %p\n",sfs.this, sfs.function_name, __builtin_extract_return_addr(__builtin_return_address(0)));
//    }
}

/*
 * ts_exit is a special case: The shadow may not skip the function call, otherwise it would not terminate and a join
 * operation would not succeed.
 * CURRENTLY NOT USED BY DELEGATE THREAD
 */
void   ts_exit(void *_retval){
	uint32_t retval = 0; //DUMMY
    shadowed_function_state sfs;

    shadow_init_f(&sfs, __FUNCTION__, IDX_TS_EXIT);
    shadow_add_param_f(&sfs, &_retval, sizeof(_retval));
    (void)shadow_prologue_f(&sfs);
	SUBS_DEBUG1("Thread %8lu calling function pthread_exit()\n", sfs.this);
    shadow_epilogue_f(&sfs, NONBLOCKING, &retval, sizeof(retval));
    shadow_end_f(&sfs);
    // In every case, the thread gets terminated
    pthread_exit(_retval);
}

//
// Mailbox Calls
//
int    ts_mbox_init(struct mbox * mb, int size){

	uint32_t retval = 0; //DUMMY
    shadowed_function_state sfs;

    shadow_init_f(&sfs, __FUNCTION__, IDX_TS_MBOX_INIT);
    shadow_add_param_f(&sfs, &mb, sizeof(mb));
    shadow_add_param_f(&sfs, &size, sizeof(size));

    if(shadow_prologue_f(&sfs)){
    	SUBS_DEBUG3("Thread %8lu calling function mbox_init(%p, %d)\n", pthread_self(), mb, size);
    	retval = mbox_init(mb, size);
    }
    shadow_epilogue_f(&sfs, NONBLOCKING, &retval, sizeof(retval));
    shadow_end_f(&sfs);
    return retval;
}

void   ts_mbox_destroy(struct mbox * mb){

	uint32_t retval = 0; //DUMMY
    shadowed_function_state sfs;

    shadow_init_f(&sfs, __FUNCTION__, IDX_TS_MBOX_DESTROY);
    shadow_add_param_f(&sfs, &mb, sizeof(mb));

    if(shadow_prologue_f(&sfs)){
		SUBS_DEBUG2("Thread %8lu calling function mbox_destroy(%p)\n", pthread_self(), mb);
		mbox_destroy(mb);
    }

    shadow_epilogue_f(&sfs, NONBLOCKING, &retval, sizeof(retval));
    shadow_end_f(&sfs);
}

void   ts_mbox_put(struct mbox * mb, uint32 msg){
	uint32_t retval = 0; //DUMMY
    shadowed_function_state sfs;

    shadow_init_f(&sfs, __FUNCTION__, IDX_TS_MBOX_PUT);
    shadow_add_param_f(&sfs, &mb, sizeof(mb));
    shadow_add_param_f(&sfs, &msg, sizeof(msg));

    if(shadow_prologue_f(&sfs)){
       SUBS_DEBUG3("Thread %8lu calling function mbox_put(%p,%d)\n", pthread_self(), mb, msg);
       mbox_put(mb, msg);
    }

    shadow_epilogue_f(&sfs, NONBLOCKING, &retval, sizeof(retval));
    shadow_end_f(&sfs);
}

uint32 ts_mbox_get(struct mbox * mb){
    uint32 retval = 0;
    shadowed_function_state sfs;

    shadow_init_f(&sfs, __FUNCTION__, IDX_TS_MBOX_GET);
    shadow_add_param_f(&sfs, &mb, sizeof(mb));

    if(shadow_prologue_f(&sfs)){
    	SUBS_DEBUG2("Thread %8lu calling function mbox_get(%p)\n", pthread_self(), mb);
    	retval = mbox_get(mb);
    }

    shadow_epilogue_f(&sfs, NONBLOCKING, &retval, sizeof(retval));
    shadow_end_f(&sfs);
    return retval;
}

int  ts_rq_init(rqueue * rq, size_t size){
	int retval = 0; //DUMMY
    shadowed_function_state sfs;

    shadow_init_f(&sfs, __FUNCTION__, IDX_TS_RQ_INIT);
    shadow_add_param_f(&sfs, &rq, sizeof(rq));
    shadow_add_param_f(&sfs, &size, sizeof(size));

    if(shadow_prologue_f(&sfs)){
		SUBS_DEBUG3("Thread %8lu calling function rq_init(%p, %zu)\n", pthread_self(), rq, size);
		retval = rq_init(rq, size);
    }
    shadow_epilogue_f(&sfs, NONBLOCKING, &retval, sizeof(retval));
    shadow_end_f(&sfs);
	return retval;
}

void ts_rq_close(rqueue * rq){
	int retval=0; //dummy
    shadowed_function_state sfs;

    shadow_init_f(&sfs, __FUNCTION__, IDX_TS_RQ_CLOSE);
    shadow_add_param_f(&sfs, &rq, sizeof(rq));

    if(shadow_prologue_f(&sfs)){
		SUBS_DEBUG2("Thread %8lu calling function rq_close(%p)\n", pthread_self(), rq);
		rq_close(rq);
    }

    shadow_epilogue_f(&sfs, NONBLOCKING, &retval, sizeof(retval));
    shadow_end_f(&sfs);
}

/*
 * Parameter msg is of outgoing type: data will be written to that address.
 * Therefore we have to provide that data to the shadow thread too.
 */
ssize_t  ts_rq_receive(rqueue * rq, uint32* msg, uint32 msg_size){
	ssize_t retval=0;
    shadowed_function_state sfs;

    shadow_init_f(&sfs, __FUNCTION__, IDX_TS_RQ_RECEIVE);
    shadow_add_param_f(&sfs, &rq, sizeof(rq));
	// msg parameter will be different for every thread, as this is a pointer to a stack variable
	//shadow_add_param_f(&sfs, &msg, sizeof(msg));
    shadow_add_param_f(&sfs, &msg_size, sizeof(msg_size));

    if(shadow_prologue_f(&sfs)){
		SUBS_DEBUG4("Thread %8lu calling function rq_receive(%p, %p, %i)\n", pthread_self(), rq, msg, msg_size);
		retval = rq_receive(rq, msg, msg_size);
    }

    shadow_epilogue_f(&sfs, NONBLOCKING, &retval, sizeof(retval));
    shadow_add_retdata_f(&sfs,msg, msg_size);
    shadow_end_f(&sfs);
	return retval;
}

void ts_rq_send(rqueue * rq, uint32* msg, uint32 msg_size){
	int retval=0; //Dummy
    shadowed_function_state sfs;

    shadow_init_f(&sfs, __FUNCTION__, IDX_TS_RQ_SEND);
    shadow_add_param_f(&sfs, &rq, sizeof(rq));
	// msg parameter will be different for every thread, as this is a pointer to a stack variable
	//shadow_add_param_f(&sfs, &msg, sizeof(msg));
    shadow_add_param_f(&sfs, &msg_size, sizeof(msg_size));

    if(shadow_prologue_f(&sfs)){
		SUBS_DEBUG4("Thread %8lu calling function rq_send(%p, %p, %i)\n", pthread_self(), rq, msg, msg_size);
		rq_send(rq, msg, msg_size);
    }
    shadow_epilogue_f(&sfs, NONBLOCKING, &retval, sizeof(retval));
    shadow_end_f(&sfs);
}
