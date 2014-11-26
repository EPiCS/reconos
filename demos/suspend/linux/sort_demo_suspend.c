#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <pthread.h>
#include <time.h>

#include "reconos.h"
#include "mbox.h"
#include "timer.h"

#define MAX_NUM_HWTS 2
#define SORT_LEN_BYTES 0x2000
#define SORT_LEN_WORDS (SORT_LEN_BYTES / 4)
#define STATE_SIZE ((SORT_LEN_WORDS + 4) * sizeof(uint32_t))

#define DEBUG
#define SUSPEND

struct reconos_resource res[2];
struct reconos_thread rt[MAX_NUM_HWTS];

struct mbox mbox_send, mbox_recv;
uint32_t **data;
uint32_t **data_ref;

#ifdef DEBUG
 #define debug(...) printf(__VA_ARGS__)
#else
 #define debug(...)
#endif

inline void print_time_diff(unsigned int start, unsigned int end) {
	unsigned int diff = end - start;

	printf("%u cc = %u µs = %u ms", diff, diff / 100, diff / 100000);
}

void bubblesort(uint32_t *data, int len_words) {
	int n, i, swapped;
	uint32_t tmp;

	n = len_words;
	do {
		swapped = 0;

		for (i = 0; i < n - 1; i++) {
			if (data[i] > data[i + 1]) {
				tmp = data[i];
				data[i] = data[i + 1];
				data[i + 1] = tmp;
				swapped = 1;
			}
		}

		n--;
	} while (swapped);
}

int main(int argc, char **argv) {
	int i, j;
	uint32_t *d, *d_ref;
	unsigned int start, end;

	debug("DEBUG: initializing ReconOS\n");
	debug("        ... reconos_init()\n");
	debug("        ... timer_init()\n");
	reconos_init();
	timer_init();
	debug("        ... %d hardware threads detected\n", RECONOS_NUM_HWTS);

	debug("DEBUG: initializing mboxes ");
	mbox_init(&mbox_send, MAX_NUM_HWTS);
	debug(".");
	mbox_init(&mbox_recv, MAX_NUM_HWTS);
	debug(".\n");

	debug("DEBUG: allocating and generating data to sort ");
	data = malloc(RECONOS_NUM_HWTS * sizeof(uint32_t *));
	if (!data) {
		debug("ERROR: failed to allocate memory\n");
		return -1;
	}

	data_ref = malloc(RECONOS_NUM_HWTS * sizeof(uint32_t *));
	if (!data_ref) {
		debug("ERROR: failed to allocate memory\n");
		return -1;
	}

	for (i = 0; i < RECONOS_NUM_HWTS; i++) {
		d = (uint32_t *)malloc(SORT_LEN_WORDS * sizeof(uint32_t));
		if (!d) {
			debug("ERROR: failed to allocate memory\n");
			return -1;
		}

		d_ref = (uint32_t *)malloc(SORT_LEN_WORDS * sizeof(uint32_t));
		if (!d_ref) {
			debug("ERROR: failed to allocate memory\n");
			return -1;
		}

		for (j = 0; j < SORT_LEN_WORDS; j++) {
			d[j] = (i + 1) * SORT_LEN_WORDS - j - 1;
			d_ref[j] = (i + 1) * SORT_LEN_WORDS - j - 1;
		}

		data[i] = d;
		data_ref[i] = d_ref;
		mbox_put(&mbox_send, (uint32_t)d);
		debug(".");
	}
	debug("\n");

	start = timer_get();

	debug("DEBUG: sorting reference data ");
	for (i = 0; i < RECONOS_NUM_HWTS; i++) {
		bubblesort(data_ref[i], SORT_LEN_WORDS);
		debug(".");
	}
	debug("\n");

	end = timer_get();

	printf("Sorting in software took ");
	print_time_diff(start, end);
	printf("\n");

	debug("DEBUG: initializing ReconOS resources\n");
	debug("        ... reconos_resource_init() ");
	reconos_resource_init(&res[0], RECONOS_RESOURCE_TYPE_MBOX, &mbox_send);
	reconos_resource_init(&res[1], RECONOS_RESOURCE_TYPE_MBOX, &mbox_recv);
	debug("\n");

	debug("DEBUG: initializing ReconOS thread\n");
	debug("        ... reconos_threadinit() ");
	for (i = 0; i < RECONOS_NUM_HWTS; i++) {
		reconos_thread_init(&rt[i], "Sort thread", STATE_SIZE);
		debug(".");
	}
	debug("\n");

	debug("        ... reconos_thread_setresources() ");
	for (i = 0; i < RECONOS_NUM_HWTS; i++) {
		reconos_thread_setresources(&rt[i], res, 2);
		debug(".");
	}
	debug("\n");

	start = timer_get();

	debug("DEBUG: starting ReconOS thread\n");
	debug("        ... reconos_thread_create() ");
	for (i = 0; i < RECONOS_NUM_HWTS; i++) {
		reconos_thread_create(&rt[i], i);
		debug(".");
	}
	debug("\n");

#ifdef SUSPEND
	debug("DEBUG: trying to suspend threads\n");
	debug("        ... reconos_thread_suspend() ");
	for (i = 0; i < RECONOS_NUM_HWTS; i++) {
		reconos_thread_suspend(&rt[i]);
		reconos_thread_join(&rt[i]);
		debug(".");
	}
	debug("\n");

	debug("DEBUG: resuming threads in switched order\n");
	debug("        ... reconos_thread_resume() ");
	for (i = 0; i < RECONOS_NUM_HWTS; i++) {
		reconos_thread_resume(&rt[i], RECONOS_NUM_HWTS - i - 1);
		debug(".");
	}
	debug("\n");
#endif

	debug("DEBUG: waiting for acknowledgments ");
	for (i = 0; i < RECONOS_NUM_HWTS; i++) {
		mbox_get(&mbox_recv);
		debug(".");
	}
	debug("\n");

	end = timer_get();

#if 0
	debug("DEBUG: sorted data\n");
	for (i = 0; i < RECONOS_NUM_HWTS; i++) {
		debug("-- data[%d] -----------------------\n", i);

		d = data[i];

		for (j = 0; j < SORT_LEN_WORDS; j += 4) {
			debug("%08x ", d[j + 0]);
			debug("%08x ", d[j + 1]);
			debug("%08x ", d[j + 2]);
			debug("%08x\n", d[j + 3]);
		}
	}
#endif

	debug("DEBUG: Checking hardware solution ");
	for (i = 0; i < RECONOS_NUM_HWTS; i++) {
		d = data[i];
		d_ref = data_ref[i];

		for (j = 0; j < SORT_LEN_WORDS; j++) {
			if (d[j] != d_ref[j]) {
				printf("ERROR: Hardware is wrong\n");
				return -1;
			}
		}
		debug(".");
	}
	debug("\n");

	debug("DEBUG: cleaning up\n");
	debug("        ... reconos_cleanup() ");
	reconos_cleanup();
	debug("\n");

	printf("Sorting in hardware took ");
	print_time_diff(start, end);
	printf("\n");

	return 0;
}
