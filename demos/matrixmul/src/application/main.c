#include "reconos.h"
#include "reconos_app.h"
#include "mbox.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define NUM_HWT 1

#define NUM_MATRICES 10
#define MATRIX_SIZE 4

#define log(...) printf(__VA_ARGS__); fflush(stdout)

static struct mbox *mbox_addr = &matrixmul_resources_address;
static struct mbox *mbox_ack = &matrixmul_resources_acknowledge;

int matrix_data[3 * NUM_MATRICES][MATRIX_SIZE][MATRIX_SIZE];
int *matrix_ptr[3 * NUM_MATRICES];
int matrix_control[MATRIX_SIZE][MATRIX_SIZE];

void std_matrix_mul(int *i_matrix_a, int *i_matrix_b, int *o_matrix_c, int matrix_size) {
	int i, j, k;
	for (i=0; i<matrix_size; ++i) {
		for (j=0; j<matrix_size; ++j) {
			int temp = 0;
			int pos = i*matrix_size;
			for (k=0; k<matrix_size; ++k) {
				temp += i_matrix_a[pos+k]*i_matrix_b[k*matrix_size+j];
			}
			o_matrix_c[pos+j] = temp;
		}
	}
}

void print_matrices(int id) {
	int m, i, j;

	printf("## Matrix dump begin ##\n");

	for (m = id; m < 3; m++) {
		for (i = 0; i < MATRIX_SIZE; i++) {
			for (j = 0; j < MATRIX_SIZE; j++) {
				printf("%i ", matrix_data[m][i][j]);
			}
			printf("\n");
		}
		printf("\n");
	}

	printf("## Matrix dump end ##\n");
}

void init_mmul_data() {
	int m, i, j;

	for (m = 0; m < 3 * NUM_MATRICES; m++) {
		matrix_ptr[m] = (int *)&matrix_data[m][0][0];

		for (i = 0; i < MATRIX_SIZE; i++) {
			for (j = 0; j < MATRIX_SIZE; j++) {
				matrix_data[m][i][j] = rand() % 128;
			}
		}
	}
}

int main(int argc, char **argv) {
	int i, j;
	uint32_t m;

	reconos_init();
	reconos_app_init();

	log("creating %d hw-threads:", NUM_HWT);
	for (i = 0; i < NUM_HWT; i++) {
		log(" %d", i);
		reconos_thread_create_hwt_matrixmul();
	}
	log("\n");

	init_mmul_data();

	for (i = 0; i < NUM_HWT; i++) {
		log("putting matrix into job queue: 0x%x\n", (uint32_t)&matrix_ptr[3 * i]);
		log("  at mbox addr + 0: 0x%x\n", (uint32_t)matrix_ptr[3 * i]);
		log("  at mbox addr + 4: 0x%x\n", (uint32_t)matrix_ptr[3 * i + 1]);
		log("  at mbox addr + 8: 0x%x\n", (uint32_t)matrix_ptr[3 * i + 2]);
		mbox_put(mbox_addr, (uint32_t)&matrix_ptr[3 * i]);
	}

	while (1) {
		m = mbox_get(mbox_ack);
		log("matrixmul finished, setting up new matrix\n");
		log("hwt returned 0x%x\n", m);

		m = (m - (uint32_t)&matrix_data[0][0][0]) / (4 * MATRIX_SIZE * MATRIX_SIZE);
		log("this should be index %d\n", m);

		std_matrix_mul(&matrix_data[m - 2][0][0], &matrix_data[m - 1][0][0], &matrix_control[0][0], MATRIX_SIZE);
		for (i = 0; i < MATRIX_SIZE; i++)
			for (j = 0; j < MATRIX_SIZE; j++)
				if (matrix_control[i][j] != matrix_data[m][i][j])
					log("ERROR at (%d,%d)\n", i, j);

		log("putting matrix into job queue:\n");
		log("  at mbox addr + 0: 0x%p\n", matrix_ptr[m - 2]);
		log("  at mbox addr + 4: 0x%p\n", matrix_ptr[m - 1]);
		log("  at mbox addr + 8: 0x%p\n", matrix_ptr[m]);
		mbox_put(mbox_addr, (uint32_t)&matrix_ptr[m - 2]);
	}

	return 0;
}
