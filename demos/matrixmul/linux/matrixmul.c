#include "reconos.h"

#include <pthread.h>
#include "mbox.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define NUM_HWT 1

#define NUM_MATRICES 10
#define MATRIX_SIZE 128

struct mbox mbox_sort_recv, mbox_sort_send;
struct mbox mbox_mmul_recv, mbox_mmul_send;

struct reconos_hwt hwt[NUM_HWT];
struct reconos_resource sort_res[2];
struct reconos_resource mmul_res[2];

pthread_t ctrl_sort, ctrl_mmul;

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

void *ctrl_mmul_thread(void *data) {
	int i;
	int m;

	int n,k;

	printf("address of first matrix: %x\n", &matrix_data[0][0][0]);

	for (i = 0; i < NUM_HWT; i++) {
		printf("Putting matrix into mbox %x:\n", &matrix_ptr[3 * i]);
		printf("at mbox addr + 0: %x\n", matrix_ptr[3 * i]);
		printf("at mbox addr + 4: %x\n", matrix_ptr[3 * i + 1]);
		printf("at mbox addr + 8: %x\n", matrix_ptr[3 * i + 2]);
		mbox_put(&mbox_mmul_recv, (unsigned int)&matrix_ptr[3 * i]);
	}

	i = 0;
	while (1) {
		m = mbox_get(&mbox_mmul_send);
		//print_matrices(3 * i);
		std_matrix_mul(&matrix_data[3*i][0][0], &matrix_data[3*i+1][0][0], &matrix_control[0][0], 128);
		for (n = 0; n < MATRIX_SIZE; n++)
			for (k = 0; k < MATRIX_SIZE; k++)
				if (matrix_control[n][k] != matrix_data[3*i+2][n][k])
					printf("ERROR at (%d,%d)\n", n, k);

		printf("Matrixmul finished, setting up new matrix\n");
		printf("HWT returned %x\n", m);
		m = (m - (int)&matrix_data[0][0][0]) / (4 * MATRIX_SIZE * MATRIX_SIZE);
		printf("This should be index %d\n", m);
		printf("Putting matrix into mbox %x:\n", &matrix_ptr[m % 2]);
		printf("at mbox addr + 0: %x\n", matrix_ptr[m % 2]);
		printf("at mbox addr + 4: %x\n", matrix_ptr[m % 2 + 1]);
		printf("at mbox addr + 8: %x\n", matrix_ptr[m % 2 + 2]);
		mbox_put(&mbox_mmul_recv, (unsigned int)&matrix_ptr[m % 2]);
	}
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
	// initialize mboxes
	mbox_init(&mbox_sort_recv, 16);
	mbox_init(&mbox_sort_send, 16);

	mbox_init(&mbox_mmul_recv, 16);
	mbox_init(&mbox_mmul_send, 16);

	init_mmul_data();

	// initialize resources
	sort_res[0].type = RECONOS_RESOURCE_TYPE_MBOX;
	sort_res[0].ptr = &mbox_sort_recv;
	sort_res[1].type = RECONOS_RESOURCE_TYPE_MBOX;
	sort_res[1].ptr = &mbox_sort_send;

	mmul_res[0].type = RECONOS_RESOURCE_TYPE_MBOX;
	mmul_res[0].ptr = &mbox_mmul_recv;
	mmul_res[1].type = RECONOS_RESOURCE_TYPE_MBOX;
	mmul_res[1].ptr = &mbox_mmul_send;

	reconos_init();

	pthread_create(&ctrl_mmul, NULL, ctrl_mmul_thread, NULL);

	reconos_hwt_setresources(&hwt[0], mmul_res, 2);
	reconos_hwt_create(&hwt[0], 0, NULL);

	pthread_join(ctrl_mmul, NULL);

	return 0;
}
