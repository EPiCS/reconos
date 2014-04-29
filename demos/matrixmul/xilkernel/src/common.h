/* common.h */

#ifndef __COMMON_H__
#define __COMMON_H__

#include "mmp.h"

unsigned int time_ms();

void generate_data(int *input_matrixes[2], int **output_matrix, int matrix_size);
void generate_result(int *input_matrixes[2], int **res, int matrix_size);
void print_matrix(int *matrix, char matrix_name, int matrix_size);
int compare_result(int *result, int *compare, int matrix_size);

void append_list(MATRIXES **std_mmp_matrixes, int *i_matrixes[7][3]);
void append_list_single(MATRIXES **str_mmp_matrixes, int *i_matrix);

#endif /* __COMMON_H__ */
