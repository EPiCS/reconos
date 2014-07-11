/*
 *                                                        ____  _____
 *                            ________  _________  ____  / __ \/ ___/
 *                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
 *                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
 *                         /_/   \___/\___/\____/_/ /_/\____//____/
 *
 * ======================================================================
 *
 *   title:        Architecture specific code
 *
 *   project:      ReconOS
 *   author:       Christoph Rüthing, University of Paderborn
 *   description:  Functions needed for ReconOS which are architecure
 *                 specific and are implemented here.
 *
 * ======================================================================
 */

#ifndef TIMER_H
#define TIMER_H

/* == Timer functions ================================================== */

/*
 * Initializes the timer. Must be called before any other function can
 * be used.
 *
 *   no parameters
 */
void timer_init();

/*
 * Resets the timer to zero.
 *
 *   no parameters
 */
void timer_reset();

/*
 * Gets the current timestamp.
 *
 *   no parameters
 */
unsigned int timer_get();

/*
 * Cleans up the driver.
 *
 *   no parameters
 */
void timer_cleanup();

#endif /* TIMER_H */