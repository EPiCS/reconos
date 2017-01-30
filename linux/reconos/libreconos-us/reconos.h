/*
 * Copyright 2012 Andreas Agne <agne@upb.de>
 * Copyright 2012 Markus Happe <markus.happe@upb.de>
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef RECONOS_H
#define RECONOS_H

#include <pthread.h>
#include <stdint.h>
#include "xutils.h"

#define RECONOS_VERSION_STRING			"v3.0"

#define RECONOS_TYPE_INVALID		0x00000000
#define RECONOS_TYPE_MBOX			0x00000001
#define RECONOS_TYPE_SEM			0x00000002
#define RECONOS_TYPE_MUTEX			0x00000004
#define RECONOS_TYPE_COND			0x00000008
#define RECONOS_TYPE_RQ				0x00000010

#define RECONOS_CMD_THREAD_GET_INIT_DATA	0x000000A0
#define RECONOS_CMD_THREAD_DELAY		0x000000A1 // ToDo
#define RECONOS_CMD_THREAD_EXIT			0x000000A2
#define RECONOS_CMD_THREAD_YIELD		0x000000A3 // ToDo
#define RECONOS_CMD_THREAD_RESUME		0x000000A4 // ToDo
#define RECONOS_CMD_THREAD_LOAD_STATE	0x000000A5 // ToDo
#define RECONOS_CMD_THREAD_STORE_STATE	0x000000A6 // ToDo
#define RECONOS_CMD_THREAD_LOAD_PROGRAM	0x000000A7

#define RECONOS_CMD_SEM_POST			0x000000B0
#define RECONOS_CMD_SEM_WAIT			0x000000B1

#define RECONOS_CMD_MUTEX_LOCK			0x000000C0
#define RECONOS_CMD_MUTEX_UNLOCK		0x000000C1
#define RECONOS_CMD_MUTEX_TRYLOCK		0x000000C2 // Not tested, yet

#define RECONOS_CMD_COND_WAIT			0x000000D0 // Not tested, yet
#define RECONOS_CMD_COND_SIGNAL			0x000000D1 // Not tested, yet
#define RECONOS_CMD_COND_BROADCAST		0x000000D2 // Not tested, yet

#define RECONOS_CMD_RQ_RECEIVE			0x000000E0 // ToDo
#define RECONOS_CMD_RQ_SEND			0x000000E1 // ToDo

#define RECONOS_CMD_MBOX_GET			0x000000F0
#define RECONOS_CMD_MBOX_PUT			0x000000F1
#define RECONOS_CMD_MBOX_TRYGET			0x000000F2 // ToDo
#define RECONOS_CMD_MBOX_TRYPUT			0x000000F3 // ToDo

/* XXX: only for compatibility reasons of demo apps */
typedef uint32_t __deprecated uint32;

struct reconos_resource {
	void *ptr;
	uint32_t type;
};

struct reconos_hwt {
	pthread_t delegate;
	int slot;
	struct reconos_resource* resources;
	size_t num_resources;
	void *init_data;
	char * program_path;
};

#define SLOTS_MAX				16
#define SLOT_FLAG_RESET				0x00000001

struct reconos_process {
	uint32_t page_faults;
	int proc_control_fsl_a; // proc_control initiates requests
	int proc_control_fsl_b; // sw initiates requests
	pthread_t proc_control_thread;
	int slot_flags[SLOTS_MAX];
	int fd_cache;
	pthread_mutex_t mutex;
};

extern void reconos_cache_flush(void);
extern void reconos_proc_control_selftest(void);

static inline __deprecated void cache_flush(void)
{
	reconos_cache_flush();
}

static inline __deprecated void proc_control_selftest(void)
{
	reconos_proc_control_selftest();
}

extern int reconos_init(int proc_ctrl_fsl_a, int proc_control_fsl_b);
extern int reconos_init_autodetect(void);
extern void reconos_mmu_stats(uint32_t *tlb_hits, uint32_t *tlb_misses,
			      uint32_t *page_faults);
extern void reconos_faultinject(uint8_t channel, uint32_t sa0, uint32_t sa1);

#define ARB_ERROR_DETECTION_MASK 0x0001
#define ARB_SHADOW_BUFFER_MASK  0x000E

#define ARB_ERROR_DETECTION_OFF 0x0000
#define ARB_ERROR_DETECTION_ON  0x0001
#define ARB_SHADOW_BUFFER_1K    0x0000
#define ARB_SHADOW_BUFFER_2K    0x0002
#define ARB_SHADOW_BUFFER_4K    0x0004
#define ARB_SHADOW_BUFFER_8K    0x0006
#define ARB_SHADOW_BUFFER_16K   0x0008
#define ARB_SHADOW_BUFFER_32K   0x000A
#define ARB_SHADOW_BUFFER_64K   0x000C
#define ARB_SHADOW_BUFFER_128K  0x000E

extern void reconos_set_arb_runtime_opts(uint16_t arb_options);
extern void reconos_hwt_setresources(struct reconos_hwt *hwt,
				     struct reconos_resource *res,
				     size_t num_resources);
extern void reconos_hwt_setprogram(struct reconos_hwt *hwt, const char * program_path);
extern void reconos_hwt_setinitdata(struct reconos_hwt *hwt, void *init_data);
extern int reconos_hwt_create(struct reconos_hwt *hwt, int slot, void *arg);

#endif /* RECONOS_H */
