/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef XT_ENGINE_H
#define XT_ENGINE_H

#include <linux/skbuff.h>
#include "xt_fblock.h"

#define PPE_SUCCESS		0
#define PPE_DROPPED		1
#define PPE_HALT		PPE_DROPPED
#define PPE_ERROR		2
#define PPE_HALT_NO_REDUCE	3

extern int process_packet(struct sk_buff *skb, enum path_type dir);
extern void engine_backlog_tail(struct sk_buff *skb, enum path_type dir);

extern int init_engine(void);
extern void cleanup_engine(void);

#ifdef WITH_RECONOS
extern void packet_sw_to_hw(struct sk_buff *skb, enum path_type dir);

extern int init_hwif(void);
extern void cleanup_hwif(void);
#else
static inline void packet_sw_to_hw(struct sk_buff *skb, enum path_type dir)
{
	kfree_skb(skb);
}

static inline int init_hwif(void)
{
	return 0;
}
static inline void cleanup_hwif(void) {}
#endif /* WITH_RECONOS */
#endif /* XT_ENGINE_H */
