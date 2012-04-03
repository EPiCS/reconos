#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#include "rqueue.h"

//! initializes ReconOS message queue with maximum 'size' messages. internally it uses mboxes.
int rq_init(rqueue * rq, int size)
{
	return mbox_init((struct mbox *) rq, size);
}

//! destroys ReconOS message queue
void rq_close(rqueue * rq)
{
	mbox_destroy((struct mbox *) rq);
}

//! send message to ReconOS message queue. The data array at address 'msg' with size 'msg_size' 
//  is stored internally and forwared to the next calling thread.
void rq_send(rqueue * rq, uint32* msg, uint32 msg_size)
{
	uint32* copy = malloc(msg_size+sizeof(uint32));
	copy[0] = msg_size;
	memcpy(&copy[1],msg,msg_size);
	mbox_put((struct mbox *) rq, (uint32)copy);
}

//! receive message from ReconOS message queue. The data array is written to address 'msg' 
//  with a maximum size of 'msg_size' bytes. If the received message size exceeds 'msg_size', 
//  the function returns -1.
int rq_receive(rqueue * rq, uint32* msg, uint32 msg_size)
{
	uint32* copy;
	uint32 size;
	copy = (uint32*) mbox_get((struct mbox *) rq);
	size = copy[0];
	// error: The message size does not fit
	if (size == 0 || size > msg_size) return -1;
	memcpy(msg,&copy[1],size);
	free(copy);
	return size;
}

