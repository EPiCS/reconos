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
	unsigned int refcnt;
	int slot;
};

extern void init_loader(void);
extern int load_plugin(struct plugin *p);
extern void unload_plugin(struct plugin *p);
extern int plugin_present(const char *so_path);
extern void get_plugin(char *basename);
extern void put_plugin(char *basename);

#endif /* LOADER_H */
