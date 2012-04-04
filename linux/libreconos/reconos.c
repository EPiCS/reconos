#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include "reconos.h"
#include "fsl.h"
#include "mbox.h"
#include "rqueue.h"
#include "xutils.h"

#define RECONOS_DEBUG(x, ...)
#define RECONOS_ERROR(x, ...)

static struct reconos_process reconos_proc;

static void reconos_slot_reset(int num, int reset)
{
	int i;
	uint32_t cmd, mask = 0;
	
	if (reset)
		reconos_proc.slot_flags[num] |= SLOT_FLAG_RESET;
	else
		reconos_proc.slot_flags[num] &= ~SLOT_FLAG_RESET;
	
	for (i = SLOTS_MAX - 1; i >= 0; i--) {
		mask = mask << 1;
		if ((reconos_proc.slot_flags[i] & SLOT_FLAG_RESET))
			mask = mask | 1;
	}

	cmd = mask | 0x01000000;
	fsl_write(reconos_proc.proc_control_fsl_b, cmd);
}

static uint32_t reconos_getpgd(void)
{
	int res, fd;
	uint32_t pgd;

	fd = open_or_die("/dev/getpgd", O_RDONLY);

	res = read(fd, &pgd, sizeof(pgd));
	if (res != sizeof(pgd))
		panic("Read error from /dev/getpgd!\n");

	close(fd);
	return pgd;
}

void reconos_mmu_stats(uint32_t *tlb_hits, uint32_t *tlb_misses,
		       uint32_t *page_faults)
{
	uint32_t hits, misses;

	fsl_write(reconos_proc.proc_control_fsl_b, 0x05000000);

	hits = fsl_read(reconos_proc.proc_control_fsl_b);
	misses = fsl_read(reconos_proc.proc_control_fsl_b);

	if (page_faults)
		*page_faults = reconos_proc.page_faults;
	if (tlb_misses)
		*tlb_misses = misses;
	if (tlb_hits)
		*tlb_hits = hits;
}

void reconos_proc_control_selftest(void)
{
	uint32_t res, expect = 0x5E1F7E57;

	fsl_write(reconos_proc.proc_control_fsl_b, 0x06000000);

	res = fsl_read(reconos_proc.proc_control_fsl_b);
	if (res == expect)
		whine("proc_control selftest part 1 success\n");
	else
		whine("proc_control selftest part 1 failed "
		      "(read 0x%08X instead of 0x%08X)\n",
		      res, expect);
}

void reconos_cache_flush(void)
{
	int one = 1;
	write(reconos_proc.fd_cache, &one, sizeof(one));
}

static void *reconos_control_thread_entry(void *arg)
{
	while (1) {
		uint32_t cmd, ret, *addr;

		/* receive page fault address */
		cmd = fsl_read(reconos_proc.proc_control_fsl_a);
		if (cmd == 0x00000001) {	
			addr = (uint32_t *) fsl_read(reconos_proc.proc_control_fsl_a);
			reconos_proc.page_faults++;

			/* This page has not been touched yet.
			 * We can safely write 0 to the page */
			*addr = 0;
			reconos_cache_flush();
			ret = *addr;
	
			ret = ret & 0x00FFFFFF; /* Clear upper 8 bits */
			ret = ret | 0x03000000; /* Set page ready command */

			/* Note: the lower 24 bits of ret are ignored by the HW. */
			fsl_write(reconos_proc.proc_control_fsl_a, ret);
		}
		if (cmd == 0x00000002)
			whine("proc_control selftest part 2 success\n");
	}
}

static int reconos_get_numfsl(void)
{
	unsigned int pvr3;

	asm volatile ("mfs %0,rPVR3" : "=d" (pvr3));

	return 0x0000001F & (pvr3 >> 7);
}

int reconos_init(int proc_control_fsl_a, int proc_control_fsl_b)
{
	int i;
	uint32_t pgd;
	pthread_attr_t attr;

	reconos_proc.proc_control_fsl_a = proc_control_fsl_a;
	reconos_proc.proc_control_fsl_b = proc_control_fsl_b;
	reconos_proc.page_faults = 0;

	for (i = 0; i < SLOTS_MAX; i++)
		reconos_proc.slot_flags[i] |= SLOT_FLAG_RESET;
	fsl_write(proc_control_fsl_b, 0x04000000);

	pgd = reconos_getpgd();
	fsl_write(proc_control_fsl_b, 0x02000000);
	fsl_write(proc_control_fsl_b, pgd);

	pthread_attr_init(&attr);	
	pthread_create(&reconos_proc.proc_control_thread, NULL,
		       reconos_control_thread_entry, NULL);

	reconos_proc.fd_cache = open_or_die("/dev/getpgd", O_WRONLY);

	return 0;
}

int reconos_init_autodetect(void)
{
	int num = reconos_get_numfsl();
	return reconos_init(num - 2, num - 1);
}

static void *reconos_delegate_thread_entry(void *arg);

int reconos_hwt_create(struct reconos_hwt * hwt, int slot, void *arg)
{
	hwt->slot = slot;
	return pthread_create(&hwt->delegate, NULL,
			      reconos_delegate_thread_entry, hwt);
}

void reconos_hwt_setresources(struct reconos_hwt *hwt,
			      struct reconos_resource *res,
			      size_t num_resources)
{
	hwt->resources = res;
	hwt->num_resources = num_resources;
}

void reconos_hwt_setinitdata(struct reconos_hwt *hwt, void *init_data)
{
	hwt->init_data = init_data;
}

static void *reconos_delegate_thread_entry(void *arg)
{
	struct reconos_hwt * hwt;
	
	hwt = (struct reconos_hwt *)arg;

	RECONOS_DEBUG("slot %d: starting delegate thread\n", hwt->slot);
	
	reconos_slot_reset(hwt->slot,1);
	reconos_slot_reset(hwt->slot,0);
	
	while(1){
		uint32_t cmd, handle, handle2, arg0, result, msg_size, *msg;
		int i;
		
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

			case RECONOS_CMD_SEM_WAIT:
				RECONOS_DEBUG("slot %d: command is SEM_WAIT\n", hwt->slot);
				handle = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: resource id is 0x%08X\n", hwt->slot, handle);
			
				if(handle >= hwt->num_resources){
					RECONOS_ERROR("slot %d: resource id %d out of range, must be lesser than %d\n",
						hwt->slot, handle, hwt->num_resources);
					exit(1);
				}
				
				if(hwt->resources[handle].type != RECONOS_TYPE_SEM){
					RECONOS_ERROR("slot %d: resource type 0x%08X expected, found 0x%08X\n",
						hwt->slot, RECONOS_TYPE_SEM, hwt->resources[handle].type);
					exit(1);
				}
				
			
				result = sem_wait(hwt->resources[handle].ptr);
				RECONOS_DEBUG("slot %d: sem_wait returns 0x%08X\n", hwt->slot, result);
				
				fsl_write(hwt->slot, result);
				break;	
			
			case RECONOS_CMD_SEM_POST:
				RECONOS_DEBUG("slot %d: command is SEM_POST\n", hwt->slot);
				handle = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: resource id is 0x%08X\n", hwt->slot, handle);
				
				if(handle >= hwt->num_resources){
					RECONOS_ERROR("slot %d: resource id %d out of range, must be lesser than %d\n",
						hwt->slot, handle, hwt->num_resources);
					exit(1);
				}
				
				if(hwt->resources[handle].type != RECONOS_TYPE_SEM){
					RECONOS_ERROR("slot %d: resource type 0x%08X expected, found 0x%08X\n",
						hwt->slot, RECONOS_TYPE_SEM, hwt->resources[handle].type);
					exit(1);
				}
				
				result = sem_post(hwt->resources[handle].ptr);
				RECONOS_DEBUG("slot %d: sem_post returns 0x%08X\n", hwt->slot, result);
				
				fsl_write(hwt->slot, 0);
				break;

			case RECONOS_CMD_MUTEX_LOCK:
				RECONOS_DEBUG("slot %d: command is MUTEX_LOCK\n", hwt->slot);
				handle = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: resource id is 0x%08X\n", hwt->slot, handle);
			
				if(handle >= hwt->num_resources){
					RECONOS_ERROR("slot %d: resource id %d out of range, must be lesser than %d\n",
						hwt->slot, handle, hwt->num_resources);
					exit(1);
				}
				
				if(hwt->resources[handle].type != RECONOS_TYPE_MUTEX){
					RECONOS_ERROR("slot %d: resource type 0x%08X expected, found 0x%08X\n",
						hwt->slot, RECONOS_TYPE_MUTEX, hwt->resources[handle].type);
					exit(1);
				}
				
			
				result = pthread_mutex_lock(hwt->resources[handle].ptr);
				RECONOS_DEBUG("slot %d: mutex_lock returns 0x%08X\n", hwt->slot, result);
				
				fsl_write(hwt->slot, result);
				break;	

			case RECONOS_CMD_MUTEX_UNLOCK:
				RECONOS_DEBUG("slot %d: command is MUTEX_UNLOCK\n", hwt->slot);
				handle = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: resource id is 0x%08X\n", hwt->slot, handle);
				
				if(handle >= hwt->num_resources){
					RECONOS_ERROR("slot %d: resource id %d out of range, must be lesser than %d\n",
						hwt->slot, handle, hwt->num_resources);
					exit(1);
				}
				
				if(hwt->resources[handle].type != RECONOS_TYPE_MUTEX){
					RECONOS_ERROR("slot %d: resource type 0x%08X expected, found 0x%08X\n",
						hwt->slot, RECONOS_TYPE_MUTEX, hwt->resources[handle].type);
					exit(1);
				}
				
				result = pthread_mutex_unlock(hwt->resources[handle].ptr);
				RECONOS_DEBUG("slot %d: mutex_unlock returns 0x%08X\n", hwt->slot, result);
				
				fsl_write(hwt->slot, 0);
				break;

			case RECONOS_CMD_MUTEX_TRYLOCK:
				RECONOS_DEBUG("slot %d: command is MUTEX_TRYLOCK\n", hwt->slot);
				handle = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: resource id is 0x%08X\n", hwt->slot, handle);
			
				if(handle >= hwt->num_resources){
					RECONOS_ERROR("slot %d: resource id %d out of range, must be lesser than %d\n",
						hwt->slot, handle, hwt->num_resources);
					exit(1);
				}
				
				if(hwt->resources[handle].type != RECONOS_TYPE_MUTEX){
					RECONOS_ERROR("slot %d: resource type 0x%08X expected, found 0x%08X\n",
						hwt->slot, RECONOS_TYPE_MUTEX, hwt->resources[handle].type);
					exit(1);
				}
				
			
				result = pthread_mutex_trylock(hwt->resources[handle].ptr);
				RECONOS_DEBUG("slot %d: mutex_trylock returns 0x%08X\n", hwt->slot, result);
				
				fsl_write(hwt->slot, result);
				break;

			case RECONOS_CMD_COND_WAIT:
				RECONOS_DEBUG("slot %d: command is COND_WAIT\n", hwt->slot);
				handle = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: resource id is 0x%08X\n", hwt->slot, handle);
				handle2 = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: resource id is 0x%08X\n", hwt->slot, handle2);
			
				if(handle >= hwt->num_resources){
					RECONOS_ERROR("slot %d: 1st resource id %d out of range, must be lesser than %d\n",
						hwt->slot, handle, hwt->num_resources);
					exit(1);
				}

				if(handle2 >= hwt->num_resources){
					RECONOS_ERROR("slot %d: 2nd resource id %d out of range, must be lesser than %d\n",
						hwt->slot, handle2, hwt->num_resources);
					exit(1);
				}
				
				if(hwt->resources[handle].type != RECONOS_TYPE_COND){
					RECONOS_ERROR("slot %d: 1st resource type 0x%08X expected, found 0x%08X\n",
						hwt->slot, RECONOS_TYPE_COND, hwt->resources[handle].type);
					exit(1);
				}
				
				if(hwt->resources[handle2].type != RECONOS_TYPE_MUTEX){
					RECONOS_ERROR("slot %d: 2nd resource type 0x%08X expected, found 0x%08X\n",
						hwt->slot, RECONOS_TYPE_MUTEX, hwt->resources[handle2].type);
					exit(1);
				}				
			
				result = pthread_cond_wait(hwt->resources[handle].ptr, hwt->resources[handle2].ptr);
				RECONOS_DEBUG("slot %d: cond_wait returns 0x%08X\n", hwt->slot, result);
				
				fsl_write(hwt->slot, result);
				break;

			case RECONOS_CMD_COND_SIGNAL:
				RECONOS_DEBUG("slot %d: command is COND_SIGNAL\n", hwt->slot);
				handle = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: resource id is 0x%08X\n", hwt->slot, handle);
				
				if(handle >= hwt->num_resources){
					RECONOS_ERROR("slot %d: resource id %d out of range, must be lesser than %d\n",
						hwt->slot, handle, hwt->num_resources);
					exit(1);
				}
				
				if(hwt->resources[handle].type != RECONOS_TYPE_COND){
					RECONOS_ERROR("slot %d: resource type 0x%08X expected, found 0x%08X\n",
						hwt->slot, RECONOS_TYPE_COND, hwt->resources[handle].type);
					exit(1);
				}
				
				result = pthread_cond_signal(hwt->resources[handle].ptr);
				RECONOS_DEBUG("slot %d: cond_signal returns 0x%08X\n", hwt->slot, result);
				
				fsl_write(hwt->slot, 0);
				break;

			case RECONOS_CMD_COND_BROADCAST:
				RECONOS_DEBUG("slot %d: command is COND_BROADCAST\n", hwt->slot);
				handle = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: resource id is 0x%08X\n", hwt->slot, handle);
				
				if(handle >= hwt->num_resources){
					RECONOS_ERROR("slot %d: resource id %d out of range, must be lesser than %d\n",
						hwt->slot, handle, hwt->num_resources);
					exit(1);
				}
				
				if(hwt->resources[handle].type != RECONOS_TYPE_COND){
					RECONOS_ERROR("slot %d: resource type 0x%08X expected, found 0x%08X\n",
						hwt->slot, RECONOS_TYPE_COND, hwt->resources[handle].type);
					exit(1);
				}
				
				result = pthread_cond_broadcast(hwt->resources[handle].ptr);
				RECONOS_DEBUG("slot %d: cond_broadcast returns 0x%08X\n", hwt->slot, result);
				
				fsl_write(hwt->slot, 0);
				break;

			case RECONOS_CMD_RQ_RECEIVE:
				RECONOS_DEBUG("slot %d: command is RQ_RECEIVE\n", hwt->slot);
				handle = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: resource id is 0x%08X\n", hwt->slot, handle);
				arg0 = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: msg_size is 0x%08X\n", hwt->slot, arg0);

				if(handle >= hwt->num_resources){
					RECONOS_ERROR("slot %d: resource id %d out of range, must be lesser than %d\n",
						hwt->slot, handle, hwt->num_resources);
					exit(1);
				}
				
				if(hwt->resources[handle].type != RECONOS_TYPE_RQ){
					RECONOS_ERROR("slot %d: resource type 0x%08X expected, found 0x%08X\n",
						hwt->slot, RECONOS_TYPE_RQ, hwt->resources[handle].type);
					exit(1);
				}
				msg_size   = arg0;                                
				msg        = (uint32_t *) malloc(msg_size); 			
				if ((result = rq_receive (hwt->resources[handle].ptr, msg, msg_size)) < 0)
		  		{
		    			RECONOS_DEBUG ("slot %d: rq_receive (0x%08X) receives error\n", 
						hwt->slot, handle);
		    			result = 0;	// signal error
		  		}
				RECONOS_DEBUG("slot %d: rq_receive returns 0x%08X\n", hwt->slot, result);
				// restore old queue attributes			
				if (result == 0 || result > msg_size)
				{			
					// error code, if there is an error or if the message exceeds the expected size
					if (result>msg_size && ((int)result)!=-1)
					{
						RECONOS_ERROR("slot %d: The received message size for rq (0x%08X) is bigger than expecetd (received %d > expected %d bytes) \n", 
						hwt->slot, handle, (int)result, (int)msg_size);
					}
					fsl_write(hwt->slot, 0);
				}
				else
				{
					fsl_write(hwt->slot, result);
					// write data to hw thread
					for(i=0; i<(result/sizeof(uint32_t));i++)
					{
						fsl_write(hwt->slot, msg[i]);
					}
				}
				free (msg);
				break;



			case RECONOS_CMD_RQ_SEND:
				RECONOS_DEBUG("slot %d: command is RQ_SEND\n", hwt->slot);
				handle = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: resource id is 0x%08X\n", hwt->slot, handle);
				arg0 = fsl_read(hwt->slot);
				RECONOS_DEBUG("slot %d: msg_size is 0x%08X\n", hwt->slot, arg0);

				if(handle >= hwt->num_resources){
					RECONOS_ERROR("slot %d: resource id %d out of range, must be lesser than %d\n",
						hwt->slot, handle, hwt->num_resources);
					exit(1);
				}
				
				if(hwt->resources[handle].type != RECONOS_TYPE_RQ){
					RECONOS_ERROR("slot %d: resource type 0x%08X expected, found 0x%08X\n",
						hwt->slot, RECONOS_TYPE_RQ, hwt->resources[handle].type);
					exit(1);
				}

				msg_size   = arg0; 
				msg        = (uint32_t *) malloc(msg_size); 

				/*if (msg_size > (12*sizeof(uint32)))
				{
					RECONOS_ERROR("slot %d: the message size for rq (0x%08X) is to big for the fsl_links: %d > %d \n", 
						hwt->slot, (int)handle, (int)msg_size, (int)(12*sizeof(uint32)));
					result = 1;
					fsl_write(hwt->slot, result);
					break;
				}*/

				// read message
				for(i=0; i<(msg_size/sizeof(uint32_t));i++)
				{
					msg[i] = fsl_read(hwt->slot);
				}
				rq_send(hwt->resources[handle].ptr, msg, msg_size);
				fsl_write(hwt->slot, 0);
				free(msg);
				break;


			case RECONOS_CMD_THREAD_GET_INIT_DATA:
				RECONOS_DEBUG("slot %d: command is GET_INIT_DATA\n", hwt->slot);
							
				result = (uint32_t)hwt->init_data;
				RECONOS_DEBUG("slot %d: init_data is 0x%08X\n", hwt->slot, result);
				
				fsl_write(hwt->slot, result);
				break;

			case RECONOS_CMD_THREAD_EXIT:
				RECONOS_DEBUG("slot %d: command is THREAD_EXIT\n", hwt->slot);
				return NULL;
			
			default:
				RECONOS_ERROR("slot %d: unknown command 0x%08X\n", hwt->slot, cmd);
				exit(1);
		}
	}
		
	return NULL;
}
