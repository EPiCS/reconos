/* str_mmp.c */

#include "mmp.h"
#include "matrix_functions.h"
#include "common.h"
#include <stdlib.h>

void get_matrix(int *i_matrix, int **o_matrix, int posY, int posX, int i_matrix_size) {
	int o_matrix_size = i_matrix_size/2;
	--posY;--posX;

	*o_matrix = malloc(o_matrix_size*o_matrix_size*sizeof(int));

	int i, j, k = 0;
	int temp1 = (posY*i_matrix_size + posX) * o_matrix_size;
	for (i=0; i<o_matrix_size; ++i) {
		int temp2 = temp1 + i*i_matrix_size;
		for (j=0; j<o_matrix_size; ++j) {
			(*o_matrix)[k++] = i_matrix[temp2+j];
		}
	}
}

void set_matrix(int *o_matrix, int *i_matrix, int posY, int posX, int i_matrix_size) {
	int o_matrix_size = i_matrix_size*2;
	--posY;--posX;

	int i, j, k = 0;
	int temp1 = (posY*o_matrix_size + posX) * i_matrix_size;
	for (i=0; i<i_matrix_size; ++i) {
		int temp2 = temp1 + i*o_matrix_size;
		for (j=0; j<i_matrix_size; ++j) {
			o_matrix[temp2+j] = i_matrix[k++];
		}
	}
}

void str_matrix_split(int *i_matrix_a, int *i_matrix_b, MATRIXES **std_mmp_matrixes, int i_matrix_size) {
	int o_matrix_size = i_matrix_size/2;
	int *o_matrixes[7][3];

	int i;
	for (i=0; i<7; ++i) {
		o_matrixes[i][0] = malloc(o_matrix_size*o_matrix_size*sizeof(int));
		o_matrixes[i][1] = malloc(o_matrix_size*o_matrix_size*sizeof(int));
		o_matrixes[i][2] = malloc(o_matrix_size*o_matrix_size*sizeof(int));
	}

	// split matrix
	int *a11, *a12, *a21, *a22;
	int *b11, *b12, *b21, *b22;

	get_matrix(i_matrix_a, &a11, 1, 1, i_matrix_size);
	get_matrix(i_matrix_a, &a12, 1, 2, i_matrix_size);
	get_matrix(i_matrix_a, &a21, 2, 1, i_matrix_size);
	get_matrix(i_matrix_a, &a22, 2, 2, i_matrix_size);

	get_matrix(i_matrix_b, &b11, 1, 1, i_matrix_size);
	get_matrix(i_matrix_b, &b12, 1, 2, i_matrix_size);
	get_matrix(i_matrix_b, &b21, 2, 1, i_matrix_size);
	get_matrix(i_matrix_b, &b22, 2, 2, i_matrix_size);

	// mmp #1 preparation
	add_matrixes(o_matrixes[0][0], a11, a22, o_matrix_size);
	add_matrixes(o_matrixes[0][1], b11, b22, o_matrix_size);

	// mmp #2 preparation
	add_matrixes(o_matrixes[1][0], a21, a22, o_matrix_size);
	copy_matrix(o_matrixes[1][1], b11, o_matrix_size);

	// mmp #3 preparation
	copy_matrix(o_matrixes[2][0], a11, o_matrix_size);
	sub_matrixes(o_matrixes[2][1], b12, b22, o_matrix_size);

	// mmp #4 preparation
	copy_matrix(o_matrixes[3][0], a22, o_matrix_size);
	sub_matrixes(o_matrixes[3][1], b21, b11, o_matrix_size);

	// mmp #5 preparation
	add_matrixes(o_matrixes[4][0], a11, a12, o_matrix_size);
	copy_matrix(o_matrixes[4][1], b22, o_matrix_size);

	// mmp #6 preparation
	sub_matrixes(o_matrixes[5][0], a21, a11, o_matrix_size);
	add_matrixes(o_matrixes[5][1], b11, b12, o_matrix_size);

	// mmp #7 preparation
	sub_matrixes(o_matrixes[6][0], a12, a22, o_matrix_size);
	add_matrixes(o_matrixes[6][1], b21, b22, o_matrix_size);

	free(a11); free(a12); free(a21); free(a22);
	free(b11); free(b12); free(b21); free(b22);

	if (o_matrix_size <= STD_MMP_MATRIX_SIZE) {
		append_list(std_mmp_matrixes, o_matrixes);
	} else {
		// recursive strassen mmp algorithm
		for (i=0; i<7; ++i) {
			str_matrix_split(o_matrixes[i][0], o_matrixes[i][1], std_mmp_matrixes, o_matrix_size);
		}
	}
}

int str_matrix_combine_step(MATRIXES **str_mmp_matrixes, MATRIXES **std_mmp_matrixes, int i_matrix_size) {
	int i;
	int o_matrix_size = i_matrix_size*2;
	MATRIXES *ptr = *std_mmp_matrixes;

	int *temp1 = malloc(i_matrix_size*i_matrix_size*sizeof(int));
	int *temp2 = malloc(i_matrix_size*i_matrix_size*sizeof(int));

	int *c11 = malloc(i_matrix_size*i_matrix_size*sizeof(int));
	int *c12 = malloc(i_matrix_size*i_matrix_size*sizeof(int));
	int *c21 = malloc(i_matrix_size*i_matrix_size*sizeof(int));
	int *c22 = malloc(i_matrix_size*i_matrix_size*sizeof(int));

	int *o_matrix = malloc(o_matrix_size*o_matrix_size*sizeof(int));

	int *std_mmp_result_matrixes[7];
	for (i=0; i<7; ++i) {
		printf("str_matrix_combine_step: i: %i, std_mmp_result_matrixes[i]: %p, ptr: %p, ptr->matrixes: %p, ptr->next: %p\n",
				i, std_mmp_result_matrixes[i], ptr, ptr->matrixes, ptr->next);
		std_mmp_result_matrixes[i] = ptr->matrixes[2];
		ptr = ptr->next;
	}

	*std_mmp_matrixes = ptr;

	// c11
	add_matrixes(temp1, std_mmp_result_matrixes[0], std_mmp_result_matrixes[3], i_matrix_size);
	sub_matrixes(temp2, temp1, std_mmp_result_matrixes[4], i_matrix_size);
	add_matrixes(c11, temp2, std_mmp_result_matrixes[6], i_matrix_size);

	// c12
	add_matrixes(c12, std_mmp_result_matrixes[2], std_mmp_result_matrixes[4], i_matrix_size);

	// c21
	add_matrixes(c21, std_mmp_result_matrixes[1], std_mmp_result_matrixes[3], i_matrix_size);

	// c22
	sub_matrixes(temp1, std_mmp_result_matrixes[0], std_mmp_result_matrixes[1], i_matrix_size);
	add_matrixes(temp2, temp1, std_mmp_result_matrixes[2], i_matrix_size);
	add_matrixes(c22, temp2, std_mmp_result_matrixes[5], i_matrix_size);

	set_matrix(o_matrix, c11, 1, 1, i_matrix_size);
	set_matrix(o_matrix, c12, 1, 2, i_matrix_size);
	set_matrix(o_matrix, c21, 2, 1, i_matrix_size);
	set_matrix(o_matrix, c22, 2, 2, i_matrix_size);

	append_list_single(str_mmp_matrixes, o_matrix);

	free(temp1); free(temp2);
	free(c11); free(c12); free(c21); free(c22);

	return o_matrix_size;
}

int *str_matrix_combine(MATRIXES **std_mmp_matrixes, int i_matrix_size, int o_matrix_size) {
	int o_matrix_size_tmp = i_matrix_size;
	MATRIXES *str_mmp_matrixes;

	while(o_matrix_size_tmp < o_matrix_size) {
		str_mmp_matrixes = NULL;

		while(NULL != *std_mmp_matrixes) {
			o_matrix_size_tmp = str_matrix_combine_step(&str_mmp_matrixes, std_mmp_matrixes, i_matrix_size);
		}

		i_matrix_size = o_matrix_size_tmp;
		*std_mmp_matrixes = str_mmp_matrixes;
	}

	return str_mmp_matrixes->matrixes[2];
}
