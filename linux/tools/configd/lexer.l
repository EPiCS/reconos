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

type_0		[a-z]
type_1		[a-z0-9_-]|\x2e
type		{type_0}+\x2e{type_1}+

%%

"^"		{ return '^'; }
";"		{ return ';'; }
"{"		{ return '{'; }
"}"		{ return '}'; }
" "		{ return ' '; }
"::"		{ return K_TYPE; }
"/*"([^\*]|\*[^/])*"*/" { /* NOP */ }
"#"[^\n]*	{/* NOP */}

{type}		{ yylval.val = xstrdup(yytext);
		  return K_TYPE_NAME; }

[a-z]+		{ yylval.val = xstrdup(yytext);
		  return K_VAR_NAME; }

"\n"		{ yylineno++; }
[ \t]+		{/* NOP */ }
.		{ printf("Unknown character '%s'", yytext);
		  yyerror("lex Unknown character"); }

%%
