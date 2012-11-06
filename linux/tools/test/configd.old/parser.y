%{

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>

#include "xutils.h"
#include "parser.tab.h"

struct entry {
	char variable[64];
	char type[128];
	struct entry **children; // elements, we can be on top of
	size_t len;
	struct entry *tmp_parent;
};

int compile_source(char *file, int verbose);

#define YYERROR_VERBOSE		0
#define YYDEBUG			0
#define YYENABLE_NLS		1
#define YYLTYPE_IS_TRIVIAL	1
#define ENABLE_NLS		1

#define MAX_ENTRIES		256
#define QLEN			1024
#define SLEN			256

extern FILE *yyin;
extern int yylex(void);
extern void yyerror(const char *);
extern int yylineno;
extern char *yytext;

static struct entry table[MAX_ENTRIES];
static unsigned int used = 0;

static struct entry **tmp = NULL;
static size_t len = 0;

static int get_table_index(char *query)
{
	int i;

	for (i = 0; i < used; ++i) {
		if (!strncmp(table[i].variable, query,
			     sizeof(table[i].variable))) {
			return i;
		}
	}

	return -1;
}

static int get_table_type_index(char *query)
{
	int i;

	for (i = 0; i < used; ++i) {
		if (!strncmp(table[i].type, query,
			     sizeof(table[i].type))) {
			return i;
		}
	}

	return -1;
}

static inline void add_to_stack(struct entry *val, struct entry *stack[SLEN],
				size_t *len)
{
	if (*len >= SLEN)
		panic("Too much entries!\n");
	stack[*len] = val;
	(*len)++;
}

static inline void enqueue(struct entry *queue[QLEN], int *tail,
			   struct entry *elem)
{
	if (*tail+1>=QLEN)
		panic("Too big!\n");

	queue[*tail] = elem;
	(*tail)++;
}

static inline struct entry *dequeue(struct entry *queue[QLEN], int *tail)
{
	struct entry *ret = queue[0];
	struct entry *tmp[QLEN];

	if (*tail==0)
		return NULL;

	memcpy(tmp, &queue[1], (QLEN-1)*sizeof(struct entry *));
	memcpy(queue, tmp, QLEN*sizeof(struct entry *));

	(*tail)--;

	return ret;
}

static void __get_dependencies(int from_upper, int to_lower,
			       struct entry *stack[SLEN], size_t *len)
{
	int tail1 = 0, tail2 = 0, i;
	struct entry *queue1[QLEN], *queue2[QLEN], *tmp, *found = NULL;

	table[from_upper].tmp_parent = NULL;
	enqueue(queue1, &tail1, &table[from_upper]);

	while (1) {
		while ((tmp = dequeue(queue1, &tail1)) != NULL) {
			for (i = 0; i < tmp->len; ++i) {
				tmp->children[i]->tmp_parent = tmp;
				if (tmp->children[i] == &table[to_lower]) {
					found = tmp->children[i];
					goto done;
				}
				enqueue(queue2, &tail2, tmp->children[i]);
			}
		}
		memcpy(queue1, queue2, sizeof(queue2));
		tail1 = tail2;
		tail2 = 0;
	}
done:
	if (found) {
		add_to_stack(&table[to_lower], stack, len);
		while ((tmp = found->tmp_parent) != NULL) {
			add_to_stack(tmp, stack, len);
			found = tmp;
		}
	}
}

static void __copy_dependencies(struct entry *estack[SLEN], char ***stack,
				size_t *len)
{
	int i;

	if (*len >= SLEN)
		panic("Sth went wrong!\n");

	*stack = xzmalloc(sizeof(**stack) * (*len));
	for (i = (*len)-1; i >= 0; --i) {
		(*stack)[i] = xstrdup(estack[i]->type);
	}
}

int get_dependencies(char *from_upper, char *to_lower, char ***stack,
		     size_t *len)
{
	int idx_from, idx_to;
	struct entry *estack[SLEN];

	idx_from = get_table_type_index(from_upper);
	idx_to = get_table_type_index(to_lower);

	if (idx_from < 0)
		panic("Not in dependency list present: '%s'!\n", from_upper);
	if (idx_to < 0)
		panic("Not in dependency list present: '%s'!\n", to_lower);

	*len = 0;
	__get_dependencies(idx_from, idx_to, estack, len);
	__copy_dependencies(estack, stack, len);

	return *len;
}

%}

%union {
	char *val;
	int foo;
}

%token K_TYPE K_TYPE_NAME K_VAR_NAME '^' '{' '}' ' ' ';'
%type <val> K_TYPE_NAME K_VAR_NAME

%%

prog
	: {}
	| prog line { }
	;

line
	: K_VAR_NAME white K_TYPE white K_TYPE_NAME ';'
		{
			if (used + 1 > MAX_ENTRIES)
				panic("Too many entries!\n");

			strlcpy(table[used].variable, $1,
				sizeof(table[used].variable));
			strlcpy(table[used].type, $5,
				sizeof(table[used].type));

			table[used].children = NULL;
			table[used].len = 0;
			table[used].tmp_parent = NULL;

			used++;
		}
	| K_VAR_NAME white '^' white '{' dependencies white '}' ';'
		{
			int curr = get_table_index($1);
			if (curr < 0)
				panic("No such element ``%s''!\n", $1);
			table[curr].len = len;
			table[curr].children = tmp;
			tmp = NULL;
			len = 0;
		}
	;

white
	: ' ' {}
	;

dependencies
	: {}
	| dependencies white K_VAR_NAME
		{
			len++;
			tmp = xrealloc(tmp, len, sizeof(struct entry *));
			int curr = get_table_index($3);
			if (curr < 0)
				panic("No such element ``%s''!\n", $3);
			tmp[len - 1] = &table[curr];
		}
	;

%%

static void stage_1(void)
{
	yyparse();
}

int compile_source(char *file, int verbose)
{
	int i, j;

	yyin = fopen(file, "r");
	if (!yyin)
		panic("Cannot open file!\n");

	stage_1();

	for (i = 0; i < used && verbose; ++i) {
		printf("%s of type %s, depends: ",
		       table[i].variable, table[i].type);
		for (j = 0; j < table[i].len; ++j) {
			printf("%s ", table[i].children[j]->variable);
		}
		printf("%s\n", table[i].len == 0 ? "-" : "");
	}

	fclose(yyin);
	return 0;
}

void yyerror(const char *err)
{
	panic("Syntax error at line %d: %s! %s!\n",
	      yylineno, yytext, err);
}
