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

#ifndef RECONOS_APP_H
#define RECONOS_APP_H

#include "mbox.h"

#include <pthread.h>
#include <semaphore.h>

/* == Application resources ============================================ */

/*
 * Definition of resource ids.
 */
<<generate for RESOURCES>>
#define <<FqnUpper>> 0x<<HexId>>
<<end generate>>

/*
 * Definition of different resources of the application.
 *
 *   mbox  - mailbox (struct mbox)
 *   sem   - semaphore (sem_t)
 *   mutex - mutex (pthread_mutex)
 *   cond  - condition variable (pthread_cond)
 */
<<generate for RESOURCES(Type == "mbox")>>
extern struct mbox <<FqnLower>>;
<<end generate>>

<<generate for RESOURCES(Type == "sem")>>
extern sem_t <<FqnLower>>;
<<end generate>>

<<generate for RESOURCES(Type == "mutex")>>
extern pthread_mutex_t <<FqnLower>>;
<<end generate>>

<<generate for RESOURCES(Type == "cond")>>
extern pthread_cond <<FqnLower>>;
<<end generate>>


/* == Application functions ============================================ */

/*
 * Initializes the application by creating all resources.
 */
void reconos_app_init();

/*
 * Cleans up the application by destroying all resources.
 */
void reconos_app_cleanup();

<<generate for THREADS>>
/*
 * Creates a hardware thread in the specified slot with its associated
 * resources.
 *
 *   rt   - pointer to the ReconOS thread
 */
struct reconos_thread *reconos_thread_create_hwt_<<Name>>();

/*
 * Creates a software thread with its associated resources.
 *
 *   rt   - pointer to the ReconOS thread
 */
struct reconos_thread *reconos_thread_create_swt_<<Name>>();


/*
 * Destroyes a hardware thread created.
 *
 *   rt   - pointer to the ReconOS thread
 */
void reconos_thread_destroy_<<Name>>(struct reconos_thread *rt);
<<end generate>>

#endif /* RECONOS_APP_H */