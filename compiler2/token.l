%option noyywrap nounput noinput
%option case-insensitive

%{
#include "nlqp.tab.h"
#include <string.h>
#include <stdlib.h>
%}

%%
"show"              return SHOW;
"all"               return ALL;
"from"              return FROM;
"where"             return WHERE;
"create"            return CREATE;
"table"             return TABLE;
"with"              return WITH;
"columns"           return COLUMNS;
"column"            return COLUMN;
"add"               return ADD;
"to"                return TO;
"alter"             return ALTER;
"delete"            return DELETE_KW;
"remove"            return DELETE_KW;
"insert"            return INSERT;
"into"              return INTO;
"values"            return VALUES;
"order"             return ORDER;
"by"                return BY;
"ascending"|"asc"   return ASC;
"descending"|"desc" return DESC;
"limit"             return LIMIT;
"top"               return LIMIT;
"drop"              return DROP;

"int"|"integer"     return INT_TYPE;
"varchar"|"text"|"string" return VARCHAR_TYPE;
"greater"           return GREATER;
"less"              return LESS;
"than"              return THAN;
"equal"|"equals"|"is" return EQUAL;
"not"               return NOT;
"and"               return AND;
"or"                return OR;

","                 return COMMA;

[0-9]+              { yylval.num = atoi(yytext); return NUMBER; }
\'[^\']*\'          { yytext[yyleng - 1] = '\0'; yylval.str = strdup(yytext + 1); return STRING; }
\"[^\"]*\"          { yytext[yyleng - 1] = '\0'; yylval.str = strdup(yytext + 1); return STRING; }

[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); return IDENTIFIER; }

[ \t\n\r]+          ;  /* skip whitespace */
.                   ;  /* silently skip unknown/punctuation characters instead of polluting stdout */
%%
