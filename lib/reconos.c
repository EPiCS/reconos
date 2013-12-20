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
#include "hwt_delegate.h"
#include "utils.h"
#include "arch/arch.h"

#include <unistd.h>
#include <signal.h>

struct reconos_runtime reconos_runtime;


/* == Configuration functions =========================================== */

void reconos_configuration_init(struct reconos_configuration *cfg, char *name, int slot) {
	cfg->resource = NULL;
	cfg->resource_count = 0;

	cfg->bitstream = NULL;
	cfg->bitstream_length = 0;

	cfg->slot = slot;

	cfg->name = name;
}

void reconos_configuration_setresources(struct reconos_configuration *cfg,
                                        struct reconos_resource *resource,
                                        size_t resource_count) {
	cfg->resource = resource;
	cfg->resource_count = resource_count;
}

void reconos_configuration_setbitstream(struct reconos_configuration *cfg,
                                        uint32_t *bitstream,
                                        unsigned int bitstream_length) {
	cfg->bitstream = bitstream;
	cfg->bitstream_length = bitstream_length;
}

void reconos_configuration_loadbitstream(struct reconos_configuration *cfg,
                                         char *filename) {
	FILE *file;
	unsigned int size;

	//printf("... Loading bitstream from %s into configuration %s\n", filename, cfg->name);

	file = fopen(filename, "rb");
	if (!file)
		panic("[reconos_core] failed to open bitstream\n");

	// figure out length of file
	fseek(file, 0L, SEEK_END);
	size = ftell(file);
	rewind(file);

	cfg->bitstream_length = size / 4;
	cfg->bitstream = (uint32_t *)malloc(size);
	if (!cfg->bitstream)
		panic("[reconos_core] failed to allocate memory for bitstream\n");

	fread(cfg->bitstream, sizeof(uint32_t), size / 4, file);

	//printf("... Loading bitstream was successful\n");

	fclose(file);
}

/* == HWT functions ===================================================== */

void reconos_hwt_setresources(struct reconos_hwt *hwt,
                              struct reconos_resource *resource,
                              size_t resource_count) {
	struct reconos_configuration *cfg;

	// creating configuration
	cfg = (struct reconos_configuration *)malloc(sizeof(struct reconos_configuration));
	if (!cfg)
		panic("[reconos_core] failed to allocate memory for configuration\n");

	reconos_configuration_init(cfg, "DEFAULT CONFIG", hwt->slot);
	reconos_configuration_setresources(cfg, resource, resource_count);

	// assigning configuration to HWT
	hwt->cfg = cfg;
}

void reconos_hwt_setinitdata(struct reconos_hwt *hwt,
                             void* init_data) {
	// setting init data in HWT
	hwt->init_data = init_data;
}

void hwt_create_delegate(struct reconos_hwt *hwt,
                                 void * arg) {
	// open osif
	hwt->osif = reconos_osif_open(hwt->slot);
	if (hwt->osif < 0)
		panic("[reconos-core] failed to open osif\n");

	// create delegate thread
	pthread_create(&hwt->delegate, NULL,
	               reconos_hwt_delegate, hwt);
}

void reconos_hwt_create(struct reconos_hwt *hwt,
                        int slot, void *arg) {
	hwt->is_reconf = 0;

	hwt->slot = slot;

	hwt->state = RECONOS_HWT_STATE_IDLE;

	hwt_create_delegate(hwt, arg);
}

void reconos_hwt_create_reconf(struct reconos_hwt *hwt,
                               int slot,
                               struct reconos_configuration *cfg,
                               void *arg) {
	//printf("... Creating reconfigurable HWT on slot %d with configuration %s\n", slot, cfg->name);

	hwt->is_reconf = 1;

	hwt->slot = slot;

	hwt->cfg = cfg;

	reconos_slot_reset(hwt->slot, 1);
	load_partial_bitstream(hwt->cfg->bitstream, hwt->cfg->bitstream_length);
	reconos_slot_reset(hwt->slot, 0);

	//printf("Hardware thread programmed into the slot and now creating delegate thread\n");

	hwt->state = RECONOS_HWT_STATE_IDLE;

	hwt_create_delegate(hwt, arg);
}


/* == General ReconOS functions ========================================= */

void *proc_control_page_fault_handler(void *arg) {
	struct proc_control *proc_control = arg;

	while (1) {
		uint32_t *addr;

		// this call blocks until a page fault occurs
		addr = (uint32_t *)reconos_proc_control_get_fault_addr(proc_control->fd);

		printf("[reconos_core] page fault occured at address %x\n", (unsigned int)addr);

		proc_control->page_faults++;

		// touch page
		*addr = 0;

		reconos_proc_control_clear_page_fault(proc_control->fd);
	}
}

void reconos_cleanup() {
	// TODO to do a cleanup we need to know our HWTs
	//      we can either maintain a list ourself here
	//      or the user must pass an array of all HWTs

	// set reset signal for all HWTs
	reconos_proc_control_sys_reset(reconos_runtime.proc_control.fd);
}

void exithandler(int sig) {
	reconos_cleanup();

	printf("[reconos-core] aborted\n");

	exit(0);
}

int reconos_init() {
	// register signal handler to cleanup on Ctrl-C
	signal(SIGINT, exithandler);
	signal(SIGTERM, exithandler);
	signal(SIGABRT, exithandler);

	// initialize driver
	reconos_drv_init();

	// initialize data structure
	reconos_runtime.scheduler = NULL;

	reconos_runtime.proc_control.fd = reconos_proc_control_open();
	if (reconos_runtime.proc_control.fd < 0) {
		whine("[reconos-core] unable to open proc control\n");
		goto proc_control_failed;
	}

	reconos_runtime.proc_control.page_faults = 0;

	// set reset signal for all HWTs
	reconos_proc_control_sys_reset(reconos_runtime.proc_control.fd);

	// set pgd
	reconos_proc_control_set_pgd(reconos_runtime.proc_control.fd);

#ifdef RECONOS_MMU_true
	// create delegate thread
	pthread_create(&reconos_runtime.proc_control.page_fault_handler, NULL,
	               proc_control_page_fault_handler, &reconos_runtime.proc_control);
#endif

	goto out;

proc_control_failed:
	panic("[reconos-core] reconos_init failed\n");
	return -1;

out:
	return 0;
}

void reconos_slot_reset(int slot, int reset) {
	// just delegate reset to driver
	reconos_proc_control_hwt_reset(reconos_runtime.proc_control.fd, slot, reset);
}

void reconos_mmu_stats(int *tlb_hits, int *tlb_misses,
                       int *page_faults) {
	uint32_t hits, misses;

	// read tlb_* register
	hits = reconos_proc_control_get_tlb_hits(reconos_runtime.proc_control.fd);
	misses = reconos_proc_control_get_tlb_misses(reconos_runtime.proc_control.fd);

	// pass back mmu statistic
	// (allows to set parameters to NULL if not interested in)
	if (tlb_hits)
		*tlb_hits = hits;
	if (tlb_misses)
		*tlb_misses = misses;
	if (page_faults)
		*page_faults = reconos_runtime.proc_control.page_faults;
}

void reconos_set_scheduler(struct reconos_configuration* (*scheduler)(struct reconos_hwt *hwt)) {
	reconos_runtime.scheduler = scheduler;
}

void reconos_cache_flush() {
	reconos_proc_control_cache_flush(reconos_runtime.proc_control.fd);
}
