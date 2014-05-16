/* std_mmp.c */

#include "mmp.h"
#include "stdio.h"

void std_matrix_mul(int *i_matrix_a, int *i_matrix_b, int *o_matrix_c, int matrix_size) {
	int i, j, k;
	for (i=0; i<matrix_size; ++i) {
		printf("std_matrix_mul i: %i\n", i);
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
