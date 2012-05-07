/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef STORAGE_H
#define STORAGE_H

#include "plugin.h"
#include "timedb.h"

extern void storage_register_task(struct plugin_instance *p);
extern void storage_unregister_task(struct plugin_instance *p);
extern void storage_update_task(struct plugin_instance *p, float64_t *cells,
				size_t len);
extern void storage_get_block(struct plugin_instance *p, int64_t off,
			      float64_t *cells, size_t len);

#endif /* STORAGE_H */
