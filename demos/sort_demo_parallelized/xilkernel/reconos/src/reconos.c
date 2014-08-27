#include "reconos.h"
#include "reconos_fsl.h"
#include "mbox.h"
#include "logging.h"
#include <xmk.h>
#include <sys/intr.h>

struct reconos_process {
	int proc_control_fsl_a; // proc_control initiates requests
	int proc_control_fsl_b; // sw initiates requests
	pthread_t proc_control_thread;
	int slot_flags[SLOTS_MAX];
};

struct reconos_process reconos;

static void reconos_slot_reset(int num, int reset)
{
	int i;
	uint32_t cmd, mask = 0;

	if (reset)
		reconos.slot_flags[num] |= SLOT_FLAG_RESET;
	else
		reconos.slot_flags[num] &= ~SLOT_FLAG_RESET;

	for (i = SLOTS_MAX - 1; i >= 0; i--) {
		mask = mask << 1;
		if ((reconos.slot_flags[i] & SLOT_FLAG_RESET))
			mask = mask | 1;
	}

	cmd = mask | 0x01000000;
	fsl_write(reconos.proc_control_fsl_b, cmd);
}

int reconos_init(int proc_ctrl_fsl_a, int proc_ctrl_fsl_b)
{
	int i;
	reconos.proc_control_fsl_a = proc_ctrl_fsl_a;
	reconos.proc_control_fsl_b = proc_ctrl_fsl_b;
	reconos.proc_control_thread = 0;
	for(i = 0; i < SLOTS_MAX; i++) reconos.slot_flags[i] = SLOT_FLAG_RESET;
	putfsl(0x04000000,15);

	return 0;
}


//int reconos_init_autodetect(void);
//void reconos_mmu_stats(uint32_t *tlb_hits, uint32_t *tlb_misses,
//			      uint32_t *page_faults);

void reconos_hwt_setresources(
		struct reconos_hwt *hwt,
		struct reconos_resource *res,
		size_t num_resources
){
	hwt->resources = res;
	hwt->num_resources = num_resources;
}

void reconos_hwt_setinitdata(struct reconos_hwt *hwt, void *init_data)
{
	hwt->init_data = init_data;
}

static void delegate_error(struct reconos_hwt * hwt, uint32_t cmd, const char * msg)
{
	printf("ERROR '%s' delegate thread %d received command 0x%08X\r\n",msg,hwt->slot,(int)cmd);
}

static inline void reconos_assert_type_and_res(struct reconos_hwt *hwt,
					       uint32_t handle, uint32_t type)
{
	if(handle >= hwt->num_resources)
		printf("wtf ... slot %d: resource id %d out of range, "
		      "must be lesser than %d\n", hwt->slot, (unsigned int)handle,
		      (int)hwt->num_resources);

	if (hwt->resources[handle].type != type)
		printf("wtf ... slot %d: resource type 0x%08X expected, "
		      "found 0x%08X\n", hwt->slot, (unsigned int)type,
		      (int)hwt->resources[handle].type);
}

static void reconos_delegate_process_get_init_data(struct reconos_hwt *hwt)
{
	fsl_write(hwt->slot, (uint32_t) hwt->init_data);
}

static void reconos_delegate_process_mbox_get(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read(hwt->slot);
	unsigned int res;

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_MBOX);

	res =  mbox_get(hwt->resources[handle].ptr);

	fsl_write(hwt->slot,res);

	DEBUG("HWT %d <- 0x%08X (mbox_get)\r\n",hwt->slot,res);
}

static void reconos_delegate_process_mbox_put(struct reconos_hwt *hwt)
{
	uint32_t handle = fsl_read(hwt->slot);
	uint32_t arg0 = fsl_read(hwt->slot);

	reconos_assert_type_and_res(hwt, handle, RECONOS_TYPE_MBOX);

	mbox_put(hwt->resources[handle].ptr, arg0);

	DEBUG("HWT %d -> 0x%08X (mbox_put)\r\n",hwt->slot,arg0);

	fsl_write(hwt->slot, 0);
}



static void *reconos_delegate_thread_entry(void *arg)
{
	struct reconos_hwt *hwt = arg;

	reconos_slot_reset(hwt->slot, 1);

	fsl_init(hwt->slot);

	reconos_slot_reset(hwt->slot, 0);
	hwt->state = RECONOS_STATE_RUNNING;

	while (1) {
		hwt->state = RECONOS_STATE_RUNNING;
		uint32_t cmd = fsl_read(hwt->slot);
		hwt->state = RECONOS_STATE_BLOCKING;
		DEBUG("HWT %d -> 0x%08X\r\n",hwt->slot,(unsigned int)cmd);
		switch (cmd) {
		case RECONOS_CMD_MBOX_GET:
			reconos_delegate_process_mbox_get(hwt);
			break;
		case RECONOS_CMD_MBOX_PUT:
			reconos_delegate_process_mbox_put(hwt);
			break;
		case RECONOS_CMD_SEM_WAIT:
			delegate_error(hwt,cmd,"UNSUPPORTED REQUEST");
			break;
		case RECONOS_CMD_SEM_POST:
			delegate_error(hwt,cmd,"UNSUPPORTED REQUEST");
			break;
		case RECONOS_CMD_MUTEX_LOCK:
			delegate_error(hwt,cmd,"UNSUPPORTED REQUEST");
			break;
		case RECONOS_CMD_MUTEX_UNLOCK:
			delegate_error(hwt,cmd,"UNSUPPORTED REQUEST");
			break;
		case RECONOS_CMD_MUTEX_TRYLOCK:
			delegate_error(hwt,cmd,"UNSUPPORTED REQUEST");
			break;
		case RECONOS_CMD_COND_WAIT:
			delegate_error(hwt,cmd,"UNSUPPORTED REQUEST");
			break;
		case RECONOS_CMD_COND_SIGNAL:
			delegate_error(hwt,cmd,"UNSUPPORTED REQUEST");
			break;
		case RECONOS_CMD_COND_BROADCAST:
			delegate_error(hwt,cmd,"UNSUPPORTED REQUEST");
			break;
		case RECONOS_CMD_RQ_RECEIVE:
			delegate_error(hwt,cmd,"UNSUPPORTED REQUEST");
			break;
		case RECONOS_CMD_RQ_SEND:
			delegate_error(hwt,cmd,"UNSUPPORTED REQUEST");
			break;
		case RECONOS_CMD_THREAD_GET_INIT_DATA:
			reconos_delegate_process_get_init_data(hwt);
			break;
		case RECONOS_CMD_THREAD_EXIT:
			DEBUG("HWT %d EXIT\r\n",hwt->slot);
			hwt->state = RECONOS_STATE_DEAD;
			return NULL;
		default:
			delegate_error(hwt,cmd,"UNSUPPORTED REQUEST");
		}
	}

	return NULL;
}

int reconos_hwt_create(struct reconos_hwt *hwt, int slot, void *arg)
{
	hwt->slot = slot;
	hwt->state = RECONOS_STATE_IDLE;
	return pthread_create(&hwt->delegate, NULL,reconos_delegate_thread_entry, hwt);
}
