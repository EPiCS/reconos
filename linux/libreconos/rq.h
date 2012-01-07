#ifndef RQ_H
#define RQ_H

/** This is the linux implementation of ReconOS message queues.
   It uses an mbox internally */

#include <semaphore.h>
#include <pthread.h>
#include "config.h"
#include "mbox.h"

//! ReconOS message queue internally uses mbox
typedef struct mbox rqueue;

//! initializes ReconOS message queue with maximum 'size' messages.
int  rq_init(rqueue * rq, int size);

//! destroys ReconOS message queue
void rq_close(rqueue * rq);

//! send message to ReconOS message queue. The data array at address 'msg' with size 'msg_size' 
//  is stored internally and forwared to the next calling thread.
int  rq_receive(rqueue * rq, uint32* msg, uint32 msg_size);

//! receive message from ReconOS message queue. The data array is written to address 'msg' 
//  with a maximum size of 'msg_size' bytes. If the received message size exceeds 'msg_size', 
//  the function returns -1.
void rq_send(rqueue * rq, uint32* msg, uint32 msg_size);

#endif

