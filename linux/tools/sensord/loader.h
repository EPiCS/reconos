/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef LOADER_H
#define LOADER_H

struct plugin {
	char *so_path;
	char *basename;
	void *sym_fd;
	int (*fn_init)(void);
	void (*fn_exit)(void);
};

extern int load_plugin(struct plugin *p);
extern void unload_plugin(struct plugin *p);

#endif /* LOADER_H */
