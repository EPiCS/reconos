/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <signal.h>

#include "notifier.h"
#include "notification.h"
#include "xutils.h"
#include "timedb.h"

int register_event_hook(struct event_block **head,
		        struct event_block *block)
{
	if (!block || !head)
		return -EINVAL;

	while ((*head) != NULL) {
		if (block->prio > (*head)->prio)
			break;

		head = &((*head)->next);
	}

	block->next = (*head);
	(*head) = block;

	return 0;
}

int unregister_event_hook(struct event_block **head,
			  struct event_block *block)
{
	if (!block || !head)
		return -EINVAL;

	while ((*head) != NULL) {
		if (unlikely(block == (*head))) {
			(*head) = block->next;
			break;
		}

		head = &((*head)->next);
	}

	return 0;
}

static inline int need_notification(struct event_block *block, float64_t *value,
				    int which)
{
	if (block->type == lower_threshold) {
		if (value[which] < block->cells_thres[which])
			return 1;
	} else {
		if (value[which] > block->cells_thres[which])
			return 1;
	}
	return 0;
}

static inline void do_softirq_proc(struct event_block *block, float64_t *value,
				   int which, char *instance)
{
	struct shmnot_hdr *hdr;

	hdr = block->shmem;
	hdr->val = value[which];
	hdr->cell_num = which;
	strncpy(hdr->plugin_inst, instance, strlen(instance));

	/* Omg, killing spree !!! */
	if (block->type == lower_threshold)
		kill(block->proc, SIG_THRES_LOWER);
	else
		kill(block->proc, SIG_THRES_UPPER);
}

void notifiy_procs_event(struct event_block **head, float64_t *value,
			 size_t len, char *instance)
{
	int i;
	struct event_block *block = *head, *next_block;

	if (!head)
		return;

	while (block) {
		next_block = block->next;

		for (i = 0; i < len; ++i) {
			if (block->cells_active[i]) {
				if (need_notification(block, value, i))
					do_softirq_proc(block, value, i,
							instance);
			}
		}

		block = next_block;
	}
}

struct event_block *get_block_by_pid(struct event_block **head, pid_t wanted)
{
	struct event_block *block = *head, *next_block;

	if (!head)
		return NULL;

	while (block) {
		next_block = block->next;

		if (block->proc == wanted)
			return block;

		block = next_block;
	}

	return NULL;
}
