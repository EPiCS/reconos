
#include "reconos.h"
#include "fsl.h"
#include "mbox.h"

#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>


#define FSL_PATH_LEN 256

struct reconos_process reconos_proc;


static void slot_reset(int num, int reset){
	uint32 cmd;
	uint32 mask = 0;
	int i;
	
	if (reset) {
		reconos_proc.slot_flags[num] |= SLOT_FLAG_RESET;
	} else {
		reconos_proc.slot_flags[num] &= ~SLOT_FLAG_RESET;
	}
	
	for(i = MAX_SLOTS - 1; i >= 0; i--){
		mask = mask << 1;
		if((reconos_proc.slot_flags[i] & SLOT_FLAG_RESET)){
			mask = mask | 1;
		}
	}
	
	cmd = mask | 0x01000000;
	
	fsl_write(reconos_proc.proc_control_fsl,cmd);
}

int reconos_init(int proc_control_fsl)
{
	int i;
	reconos_proc.proc_control_fsl = proc_control_fsl;
	for(i = 0; i < MAX_SLOTS; i++){
		reconos_proc.slot_flags[i] |= SLOT_FLAG_RESET;
	}
	return 0;
}


void * delegate_thread_entry(void * arg);

int reconos_hwt_create(
		struct reconos_hwt * hwt,
		int slot,
		void * arg)
{
	hwt->slot = slot;
	return pthread_create(&hwt->delegate,NULL,delegate_thread_entry,hwt);
}

void reconos_hwt_setresources(struct reconos_hwt * hwt, struct reconos_resource * res, int num_resources)
{
	hwt->resources = res;
	hwt->num_resources = num_resources;
}

#if 1
#define RECONOS_DEBUG(...) fprintf(stderr,__VA_ARGS__);
#else
#define RECONOS_DEBUG(...)
#endif

#define RECONOS_ERROR(...) fprintf(stderr,"ERROR:" __VA_ARGS__);


void * delegate_thread_entry(void * arg)
{
	struct reconos_hwt * hwt;
	
	hwt = (struct reconos_hwt *)arg;

	RECONOS_DEBUG("slot %d: starting delegate thread\n", hwt->slot);
	
	slot_reset(hwt->slot,1);
	slot_reset(hwt->slot,0);
	
	while(1){
		uint32 cmd;
		uint32 handle;
		uint32 arg0;
		uint32 result;
		
		cmd = fsl_read(hwt->slot);
		
		RECONOS_DEBUG("slot %d: received command 0x%08X\n", hwt->slot, cmd);
		
		switch(cmd){
			case RECONOS_CMD_MBOX_GET:
				RECONOS_DEBUG("slot %d: command is MBOX_GET\n", hwt->slot);
				handle = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: resource id is 0x%08X\n", hwt->slot, handle);
			
				if(handle >= hwt->num_resources){
					RECONOS_ERROR("slot %d: resource id %d out of range, must be lesser than %d\n",
						hwt->slot, handle, hwt->num_resources);
					exit(1);
				}
				
				if(hwt->resources[handle].type != RECONOS_TYPE_MBOX){
					RECONOS_ERROR("slot %d: resource type 0x%08X expected, found 0x%08X\n",
						hwt->slot, RECONOS_TYPE_MBOX, hwt->resources[handle].type);
					exit(1);
				}
				
			
				result = mbox_get(hwt->resources[handle].ptr);
				RECONOS_DEBUG("slot %d: mbox_get returns 0x%08X\n", hwt->slot, result);
				
				fsl_write(hwt->slot, result);
				break;	
			
			case RECONOS_CMD_MBOX_PUT:
				RECONOS_DEBUG("slot %d: command is MBOX_PUT\n", hwt->slot);
				handle = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: resource id is 0x%08X\n", hwt->slot, handle);
				arg0 = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: data is 0x%08X\n", hwt->slot, arg0);
				
				if(handle >= hwt->num_resources){
					RECONOS_ERROR("slot %d: resource id %d out of range, must be lesser than %d\n",
						hwt->slot, handle, hwt->num_resources);
					exit(1);
				}
				
				if(hwt->resources[handle].type != RECONOS_TYPE_MBOX){
					RECONOS_ERROR("slot %d: resource type 0x%08X expected, found 0x%08X\n",
						hwt->slot, RECONOS_TYPE_MBOX, hwt->resources[handle].type);
					exit(1);
				}
				
				mbox_put(hwt->resources[handle].ptr, arg0);
				RECONOS_DEBUG("slot %d: mbox_put returns void\n", hwt->slot);
				
				fsl_write(hwt->slot, 0);
				break;
			
			default:
				RECONOS_ERROR("slot %d: unknown command 0x%08X\n", hwt->slot, cmd);
				exit(1);
		}
	}
		
	return NULL;
}



