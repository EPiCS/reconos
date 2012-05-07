/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef NOTIFIER_H
#define NOTIFIER_H

#include <stdint.h>
#include <stdio.h>

#include "locking.h"
#include "timedb.h"
#include "notification.h"

#define BLOCK_SUCC_DONE   0
#define BLOCK_STOP_CHAIN  1

enum event_prio {
        PRIO_VERYLOW,
        PRIO_LOW,
        PRIO_MEDIUM,
        PRIO_HIGH,
        PRIO_EXTRA,
};

struct event_block {
	pid_t proc;
	enum event_prio prio;
	enum threshold_type type;
	uint8_t *cells_active;
	float64_t *cells_thres;
	int shmid;
	void *shmem;
	struct event_block *next;
};

struct event_head {
	struct event_block *head;
	struct mutexlock lock;
};

static inline void init_event_head(struct event_head *head)
{
	head->head = NULL;
	mutexlock_init(&head->lock);
}

extern int register_event_hook(struct event_block **head,
			       struct event_block *block);
extern int unregister_event_hook(struct event_block **head,
				 struct event_block *block);
extern void notifiy_procs_event(struct event_block **head,
				float64_t *value, size_t len, char *instance);
extern struct event_block *get_block_by_pid(struct event_block **head, pid_t wanted);

#endif /* NOTIFIER_H */
