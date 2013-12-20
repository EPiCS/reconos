#include "mergesort.h"
#include <stdlib.h>
#include <string.h>

static void merge(unsigned int * a, unsigned int * b, unsigned int * result,
                unsigned int block_words)
{
	int ai, bi, i;

	ai = bi = 0;

	for(i = 0; i < block_words; i++){
		if(ai >= block_words) result[i] = b[bi++];
		else if(bi >= block_words) result[i] = a[ai++];
		else {
			if(a[ai] < b[bi]) result[i] = a[ai++];
			else result[i] = b[bi++];
		}
	}
}

void mergesort(unsigned int * data, unsigned int * result, int num_blocks, int block_words)
{
	unsigned int *p, *q;

	p = data;
	q = result;

	while(num_blocks > 1){
		unsigned int * tmp;
		int i;
		for(i = 0; i < num_blocks; i += 2){
			merge(p + i*block_words, p + (i + 1)*block_words, q + i*block_words, block_words);
		}
		num_blocks = num_blocks/2;
		block_words = block_words*2;
		tmp = p; p = q; q = tmp;
	}

	if(p != result) memcpy(result,p,num_blocks*block_words*sizeof*result);
}
