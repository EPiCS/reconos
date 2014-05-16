/* mmp.h */

#ifndef __MMP_H__
#define __MMP_H__

/*
 * Remember: always use power of two numbers.
 * And don't forget to resynthesize hardware
 * with new constraints, if you change STD_MMP_MATRIX_SIZE.
 */
#define STD_MMP_MATRIX_SIZE 128
#define STR_MMP_INPUT_MATRIX_SIZE 512

// 2 recursive steps (512->256->128) => 7^2=49
// now calculated at runtime, so define is not longer needed
//#define MBOX_SIZE 49

void std_matrix_mul(int *i_matrix_a, int *i_matrix_b, int *o_matrix_c, int matrix_size);

typedef struct matrix_list {
	int *matrixes[3];
	int pos;
	struct matrix_list* next;
} MATRIXES;

void str_matrix_split(int *i_matrix_a, int *i_matrix_b, MATRIXES **std_mmp_matrixes, int i_matrix_size);
int *str_matrix_combine(MATRIXES **std_mmp_matrixes, int i_matrix_size, int o_matrix_size);

#endif /* __MMP_H__ */
