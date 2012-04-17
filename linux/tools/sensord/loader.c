/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

/* -ldl */

#include <stdio.h>
#include <dlfcn.h>
#include <stdlib.h>

int main(void)
{
	char *error;
	int (*fn_init)(void);
	void (*fn_exit)(void);
	void *lfd;

	lfd = dlopen("plugins/dummy.so.1.0", RTLD_LAZY);
	if (!lfd) {
		fprintf(stderr, "Failed to open lib!\n");
		exit(1);
	}

	fn_init = dlsym(lfd, "plugin_init_fn");
	if ((error = dlerror()) != NULL) {
		fprintf(stderr, "%s\n", error);
		exit(1);
	}

	fn_exit = dlsym(lfd, "plugin_exit_fn");
	if ((error = dlerror()) != NULL) {
		fprintf(stderr, "%s\n", error);
		exit(1);
	}

	(*fn_init)();
	(*fn_exit)();

	dlclose(lfd);
	return 0;
}
