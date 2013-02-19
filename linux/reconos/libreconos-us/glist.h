///
/// \file glist.h
/// Generic list implementation header file.
/// \author     Sebastian Meisner   <sebastian.meisner@upb.de>
/// \date       06.07.2011
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2011.
//

#ifndef GLIST_H_
#define GLIST_H_

struct glist {
	struct glist * next;
	void * data;
};
typedef struct glist glist_t;


// Utility functions
unsigned int glist_length(const glist_t *list);
int glist_find(const glist_t * list, void * item); // returns index on success and -1 on failure
glist_t * glist_findf(const glist_t * list, int (*is_equal)(void*a, void*b), void *item_to_find); // intended to search the list for arbitrary keys

// Getting/Setting Items functions
void * glist_add_front( glist_t ** list, void * item );
void * glist_add_back( glist_t ** list, void * item );
void * glist_get_index( glist_t **list, unsigned int index );
void * glist_remove_index( glist_t ** list, unsigned int index );
void * glist_remove_item( glist_t ** list, void * item );
void   glist_remove_list( glist_t ** list, void (*delete_data)(void * item) );
void   glist_remove_tail( glist_t * list_element, void delete_data(void * item) );
void * glist_remove_next( glist_t * list_element );

// Efficient handling of list elements
void * glist_get_data(const glist_t * le);
glist_t * glist_get_next(const glist_t * le);
glist_t * glist_insert_after(glist_t * le, void * item);

// Algorithms on lists
void glist_apply(glist_t * list, void (*func)(void * data, void * state), void * state);
int  glist_is_sublist(glist_t * longer, glist_t * shorter, int (*is_equal)(void*a, void*b));

#endif /* GLIST_H_ */
