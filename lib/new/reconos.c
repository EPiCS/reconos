/*
 *                                                        ____  _____
 *                            ________  _________  ____  / __ \/ ___/
 *                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
 *                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
 *                         /_/   \___/\___/\____/_/ /_/\____//____/
 *
 * ======================================================================
 *
 *   title:        ReconOS library - Main library
 *
 *   project:      ReconOS
 *   author:       Andreas Agne, University of Paderborn
 *                 Markus Happe, University of Paderborn
 *                 Daniel Borkmann, ETH Zürich
 *                 Sebastian Meisner, University of Paderborn
 *                 Christoph Rüthing, University of Paderborn
 *   description:  Main ReconOS library
 *
 * ======================================================================
 */

#include "reconos.h"
#include "private.h"
#include "arch/arch.h"

#include <unistd.h>
#include <signal.h>

static int RECONOS_NUM_HWTS = 0;

static struct hwslot *_hwslots;
static int proc_control;


/* == ReconOS resource ================================================= */

 void reconos_resource_init(struct reconos_resource *rr,
                           int type, void *ptr) {
 	rr->type = type;
 	rr->ptr = ptr;
 }


/* == ReconOS thread =================================================== */

void reconos_thread_init(struct reconos_thread *rt, char* name) {
	rt->name = name;

	rt->init_data = NULL;
	rt->resources = NULL;
	rt->resource_count = 0;

	rt->state = RECONOS_THREAD_STATE_INIT;
	// TODO: Where to allocate memory?
	rt->state_data = NULL;

	rt->hwslot = NULL;

	rt->bitstreams = NULL;
	rt->bitstream_lengths = NULL;
}

void reconos_thread_setinitdata(struct reconos_thread *rt, void *init_data) {
	rt->init_data = init_data;
}

void reconos_thread_setresources(struct reconos_thread *rt,
                                 struct reconos_resource *resources,
                                 int resource_count) {
	rt->resources = resources;
	rt->resouce_count = resource_count;
}

void reconos_thread_setbitstream(struct reconos_thread *rt,
                                 char **bitstreams,
                                 int *bitstream_lengths) {
	rt->bitstreams = bitstreams;
	rt->bitstream_lengths = bitstream_lengths;
}

void reconos_thread_loadbitstream(struct reconos_thread *rt,
                                  char *path) {
	FILE *file;
	unsigned int size;

	debug("[reconos-core] loading bitstreams from %s\n", path);

	rt->bitstream_lengths = (int *)malloc(RECONOS_NUM_HWTS * sizeof(int));
	if (!rt->bitstream_lengths)
		panic("[reconos-core] failed to allocate memory for bitstream");

	rt->bitstreams = (char **)malloc(RECONOS_NUM_HWTS * sizeof(char *));
	if (!rt->bitstreams)
		panic("[reconos-core] failed to allocate memory for bitstream");

	for (int i = 0; i < RECONOS_NUM_HWTS; i++) {
		file = fopen(filename, "rb");
		if (!file)
			panic("[reconos-core] failed to open bitstream\n");

		fseek(file, 0L, SEEK_END);
		size = ftell(file) / 4;
		rewind(file);

		rt->bitstream_lengths[i] = size;
		rt->bitstreams[i] = (uint32_t *)malloc(size * sizeof(uint32_t));
		if (!rt->bitstreams[i])
			panic("[reconos-core] failed to allocate memory for bitstream\n");

		fread(cfg->bitstream, sizeof(uint32_t), size, file);

		fclose(file);
	}
}

void reconos_thread_create(struct reconos_thread *rt, int slot) {
	if (slot < 0 || slot >= RECONOS_NUM_HWTS)
		panic("[reconos-core] slot id out of range")

	if (rt->state == RECONOS_THREAD_STATE_RUNNING_HW)
		panic("[reconos-core] thread is already running")

	rt->hwslot = _hwslots[slot];
	hwslot_createthread(_hwslots[slot], rt);
	rt->state = RECONOS_THREAD_STATE_RUNNING_HW;
}

void reconos_thread_suspend(struct reconos_thread *rt) {
	if (rt->state != RECONOS_THREAD_STATE_RUNNING_HW)
		panic("[reconos-core] cannot suspend not running thread");

	rt->state = RECONOS_THREAD_STATE_SUSPENDING;
	hwslot_suspendthread(rt->hwslot);
	rt->state = RECONOS_THREAD_STATE_SUSPENDED;
}

void reconos_thread_resume(struct reconos_thread *rt, int slot) {
	if (slot < 0 || slot >= RECONOS_NUM_HWTS)
		panic("[reconos-core] slot id out of range")

	hwslot_resumethread(_hwslots[slot], rt);
	rt->state = RECONOS_THREAD_STATE_RUNNING_HW;
}

void reconos_thread_kill(struct reconos_thread *rt) {
	if (rt->state != RECONOS_THREAD_STATE_RUNNING_HW)
		panic("[reconos-core] cannot kill not running thread");

	hwslot_killthread(rt->hwslot);
	rt->state = RECONOS_THREAD_STATE_INIT;
}


/* == General functions ================================================ */

void exit_signal(int sig) {
	reconos_cleanup();

	printf("[reconos-core] aborted\n");

	exit(0);
}

void delegate_signal(int sig) {
	debug("[reconos-core] delegate received signal");
}

void reconos_init() {
	int i, osif;
	struct sigaction sa;

	signal(SIGINT, exit_signal);
	signal(SIGTERM, exit_signal);
	signal(SIGABRT, exit_signal);

	reconos_drv_init();

	proc_control = reconos_proc_control_open();
	if (proc_control < 0)
		panic("[reconos-core] unable to open proc control\n");

	RECONOS_NUM_HWTS = reconos_proc_control_get_num_hwts(proc_control);

	_hwslots = (struct hwslot *)malloc(NUM_HWTS * sizeof(struct hwslot));
	if (!_hwslots)
		panic("[reconos-core] unable to allocate memory for slots\n")

	for (i = 0; i < NUM_HWTS; i++) {
		osif = reconos_osif_open(i);
		if (osif < 0)
			panic("[reconos-core] unable to open osif %d\n", i);

		hwslot_init(&_hwslots[i], i, osif);
	}

	sa.sa_handler = delegate_signal;
	sigaction(SIGUSR1, &sa, NULL);
}

void reconos_cleanup() {
	reconos_proc_control_sys_reset(proc_control);
}


/* == ReconOS hwslot =================================================== */

void hwslot_init(struct reconos_hwslot *slot, int id, int osif) {
	slot->id = id;
	slot->osif = osif;

	slot->rt = NULL;

	slot->dt = NULL;
	slot->dt_state = DELEGATE_STATE_STOPPED;
	slot->dt_signal = 0;
	sem_init(&slot->dt_wait, 0);
}

void hwslot_reset(struct reconos_hwslot *slot) {
	reconos_proc_control_hwt_reset(proc_control, slot->id, 1);
	reconos_proc_control_hwt_suspres(proc_control, slot->id, 0);
	reconos_proc_control_hwt_reset(proc_control, slot->id, 0);
}

void hwslot_setreset(struct reconos_hwslot *slot, int reset) {
	reconos_proc_control_hwt_reset(proc_control, slot->id, reset);
}

void hwslot_createdelegate(struct reconos_hwslot *slot) {
	if (slot->delegate)
		panic("[reconos-core] delegate thread already running")

	slot->dt_state = DELEGATE_STATE_INIT;
	slot->dt_signal = 0;

	pthread_create(&slot->delegate, NULL, hwslot_delegate, slot);
}

void hwslot_stopdelegate(struct reconos_hwslot *slot) {
	slot->dt_irq = DELEGATE_SIGNAL_STOP;

	switch (slot->dt_state) {
		case DELEGATE_STATE_BLOCKED_OSIF:
			reconos_osif_interrupt(slot->osif);
			break;

		case DELEGATE_STATE_BLOCKED_SYSCALL:
			pthread_kill(slot->dt, SIGUSR1);
			break;
	}

	sem_wait(slot->dt_wait);

	slot->dt_state = DELEGATE_STATE_STOPPED

	slot->dt = NULL;
}

void hwslot_createthread(struct reconos_hwslot *slot,
                         struct reconos_thread *rt) {
	if (slot->rt)
		panic("[reconos-core] a thread is already running");

	hwslot_reset(slot);
	hwslot_createdelegate(slot);
}

void hwslot_suspendthread(struct reconos_hwslot *slot) {
	if (!slot->rt)
		panic("[reconos-core] no thread running");

	hwslot_stopdelegate(slot);

	reconos_proc_control_hwt_suspres(proc_control, slot->id, 1);

	reconos_osif_write(slot->osif, (uint32_t)slot->rt->state_data);

	reconos_osif_read(slot->osif);

	hwslot_setreset(slot, 1);
	slot->rt = NULL;
}

void hwslot_resumethread(struct reconos_hwslot *slot,
                         struct reconos_thread *rt) {
	if (slot->rt)
		panic("[reconos-core] a thread is already running");

	hwslot_reset(slot);

	reconos_osif_write(slot->osif, (uint32_t)slot->rt_state_data);

	reconos_osif_read(slot->osif);

	slot->rt = rt;
	hwslot_createdelegate(slot);
}

void hwslot_killthread(struct reconos_hwslot *slot) {
	if (!slot->rt)
		panic("[reconos-core] no thread running");

	hwslot_stopdelegate(slot);

	hwslot_setreset(slot, 1);
}


/* == ReconOS delegate ================================================= */

static uint32_t dt_get_init_data(struct hwslot *slot) {
	return (uint32_t)slot->rt->init_data;
}

static uint32_t dt_sem_post(struct hwslot *slot) {
	int handle;

	handle = reconos_osif_read(slot->osif);
	resource_check_type(slot->rt, handle, RECONOS_RESOURCE_TYPE_SEM);

	debug("[reconos-dt-%d] (sem_post on %d) ...\n", slot->id, handle);
	sem_post(slot->rt->resources[handle].ptr);
	debug("[reconos-dt-%d] (sem_post on %d) done\n", slot->id, handle);

	return (uint32_t)0;
}

static uint32_t dt_sem_wait(struct hwslot *slot) {
	int handle;
	int ret;

	handle = reconos_osif_read(slot->osif);
	resource_check_type(slot->rt, handle, RECONOS_RESOURCE_TYPE_SEM);

	debug("[reconos-dt-%d] (sem_wait on %d) ...\n", slot->id, handle);
	ret = sem_wait(slot->rt->resources[handle].ptr);
	debug("[reconos-dt-%d] (sem_wait on %d) done\n", slot->id, handle);

	return (uint32_t)ret;
}

static uint32_t dt_mutex_lock(struct hwslot *slot) {
	int handle;
	int ret;

	handle = reconos_osif_read(slot->osif);
	resource_check_type(slot->rt, handle, RECONOS_RESOURCE_TYPE_MUTEX);

	debug("[reconos-dt-%d] (mutex_lock on %d) ...\n", slot->id, handle);
	ret = pthread_mutex_lock(slot->rt->resources[handle].ptr);
	debug("[reconos-dt-%d] (mutex_lock on %d) done\n", slot->id, handle);

	return (uint32_t)ret;
}

static uint32_t dt_mutex_unlock(struct hwslot *slot) {
	int handle;
	int ret;

	handle = reconos_osif_read(slot->osif);
	resource_check_type(slot->rt, handle, RECONOS_RESOURCE_TYPE_MUTEX);

	debug("[reconos-dt-%d] (mutex_unlock on %d) ...\n", slot->id, handle);
	ret = pthread_mutex_unlock(slot->rt->resources[handle].ptr);
	debug("[reconos-dt-%d] (mutex_unlock on %d) done\n", slot->id, handle);

	return (uint32_t)0;
}

static uint32_t dt_mutex_trylock(struct hwslot *slot) {
	int handle;
	int ret;

	handle = reconos_osif_read(slot->osif);
	resource_check_type(slot->rt, handle, RECONOS_RESOURCE_TYPE_MUTEX);

	debug("[reconos-dt-%d] (mutex_trylock on %d) ...\n", slot->id, handle);
	ret = pthread_mutex_trylock(slot->rt->resources[handle].ptr);
	debug("[reconos-dt-%d] (mutex_trylock on %d) done\n", slot->id, handle);

	return (uint32_t)ret;
}

static uint32_t dt_cond_wait(struct hwslot *slot) {
#ifndef RECONOS_MINIMAL
	int handle, handle2;
	int ret;

	handle = reconos_osif_read(slot->osif);
	handle2 = reconos_osif_read(slot->osif);
	resource_check_type(slot->rt, handle, RECONOS_RESOURCE_TYPE_COND);
	resource_check_type(slot->rt, handle2, RECONOS_RESOURCE_TYPE_MUTEX);

	debug("[reconos-dt-%d] (cond_wait on %d) ...\n", slot->id, handle);
	ret = pthread_cond_wait(slot->rt->resources[handle].ptr,
	                        slot->rt->resources[handle2].ptr);
	debug("[reconos-dt-%d] (cond_wait on %d) done\n", slot->id, handle);

	return (uint32_t)ret;
#else
	panic("[reconos-dt-%d] (cond_wait on %d) not supported\n", slot->id, handle);

	return (uint32_t)0;
#endif
}

static uint32_t dt_cond_signal(struct hwslot *slot) {
#ifndef RECONOS_MINIMAL
	int handle;

	handle = reconos_osif_read(slot->osif);
	resource_check_type(slot->rt, handle, RECONOS_RESOURCE_TYPE_COND);

	debug("[reconos-dt-%d] (cond_signal on %d) ...\n", slot->id, handle);
	ret = pthread_cond_wait(slot->rt->resources[handle].ptr);
	debug("[reconos-dt-%d] (cond_signal on %d) done\n", slot->id, handle);

	return (uint32_t)0;
#else
	panic("[reconos-dt-%d] (cond_signal on %d) not supported\n", slot->id, handle);

	return (uint32_t)0;
#endif
}

static uint32_t dt_cond_broadcast(struct hwslot *slot) {
#ifndef RECONOS_MINIMAL
	int handle;

	handle = reconos_osif_read(slot->osif);
	resource_check_type(slot->rt, handle, RECONOS_RESOURCE_TYPE_COND);

	debug("[reconos-dt-%d] (cond_broadcast on %d) ...\n", slot->id, handle);
	ret = pthread_cond_broadcast(slot->rt->resources[handle].ptr);
	debug("[reconos-dt-%d] (cond_broadcast on %d) done\n", slot->id, handle);

	return (uint32_t)0;
#else
	panic("[reconos-dt-%d] (cond_broadcast on %d) not supported\n", slot->id, handle);

	return (uint32_t)0;
#endif
}

static uint32_t dt_mbox_get(struct hwslot *slot) {
	int handle;
	uint32_t ret;

	handle = reconos_osif_read(slot->osif);
	resource_check_type(slot->rt, handle, RECONOS_RESOURCE_TYPE_MBOX);

	debug("[reconos-dt-%d] (mbox_get on %d) ...\n", slot->id, handle);
	ret = mbox_get(slot->rt->resources[handle].ptr);
	debug("[reconos-dt-%d] (mbox_get on %d) done\n", slot->id, handle);

	return (uint32_t)ret;
}

static uint32_t dt_mbox_put(struct hwslot *slot) {
	int handle;
	uint32_t arg0;

	handle = reconos_osif_read(slot->osif);
	resource_check_type(slot->rt, handle, RECONOS_RESOURCE_TYPE_MBOX);

	arg0 = reconos_osif_read(slot->osif);

	debug("[reconos-dt-%d] (mbox_put on %d) ...\n", slot->id, handle);
	mbox_put(slot->rt->resources[handle].ptr, arg0);
	debug("[reconos-dt-%d] (mbox_put on %d) done\n", slot->id, handle);

	return (uint32_t)0;
}

static uint32_t dt_mbox_tryget(struct hwslot *slot) {
	int handle;
	uint32_t data;
	int ret;

	handle = reconos_osif_read(slot->osif);
	resource_check_type(slot->rt, handle, RECONOS_RESOURCE_TYPE_MBOX);

	debug("[reconos-dt-%d] (mbox_tryget on %d) ...\n", slot->id, handle);
	ret = mbox_tryget(slot->rt->resources[handle].ptr, &data);
	reconos_osif_write(slot->osif, data);
	debug("[reconos-dt-%d] (mbox_tryget on %d) done\n", slot->id, handle);

	return (uint32_t)ret;
}

static uint32_t dt_mbox_tryput(struct hwslot *slot) {
	int handle;
	uint32_t arg0;

	handle = reconos_osif_read(slot->osif);
	resource_check_type(slot->rt, handle, RECONOS_RESOURCE_TYPE_MBOX);

	arg0 = reconos_osif_read(slot->osif);

	debug("[reconos-dt-%d] (mbox_tryput on %d) ...\n", slot->id, handle);
	ret = mbox_tryput(slot->rt->resources[handle].ptr, arg0);
	reconos_osif_write(slot->osif, data);
	debug("[reconos-dt-%d] (mbox_tryput on %d) done\n", slot->id, handle);

	return (uint32_t)ret;
}

static void *dt_delegate(void *arg) {
	struct hwslot *slot;
	uint32_t cmd, ret;

	// do initialization here ...

	while(1) {
		debug("[reconos-dt-%d] waiting for command ...\n", slot->id);
		cmd = reconos_osif_read(slot->osif);
		debug("[reconos-dt-%d] received command 0x%x\n", slot->id, cmd);

		switch (cmd * OSIF_CMD_MASK) {
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

			case OSIF_CMD_THREAD_GET_INIT_DATA:
				ret = hwt_delegate_get_init_data(hwt);
				break;

			case OSIF_CMD_THREAD_EXIT:
				reconos_slot_reset(hwt->slot, 1);
				goto out;
				break;
		}

		debug("[reconos-dt-%d] writing back result 0x%x\n", slot->id, ret);
		reconos_osif_write(slot->osif, ret);
	}

out:
	// do cleanup here ...
	return NULL;
}