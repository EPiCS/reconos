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

/*
 * Structure representing a configuration
 *
 *   resource         - pointer to the resource array
 *   resource_count   - number of resources in the resource array
 *   bitstream        - pointer to the bitstream data
 *   bitstream_length - length of the bitstream in 32bit-words
 *   slot             - slot number the configuration shoul run in
 *   name             - human readable name to identify the hardwarethread
 */
struct reconos_configuration {
	struct reconos_resource *resource;
	size_t resource_count;

	uint32_t *bitstream;
	unsigned int bitstream_length;

	int slot;

	char *name;
};


/*
 * Initializes a new configuration with default values. This function must
 * be called for every configuration you want to use.
 *
 *   cfg  - pointer to the configuration structure
 *   name - name to identify the configuration
 *   slot - the slot number you want to run the configuration in
 *          (the same number as used in reconos_hwt_create)
 */
void reconos_configuration_init(struct reconos_configuration *cfg, char *name, int slot);

/*
 * Associates a resource array to this configuration. This is the equivalent
 * to reconos_set_resources for not reconfigurable hardware threads.
 *
 *   cfg            - pointer to the configuration structure
 *   resource       - pointer to the resource array to use
 *   recource_count - number of resources in the resource array
 */
void reconos_configuration_setresources(struct reconos_configuration *cfg,
                                        struct reconos_resource *resorce,
                                        size_t resource_count);

/*
 * Associates a bitstream to this configuration to program the FPGA
 * on reconfiguration.
 *
 *   cfg              - pointer to the configuration structure
 *   bitstream        - pointer to the bitstream data
 *   bitstream_length - length of the bitstream in 32bit-words
 */
void reconos_configuration_setbitstream(struct reconos_configuration *cfg,
                                        uint32_t *bitstream,
                                        unsigned int bitstream_length);
/*
 * Loads a bitstram from the filesystem and associates it to the configuration
 * by calling reconos_configuration_setbitstream.
 *
 *   cfg      - pointer to the configuration structure
 *   filename - filname of the bitstream-file
 */
void reconos_configuration_loadbitstream(struct reconos_configuration *cfg,
                                         char *filename);


/* == HWT functions ===================================================== */

/*
 * Structure representing a hardware thread
 *
 *   delegate  - delegate thread associated to the hardware thread
 *   osif      - file handle of the OSIF (/dev/osif-<slot>)
 *   slot      - slot number the hardware thread is running in
 *   is_reconf - boolean attribute indicating whether the hardware thread
 *               is reconfigurable or not
 *   state     - current state of the hardware thread
 *               (IDLE, RUNNING, RECONFIGURING, BLOCKING)
 *   cfg       - pointer to the current configuration
 *   init_data - pointer to the initialization data
 */
struct reconos_hwt {
	pthread_t delegate;
	int osif;
	int slot;

	int is_reconf;
	int state;

	struct reconos_configuration *cfg;
	void *init_data;
};

/*
 * State definition for the hardware thread
 */
#define RECONOS_HWT_STATE_IDLE 0
#define RECONOS_HWT_STATE_RUNNING 1
#define RECONOS_HWT_STATE_RECONFIGURING 2
#define RECONOS_HWT_STATE_BLOCKING 3

/*
 * Associates a resource array to this hardware thread.
 *
 *   hwt            - pointer to the hardware thread
 *   resource       - pointer to the resource array to use
 *   recource_count - number of resources in the resource array
 */
void reconos_hwt_setresources(struct reconos_hwt *hwt,
                              struct reconos_resource *resorce,
                              size_t resource_count);

/*
 * Associated initialization data to this hardware thread.
 *
 *   hwt       - pointer to the hardware thread
 *   init_data - pointer to the iniltialization data
 */
void reconos_hwt_setinitdata(struct reconos_hwt *hwt,
                             void* init_data);

/*
 * Creates a new hardware thread running in the a specific slot. Before
 * executed the slot will be resetted.
 *
 *   hwt  - pointer to the hardware thread
 *   slot - slot number to run the hardware thread in
 *   arg  - arguments for the delegate thread (passed to pthread_create)
 */
void reconos_hwt_create(struct reconos_hwt *hwt,
                        int slot, void *arg);

/*
 * Creates a new reconfigurable hardwar thread runnin in the specific slot.
 * Before ecxecuted the slot is reconfigured with the appropriate bitstream
 * and resetted.
 *
 *   hwt  - pointer to the hardware thread
 *   slot - slot number to run the hardware thread in
 *          (this number must be the same as used in the configuration)
 *   cfg  - pointer to the configuration
 *   arg  - arguments for the delegate thread (passed to pthread_create)
 */
void reconos_hwt_create_reconf(struct reconos_hwt *hwt,
                               int slot,
                               struct reconos_configuration *cfg,
                               void *arg);


/* == General ReconOS functions ========================================= */

/*
 * Cleans up the ReconOS environment and resets the hardware. You should
 * call this method before termination to prevent the hardware threads from
 * operating and avoid undesirable effects.
 * By default this method is registered as a signal handler for SIGINT,
 * SIGTERM and SIGABRT. Keep this in mind when overriding these handlers.
 */
void reconos_cleanup();

/*
 * Initializes the ReconOS environtmen and resets the hardware. You must
 * call this method before you can use any ReconOS function.
 */
int reconos_init();

/*
 * Allows to read out simple statistics of the MMU.
 *    tlb_hits    - pointer to store the number of tlb hits in
 *    tlb_misses  - pointer to store the number of tlb misses in
 *    page_faults - pointer to store the number of page faults in
 */
void reconos_mmu_stats(int *tlb_hits, int *tlb_misses,
                       int *page_faults);

/*
 * Resets a single hardware thread slot.
 */
void reconos_slot_reset(int slot, int reset);

/*
 * Specifies the scheduler for reconfigurable hardware threads. The
 * scheduler will be called when a hardware thread yields. Keep in mind
 * that the scheduler can be called concurrently multiple times and must
 * be synchronized.
 */
void reconos_set_scheduler(struct reconos_configuration* (*scheduler)(struct reconos_hwt *hwt));

/*
 * Flushes the cache of the processor. Consider that this method might not
 * be implemented on all architectures.
 */
void reconos_cache_flush();

#endif /* RECONOS_H */
