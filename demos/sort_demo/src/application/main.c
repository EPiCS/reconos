#include "reconos.h"
#include "reconos_app.h"
#include "mbox.h"

#include <stdio.h>
#include <stdlib.h>

#define BLOCK_SIZE 1024

#define log(...) printf(__VA_ARGS__); fflush(stdout)

static struct mbox *mbox_addr = &sortdemo_resources_address;
static struct mbox *mbox_ack = &sortdemo_resources_acknowledge;

void print_help() {
	printf("ReconOS v3 sort demo application.\n"
	       "Sorts a buffer full of data with a variable number of sw and hw threads.\n"
	       "\n"
	       "Usage:\n"
	       "    sort_demo <num_hw_threads> <num_sw_threads> <num_of_blocks>\n"
	);
}

int cmp_uint32t(const void *a, const void *b) {
	return *(uint32_t *)a - *(uint32_t *)b;
}

void _merge(uint32_t *data, uint32_t *tmp,
           int l_count, int r_count) {
	int i;
	uint32_t *l = data, *r = data + l_count;
	int li = 0, ri = 0;

	for (i = 0; i < l_count; i++) {
		tmp[i] = l[i];
	}

	for (i = 0; i < l_count + r_count; i++) {
		if (ri >= r_count || (li < l_count && tmp[li] < r[ri])) {
			data[i] = tmp[li];
			li++;
		} else {
			data[i] = r[ri];
			ri++;
		}
	}
}

void merge(uint32_t *data, int data_count) {
	int bs, bi, i;
	int li, lim, ri, rim;
	uint32_t *tmp;

	tmp = (uint32_t *)malloc(data_count * sizeof(uint32_t));

	for (bs = BLOCK_SIZE; bs < data_count; bs += bs) {
		for (bi = 0; bi < data_count; bi += bs + bs) {
			if (bi + bs + bs > data_count) {
				_merge(data + bi, tmp, bs, data_count - bi - bs);
			} else {
				_merge(data + bi, tmp, bs, bs);
			}
		}
	}

	free(tmp);
}

int main(int argc, char **argv) {
	int i, j;
	int num_hwts, num_swts, num_blocks;
	uint32_t *data, *copy, *tmp;
	int data_count;

	unsigned int t_start, t_gen, t_sort, t_merge, t_check;

	if (argc != 4) {
		print_help();
		return 0;
	}

	num_hwts = atoi(argv[1]);
	num_swts = atoi(argv[2]);
	num_blocks = atoi(argv[3]);

	reconos_init();
	reconos_app_init();
	timer_init();

	log("creating %d hw-threads:", num_hwts);
	for (i = 0; i < num_hwts; i++) {
		log(" %d", i);
		reconos_thread_create_hwt_sortdemo();
	}
	log("\n");

	log("creating %d sw-thread:", num_swts);
	for (i = 0; i < num_swts; i++) {
		log(" %d", i);
		reconos_thread_create_swt_sortdemo();
	}
	log("\n");

	t_start = timer_get();
	log("generating data ...\n");
	data_count = num_blocks * BLOCK_SIZE;
	data = (uint32_t *)malloc(data_count * sizeof(uint32_t));
	for (i = 0; i < data_count; i++) {
		data[i] = data_count - 1;
	}
	memcpy(copy, data, data_count * sizeof(uint32_t));
	t_gen = timer_get() - t_start;

	log("putting %d blocks into job queue: ", num_blocks);
	for (i = 0; i < num_blocks; i++) {
		mbox_put(mbox_addr, (uint32_t)(data + i * BLOCK_SIZE));
		log(".");
	}
	log("\n");

	t_start = timer_get();
	log("waiting for %d acknowledgements: ", num_blocks);
	for (i = 0; i < num_blocks; i++) {
		mbox_get(mbox_ack);
		log(".");
	}
	log("\n");
	t_sort = timer_get() - t_start;

	t_start = timer_get();
	log("merging sorted data slices ...\n");
	merge(data, data_count);
	t_sort = timer_get() - t_start;

	t_start = timer_get();
	log("checking sorted data ...");
	qsort(copy, data_count, sizeof(uint32_t), cmp_uint32t);
	for (i = 0; i < data_count; i++) {
		if (data[i] != copy[i]) {
			log("expected 0x%08x but found 0x%08x\n at %d", copy[i], data[i], i);
		}
	}
	t_check = timer_get() - t_start;

	log("sending terminate message:");
	for (i = 0; i < num_hwts + num_swts; i++) {
		log(" %d", i);
		mbox_put(mbox_addr, 0xffffffff);
	}
	log("\n");

	printf("Running times (size: %d words, %d hw-threads, %d sw-threads):\n"
	       "  Generate data: %u ms\n"
	       "  Sort data    : %u ms\n"
	       "  Merge data   : %u ms\n"
	       "  Check data   : %u ms\n"
	       "Total computation time (sort & merge): %u ms\n",
	       data_count * sizeof(uint32_t), num_hwts, num_swts,
	       t_gen, t_sort, t_merge, t_check, t_sort + t_merge );

	timer_cleanup();
	reconos_app_cleanup();
	reconos_cleanup();

	return 0;
}