///
/// \file thread_shadowing.h
/// Thread shadowing framework. Include file for user threads, wanting
/// to use thread shadowing.
///
/// \author     Sebastian Meisner   <sebastian.meisner@upb.de>
/// \date       22.02.2012
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2012.
//

#ifndef __THREAD_SHADOWING_SUBS_H__
#define __THREAD_SHADOWING_SUBS_H__

#include "mbox.h"
#include "rqueue.h"
//
// Mailbox Calls
//
#ifndef TS_NO_OS_CALL_SUBSTITUTION
	#define pthread_yield()				 ts_yield()
    #define pthread_exit(retval)	     ts_exit((retval))

	#define mbox_init(mbox, size)       ts_mbox_init((mbox), (size))
    #define mbox_destroy(mbox)          ts_mbox_destroy((mbox))
    #define mbox_put(mbox, msg)         ts_mbox_put((mbox), (msg))
    #define mbox_get(mbox)              ts_mbox_get((mbox))

	#define rq_init(rq, size)			 ts_rq_init((rq), (size))
	#define rq_close(rq)				 ts_rq_close((rq))
	#define rq_receive(rq, msg, size)	 ts_rq_receive((rq),(msg),(size))
	#define rq_send(rq,msg,size)		 ts_rq_send((rq),(msg),(size))

#endif

void   ts_yield();
void   ts_exit(void *retval);

int    ts_mbox_init(struct mbox * mb, int size);
void   ts_mbox_destroy(struct mbox * mb);
void   ts_mbox_put(struct mbox * mb, uint32 msg);
uint32 ts_mbox_get(struct mbox * mb);

int  ts_rq_init(rqueue * rq, int size);
void ts_rq_close(rqueue * rq);
int  ts_rq_receive(rqueue * rq, uint32* msg, uint32 msg_size);
void ts_rq_send(rqueue * rq, uint32* msg, uint32 msg_size);


#endif

