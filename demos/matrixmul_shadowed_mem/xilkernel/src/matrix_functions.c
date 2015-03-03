/* matrix_functions.c */

#include "matrix_functions.h"

void add_matrixes(int* target, int *source_a, int *source_b, int matrix_size) {
	int i;
	for (i=0; i<(matrix_size*matrix_size); ++i) {
		target[i] = source_a[i] + source_b[i];
	}
}

void sub_matrixes(int* target, int *source_a, int *source_b, int matrix_size) {
	int i;
	for (i=0; i<(matrix_size*matrix_size); ++i) {
		target[i] = source_a[i] - source_b[i];
	}
}

void copy_matrix(int* target, int *source, int matrix_size) {
	int i;
	for (i=0; i<(matrix_size*matrix_size); ++i) {
		target[i] = source[i];
	}
}
