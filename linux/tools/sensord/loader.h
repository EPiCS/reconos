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
	int slot;
};

extern void init_loader(void);
extern int load_plugin(struct plugin *p);
extern void unload_plugin(struct plugin *p);
extern int plugin_present(const char *so_path);
extern void unload_all_plugins(void);

#endif /* LOADER_H */
