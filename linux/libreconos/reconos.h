#ifndef RECONOS_H
#define RECONOS_H

#include "config.h"

#include <pthread.h>

#define RECONOS_TYPE_MBOX    0x00000001

#define RECONOS_CMD_MBOX_GET 0x000000F0
#define RECONOS_CMD_MBOX_PUT 0x000000F1

struct reconos_resource {
	void * ptr;       // pointer to resource (can be an object or a handle)
	uint32 type;      // integer identifying the resource type
};

struct reconos_hwt {
	pthread_t                delegate;
	int                      slot;
	struct reconos_resource* resources;
	int                      num_resources;
	void *                   init_data;
};

#define SLOT_FLAG_RESET 0x00000001

struct reconos_process
{
	int proc_control_fsl;
	pthread_t proc_control_thread;
	int slot_flags[MAX_SLOTS];
};

extern struct reconos_process reconos_proc;

int reconos_init(int proc_ctrl_fsl);

void reconos_hwt_setresources(struct reconos_hwt * hwt, struct reconos_resource * res, int num_resources);

int reconos_hwt_create(struct reconos_hwt * hwt, int slot, void * arg);

#endif

