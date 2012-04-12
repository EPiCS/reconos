/*
 * Lightweight Autonomic Network Architecture
 * Copyright 2011 Daniel Borkmann <dborkma@tik.ee.ethz.ch>,
 * Swiss federal institute of technology (ETH Zurich)
 * Subject to the GPL.
 */

/* apt-get install libcelt0-0 libcelt-dev libspeexdsp1 libspeexdsp-dev libasound2-dev libasound2 */

/* NOTE: make sure you also have the alsa userspace tools compiled with
 *       the same version! */

/*
 * Copyright (C) 2011 Daniel Borkmann (major cleanups, improvements, fixed bugs,
 *                                     new API, used PF_LANA instead of IPv4/UDP)
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

#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <time.h>
#include <sys/time.h>
#include <sys/types.h>
#include <netdb.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <celt/celt.h>
#include <speex/speex_jitter.h>
#include <speex/speex_echo.h>
#include <sched.h>
#include <sys/ioctl.h>
#include <net/if.h>

#include "alsa.h"
#include "signals.h"
#include "die.h"
#include "xmalloc.h"

#define AF_LANA		27

#define MAX_MSG		1500
#define SAMPLING_RATE	48000
#define FRAME_SIZE	256
#define PACKETSIZE	43
#define CHANNELS	1

static sig_atomic_t sigint = 0;
static sig_atomic_t pkts_in = 0, pkts_out = 0;
static struct itimerval itimer;
static unsigned long interval = 100;

void sighandler(int nr)
{
	if (nr == SIGINT)
		sigint = 1;
}

static char blubber[] = {'-', '\\', '|', '/'};

static void timer_elapsed(int number)
{
	unsigned int in = pkts_in, out = pkts_out;

	itimer.it_interval.tv_sec = 0;
	itimer.it_interval.tv_usec = interval;
	itimer.it_value.tv_sec = 0;
	itimer.it_value.tv_usec = interval;

	printf("\rnet: in %c, out %c\t",
	       blubber[in % sizeof(blubber)], blubber[out % sizeof(blubber)]);
	fflush(stdout);
	setitimer(ITIMER_REAL, &itimer, NULL); 
}

void hack_mac(char *dst, char *src, size_t len)
{
	unsigned int dst1[6];
	/* Fucked up crap. */
	sscanf(src, "%x:%x:%x:%x:%x:%x",
	       &dst1[0], &dst1[1], &dst1[2],
	       &dst1[3], &dst1[4], &dst1[5]);
	dst[0] = (uint8_t) dst1[0];
	dst[1] = (uint8_t) dst1[1];
	dst[2] = (uint8_t) dst1[2];
	dst[3] = (uint8_t) dst1[3];
	dst[4] = (uint8_t) dst1[4];
	dst[5] = (uint8_t) dst1[5];
}

int main(int argc, char **argv)
{
	int sd, rc, n, tmp;
	char msg[MAX_MSG];
	int nfds;
	int send_timestamp = 0;
	int recv_started = 0;
	struct pollfd *pfds;
	struct alsa_dev *dev;
	CELTEncoder *enc_state;
	CELTDecoder *dec_state;
	CELTMode *mode;
	struct sched_param param;
	JitterBuffer *jitter;
	SpeexEchoState *echo_state;
	char mac_own[6], mac_remote[6];

	if (argc != 4)
		panic("Usage %s plughw:0,0 <lmac in xx:xx:xx:xx:xx:xx> <rmac>\n", argv[0]);
 
	register_signal(SIGINT, sighandler);

	hack_mac(mac_own, argv[2], strlen(argv[2]));
	hack_mac(mac_remote, argv[3], strlen(argv[3]));
 
	sd = socket(AF_LANA, SOCK_RAW, 0);
	if (sd < 0)
		panic("%s: cannot open socket \n", argv[0]);

	printf("If ready hit key!\n"); //user must do binding
	getchar();

	dev = alsa_open(argv[1], SAMPLING_RATE, CHANNELS, FRAME_SIZE);

	mode = celt_mode_create(SAMPLING_RATE, FRAME_SIZE, NULL);
	enc_state = celt_encoder_create(mode, CHANNELS, NULL);
	dec_state = celt_decoder_create(mode, CHANNELS, NULL);

	param.sched_priority = sched_get_priority_min(SCHED_FIFO);
	if (sched_setscheduler(0, SCHED_FIFO, &param))
		whine("sched_setscheduler error!\n");
   
	/* Setup all file descriptors for poll()ing */
	nfds = alsa_nfds(dev);
	pfds = xmalloc(sizeof(*pfds) * (nfds + 1));

	alsa_getfds(dev, pfds, nfds);

	pfds[nfds].fd = sd;
	pfds[nfds].events = POLLIN;

	/* Setup jitter buffer using decoder */
	jitter = jitter_buffer_init(FRAME_SIZE);
	tmp = FRAME_SIZE;
	jitter_buffer_ctl(jitter, JITTER_BUFFER_SET_MARGIN, &tmp);

	/* Echo canceller with 200 ms tail length */
	echo_state = speex_echo_state_init(FRAME_SIZE, 10 * FRAME_SIZE);
	tmp = SAMPLING_RATE;
	speex_echo_ctl(echo_state, SPEEX_ECHO_SET_SAMPLING_RATE, &tmp);

	register_signal_f(SIGALRM, timer_elapsed, SA_SIGINFO);

	alsa_start(dev);
	printf("ALSA started!\n");

	itimer.it_interval.tv_sec = 0;
	itimer.it_interval.tv_usec = interval;
	itimer.it_value.tv_sec = 0;
	itimer.it_value.tv_usec = interval;
	setitimer(ITIMER_REAL, &itimer, NULL);

	while (!sigint) {
		poll(pfds, nfds + 1, -1);

		/* Received packets */
		if (pfds[nfds].revents & POLLIN) {
			memset(msg, 0, MAX_MSG);
			n = recv(sd, msg, MAX_MSG, 0);
			if (n <= 0)
				goto do_alsa;
			pkts_in++;
			int recv_timestamp;
			memcpy(&recv_timestamp, msg, sizeof(recv_timestamp));
			JitterBufferPacket packet;
			packet.data = msg+4/*+6+6+2*/;
			packet.len = n-4/*-6-6-2*/;
			packet.timestamp = recv_timestamp;
			packet.span = FRAME_SIZE;
			packet.sequence = 0;

			/* Put content of the packet into the jitter buffer,
			   except for the pseudo-header */
			jitter_buffer_put(jitter, &packet);
			recv_started = 1;
		}
do_alsa:
		/* Ready to play a frame (playback) */
		if (alsa_play_ready(dev, pfds, nfds)) {
			short pcm[FRAME_SIZE * CHANNELS] = {0};
			if (recv_started) {
				JitterBufferPacket packet;
				/* Get audio from the jitter buffer */
				packet.data = msg;
				packet.len  = MAX_MSG;
				jitter_buffer_tick(jitter);
				jitter_buffer_get(jitter, &packet, FRAME_SIZE,
						  NULL);
				if (packet.len == 0)
					packet.data=NULL;
				celt_decode(dec_state, (const unsigned char *)
					    packet.data, packet.len, pcm);
			}
			/* Playback the audio and reset the echo canceller
			   if we got an underrun */

			alsa_write(dev, pcm, FRAME_SIZE);
//			if (alsa_write(dev, pcm, FRAME_SIZE)) 
//				speex_echo_state_reset(echo_state);
			/* Put frame into playback buffer */
//			speex_echo_playback(echo_state, pcm);
		}

		/* Audio available from the soundcard (capture) */
		if (alsa_cap_ready(dev, pfds, nfds)) {
			short pcm[FRAME_SIZE * CHANNELS];
			      //pcm2[FRAME_SIZE * CHANNELS];
			char outpacket[MAX_MSG];

			alsa_read(dev, pcm, FRAME_SIZE);
			/* Perform echo cancellation */
//			speex_echo_capture(echo_state, pcm, pcm2);
//			for (i = 0; i < FRAME_SIZE * CHANNELS; ++i)
//				pcm[i] = pcm2[i];

			celt_encode(enc_state, pcm, NULL, (unsigned char *)
				    (outpacket+4+6+6+2), PACKETSIZE);

			/* Pseudo header: four null bytes and a 32-bit
			   timestamp; XXX hack */
			memcpy(outpacket,mac_remote,6);
			memcpy(outpacket+6,mac_own,6);
			outpacket[6+6] = (uint8_t) 0xac;
			outpacket[6+6+1] = (uint8_t) 0xdc;
			memcpy(outpacket+6+6+2, &send_timestamp, sizeof(send_timestamp));
			send_timestamp += FRAME_SIZE;

			rc = sendto(sd, outpacket, PACKETSIZE+4+6+6+2, 0, NULL, 0);
			if (rc < 0)
				panic("cannot send to socket");
			pkts_out++;
		}
	}

	itimer.it_interval.tv_sec = 0;
	itimer.it_interval.tv_usec = 0;
	itimer.it_value.tv_sec = 0;
	itimer.it_value.tv_usec = 0;
	setitimer(ITIMER_REAL, &itimer, NULL); 

	close(sd);
	return 0;
}

