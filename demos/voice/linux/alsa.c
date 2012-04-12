/*
 * Lightweight Autonomic Network Architecture
 * Copyright 2011 Daniel Borkmann <dborkma@tik.ee.ethz.ch>,
 * Swiss federal institute of technology (ETH Zurich)
 * Subject to the GPL.
 */

/*
 * Copyright (C) 2011 Daniel Borkmann (major cleanups, improvements, fixed bugs)
 * Copyright (C) 2004-2006 Jean-Marc Valin
 * Copyright (C) 2006 Commonwealth Scientific and Industrial Research
 *                    Organisation (CSIRO) Australia
 *  
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include "compiler.h"
#include "die.h"
#include "alsa.h"
#include "xmalloc.h"
#include "strlcpy.h"

#define PERIODS	3

struct alsa_dev {
	char *name;
	int channels;
	int period;
	snd_pcm_t *capture_handle;
	snd_pcm_t *playback_handle;
	unsigned int read_fds;
	struct pollfd *read_fd;
	unsigned int write_fds;
	struct pollfd *write_fd;
};

static void alsa_set_hw_params(struct alsa_dev *dev, snd_pcm_t *handle,
			       unsigned int rate, int channels, int period)
{
	int dir, ret;
	snd_pcm_uframes_t period_size;
	snd_pcm_uframes_t buffer_size;
	snd_pcm_hw_params_t *hw_params;

	ret = snd_pcm_hw_params_malloc(&hw_params);
	if (ret < 0)
		panic("Cannot allocate hardware parameters: %s\n",
			     snd_strerror(ret));
	ret = snd_pcm_hw_params_any(handle, hw_params);
	if (ret < 0)
		panic("Cannot initialize hardware parameters: %s\n",
			     snd_strerror(ret));
	ret = snd_pcm_hw_params_set_access(handle, hw_params,
					   SND_PCM_ACCESS_RW_INTERLEAVED);
	if (ret < 0)
		panic("Cannot set access type: %s\n",
			     snd_strerror(ret));
	ret = snd_pcm_hw_params_set_format(handle, hw_params,
					   SND_PCM_FORMAT_S16_LE);
	if (ret < 0)
		panic("Cannot set sample format: %s\n",
			     snd_strerror(ret));
	ret = snd_pcm_hw_params_set_rate_near(handle, hw_params, &rate, 0);
	if (ret < 0)
		panic("Cannot set sample rate: %s\n",
			     snd_strerror(ret));
	ret = snd_pcm_hw_params_set_channels(handle, hw_params, channels);
	if (ret < 0)
		panic("Cannot set channel number: %s\n",
			     snd_strerror(ret));
	period_size = period;
	dir = 0;
	ret = snd_pcm_hw_params_set_period_size_near(handle, hw_params,
						     &period_size, &dir);
	if (ret < 0)
		panic("Cannot set period size: %s\n",
			     snd_strerror(ret));
	ret = snd_pcm_hw_params_set_periods(handle, hw_params, PERIODS, 0);
	if (ret < 0)
		panic("Cannot set period number: %s\n",
			     snd_strerror(ret));
	buffer_size = period_size * PERIODS;
	dir = 0;
	ret = snd_pcm_hw_params_set_buffer_size_near(handle, hw_params,
						     &buffer_size);
	if (ret < 0)
		panic("Cannot set buffer size: %s\n",
			     snd_strerror(ret));
	ret = snd_pcm_hw_params(handle, hw_params);
	if (ret < 0)
		panic("Cannot set capture parameters: %s\n",
			     snd_strerror(ret));
	snd_pcm_hw_params_free(hw_params);
}

static void alsa_set_sw_params(struct alsa_dev *dev, snd_pcm_t *handle,
			       int period, int thres)
{
	int ret;
	snd_pcm_sw_params_t *sw_params;

	ret = snd_pcm_sw_params_malloc(&sw_params);
	if (ret < 0)
		panic("Cannot allocate software parameters: %s\n",
			     snd_strerror(ret));
	ret = snd_pcm_sw_params_current(handle, sw_params);
	if (ret < 0)
		panic("Cannot initialize software parameters: %s\n",
			     snd_strerror(ret));
	ret = snd_pcm_sw_params_set_avail_min(handle, sw_params, period);
	if (ret < 0)
		panic("Cannot set minimum available count: %s\n",
			     snd_strerror(ret));
	if (thres) {
		ret = snd_pcm_sw_params_set_start_threshold(handle, sw_params,
							    period);
		if (ret < 0)
			panic("Cannot set start mode: %s\n",
				     snd_strerror(ret));
		
	}
	ret = snd_pcm_sw_params(handle, sw_params);
	if (ret < 0)
		panic("Cannot set software parameters: %s\n",
			     snd_strerror(ret));
	snd_pcm_sw_params_free(sw_params);
}

struct alsa_dev *alsa_open(char *devname, unsigned int rate,
			   int channels, int period)
{
	int ret;
	struct alsa_dev *dev;

	if (!devname)
		devname = "plughw:0,0";

	dev = xzmalloc(sizeof(*dev));
	dev->name = xstrdup(devname);
	dev->channels = channels;
	dev->period = period;

	ret = snd_pcm_open(&dev->capture_handle, dev->name,
			   SND_PCM_STREAM_CAPTURE, 0);
	if (ret < 0)
		panic("Cannot open audio capture device %s: %s\n",
			     dev->name, snd_strerror(ret));
	alsa_set_hw_params(dev, dev->capture_handle, rate, channels, period);
	alsa_set_sw_params(dev, dev->capture_handle, period, 0);

	ret = snd_pcm_open(&dev->playback_handle, dev->name,
			   SND_PCM_STREAM_PLAYBACK, 0);
	if (ret < 0)
		panic("Cannot open audio playback device %s: %s\n",
			     dev->name, snd_strerror(ret));
	alsa_set_hw_params(dev, dev->playback_handle, rate, channels, period);
	alsa_set_sw_params(dev, dev->playback_handle, period, 1);

	snd_pcm_link(dev->capture_handle, dev->playback_handle);

	ret = snd_pcm_prepare(dev->capture_handle);
	if (ret < 0)
		panic("Cannot prepare audio interface: %s\n",
			     snd_strerror(ret));

	ret = snd_pcm_prepare(dev->playback_handle);
	if (ret < 0)
		panic("Cannot prepare audio interface: %s\n",
			     snd_strerror(ret));

	dev->read_fds = snd_pcm_poll_descriptors_count(dev->capture_handle);
	dev->write_fds = snd_pcm_poll_descriptors_count(dev->playback_handle);

	dev->read_fd = xzmalloc(dev->read_fds * sizeof(*dev->read_fd));
	ret = snd_pcm_poll_descriptors(dev->capture_handle, dev->read_fd,
				       dev->read_fds);
	if (ret != dev->read_fds)
		panic("Cannot obtain capture file descriptors: %s\n",
			     snd_strerror(ret));

	dev->write_fd = xzmalloc(dev->write_fds * sizeof(*dev->write_fd));
	ret = snd_pcm_poll_descriptors(dev->playback_handle, dev->write_fd,
				       dev->write_fds);
	if (ret != dev->write_fds)
		panic("Cannot obtain playback file descriptors: %s\n",
			     snd_strerror(ret));

	return dev;
}

void alsa_close(struct alsa_dev *dev)
{
	snd_pcm_close(dev->capture_handle);
	snd_pcm_close(dev->playback_handle);

	xfree(dev->name);
	xfree(dev->read_fd);
	xfree(dev->write_fd);
	xfree(dev);
}

ssize_t alsa_read(struct alsa_dev *dev, short *pcm, size_t len)
{
	ssize_t ret;
	ret = snd_pcm_readi(dev->capture_handle, pcm, len);
	if (unlikely(ret != len)) {
		if (ret < 0) {
			if (ret == -EPIPE) {
				info("An overrun has occured, "
					    "reseting capture!\n");
			} else {
				info("Read from audio interface "
					    "failed: %s\n", snd_strerror(ret));
			}

			ret = snd_pcm_prepare(dev->capture_handle);
			if (unlikely(ret < 0))
				info("Error preparing interface: %s\n",
					    snd_strerror(ret));

			ret = snd_pcm_start(dev->capture_handle);
			if (unlikely(ret < 0))
				info("Error preparing interface: %s\n",
					    snd_strerror(ret));
		}
	}

	return ret;
}

ssize_t alsa_write(struct alsa_dev *dev, const short *pcm, size_t len)
{
	ssize_t ret;
	ret = snd_pcm_writei(dev->playback_handle, pcm, len);
	if (unlikely(ret != len)) {
		if (ret < 0) {
			if (ret == -EPIPE) {
				info("An underrun has occured, "
					    "reseting playback!\n");
			} else {
				info("Write to audio interface "
					    "failed: %s\n", snd_strerror(ret));
			}

			ret = snd_pcm_prepare(dev->playback_handle);
			if (unlikely(ret < 0))
				info("Error preparing interface: %s\n",
					    snd_strerror(ret));
		}
	}

	return ret;
}

int alsa_cap_ready(struct alsa_dev *dev, struct pollfd *pfds,
		   unsigned int nfds)
{
	int ret;
	unsigned short revents = 0;

	ret = snd_pcm_poll_descriptors_revents(dev->capture_handle, pfds,
					       dev->read_fds, &revents);
	if (ret < 0) {
		whine("error in alsa_cap_ready: %s\n",
			     snd_strerror(ret));
		return pfds[0].revents & POLLIN;
	}

	return revents & POLLIN;
}

int alsa_play_ready(struct alsa_dev *dev, struct pollfd *pfds,
		    unsigned int nfds)
{
	int ret;
	unsigned short revents = 0;
	ret = snd_pcm_poll_descriptors_revents(dev->playback_handle,
					       pfds + dev->read_fds,
					       dev->write_fds, &revents);
	if (ret < 0) {
		whine("error in alsa_play_ready: %s\n",
			     snd_strerror(ret));
		return pfds[1].revents & POLLOUT;
	}

	return revents & POLLOUT;
}

void alsa_start(struct alsa_dev *dev)
{
	short *pcm;
	size_t len = dev->period * dev->channels;

	pcm = xzmalloc(len * sizeof(*pcm));
	alsa_write(dev, pcm, dev->period);
	alsa_write(dev, pcm, dev->period);
	xfree(pcm);

	snd_pcm_start(dev->capture_handle);
	snd_pcm_start(dev->playback_handle);
}

inline unsigned int alsa_nfds(struct alsa_dev *dev)
{
	return dev->read_fds + dev->write_fds;
}

void alsa_getfds(struct alsa_dev *dev, struct pollfd *pfds,
		 unsigned int nfds)
{
	int i;

	BUG_ON(nfds < alsa_nfds(dev), "%s\n", __func__);

	for (i = 0; i < dev->read_fds; ++i)
		pfds[i] = dev->read_fd[i];
	for (i = 0; i < dev->write_fds; ++i)
		pfds[i + dev->read_fds] = dev->write_fd[i];
}

