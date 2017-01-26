///
/// \file glist.c
/// Generic list implementation file.
/// \author     Sebastian Meisner   <sebastian.meisner@upb.de>
/// \date       06.07.2011
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2011.
//

#include <stdlib.h>
#include "glist.h"


unsigned int glist_length(const glist_t *list){
	unsigned int length = 0;
	for ( ; list != NULL; list = list->next) {
		length++;
	}
	return length;
}

int glist_find(const glist_t * list, void * item){
    int i=0;

    for ( ; list != NULL; list = list->next) {
        if (list->data == item) { return i;}
        i++;
    }
    return -1;
}

glist_t * glist_findf(const glist_t * list, int (*is_equal)(void*a, void*b), void *item_to_find){
	for ( ; list != NULL; list = list->next) {
		if ( is_equal(list->data, item_to_find) != 0 ) { return (glist_t *)list;}
	}
	return NULL;
}

void * glist_add_front(glist_t ** list, void * item){
	glist_t * tempptr = NULL;
	glist_t * newptr  = NULL;

	if ( (item != NULL) && ( newptr = malloc(sizeof(glist_t)) ) != NULL  ){
		tempptr = *list;
		*list = newptr;
		(*list)->next = tempptr;
		(*list)->data = item;
		return item;
	} else {
		return NULL;
	}
}

void * glist_add_back(glist_t ** list, void * item){
	glist_t * newptr;
	glist_t * runptr;

	if((list!=NULL) && (item!=NULL)){
		runptr = *list;
	}else{
		return NULL;
	}
	while(runptr->next){
		runptr = runptr->next;
	}
	if ((newptr = malloc(sizeof(glist_t)))){
		runptr->next = newptr;
		newptr->next = NULL;
		newptr->data = item;
		return item;
	} else {
		return NULL;
	}
}

void * glist_get_index(glist_t **list, unsigned int index){
	unsigned int tmp_index=0;
	const glist_t * tmp_list = *list;

	while(tmp_list != NULL && index != tmp_index){
		tmp_list = tmp_list->next;
		tmp_index++;
	}
	return tmp_list?tmp_list->data:NULL;
}

void * glist_remove_index(glist_t ** list, unsigned int index){
	glist_t * removeptr;
	glist_t ** runptr;
	void * tmp_data;
	unsigned int i = 0;

	if ( (list!=NULL) && (*list!=NULL) ){
		runptr = list;
		while(index != i){
			if((*runptr)->next){
				i++;
				runptr = &((*runptr)->next);
			}else{
				return NULL;
			}
		}
		removeptr = *runptr;
		*runptr = (*runptr)->next;
		tmp_data = removeptr->data;
		free(removeptr);
		return tmp_data;
	} else {
		return NULL;
	}
}

void * glist_remove_item(glist_t ** list, void * item){
	glist_t * removeptr;
	glist_t ** runptr;
	void * tmp_data;

	if ( (list!=NULL) && (*list!=NULL) && (item!=NULL) ){
		runptr = list;
		while((*runptr)->data != item){
			if((*runptr)->next){
				runptr = &((*runptr)->next);
			}else{
				return NULL;
			}
		}
		removeptr = *runptr;
		*runptr = (*runptr)->next;
		tmp_data = removeptr->data;
		free(removeptr);
		return tmp_data;
	} else {
		return NULL;
	}
}

// Delete whole list. list has to be the list anchor, not an element of the list.
// The delete_data() function is necessary if your elements have pointers to
// data, which has to be deleted. If delete_data() is NULL, we call free(data)
// on the data pointer of every item in the list.
void glist_remove_list(glist_t ** list, void delete_data(void * item)){
	if(delete_data){
		while( (list!=NULL) && (*list!=NULL) ){
			delete_data(glist_remove_index(list, 0));
		}
	} else {
		while( (list!=NULL) && (*list!=NULL) ){
			free(glist_remove_index(list, 0));
		}
	}
}

//
// Delete tail of list starting with the element after list_element.
// In contrast to glist_remove_list you can call this
// function on a list element.
//
void glist_remove_tail( glist_t * list_element, void delete_data(void * item) ){
	if(delete_data){
		while(list_element != NULL){
			delete_data(glist_remove_next(list_element));
		}
	} else {
		while(list_element != NULL){
			free(glist_remove_next(list_element));
		}
	}
}

//
// Removes element after list_element from list and returns pointer to data.
// User has to free data from heap.
//
void * glist_remove_next( glist_t * list_element ){
	glist_t * le;
	void * data;
	if ( list_element ){
		le = list_element->next;
		data = list_element->next->data;
		list_element->next = list_element->next->next;
		free(le);
		return data;
	} else {
		return NULL;
	}
}

void * glist_get_data(const glist_t * le){
    return le?le->data:NULL;
}

glist_t * glist_get_next(const glist_t * le){
	return le?le->next:NULL;
}

glist_t * glist_insert_after(glist_t * le, void * item){
	glist_t * tmp_le;
	glist_t * tmp_le2;

	tmp_le  = le->next;
	tmp_le2 = malloc(sizeof(glist_t));
	if ( (item != NULL) && (tmp_le2 != NULL) ) {
		le->next = tmp_le2;
		tmp_le2->next = tmp_le;
		tmp_le2->data = item;
		return item;
	}else {
		return NULL;
	}
}


void glist_apply(glist_t * list, void (*func)(void * data, void * state), void * state){
	if( (list!=NULL) && (func!=NULL) ){
		while(list){
			func(glist_get_data(list), state);
			list = glist_get_next(list);
		}
	}
}

// Assumptions:
// - longer list may have extra elements at the beginning an end!
// - the rest of elements have to be equal until the end of the shorter list
// - is_equal() has to return 1 if data is equal and 0 if data is not equal
int glist_is_sublist(glist_t * longer, glist_t * shorter, int (*is_equal)(void*a, void*b)){
	// Skip elements of longer list until first match is found
	while( (longer!=NULL) && (is_equal(glist_get_data(longer), glist_get_data(shorter)) == 0) ){
		longer = glist_get_next(longer);
	}

	// Assure that the rest of the list is equal
	while(is_equal(glist_get_data(longer), glist_get_data(shorter)) != 0){
		longer  = glist_get_next(longer);
		shorter = glist_get_next(shorter);
	}

	if(shorter == NULL){
		return 1;
	}else{
		return 0;
	}
}
