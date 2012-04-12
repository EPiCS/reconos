/*
 * Lightweight Autonomic Network Architecture
 * Copyright 2011 Daniel Borkmann <dborkma@tik.ee.ethz.ch>,
 * Swiss federal institute of technology (ETH Zurich)
 * Subject to the GPL.
 */

#ifndef SIGNALS_H
#define SIGNALS_H

#include <signal.h>
#include <assert.h>

static inline void register_signal(int signal, void (*handler)(int))
{
	sigset_t block_mask;
	struct sigaction saction;

	assert(handler);

	sigfillset(&block_mask);
	saction.sa_handler = handler;
	saction.sa_mask = block_mask;
	saction.sa_flags = SA_RESTART;

	sigaction(signal, &saction, NULL);
}

static inline void register_signal_f(int signal, void (*handler)(int),
				     int flags)
{
	sigset_t block_mask;
	struct sigaction saction;

	assert(handler);

	sigfillset(&block_mask);
	saction.sa_handler = handler;
	saction.sa_mask = block_mask;
	saction.sa_flags = flags;

	sigaction(signal, &saction, NULL);
}

#endif /* SIGNALS_H */
