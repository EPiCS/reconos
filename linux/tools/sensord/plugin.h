/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef PLUGIN_H
#define PLUGIN_H

enum plugin_type {
	TYPE_SIGNED,
	TYPE_UNSIGNED,
	TYPE_FLOAT,
	TYPE_BOOL,
};

struct plugin_instance {
	char *name;                     /* unique instance name */
	char *basename;                 /* basename of plugin */
	enum plugin_type type;          /* plugin data type */
	void (*fetch)(struct plugin_instance *self);    /* callback function */
	void *private_data;             /* plugin-private data */
	unsigned long schedule_int;     /* scheduling interval in us */
	struct timeval last;            /* last time instance called fetch */
	/* TODO: rrd descriptor */
};

extern int register_plugin_instance(struct plugin_instance *pi,
				    char *basename, unsigned long schedule_int);
extern void unregister_plugin_instance(struct plugin_instance *pi);

#endif /* PLUGIN_H */
