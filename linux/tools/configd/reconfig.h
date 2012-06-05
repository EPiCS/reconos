/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef RECONFIG_H
#define RECONFIG_H

extern void setup_initial_stack(void);
extern void cleanup_stack(void);

extern void reconfig_notify_reliability(int type);
extern void reconfig_reliability(void);

#endif /* RECONFIG_H */
