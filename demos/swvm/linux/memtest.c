#include "reconos.h"
#include "mbox.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>
#include <string.h>

#define PROC_CONTROL_FSL 1


struct reconos_resource res[2];

struct reconos_hwt hwt;

struct mbox hw2sw,sw2hw;

void print_help()
{
  printf(
"Usage: memtest <hwt slot number>  <memory address>\n"
"Simple test program for testing communication with memaccess hardware thread.\n"
"\n"
"Parameters:\n"
"\t<hwt slot number>\tnumber of hardware thread to use.\n"
"\t<memory <address>\tMemory Address that shall be read by the memaccess thread.\n"

  );
}


int main(int argc, char ** argv)
{
        uint32 slot;
	uint32 addr;
	uint32 data;
	
	if (argc < 3 ||
	    (strcmp(argv[1], "--help") == 0)||
	    (strcmp(argv[1], "-h") == 0))
	  {
	    print_help();
	    exit(0);
	  }

	slot = atoi(argv[1]);
	addr = atoi(argv[2]);
	
	res[0].type = RECONOS_TYPE_MBOX;
	res[0].ptr  = &sw2hw;
	
	res[1].type = RECONOS_TYPE_MBOX;
	res[1].ptr  = &hw2sw;
	
	printf("\nInit Mailboxes...\n");
	mbox_init(&sw2hw,3);
	mbox_init(&hw2sw,3);
	
	printf("\nInit ReconOS...\n");
	reconos_init(PROC_CONTROL_FSL);
	
	printf("\nSetting Resources...\n");
	reconos_hwt_setresources(&hwt,res,2);

	printf("\nCreating Hardware Threads...\n");
	reconos_hwt_create(&hwt,slot,NULL);
	
	printf("\nPut to mailbox...\n");
	mbox_put(&sw2hw,addr);

	printf("\nGet from mailbox...\n");
	data = mbox_get(&hw2sw);
	
	printf("0x%08X: 0x%08X\n",addr,data);
	
	pthread_join(hwt.delegate,NULL);
	
	return 0;
}

