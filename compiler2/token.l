%{
#include "nlqp.tab.h"
#include <string.h>
%}

%option noyywrap
%option case-insensitive

%%

"show"              { return SHOW; }
"all"               { return ALL; }
"from"              { return FROM; }
"where"             { return WHERE; }
"create"            { return CREATE; }
"table"             { return TABLE; }
"with"              { return WITH; }
"columns"           { return COLUMNS; }
"column"            { return COLUMN; }
"add"               { return ADD; }
"to"                { return TO; }
"alter"             { return ALTER; }
"select"            { return SELECT; }
"insert"            { return INSERT; }
"into"              { return INTO; }
"values"            { return VALUES; }
"update"            { return UPDATE; }
"set"               { return SET; }
"delete"            { return DELETE; }
"order"             { return ORDER; }
"by"                { return BY; }
"asc"               { return ASC; }
"desc"              { return DESC; }
"limit"             { return LIMIT; }

"int"               { return INT_TYPE; }
"integer"           { return INT_TYPE; }
"varchar"           { return VARCHAR_TYPE; }
"string"            { return VARCHAR_TYPE; }
"text"              { return VARCHAR_TYPE; }

"greater"           { return GREATER; }
"less"              { return LESS; }
"than"              { return THAN; }
"equal"             { return EQUAL; }
"equals"            { return EQUAL; }
"not"               { return NOT; }
"and"               { return AND; }
"or"                { return OR; }
"is"                { return IS; }

[0-9]+              { yylval.num = atoi(yytext); return NUMBER; }

\'[^\']*\'          {
                        yytext[yyleng - 1] = '\0';
                        yylval.str = strdup(yytext + 1);
                        return STRING;
                    }

\"[^\"]*\"          {
                        yytext[yyleng - 1] = '\0';
                        yylval.str = strdup(yytext + 1);
                        return STRING;
                    }

[a-zA-Z_][a-zA-Z0-9_]*  {
                            yylval.str = strdup(yytext);
                            return IDENTIFIER;
                        }

[ \t\n\r]+          ;   /* skip whitespace */

.                   { /* ignore unknown single chars quietly */ }

%%
