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

#ifndef RECONOS_H
#define RECONOS_H

#include <pthread.h>
#include <stdint.h>

#define RECONOS_VERSION_STRING          "v3.0"


/* == Resource options ================================================== */

struct reconos_resource {
	uint32_t type;
	void *ptr;
};

#define RECONOS_RESOURCE_TYPE_MBOX     0x00000001
#define RECONOS_RESOURCE_TYPE_SEM      0x00000002
#define RECONOS_RESOURCE_TYPE_MUTEX    0x00000004
#define RECONOS_RESOURCE_TYPE_COND     0x00000008
#define RECONOS_RESOURCE_TYPE_RQ       0x00000010

// just for backward compatability
#define RECONOS_TYPE_MBOX              RECONOS_RESOURCE_TYPE_MBOX
#define RECONOS_TYPE_SEM               RECONOS_RESOURCE_TYPE_SEM
#define RECONOS_TYPE_MUTEX             RECONOS_RESOURCE_TYPE_MUTEX
#define RECONOS_TYPE_COND              RECONOS_RESOURCE_TYPE_COND
#define RECONOS_TYPE_RQ                RECONOS_RESOURCE_TYPE_RQ


/* == Configuration functions =========================================== */

struct reconos_configuration {
	struct reconos_resource *resource;
	size_t resource_count;

	uint32_t *bitstream;
	unsigned int bitstream_length;

	int slot;

	char *name;
};


void reconos_configuration_init(struct reconos_configuration *cfg, char *name, int slot);

void reconos_configuration_setresources(struct reconos_configuration *cfg,
                                        struct reconos_resource *resorce,
                                        size_t resource_count);

void reconos_configuration_setbitstream(struct reconos_configuration *cfg,
                                        uint32_t *bitstream,
                                        unsigned int bitstream_length);

void reconos_configuration_loadbitstream(struct reconos_configuration *cfg,
                                         char *filename);


/* == HWT functions ===================================================== */

struct reconos_hwt {
	pthread_t delegate;
	int osif;
	int slot;

	int is_reconf;
	int state;

	struct reconos_configuration *cfg;
	void *init_data;
};

#define RECONOS_HWT_STATE_IDLE 0
#define RECONOS_HWT_STATE_RUNNING 1
#define RECONOS_HWT_STATE_RECONFIGURING 2
#define RECONOS_HWT_STATE_BLOCKING 3

void reconos_hwt_setresources(struct reconos_hwt *hwt,
                              struct reconos_resource *resorce,
                              size_t resource_count);

void reconos_hwt_setinitdata(struct reconos_hwt *hwt,
                             void* init_data);

void reconos_hwt_create(struct reconos_hwt *hwt,
                        int slot, void *arg);

void reconos_hwt_create_reconf(struct reconos_hwt *hwt,
                               int slot,
                               struct reconos_configuration *cfg,
                               void *arg);


/* == General ReconOS functions ========================================= */

void reconos_cleanup();

int reconos_init();

void reconos_mmu_stats(int *tlb_hits, int *tlb_misses,
                       int *page_faults);

void reconos_slot_reset(int slot, int reset);

void reconos_set_scheduler(struct reconos_configuration* (*scheduler)(struct reconos_hwt *hwt));

void reconos_cache_flush();

#endif /* RECONOS_H */
