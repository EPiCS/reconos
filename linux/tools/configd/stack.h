/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef STACK_H
#define STACK_H

#include <stdio.h>

#define MAX_STR_LEN	128

struct stack_elem {
	char name[MAX_STR_LEN];
	char type[MAX_STR_LEN];

	struct stack_elem **bindings;
	size_t num_bindings;
};

struct stack_desc {
	struct stack_elem *start;
};

extern struct stack_desc *build_stack_on_the_fly(void);
extern void free_stack(struct stack_desc *stack);

#endif /* STACK */
