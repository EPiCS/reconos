/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <limits.h>

#ifndef likely
# define likely(x) __builtin_expect(!!(x), 1)
#endif
#ifndef unlikely
# define unlikely(x) __builtin_expect(!!(x), 0)
#endif

#define MAX_STR_LEN	128
#define MAX_BINDING	64
#define MAX_ELEMS	256

struct graph_node {
	char name[MAX_STR_LEN];
	char type[MAX_STR_LEN];
	unsigned int idp;
	unsigned int bindings[MAX_BINDING];
};

static struct graph_node table[MAX_ELEMS];
static size_t elems;

/* Copyright 1991, 1992 Linus Torvalds <torvalds@linux-foundation.org> */
static size_t strlcpy(char *dest, const char *src, size_t size)
{
	size_t ret = strlen(src);
	if (size) {
		size_t len = (ret >= size) ? size - 1 : ret;
		memcpy(dest, src, len);
		dest[len] = '\0';
	}
	return ret;
}

static inline void die(void)
{
	exit(EXIT_FAILURE);
}

static inline void panic(char *msg, ...)
{
	va_list vl;

	va_start(vl, msg);
	vfprintf(stderr, msg, vl);
	va_end(vl);

	die();
}

static void check_for_root_maybe_die(void)
{
	if (geteuid() != 0 || geteuid() != getuid())
		panic("Uhhuh, not root?! \n");
}

int main(void)
{
	int first = 1, i, j;
	FILE *fp;
	char bindings[MAX_STR_LEN], name[MAX_STR_LEN], type[MAX_STR_LEN];
	char buff[1024], *ptr, *nptr;
	unsigned int idp;

	check_for_root_maybe_die();

	fp = fopen("/proc/net/lana/fblocks", "r");
	if (!fp)
		panic("LANA not running?\n");

	elems = 0;
	memset(table, 0, sizeof(table));
	memset(buff, 0, sizeof(buff));
	while (fgets(buff, sizeof(buff), fp) != NULL) {
		buff[sizeof(buff) - 1] = 0;
		if (first) {
			first = 0;
			continue;
		}

		if (elems + 1 >= MAX_ELEMS)
			panic("Too many fblock instances!\n");

		memset(bindings, 0, sizeof(bindings));
		memset(name, 0, sizeof(name));
		memset(type, 0, sizeof(type));

		if (sscanf(buff, "%s %s %*x %u %*u [%s] ", name, type,
			   &idp, bindings) != 4)
			continue;

		strlcpy(table[elems].name, name, sizeof(table[elems].name));
		strlcpy(table[elems].type, type, sizeof(table[elems].type));
		table[elems].idp = idp;

		i = 0;
		bindings[strlen(bindings) - 1] = 0;
		ptr = bindings;
		while ((j = strtoul(ptr, &nptr, 10))) {
			if (!nptr)
				break;
			table[elems].bindings[i++] = j;
			ptr = nptr;
		}

		memset(buff, 0, sizeof(buff));
		elems++;
	}

	fclose(fp);

	printf("# run with e.g. fbviz | dot -Tpng > test.png\n");
	printf("digraph G\n{\n");
	printf("  node [shape = record];\n");
	for (i = 0; i < elems; ++i) {
		printf("  node%u [ label = \"<e> %s:%s\" ];\n",
		       table[i].idp, table[i].name, table[i].type);
		for (j = 0; j < MAX_BINDING; ++j) {
			if (table[i].bindings[j] != 0) {
				printf("  \"node%u\":e -> \"node%u\":e;\n",
				       table[i].idp, table[i].bindings[j]);
			}
		}
	}
	printf("}\n");

	return 0;
}
