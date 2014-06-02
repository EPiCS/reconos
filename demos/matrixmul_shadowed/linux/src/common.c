/* common.c */

#include <stdlib.h>
#include <stdio.h>
#include "common.h"
#include "mmp.h"
#include "timing.h"
#include "xutils.h"


unsigned int time_ms(){
	timing_t now;
	now = gettime();
	return (unsigned int) timer2ms(&now);
}

void generate_data(int *input_matrixes[2], int **output_matrix, int matrix_size) {
	input_matrixes[0]	= xmalloc_aligned(matrix_size*matrix_size*sizeof(int), PAGE_SIZE);
	input_matrixes[1]	= xmalloc_aligned(matrix_size*matrix_size*sizeof(int), PAGE_SIZE);
	*output_matrix		= xmalloc_aligned(matrix_size*matrix_size*sizeof(int), PAGE_SIZE);

	int i;
	for (i=0; i<matrix_size*matrix_size; ++i) {
		input_matrixes[0][i]	= -1;//i-32;
		input_matrixes[1][i]	= 2;//32+i;
		(*output_matrix)[i]		= 55555;
	}
}

void generate_result(int *input_matrixes[2], int **res, int matrix_size) {
	*res = xmalloc_aligned(matrix_size*matrix_size*sizeof(int), PAGE_SIZE);

	std_matrix_mul(input_matrixes[0], input_matrixes[1], *res, matrix_size);
}

void print_matrix(int *matrix, char matrix_name, int matrix_size) {
	int i, j;
	printf("%c =\n", matrix_name);
	for (i=0; i<matrix_size; ++i) {
		printf("\t[ ");
		int pos = i*matrix_size;
		for (j=0; j<matrix_size; ++j) {
			printf("%8i ", matrix[pos+j]);
		}
		printf("]\n");
	}
}

/*
 * Compares two matrixes for equality.
 * Return value is -1 if equal, else it returns the index where comparison failed.
 */
int compare_result(int *result, int *compare, int matrix_size) {
	int i;
	for (i=0; i<matrix_size*matrix_size; ++i) {
		if (result[i] != compare[i]) {
			return i;
		}
	}
	return -1;
}

void append_list(MATRIXES **std_mmp_matrixes, int *i_matrixes[7][3]) {
	MATRIXES *ptr = *std_mmp_matrixes;
	int pos = -1;
	int i;

	for (i=0; i<7; ++i) {
		if (NULL == *std_mmp_matrixes) {
			*std_mmp_matrixes = xmalloc_aligned(sizeof(MATRIXES), PAGE_SIZE);
			ptr = *std_mmp_matrixes;
			pos = 0;
		} else {
			while (ptr->next != NULL) ptr = ptr->next;
			ptr->next = xmalloc_aligned(sizeof(MATRIXES), PAGE_SIZE);
			pos = ptr->pos + 1;
			ptr = ptr->next;
		}

		ptr->next			= NULL;
		ptr->pos			= pos;
		ptr->matrixes[0]	= i_matrixes[i][0];
		ptr->matrixes[1]	= i_matrixes[i][1];
		ptr->matrixes[2]	= i_matrixes[i][2];
	}
}

void append_list_single(MATRIXES **str_mmp_matrixes, int *i_matrix) {
	MATRIXES *ptr = *str_mmp_matrixes;
	int pos = -1;

	if (NULL == *str_mmp_matrixes) {
		*str_mmp_matrixes = xmalloc_aligned(sizeof(MATRIXES), PAGE_SIZE);
		ptr = *str_mmp_matrixes;
		pos = 0;
	} else {
		while (ptr->next != NULL) ptr = ptr->next;
		ptr->next = xmalloc_aligned(sizeof(MATRIXES), PAGE_SIZE);
		pos = ptr->pos + 1;
		ptr = ptr->next;
	}

	ptr->next			= NULL;
	ptr->pos			= pos;
	ptr->matrixes[0]	= NULL;
	ptr->matrixes[1]	= NULL;
	ptr->matrixes[2]	= i_matrix;
}
