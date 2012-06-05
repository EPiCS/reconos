/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <signal.h>

#include "reconfig.h"
#include "notification.h"
#include "xutils.h"
#include "stack.h"

void setup_initial_stack(void)
{
	printd("Initial stack set up!\n");
}

void cleanup_stack(void)
{
	printd("Stack cleaned up!\n");
}

static sig_atomic_t need_reliability = 0, need_reliability_switched = 0;

static void __reconfig_reliability_check_for_inclusion(void)
{
	/* Walk the stack, and trigger reconfig */
}

static void __reconfig_reliability_check_for_exclusion(void)
{
	/* Walk the stack, and trigger reconfig */
}

void reconfig_notify_reliability(int type)
{
	if (type == SIG_THRES_UPPER) {
		if (need_reliability == 1)
			need_reliability_switched = 1;
		need_reliability = 0;
	} else {
		if (need_reliability == 0)
			need_reliability_switched = 1;
		need_reliability = 1;
	}
}

void reconfig_reliability(void)
{
	if (need_reliability == 1 && need_reliability_switched == 1) {
		printd("Need reliability!\n");
		__reconfig_reliability_check_for_inclusion();
	} else if (need_reliability == 0 && need_reliability_switched == 1) {
		printd("Don't need reliability!\n");
		__reconfig_reliability_check_for_exclusion();
	}

	need_reliability_switched = 0;
}
