#ifndef RECONFIG_H
#define RECONFIG_H

extern void init_reconfig(char *upper_name, char *upper_type,
			  char *lower_name, char *lower_type);

extern void cleanup_pipeline(void);

extern void setup_initial_stack(void);
extern void cleanup_stack(void);

extern void insert_and_bind_elem_to_stack(char *type, char *name, size_t len);
extern void remove_and_unbind_elem_from_stack(char *name, size_t len);

extern void insert_elem_to_stack(char *type, char *name, size_t len);
extern void remove_elem_from_stack(char *name);
extern void bind_elems_in_stack(char *name1, char *name2);
extern void unbind_elems_in_stack(char *name1, char *name2);
extern void setopt_of_elem_in_stack(char *name, char *opt, size_t len);

extern void reconfig_notify_reliability(int type);
extern void reconfig_reliability(void);

extern void get_dependencies(char *from_upper, char *to_lower, char ***stack,
			     size_t *len);

#endif /* RECONFIG_H */
