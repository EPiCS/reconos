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

int compile_source(char *file, int verbose);

#define YYERROR_VERBOSE		0
#define YYDEBUG			0
#define YYENABLE_NLS		1
#define YYLTYPE_IS_TRIVIAL	1
#define ENABLE_NLS		1

extern FILE *yyin;
extern int yylex(void);
extern void yyerror(const char *);
extern int yylineno;
extern char *yytext;

%}

%union {
	char *val;
	int foo;
}

%token K_TYPE K_TYPE_NAME K_VAR_NAME '^' '{' '}' ' '
%type <val> K_TYPE_NAME K_VAR_NAME

%%

prog
	: {}
	| prog line { }
	;

line
	: K_VAR_NAME white K_TYPE white K_TYPE_NAME
		{ printf("%s declared from %s\n", $1, $5); }
	| K_VAR_NAME white '^' white '{' white dependencies white '}'
		{ printf("blubb\n"); }
	;

white
	: {}
	| ' ' {}
	;

dependencies
	: {}
	| dependencies white K_VAR_NAME {}
	;

%%

static void stage_1(void)
{
	yyparse();
}

int compile_source(char *file, int verbose)
{
	yyin = fopen(file, "r");
	if (!yyin)
		panic("Cannot open file!\n");

	stage_1();

	fclose(yyin);
	return 0;
}

void yyerror(const char *err)
{
	panic("Syntax error at line %d: %s! %s!\n",
	      yylineno, yytext, err);
}
