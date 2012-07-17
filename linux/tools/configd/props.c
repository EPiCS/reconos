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
	enum fblock_props props[MAX_PROPS];
	int prio;
};

#define MAX_ELEMS	1024

static struct prop_type table[MAX_ELEMS];
static size_t elems;
static struct mutexlock lock;

int find_type_by_properties(char name[FBNAMSIZ],
			    enum fblock_props needed[MAX_PROPS],
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
	int first = 1, i, j, stop;
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
			while (!stop && (j = strtoul(ptr, &nptr, 10))) {
				if (!nptr)
					break;
				if (i + 1 >= MAX_PROPS)
					panic("Too many properties!\n");
				table[elems].props[i++] = j;
				if (*nptr == ']')
					stop = 1;
				nptr++;
				ptr = nptr;
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
