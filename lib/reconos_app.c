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
 *   description:  Auto-generated application specific header file.
 *
 * ======================================================================
 */

<<reconos_preproc>>

#include "reconos_app.h"

#include "reconos.h"
#include "utils.h"

/* == Application resources ============================================ */

/*
 * @see header
 */
<<generate for RESOURCES(Type == "mbox")>>
struct mbox <<FqnLower>>;
<<end generate>>

<<generate for RESOURCES(Type == "sem")>>
sem_t <<FqnLower>>;
<<end generate>>

<<generate for RESOURCES(Type == "mutex")>>
pthread_mutex_t <<FqnLower>>;
<<end generate>>

<<generate for RESOURCES(Type == "cond")>>
pthread_cond <<FqnLower>>;
<<end generate>>

<<generate for RESOURCES>>
struct reconos_resource <<FqnLowerRes>> = {
	.ptr = &<<FqnLower>>,
	.type = RECONOS_RESOURCE_TYPE_<<TypeUpper>>
};
<<end generate>>


/* == Application functions ============================================ */

/*
 * @see header
 */
void reconos_app_init() {
	<<generate for RESOURCES(Type == "mbox")>>
	mbox_init(&<<FqnLower>>, <<Args>>);
	<<end generate>>

	<<generate for RESOURCES(Type == "sem")>>
	sem_init(&<<FqnLower>>, <<Args>>);
	<<end generate>>

	<<generate for RESOURCES(Type == "mutex")>>
	pthread_mutex_init(&<<FqnLower>>, NULL);
	<<end generate>>

	<<generate for RESOURCES(Type == "cond")>>
	pthread_cond_init(&<<FqnLower>>, NULL);
	<<end generate>>
}

/*
 * @see header
 */
void reconos_app_cleanup() {
	<<generate for RESOURCES(Type == "mbox")>>
	mbox_destroy(&<<FqnLower>>);
	<<end generate>>

	<<generate for RESOURCES(Type == "sem")>>
	sem_destroy(&<<FqnLower>>);
	<<end generate>>

	<<generate for RESOURCES(Type == "mutex")>>
	pthread_mutex_destroy(&<<FqnLower>>);
	<<end generate>>

	<<generate for RESOURCES(Type == "cond")>>
	pthread_cond_destroy(&<<FqnLower>>, NULL);
	<<end generate>>
}

/*
 * Empty software thread if no software specified
 *
 *   data - pointer to ReconOS thread
 */
void *swt_idle(void *data) {
	pthread_exit(0);
}

<<generate for THREADS>>

struct reconos_resource *resources_<<Name>>[] = {<<Resources>>};

/*
 * @see header
 */
struct reconos_thread *reconos_thread_create_hwt_<<Name>>() {
	struct reconos_thread *rt = (struct reconos_thread *)malloc(sizeof(struct reconos_thread));
	if (!rt) {
		panic("[reconos-core] ERROR: failed to allocate memory for thread\n");
	}

	int slots[] = {<<Slots>>};
	reconos_thread_init(rt, "<<Name>>", 0);
	reconos_thread_setinitdata(rt, 0);
	reconos_thread_setallowedslots(rt, slots, <<SlotCount>>);
	reconos_thread_setresourcepointers(rt, resources_<<Name>>, <<ResourceCount>>);
	reconos_thread_create_auto(rt, RECONOS_THREAD_HW);

	return rt;
}

extern void *<<SwEntry>>(void *data);

/*
 * @see header
 */
struct reconos_thread *reconos_thread_create_swt_<<Name>>() {
	struct reconos_thread *rt = (struct reconos_thread *)malloc(sizeof(struct reconos_thread));
	if (!rt) {
		panic("[reconos-core] ERROR: failed to allocate memory for thread\n");
	}

	int slots[] = {<<Slots>>};
	reconos_thread_init(rt, "<<Name>>", 0);
	reconos_thread_setinitdata(rt, 0);
	reconos_thread_setallowedslots(rt, slots, <<SlotCount>>);
	reconos_thread_setresourcepointers(rt, resources_<<Name>>, <<ResourceCount>>);
	reconos_thread_setswentry(rt, <<SwEntry>>);
	reconos_thread_create_auto(rt, RECONOS_THREAD_SW);

	return rt;
}


/*
 * @see header
 */
void reconos_thread_destroy_<<Name>>(struct reconos_thread *rt) {
	// not implemented yet
}
<<end generate>>