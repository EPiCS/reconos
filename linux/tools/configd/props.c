#include <stdio.h>
#include <pthread.h>
#include <stdint.h>
#include <signal.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <linux/types.h>
#include <linux/netlink.h>
#include <linux/if.h>

#include "xt_vlink.h"
#include "xt_fblock.h"
#include "props.h"
#include "locking.h"
#include "xutils.h"

static pthread_t thread;

extern sig_atomic_t sigint;

struct prop_type {
	char name[FBNAMSIZ];
	int props[MAX_PROPS];
	int prio;
};

#define MAX_ELEMS	1024

static char *property_str_tab[MAX_ELEMS];
static struct prop_type table[MAX_ELEMS];
static size_t elems;
static struct mutexlock lock;

static inline void init_prop_str_tab(void)
{
	memset(property_str_tab, 0, sizeof(property_str_tab));
}

int prop_str_tab_get_idx(char *property)
{
	int idx = -1, i;
	for (i = 0; i < array_size(property_str_tab); ++i) {
		if (property_str_tab[i] == NULL)
			continue;
		if (!strcmp(property, property_str_tab[i])) {
			idx = i;
			break;
		}
	}
	return idx;
}

int prop_str_tab_put_idx(char *property)
{
	int idx = -1, i;
	for (i = 0; i < array_size(property_str_tab); ++i) {
		if (!strcmp(property_str_tab[i], property))
			return i;
		if (property_str_tab[i] != NULL)
			continue;
		property_str_tab[i] = xstrdup(property);
		idx = i;
		break;
	}
	return idx;
}

int fbtype_is_available(char name[FBNAMSIZ])
{
	int available = 0, i;

	mutexlock_lock(&lock);
	for (i = 0; i < elems; ++i) {
		if (!strncmp(table[i].name, name, sizeof(table[i].name))) {
			available = 1;
			break;
		}
	}
	mutexlock_unlock(&lock);

	return available;
}

int find_type_by_properties(char name[FBNAMSIZ],
			    int needed[MAX_PROPS],
			    size_t *num)
{
	size_t sat, sat_max = 0;
	int idx_max = -1, i, j, l, ret;

	if (*num <= 0)
		return -64;

	mutexlock_lock(&lock);
	for (i = 0; i < elems; ++i) {
		sat = 0;
		for (j = 0; j < MAX_PROPS; ++j) {
			if (table[i].props[j] == 0)
				continue;
			for (l = 0; l < MAX_PROPS; ++l) {
				if (needed[l] == 0)
					continue;
				if (needed[l] == table[i].props[j]) {
					sat++;
					if (sat > sat_max) {
						sat_max = sat;
						idx_max = i;
					}
				}
			}
		}
	}

	if (idx_max < 0) {
		mutexlock_unlock(&lock);
		return -64;
	}

	for (j = 0; j < MAX_PROPS; ++j) {
		if (table[idx_max].props[j] == 0)
			continue;
		for (l = 0; l < MAX_PROPS; ++l) {
			if (needed[l] == table[idx_max].props[j]) {
				needed[l] = 0;
				(*num)--;
			}
		}
	}

	strlcpy(name, table[idx_max].name, sizeof(table[idx_max].name));
	ret = table[idx_max].prio;

	mutexlock_unlock(&lock);

	return ret;
}

static void *property_fetcher(void *null)
{
	int first = 1, i, stop;
	FILE *fp;
	char buff[1024], *ptr, *nptr;
	char type[128];

	mutexlock_init(&lock);

	while (!sigint) {
		/* FIXME: HACK: extremly lame, do it better later on */

		mutexlock_lock(&lock);

		memset(table, 0, sizeof(table));
		elems = 0;
		first = 1;

		fp = fopen("/proc/net/lana/properties", "r");
		if (!fp)
			panic("LANA not running?\n");

		memset(buff, 0, sizeof(buff));
		while (fgets(buff, sizeof(buff), fp) != NULL) {
			buff[sizeof(buff) - 1] = 0;
			if (first) {
				first = 0;
				continue;
			}

			if (elems + 1 >= MAX_ELEMS)
				panic("Too many fblock instances!\n");

			memset(type, 0, sizeof(type));
			if (sscanf(buff, "%s [", type) != 1)
				continue;

			strlcpy(table[elems].name, type, sizeof(table[elems].name));

			i = stop = 0;
			ptr = strstr(buff, "[");
			ptr++;
			//XXX
			// prop_str_tab_put_idx(char*)
//			while (!stop && (j = strtoul(ptr, &nptr, 10))) {
			while (!stop) {
				//beginning: ptr
				//end: nptr
				nptr = ptr;
				while (*nptr != ' ' || *nptr != ']')
					nptr++;
				if (*nptr == ' ') {
					int tmp;
					*nptr = '\0';
					table[elems].props[i++] = tmp = prop_str_tab_put_idx(ptr);
					printd("Added %s (%d) to %s.\n",
						ptr, tmp, table[elems].name);
					ptr = nptr + 1;
				} else if (*nptr != ']') {
					stop = 1;
				}
//				if (!nptr)
//					break;
//				if (i + 1 >= MAX_PROPS)
//					panic("Too many properties!\n");
//				table[elems].props[i++] = j;
//				if (*nptr == ']')
//					stop = 1;
//				nptr++;
//				ptr = nptr;
			}

			table[elems].prio = strtol(ptr, &nptr, 10);
			memset(buff, 0, sizeof(buff));
			elems++;
		}

		fclose(fp);

		mutexlock_unlock(&lock);
		sleep(10);
	}

	mutexlock_destroy(&lock);
	pthread_exit(NULL);
}

void start_property_fetcher(void)
{
	init_prop_str_tab();
	int ret = pthread_create(&thread, NULL, property_fetcher, NULL);
	if (ret < 0)
		panic("Cannot create thread!\n");

	printd("Start property collector!\n");
}

void stop_property_fetcher(void)
{
	pthread_join(thread, NULL);

	printd("Stop property collector!\n");
}
