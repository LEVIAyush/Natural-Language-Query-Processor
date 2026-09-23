%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);

/* Generous, bounded scratch buffers. Every production writes with
   snprintf (never plain sprintf) so a long query can never overflow
   these buffers - it will just be truncated safely instead of
   corrupting memory. */
#define SQL_BUF_SIZE 4096
#define FRAG_BUF_SIZE 2048

char output_sql[SQL_BUF_SIZE];

static char *make_fragment(const char *fmt, ...);
%}

%union {
    char* str;
    int num;
}

%token SHOW ALL FROM WHERE IS GREATER LESS THAN EQUAL NOT AND OR
%token CREATE TABLE COLUMNS COLUMN WITH ADD TO ALTER
%token DELETE_KW INSERT INTO VALUES ORDER BY ASC DESC LIMIT DROP COMMA
%token INT_TYPE VARCHAR_TYPE
%token <str> IDENTIFIER STRING
%token <num> NUMBER

%type <str> value comparator condition_expr column_def column_defs
%type <str> value_list opt_where opt_order opt_limit order_dir

%%

query:
    SHOW ALL FROM IDENTIFIER opt_where opt_order opt_limit {
        snprintf(output_sql, SQL_BUF_SIZE, "SELECT * FROM %s%s%s%s;", $4, $5, $6, $7);
    }
    |
    CREATE TABLE IDENTIFIER WITH COLUMNS column_defs {
        snprintf(output_sql, SQL_BUF_SIZE, "CREATE TABLE %s (%s);", $3, $6);
    }
    |
    ALTER TABLE IDENTIFIER ADD COLUMN column_def TO IDENTIFIER {
        snprintf(output_sql, SQL_BUF_SIZE, "ALTER TABLE %s ADD COLUMN %s;", $3, $6);
    }
    |
    DELETE_KW FROM IDENTIFIER opt_where {
        snprintf(output_sql, SQL_BUF_SIZE, "DELETE FROM %s%s;", $3, $4);
    }
    |
    INSERT INTO IDENTIFIER VALUES value_list {
        snprintf(output_sql, SQL_BUF_SIZE, "INSERT INTO %s VALUES (%s);", $3, $5);
    }
    |
    DROP TABLE IDENTIFIER {
        snprintf(output_sql, SQL_BUF_SIZE, "DROP TABLE %s;", $3);
    }
;

opt_where:
    WHERE condition_expr { $$ = make_fragment(" WHERE %s", $2); }
    | /* empty */         { $$ = make_fragment(""); }
;

opt_order:
    ORDER BY IDENTIFIER order_dir { $$ = make_fragment(" ORDER BY %s%s", $3, $4); }
    | /* empty */                 { $$ = make_fragment(""); }
;

order_dir:
    ASC           { $$ = make_fragment(" ASC"); }
    | DESC        { $$ = make_fragment(" DESC"); }
    | /* empty */ { $$ = make_fragment(""); }
;

opt_limit:
    LIMIT NUMBER  { $$ = make_fragment(" LIMIT %d", $2); }
    | /* empty */ { $$ = make_fragment(""); }
;

condition_expr:
    IDENTIFIER comparator value {
        $$ = make_fragment("%s %s %s", $1, $2, $3);
    }
    |
    NOT condition_expr {
        $$ = make_fragment("NOT (%s)", $2);
    }
    |
    condition_expr AND condition_expr {
        $$ = make_fragment("(%s AND %s)", $1, $3);
    }
    |
    condition_expr OR condition_expr {
        $$ = make_fragment("(%s OR %s)", $1, $3);
    }
;

comparator:
    GREATER THAN      { $$ = strdup(">"); }
    |
    LESS THAN         { $$ = strdup("<"); }
    |
    EQUAL             { $$ = strdup("="); }
    |
    NOT EQUAL         { $$ = strdup("!="); }
;

value:
    NUMBER {
        $$ = make_fragment("%d", $1);
    }
    |
    STRING {
        $$ = make_fragment("'%s'", $1);
    }
;

value_list:
    value_list COMMA value {
        $$ = make_fragment("%s, %s", $1, $3);
    }
    |
    value {
        $$ = strdup($1);
    }
;

column_defs:
    column_defs COMMA column_def {
        $$ = make_fragment("%s, %s", $1, $3);
    }
    |
    column_def {
        $$ = strdup($1);
    }
;

column_def:
    IDENTIFIER INT_TYPE {
        $$ = make_fragment("%s INT", $1);
    }
    |
    IDENTIFIER VARCHAR_TYPE {
        $$ = make_fragment("%s VARCHAR(255)", $1);
    }
;

%%

#include <stdarg.h>

/* Formats into a fresh heap buffer every time (instead of one shared
   global scratch buffer) so nested/recursive rules never stomp on
   each other's partial results. Caller does not need to free it -
   this is a short-lived CLI process, so we accept the small leak in
   exchange for correctness and simplicity. */
static char *make_fragment(const char *fmt, ...) {
    char *buf = malloc(FRAG_BUF_SIZE);
    if (!buf) {
        fprintf(stderr, "Out of memory\n");
        exit(1);
    }
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, FRAG_BUF_SIZE, fmt, args);
    va_end(args);
    return buf;
}

void yyerror(const char *s) {
    fprintf(stderr, "Parse error: %s\n", s);
}
