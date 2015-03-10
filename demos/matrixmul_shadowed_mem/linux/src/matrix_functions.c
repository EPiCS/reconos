/* matrix_functions.c */

#include "matrix_functions.h"
#include <stdio.h>

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

int read_matrix(int* target, char *source_file, int matrix_size){
	// WARNING: no path string sanitizing! Use with caution!
	FILE* mf = fopen(source_file, "r");
	size_t read_items = fread(target, sizeof(int), matrix_size*matrix_size, mf);
	fclose(mf);

	return (read_items == (matrix_size*matrix_size) );
}

int write_matrix(int* source, char *target_file, int matrix_size){
	// WARNING: no path string sanitizing! Use with caution!
	FILE* mf = fopen(target_file, "w");
	size_t written_items = fwrite(source, sizeof(int), matrix_size*matrix_size, mf);
	fclose(mf);

	return (written_items == (matrix_size*matrix_size) );
}
