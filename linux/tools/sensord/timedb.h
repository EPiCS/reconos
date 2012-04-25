/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 * Subject to the GNU GPL, version 2.0.
 */

#ifndef TIMEDB_H
#define TIMEDB_H

#include <sys/time.h>
#include <time.h>
#include <stdint.h>

#ifndef __packed
# define __packed		__attribute__((packed))
#endif

typedef float float32_t;
typedef double float64_t;

typedef uint64_t seq64_t;

struct timedb_timeval {
	uint32_t tv_sec;
	uint32_t tv_usec;
} __packed;

struct timedb_hdr {
	uint32_t canary;		/* file canary */
	uint8_t version_major;		/* major version number */
	uint8_t version_minor;		/* minor version number */
	struct timedb_timeval start;	/* start time of measurement */
	uint64_t interval;		/* in us */
	uint64_t block_entries;		/* num of max blocks */
	uint16_t cells_per_block;	/* cells per block + seq */
	uint64_t offset_next;		/* next write offset from file beginning */
	seq64_t seq_next;		/* next seq num */
} __packed;

struct timedb_block {
	seq64_t seqnr;
	float64_t cells[];
};

#define TIMEDB_VERSION_MAJOR	1
#define TIMEDB_VERSION_MINOR	0
#define TIMEDB_CANARY		0xdeadbeef

static inline void timedb_fill_timeval(struct timedb_timeval *t)
{
	struct timeval tv;
	gettimeofday(&tv, NULL);

	t->tv_sec = (uint32_t) tv.tv_sec;
	t->tv_usec = (uint32_t) tv.tv_usec;
}

static inline void timedb_fill_hdr(struct timedb_hdr *th, uint64_t interval,
				   uint64_t block_entries,
				   uint16_t cells_per_block)
{
	memset(th, 0, sizeof(*th));
	th->canary = TIMEDB_CANARY;
	th->version_major = TIMEDB_VERSION_MAJOR;
	th->version_minor = TIMEDB_VERSION_MINOR;
	timedb_fill_timeval(&th->start);
	th->interval = interval;
	th->block_entries = block_entries;
	th->cells_per_block = cells_per_block + 1 /* seq64_t */;
	th->offset_next = sizeof(struct timedb_hdr);
	th->seq_next = 1;
}

#define block_to_seq(x)		(*((seq64_t *) (x)))
#define block_to_data_off(x, j)	(*(float64_t *) ((x) + sizeof(seq64_t) + sizeof(float64_t) * (j)))

#endif /* TIMEDB_H */
