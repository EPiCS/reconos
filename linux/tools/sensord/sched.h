/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef SCHED_H
#define SCHED_H

#include "plugin.h"

extern void sched_init(void);
extern void sched_cleanup(void);
extern void sched_register_task(struct plugin_instance *p);
extern void sched_unregister_task(struct plugin_instance *p);
extern void sched_remove_all_tasks(void);

#endif /* SCHED_EDF_H */
