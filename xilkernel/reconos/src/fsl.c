//#include "xmk.h"
//#include "sys/init.h"
//#include "platform.h"
//#include "mb_interface.h"

#include "xmk.h"
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include "sys/process.h"

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
	}
	yield();
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

int fsl_read(int id)
{
	int err;
	int val;
	while(1){
		err = fngetfsl(id,&val);
		if(err == 0) return val;
		if(err == 2){
			printf("FSL-ERROR: FSL %d does not exist\r\n",id);
			exit(1);
		}
		yield();
	}
}
