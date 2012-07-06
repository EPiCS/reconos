/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

%{

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>

#include "xutils.h"
#include "parser.tab.h"

struct entry {
	char variable[64];
	char type[64];
	struct entry **on_top_of;
	size_t len;
};

int compile_source(char *file, int verbose);

#define YYERROR_VERBOSE		0
#define YYDEBUG			0
#define YYENABLE_NLS		1
#define YYLTYPE_IS_TRIVIAL	1
#define ENABLE_NLS		1

#define MAX_ENTRIES		256

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

			table[used].on_top_of = NULL;
			table[used].len = 0;

			used++;
		}
	| K_VAR_NAME white '^' white '{' white dependencies white '}' ';'
		{
			int curr = get_table_index($1);
			if (curr < 0)
				panic("No such element ``%s''!\n", $1);
			table[curr].len = len;
			table[curr].on_top_of = tmp;
			tmp = NULL;
			len = 0;
		}
	;

white
	: {}
	| ' ' {}
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
			printf("%s ", table[i].on_top_of[j]->variable);
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
