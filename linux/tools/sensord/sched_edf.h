/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef SCHED_EDF_H
#define SCHED_EDF_H

#include "plugin.h"

extern void sched_edf_main(void);
extern void sched_edf_register_task(struct plugin_instance *p);
extern void sched_edf_unregister_task(struct plugin_instance *p);

#endif /* SCHED_EDF_H */
