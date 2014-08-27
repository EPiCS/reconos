//#include "xmk.h"
//#include "sys/init.h"
//#include "platform.h"
//#include "mb_interface.h"


#include "xmk.h"
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <sys/intr.h>
#include "sys/process.h"
#include "logging.h"
#include "timing.h"

#define FSL_BUFFER_SIZE (16)
#define FSL_BUFFER_MASK (FSL_BUFFER_SIZE-1)

struct fsl_buffer{
	unsigned int data[FSL_BUFFER_SIZE];
	int write_idx;
	int read_idx;
	int fill;
	sem_t sem;
};

struct fsl_buffer private_fsl_buffer[16];


/* Returns: 0 - ok, 1 - no data available, 2 - error */
static int fnputfsl(int id, int val)
{
	int ret;
	switch (id) {
	case 0x0:
		asm volatile ("nput\t%0,rfsl0" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x1:
		asm volatile ("nput\t%0,rfsl1" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x2:
		asm volatile ("nput\t%0,rfsl2" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x3:
		asm volatile ("nput\t%0,rfsl3" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x4:
		asm volatile ("nput\t%0,rfsl4" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x5:
		asm volatile ("nput\t%0,rfsl5" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x6:
		asm volatile ("nput\t%0,rfsl6" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x7:
		asm volatile ("nput\t%0,rfsl7" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x8:
		asm volatile ("nput\t%0,rfsl8" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x9:
		asm volatile ("nput\t%0,rfsl9" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xA:
		asm volatile ("nput\t%0,rfsl10" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xB:
		asm volatile ("nput\t%0,rfsl11" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xC:
		asm volatile ("nput\t%0,rfsl12" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xD:
		asm volatile ("nput\t%0,rfsl13" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xE:
		asm volatile ("nput\t%0,rfsl14" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xF:
		asm volatile ("nput\t%0,rfsl15" :: "d" (val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	default:
		return 2;
	}
	return ret;
}

void fsl_write(int id, int val)
{
	int err;
	while(1){
		err = fnputfsl(id,val);
		if(err == 0) break;
		if(err == 2){
			printf("FSL-ERROR: FSL %d does not exist\r\n",id);
			exit(1);
		}
		INFO("FSL-WARNING: FSL %d is full\r\n",id);
		yield();
	}
}

/* Returns: 0 - ok, 1 - no data available, 2 - error */
static int fngetfsl(int id, int *val)
{
	int ret;
	switch (id) {
	case 0x0:
		asm volatile ("nget\t%0,rfsl0" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x1:
		asm volatile ("nget\t%0,rfsl1" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x2:
		asm volatile ("nget\t%0,rfsl2" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x3:
		asm volatile ("nget\t%0,rfsl3" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x4:
		asm volatile ("nget\t%0,rfsl4" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x5:
		asm volatile ("nget\t%0,rfsl5" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x6:
		asm volatile ("nget\t%0,rfsl6" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x7:
		asm volatile ("nget\t%0,rfsl7" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x8:
		asm volatile ("nget\t%0,rfsl8" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0x9:
		asm volatile ("nget\t%0,rfsl9" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xA:
		asm volatile ("nget\t%0,rfsl10" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xB:
		asm volatile ("nget\t%0,rfsl11" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xC:
		asm volatile ("nget\t%0,rfsl12" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xD:
		asm volatile ("nget\t%0,rfsl13" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xE:
		asm volatile ("nget\t%0,rfsl14" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	case 0xF:
		asm volatile ("nget\t%0,rfsl15" : "=d" (*val));
		asm volatile ("addic\t%0,r0,0"  : "=d" (ret));
		break;
	default:
		return 2;
	}
	return ret;
}

// warning : this is not thread-save, only one thread is allowed to access each FSL
int fsl_read(int id)
{
	int res;
	while(private_fsl_buffer[id].fill == 0) sem_wait(& private_fsl_buffer[id].sem);
	res = private_fsl_buffer[id].data[private_fsl_buffer[id].read_idx];
	private_fsl_buffer[id].fill--;
	private_fsl_buffer[id].read_idx = (private_fsl_buffer[id].read_idx + 1) & FSL_BUFFER_MASK;
	return res;
}

unsigned int intr_freq[32] = {0};

void fsl_isr(void * arg){
	int id,err,val;
	int n = 0;

	id = (int)(arg);

	acknowledge_interrupt(id);
	intr_freq[id]++;

	while(1){
		err = fngetfsl(id,&val);
		if(err == 0){
			if(private_fsl_buffer[id].fill >= FSL_BUFFER_SIZE){
				printf("FSL-WARNING: FSL %d: READ BUFFER FULL\r\n",id);
				break;
			}

			private_fsl_buffer[id].data[private_fsl_buffer[id].write_idx] = val;
			private_fsl_buffer[id].write_idx = (private_fsl_buffer[id].write_idx + 1) & FSL_BUFFER_MASK;
			private_fsl_buffer[id].fill++;
			n++;
			continue;
		}
		if(n == 0){
			printf("FSL-ERROR: INTERNAL ERROR: FSL %d: FSL IS EMPTY!\r\n",id);
			return;
		}
		break;
	}

	sem_post(&private_fsl_buffer[id].sem);
}

void fsl_init(int id)
{
	int j,err;

	private_fsl_buffer[id].write_idx = 0;
	private_fsl_buffer[id].read_idx = 0;
	private_fsl_buffer[id].fill = 0;

	for(j = 0; j < FSL_BUFFER_SIZE-1; j++) private_fsl_buffer[id].data[j] = 0;


	sem_init(&private_fsl_buffer[id].sem,0,0);


	disable_interrupt(id);


	err = register_int_handler(id, fsl_isr, (void*)id);
	if(err){
		INFO("COULD NOT REGISTER INTERRUPT SERCIVE ROUTINE\r\n");
		return;
	}


	enable_interrupt(id);

}
