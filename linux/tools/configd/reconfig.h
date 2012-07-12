/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef RECONFIG_H
#define RECONFIG_H

extern int get_dependencies(char *from, char *to, char **stack, size_t len);

extern void setup_initial_stack(void);
extern void cleanup_stack(void);

extern void insert_elem_to_stack(char *type, char *name, size_t len);
extern void insert_and_bind_elem_to_stack(char *type, int prio, char *name,
					  size_t len);
extern void remove_elem_from_stack(char *name);
extern void bind_elems_in_stack(char *name1, char *name2);
extern void unbind_elems_in_stack(char *name1, char *name2);
extern void setopt_of_elem_in_stack(char *name, char *opt, size_t len);

extern void reconfig_notify_reliability(int type);
extern void reconfig_reliability(void);

#endif /* RECONFIG_H */
