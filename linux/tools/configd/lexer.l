/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "parser.tab.h"
#include "xutils.h"

extern void yyerror(const char *);

%}

%option align
%option nounput
%option noyywrap
%option noreject
%option 8bit
%option caseless
%option noinput
%option nodefault

%%

"foo"			{ return K_FOO; }
"/*"([^\*]|\*[^/])*"*/" { return K_COMMENT; }

";"[^\n]*	{/* NOP */}
"\n"		{ yylineno++; }
[ \t]+		{/* NOP */ }
.		{ printf("Unknown character '%s'", yytext);
		  yyerror("lex Unknown character"); }

%%
