/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 * Copyright 2012 Andreas Agne <agne@upb.de>
 */

#ifndef RECONOS_H
#define RECONOS_H

#include <linux/sched.h>

#define RECONOS_VERSION_STRING			"v3.0"

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
#define RECONOS_CMD_THREAD_LOAD_STATE		0x000000A5 // ToDo
#define RECONOS_CMD_THREAD_STORE_STATE		0x000000A6 // ToDo

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

#define ____can_sleep

struct reconos_resource {
	void *ptr;
	uint32_t type;
};

struct reconos_hwt {
	struct task_struct *delegate;
	struct reconos_resource* resources;
	size_t num_resources;
	int slot;
	void *init_data;
} ____cacheline_aligned_in_smp;

#define SLOTS_MAX				16
#define SLOT_FLAG_RESET				0x00000001

struct reconos_process {
	struct task_struct *proc_control_thread;
	int proc_control_fsl_a; // proc_control initiates requests
	int proc_control_fsl_b; // sw initiates requests
	int slot_flags[SLOTS_MAX];
	uint32_t page_faults;
} ____cacheline_aligned_in_smp;

extern void reconos_cache_flush(void);
extern void reconos_proc_control_selftest(void);
extern int reconos_init(int proc_ctrl_fsl_a, int proc_control_fsl_b);
extern int reconos_init_autodetect(void);
extern void reconos_cleanup(void);
extern void reconos_mmu_stats(uint32_t *tlb_hits, uint32_t *tlb_misses,
			      uint32_t *page_faults);
extern void reconos_hwt_setresources(struct reconos_hwt *hwt,
				     struct reconos_resource *res,
				     size_t num_resources);
extern void reconos_hwt_setinitdata(struct reconos_hwt *hwt, void *init_data);
extern int reconos_hwt_create(struct reconos_hwt *hwt, int slot, void *arg);

#endif /* RECONOS_H */
