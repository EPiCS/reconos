/*
 * main.c
 *
 *  Created on: 07.12.2012
 *      Author: meise
 */

#include <stdio.h>
#include <stdlib.h>

#include "eif.h"

#define TESTDATA_SIZE 1024

int foo(int a, int b) {
	int i = 0;
	int r = 0;
	for (i=0; i< b; i++){
		r+= a++%b;
	}
	return r;
}

int main(int argc, char** argv){
	unsigned int i,j;
	unsigned char testdata[TESTDATA_SIZE];
	int foo_result;

	// Fill testdata
	for ( i = 0; i<TESTDATA_SIZE; i++){
		testdata[i]=i;
	}

	// Print testdata;
	for ( i = 0; i<TESTDATA_SIZE; i++){
			printf("%5i",testdata[i]);
			if( i%16 == 15 ) {printf("\n");}
	}

	// Setup error injection
	//eif_add(testdata,TESTDATA_SIZE, 10, 1000, 5000, SET_VALUE,0);
	if(eif_add_trans(foo,65, 2, 1000, 5000, SINGLE_BIT_FLIP,0)!=0){
		printf("Can't change permissions for memory area beginning at %8p.\n", foo);
	}
	eif_start();

	printf("\nError Injection started!\n\n");

	eif_join();
	// Check testdata;
	j=0;
	for ( i = 0; i<TESTDATA_SIZE; i++){
		if (testdata[i] != (i%256)){
			printf("Error #%04i at %5i : %5i\n",j++, i, testdata[i]);
		}
	}

	// Check testfunction
	foo_result = foo(123,17); // result should be 136
	printf("Function foo() says: %i\n", foo_result);
	printf("Result is %s \n", foo_result==136?"correct":"wrong");

	return 0;
}
