/*
 *                                                        ____  _____
 *                            ________  _________  ____  / __ \/ ___/
 *                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
 *                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
 *                         /_/   \___/\___/\____/_/ /_/\____//____/
 *
 * ======================================================================
 *
 *   title:        ReconOS library - Delegate thread
 *
 *   project:      ReconOS
 *   author:       Andreas Agne, University of Paderborn
 *                 Markus Happe, University of Paderborn
 *                 Daniel Borkmann, ETH Zürich
 *                 Sebastian Meisner, University of Paderborn
 *                 Christoph Rüthing, University of Paderborn
 *   description:  Delegate methods to handle call from HWTs.
 *
 * ======================================================================
 */

#include "hwt_delegate.h"

#include "reconos.h"
#include "utils.h"
#include "private.h"
#include "arch/arch.h"

#include "legacy_os_calls/mbox.h"
#include "legacy_os_calls/rqueue.h"

#include <pthread.h>

#include <stdlib.h>
#include <sys/types.h>

// define all commands

#define OSIF_CMD_THREAD_GET_INIT_DATA  0x000000A0
#define OSIF_CMD_THREAD_DELAY          0x000000A1 // ToDo
#define OSIF_CMD_THREAD_EXIT           0x000000A2
#define OSIF_CMD_THREAD_YIELD          0x000000A3 // ToDo
#define OSIF_CMD_THREAD_RESUME         0x000000A4 // ToDo
#define OSIF_CMD_THREAD_LOAD_STATE     0x000000A5 // ToDo
#define OSIF_CMD_THREAD_STORE_STATE    0x000000A6 // ToDo

#define OSIF_CMD_SEM_POST              0x000000B0
#define OSIF_CMD_SEM_WAIT              0x000000B1

#define OSIF_CMD_MUTEX_LOCK            0x000000C0
#define OSIF_CMD_MUTEX_UNLOCK          0x000000C1
#define OSIF_CMD_MUTEX_TRYLOCK         0x000000C2 // Not tested, yet

#define OSIF_CMD_COND_WAIT             0x000000D0 // Not tested, yet
#define OSIF_CMD_COND_SIGNAL           0x000000D1 // Not tested, yet
#define OSIF_CMD_COND_BROADCAST        0x000000D2 // Not tested, yet

#define OSIF_CMD_RQ_RECEIVE            0x000000E0 // ToDo
#define OSIF_CMD_RQ_SEND               0x000000E1 // ToDo

#define OSIF_CMD_MBOX_GET              0x000000F0
#define OSIF_CMD_MBOX_PUT              0x000000F1
#define OSIF_CMD_MBOX_TRYGET           0x000000F2 // ToDo
#define OSIF_CMD_MBOX_TRYPUT           0x000000F3 // ToDo

#define OSIF_CMD_MASK                  0x000000FF
#define OSIF_CMD_YIELD_MASK            0x80000000

inline void resource_check_type(struct reconos_hwt *hwt,
                                uint32_t handle, uint32_t type) {
	if (handle >= hwt->cfg->resource_count)
		panic("[reconos-core] resource out of range: %d\n", handle);

	if (hwt->cfg->resource[handle].type != type)
		panic("[reconos-core] wrong resource type: %x expected %x\n", hwt->cfg->resource[handle].type, type);
}


uint32_t hwt_delegate_get_init_data(struct reconos_hwt *hwt) {
	return (uint32_t) hwt->init_data;
}


uint32_t hwt_delegate_sem_post(struct reconos_hwt *hwt) {
	uint32_t handle = reconos_osif_read(hwt->osif);

	//printf("RECONOS DELEGATE THREAD %d: RES %d: SEM_POST\n", hwt->slot, handle);

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_SEM);

	sem_post(hwt->cfg->resource[handle].ptr);

	//printf("RECONOS DELEGATE THREAD %d: RES %d: SEM_POST DONE\n", hwt->slot, handle);

	return 0;
}

uint32_t hwt_delegate_sem_wait(struct reconos_hwt *hwt) {
	uint32_t handle = reconos_osif_read(hwt->osif);

	//printf("RECONOS DELEGATE THREAD %d: RES %d: SEM_WAIT\n", hwt->slot, handle);

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_SEM);

	//printf("RECONOS DELEGATE THREAD %d: RES %d: SEM_WAIT DONE\n", hwt->slot, handle);

	return sem_wait(hwt->cfg->resource[handle].ptr);
}

uint32_t hwt_delegate_mutex_lock(struct reconos_hwt *hwt) {
	uint32_t handle = reconos_osif_read(hwt->osif);

	//printf("RECONOS DELEGATE THREAD %d: RES %d: MUTEX_LOCK\n", hwt->slot, handle);

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_MUTEX);

	//printf("RECONOS DELEGATE THREAD %d: RES %d: MUTEX_LOCK DONE\n", hwt->slot, handle);

	return pthread_mutex_lock(hwt->cfg->resource[handle].ptr);
}

uint32_t hwt_delegate_mutex_unlock(struct reconos_hwt *hwt) {
	uint32_t handle = reconos_osif_read(hwt->osif);

	//printf("RECONOS DELEGATE THREAD %d: RES %d: MUTEX_UNLOCK\n", hwt->slot, handle);

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_MUTEX);

	pthread_mutex_unlock(hwt->cfg->resource[handle].ptr);

	//printf("RECONOS DELEGATE THREAD %d: RES %d: MUTEX_UNLOCK DONE\n", hwt->slot, handle);

	return 0;
}

uint32_t hwt_delegate_mutex_trylock(struct reconos_hwt *hwt) {
	uint32_t handle = reconos_osif_read(hwt->osif);

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_MUTEX);

	return pthread_mutex_trylock(hwt->cfg->resource[handle].ptr);
}

uint32_t hwt_delegate_cond_wait(struct reconos_hwt *hwt) {
#ifndef RECONOS_MINIMAL
	uint32_t handle = reconos_osif_read(hwt->osif);
	uint32_t handle2 = reconos_osif_read(hwt->osif);

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_COND);
	resource_check_type(hwt, handle2, RECONOS_RESOURCE_TYPE_MUTEX);

	return pthread_cond_wait(hwt->cfg->resource[handle].ptr,
	                         hwt->cfg->resource[handle2].ptr);
#else
	return 0;
#endif
}

uint32_t hwt_delegate_cond_signal(struct reconos_hwt *hwt) {
#ifndef RECONOS_MINIMAL
	uint32_t handle = reconos_osif_read(hwt->osif);

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_COND);

	pthread_cond_signal(hwt->cfg->resource[handle].ptr);

	return 0;
#else
	return 0;
#endif
}

uint32_t hwt_delegate_cond_broadcast(struct reconos_hwt *hwt) {
#ifndef RECONOS_MINIMAL
	uint32_t handle = reconos_osif_read(hwt->osif);

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_COND);

	pthread_cond_broadcast(hwt->cfg->resource[handle].ptr);

	return 0;
#else
	return 0;
#endif
}

uint32_t hwt_delegate_rq_receive(struct reconos_hwt *hwt) {
	int i;
	ssize_t res;
	uint32_t handle, arg0, msg_size, *msg;

	handle = reconos_osif_read(hwt->osif);
	arg0 = reconos_osif_read(hwt->osif);

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_RQ);

	msg_size = arg0;
	msg = malloc(msg_size);

	// read data from rq
	res = rq_receive(hwt->cfg->resource[handle].ptr, msg, msg_size);
	if (res <= 0 || res > msg_size) {
		whine("rq_receive screwed up: %zd\n", res);
		reconos_osif_write(hwt->osif, 0);
		goto out;
	}

	// write data to HWT
	reconos_osif_write(hwt->osif, (uint32_t) res);
	for (i = 0; i < res / sizeof(uint32_t); i++)
		reconos_osif_write(hwt->osif, msg[i]);

out:
	free(msg);

	return 0;
}

uint32_t hwt_delegate_rq_send(struct reconos_hwt *hwt) {
	int i;
	uint32_t handle, arg0, msg_size, *msg;

	handle = reconos_osif_read(hwt->osif);
	arg0 = reconos_osif_read(hwt->osif);

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_RQ);

	msg_size = arg0;
	msg = malloc(msg_size);

	// read data from HWT
	for (i = 0; i < msg_size / sizeof(uint32_t); i++)
		msg[i] = reconos_osif_read(hwt->osif);

	// write data into rq
	rq_send(hwt->cfg->resource[handle].ptr, msg, msg_size);

	free(msg);

	return 0;
}

uint32_t hwt_delegate_mbox_get(struct reconos_hwt *hwt) {
	uint32_t handle = reconos_osif_read(hwt->osif);

	//printf("RECONOS DELEGATE THREAD %d: RES %d: MBOX_GET\n", hwt->slot, handle);

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_MBOX);

	//printf("RECONOS DELEGATE THREAD %d: RES %d: MBOX_GET DONE: %x\n", hwt->slot, handle, data);

	return mbox_get(hwt->cfg->resource[handle].ptr);
}

uint32_t hwt_delegate_mbox_put(struct reconos_hwt *hwt) {
	uint32_t handle = reconos_osif_read(hwt->osif);
	uint32_t arg0 = reconos_osif_read(hwt->osif);

	//printf("RECONOS DELEGATE THREAD %d: RES %d: MBOX_PUT\n", hwt->slot, handle);

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_MBOX);

	mbox_put(hwt->cfg->resource[handle].ptr, arg0);

	//printf("RECONOS DELEGATE THREAD %d: RES %d: MBOX_PUT DONE: %x\n", hwt->slot, handle, arg0);

	return 0;
}

uint32_t hwt_delegate_mbox_tryget(struct reconos_hwt *hwt) {
	uint32_t handle = reconos_osif_read(hwt->osif);
	uint32_t data, ret;

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_MBOX);

	data = 0;
	ret = mbox_tryget(hwt->cfg->resource[handle].ptr, &data);
	reconos_osif_write(hwt->osif, data);

	return ret;
}

uint32_t hwt_delegate_mbox_tryput(struct reconos_hwt *hwt) {
	uint32_t handle = reconos_osif_read(hwt->osif);
	uint32_t arg0 = reconos_osif_read(hwt->osif);

	resource_check_type(hwt, handle, RECONOS_RESOURCE_TYPE_MBOX);

	return mbox_tryput(hwt->cfg->resource[handle].ptr, arg0);
}

void *reconos_hwt_delegate(void *arg) {
	struct reconos_hwt *hwt = arg;
	struct reconos_configuration *cfg;
	uint32_t cmd, ret;

	reconos_slot_reset(hwt->slot, 1);
	reconos_slot_reset(hwt->slot, 0);
	hwt->state = RECONOS_HWT_STATE_RUNNING;

	while (1) {
		//printf("... Waiting for command\n");

		cmd = reconos_osif_read(hwt->osif);

		//printf("... Received command %x on hwt %d\n", cmd, hwt->slot);

		// perfom OSIF calls that should be executed independent from scheduling
		switch (cmd & OSIF_CMD_MASK) {
			case OSIF_CMD_MBOX_PUT:
				ret = hwt_delegate_mbox_put(hwt);
				break;
			case OSIF_CMD_MBOX_TRYPUT:
				ret = hwt_delegate_mbox_tryput(hwt);
				break;
			case OSIF_CMD_SEM_POST:
				ret = hwt_delegate_sem_post(hwt);
				break;
			case OSIF_CMD_MUTEX_UNLOCK:
				ret = hwt_delegate_mutex_unlock(hwt);
				break;
			case OSIF_CMD_COND_SIGNAL:
				ret = hwt_delegate_cond_signal(hwt);
				break;
			case OSIF_CMD_COND_BROADCAST:
				ret = hwt_delegate_cond_broadcast(hwt);
				break;
			case OSIF_CMD_RQ_SEND:
				ret = hwt_delegate_rq_send(hwt);
				break;
		}

		// perfom scheduling
		if (hwt->is_reconf && cmd & OSIF_CMD_YIELD_MASK ) {
			if (!reconos_runtime.scheduler)
				panic("[reconos_core] No scheduler defined\n");

			cfg = reconos_runtime.scheduler(hwt);
			if (cfg) {
				//printf("... Performing scheduling, loading configuration '%s' into slot %d\n", cfg->name, hwt->slot);

				hwt->state = RECONOS_HWT_STATE_RECONFIGURING;

				hwt->cfg = cfg;
				reconos_slot_reset(hwt->slot, 1);

				load_partial_bitstream(hwt->cfg->bitstream, hwt->cfg->bitstream_length);
				
				hwt->state = RECONOS_HWT_STATE_RUNNING;
				reconos_slot_reset(hwt->slot, 0);

				continue;
			}
		}

		// perform OSIF calls only if not scheduled
		switch (cmd & OSIF_CMD_MASK) {
			case OSIF_CMD_MBOX_GET:
				ret = hwt_delegate_mbox_get(hwt);
				break;
			case OSIF_CMD_MBOX_TRYGET:
				ret = hwt_delegate_mbox_tryget(hwt);
				break;
			case OSIF_CMD_SEM_WAIT:
				ret = hwt_delegate_sem_wait(hwt);
				break;	
			case OSIF_CMD_MUTEX_LOCK:
				ret = hwt_delegate_mutex_lock(hwt);
				break;	
			case OSIF_CMD_MUTEX_TRYLOCK:
				ret = hwt_delegate_mutex_trylock(hwt);
				break;
			case OSIF_CMD_COND_WAIT:
				ret = hwt_delegate_cond_wait(hwt);
				break;
			case OSIF_CMD_RQ_RECEIVE:
				ret = hwt_delegate_rq_receive(hwt);
				break;
			case OSIF_CMD_THREAD_GET_INIT_DATA:
				ret = hwt_delegate_get_init_data(hwt);
				break;
			case OSIF_CMD_THREAD_EXIT:
				return NULL;
				break;
		}

		reconos_osif_write(hwt->osif, ret);
	}

return NULL;
}
