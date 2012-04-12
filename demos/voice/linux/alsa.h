/*
 * Lightweight Autonomic Network Architecture
 * Copyright 2011 Daniel Borkmann <dborkma@tik.ee.ethz.ch>,
 * Swiss federal institute of technology (ETH Zurich)
 * Subject to the GPL.
 */

#ifndef ALSA_H
#define ALSA_H

#include <stdlib.h>
#include <sys/poll.h>
#include <alsa/asoundlib.h>

#include "alsa.h"

struct alsa_dev;

extern struct alsa_dev *alsa_open(char *devname, unsigned int rate,
				  int channels, int period);
extern void alsa_close(struct alsa_dev *dev);
extern ssize_t alsa_read(struct alsa_dev *dev, short *pcm, size_t len); 
extern ssize_t alsa_write(struct alsa_dev *dev, const short *pcm, size_t len);
extern int alsa_cap_ready(struct alsa_dev *dev, struct pollfd *pfds,
			  unsigned int nfds);
extern int alsa_play_ready(struct alsa_dev *dev, struct pollfd *pfds,
			   unsigned int nfds);
extern void alsa_start(struct alsa_dev *dev);
extern unsigned int alsa_nfds(struct alsa_dev *dev);
extern void alsa_getfds(struct alsa_dev *dev, struct pollfd *pfds,
			unsigned int nfds);

#endif /* ALSA_H */
