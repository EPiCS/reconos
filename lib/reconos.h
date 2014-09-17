/*
 *                                                        ____  _____
 *                            ________  _________  ____  / __ \/ ___/
 *                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
 *                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
 *                         /_/   \___/\___/\____/_/ /_/\____//____/
 *
 * ======================================================================
 *
 *   title:        ReconOS library - ReconOS Main header
 *
 *   project:      ReconOS
 *   author:       Andreas Agne, University of Paderborn
 *                 Christoph Rüthing, University of Paderborn
 *   description:  Main head file including general functions.
 *
 * ======================================================================
 */

#ifndef RECONOS_H
#define RECONOS_H

#define RECONOS_VERSION_STRING "v3.1"

extern int RECONOS_NUM_HWTS;

/* == ReconOS resource ================================================= */

/*
 * Definition of the different resource types.
 *
 *   mbox  - mailbox (struct mbox)
 *   sem   - semaphore (sem_t)
 *   mutex - mutex (pthread_mutex)
 *   cond  - condition variable (pthread_cond)
 */
#define RECONOS_RESOURCE_TYPE_MBOX     0x00000001
#define RECONOS_RESOURCE_TYPE_SEM      0x00000002
#define RECONOS_RESOURCE_TYPE_MUTEX    0x00000004
#define RECONOS_RESOURCE_TYPE_COND     0x00000008
//#define RECONOS_RESOURCE_TYPE_RQ       0x00000010

/*
 * Object representing a single resource.
 *
 *   type - type of the resource (RECONOS_RESOURCE_TYPE_...)
 *   ptr  - pointer to the representation of the resource
 */
struct reconos_resource {
	int type;
	void *ptr;
};

/*
 * Initializes the resource.
 * Simply assigning type and ptr is also appropriate.
 *
 *   rr   - pointer to the resource
 *   type - type of the resource
 *   ptr  - pointer to the representation of the resource
 */
void reconos_resource_init(struct reconos_resource *rr,
                           int type, void *ptr);


/* == ReconOS thread =================================================== */

/*
 * Definition of the thread states
 *
 *   stoped     - not created yet
 *   running_hw - executing as a hardware thread
 *   running_sw - executing as a software thread
 *   suspended  - suspendend and ready for sheduling
 *   suspending - currently suspending and saving state
 */
#define RECONOS_THREAD_STATE_INIT         0x01
#define RECONOS_THREAD_STATE_STOPED       0x02
#define RECONOS_THREAD_STATE_RUNNING_HW   0x04
#define RECONOS_THREAD_STATE_RUNNING_SW   0x08
#define RECONOS_THREAD_STATE_SUSPENDED    0x10
#define RECONOS_THREAD_STATE_SUSPENDING   0x20


/*
 * Object representing a hardware thread
 *
 *   init_data         - pointer to the initialization data
 *   resources         - array of resources associated
 *   resource_count    - number of resources in resource array
 *
 *   state             - current state (refers to RECONOS_THREAD_STATE_...)
 *   state_data        - memory to store the internal state
 *
 *   hw_slot           - hardware slot the thread is executing in
 *
 *   bitstreams        - array of bitstreams for the different slots
 *   bitstream_lengths - length of the bitstreams
 */
struct reconos_thread {
	char *name;
	int id;

	void *init_data;
	struct reconos_resource *resources;
	int resource_count;

	int state;
	volatile void *state_data;

	struct hwslot *hwslot;

	char **bitstreams;
	int *bitstream_lengths;
};

/*
 * Initializes the ReconOS thread. Must be called before all other
 * methods.
 *
 *   rt         - pointer to the ReconOS thread
 *   name       - name of the thread (can be null)
 *   state_size - size in bytes for the state of the thread
 */
void reconos_thread_init(struct reconos_thread *rt,
                         char* name,
                         int state_size);

/*
 * Associates initialization data to this thread.
 *
 *   rt        - pointer to the ReconOS thread
 *   init_data - pointer to the initialization data
 */
void reconos_thread_setinitdata(struct reconos_thread *rt, void *init_data);

/*
 * Associated the resource array to this thread.
 *
 *   rt             - pointer to the ReconOS thread
 *   resources      - array of resources
 *   resource_count - number of resources in resource array
 */
void reconos_thread_setresources(struct reconos_thread *rt,
                                 struct reconos_resource *resources,
                                 int resource_count);

/*
 * Assigns the bitstream array to the hardware thread. The bitstream
 * array must contain a bitstream for each hardware slot.
 *
 *   rt  - pointer to the ReconOS thread
 *   bitstreams - array of bitstreams (array of chars)
 *   bitstream_lengths - lengths of the different bitstreams
 */
void reconos_thread_setbitstream(struct reconos_thread *rt,
                                 char **bitstreams,
                                 int *bitstream_lengths);

/*
 * Loads bitstreams from the filesystem and assigns them to the
 * thread. A bitstream for each slot must be provided.
 *
 *   rt   - pointer to the ReconOS thread
 *   path - paths of the bitstream containing, %d replaced by slot number
 */
void reconos_thread_loadbitstream(struct reconos_thread *rt,
                                  char *path);

/*
 * Creates the ReconOS thread and executes it in the given slot number.
 *
 *   rt   - pointer to the ReconOS thread
 *   slot - slot number to execute the thread in
 *
 */
void reconos_thread_create(struct reconos_thread *rt, int slot);

/*
 * Suspends the ReconOS thread by saving its state and pausing execution.
 * This method does not block until the thread is suspended, use
 * reconos_thread_join(...) to wait for termination of thread.
 *
 *   rt   - pointer to the ReconOS thread
 */
void reconos_thread_suspend(struct reconos_thread *rt);

/*
 * Suspends the ReconOS thread by saving its state and pausing execution.
 * This method blocks unit the thread is suspended.
 */
void reconos_thread_suspend_block(struct reconos_thread *rt);

/*
 * Resumes the ReconOS thread in the given slot by restoring its state
 * and starting execution.
 *
 *   rt   - pointer to the ReconOS thread
 *   slot - slot number to execute the thread in
 */
void reconos_thread_resume(struct reconos_thread *rt, int slot);

/*
 * Waits for the termination of the hardware thread.
 *
 *   rt - pointer to the ReconOS thread
 */
void reconos_thread_join(struct reconos_thread *rt);

/*
 * Sets a signal to the hardware thread. The signal must be cleared
 * by the hardware using the right system call.
 *
 *   rt - pointer to the ReconOS thread
 */
void reconos_thread_signal(struct reconos_thread *rt);

/* == General functions ================================================ */

/*
 * Initializes the ReconOS environment and resets the hardware. You must
 * call this method before you can use any of the other functions.
 */
void reconos_init();

/*
 * Cleans up the ReconOS environment and resets the hardware. You should
 * call this method before termination to prevent the hardware threads from
 * operating and avoid undesirable effects.
 * By default this method is registered as a signal handler for SIGINT,
 * SIGTERM and SIGABRT. Keep this in mind when overriding these handlers.
 */
void reconos_cleanup();

/*
 * Flushes the cache if needed.
 */
void reconos_cache_flush();

#endif /* RECONOS_H */