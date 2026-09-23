%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);

char output_sql[2048];
static char condition_buf[1024];
%}

%union {
    char* str;
    int   num;
}

%token SHOW ALL FROM WHERE IS GREATER LESS THAN EQUAL NOT AND OR
%token CREATE TABLE COLUMNS COLUMN WITH ADD TO ALTER
%token SELECT INSERT INTO VALUES UPDATE SET DELETE
%token ORDER BY ASC DESC LIMIT
%token INT_TYPE VARCHAR_TYPE
%token <str> IDENTIFIER STRING
%token <num> NUMBER

%type <str> value comparator condition_expr column_def column_defs
%type <str> order_dir

%left OR
%left AND
%right NOT

%%

query:
      show_query
    | create_query
    | alter_query
    | select_query
    | insert_query
    | update_query
    | delete_query
    ;

/* ---------- SHOW ---------- */
show_query:
    SHOW ALL FROM IDENTIFIER WHERE condition_expr {
        snprintf(output_sql, sizeof(output_sql),
                 "SELECT * FROM %s WHERE %s;", $4, $6);
        free($4); free($6);
    }
    | SHOW ALL FROM IDENTIFIER {
        snprintf(output_sql, sizeof(output_sql),
                 "SELECT * FROM %s;", $4);
        free($4);
    }
    | SHOW ALL FROM IDENTIFIER ORDER BY IDENTIFIER order_dir {
        snprintf(output_sql, sizeof(output_sql),
                 "SELECT * FROM %s ORDER BY %s %s;", $4, $7, $8);
        free($4); free($7); free($8);
    }
    | SHOW ALL FROM IDENTIFIER WHERE condition_expr ORDER BY IDENTIFIER order_dir {
        snprintf(output_sql, sizeof(output_sql),
                 "SELECT * FROM %s WHERE %s ORDER BY %s %s;", $4, $6, $9, $10);
        free($4); free($6); free($9); free($10);
    }
    ;

order_dir:
      ASC   { $$ = strdup("ASC"); }
    | DESC  { $$ = strdup("DESC"); }
    | /* empty */ { $$ = strdup("ASC"); }
    ;

/* ---------- SELECT (alias of show) ---------- */
select_query:
    SELECT ALL FROM IDENTIFIER WHERE condition_expr {
        snprintf(output_sql, sizeof(output_sql),
                 "SELECT * FROM %s WHERE %s;", $4, $6);
        free($4); free($6);
    }
    | SELECT ALL FROM IDENTIFIER {
        snprintf(output_sql, sizeof(output_sql),
                 "SELECT * FROM %s;", $4);
        free($4);
    }
    ;

/* ---------- CREATE ---------- */
create_query:
    CREATE TABLE IDENTIFIER WITH COLUMNS column_defs {
        snprintf(output_sql, sizeof(output_sql),
                 "CREATE TABLE %s (%s);", $3, $6);
        free($3); free($6);
    }
    ;

/* ---------- ALTER ---------- */
alter_query:
    ALTER TABLE IDENTIFIER ADD COLUMN column_def TO IDENTIFIER {
        snprintf(output_sql, sizeof(output_sql),
                 "ALTER TABLE %s ADD COLUMN %s;", $3, $6);
        free($3); free($6); free($8);
    }
    | ALTER TABLE IDENTIFIER ADD COLUMN column_def {
        snprintf(output_sql, sizeof(output_sql),
                 "ALTER TABLE %s ADD COLUMN %s;", $3, $6);
        free($3); free($6);
    }
    ;

/* ---------- INSERT ---------- */
insert_query:
    INSERT INTO IDENTIFIER VALUES value {
        snprintf(output_sql, sizeof(output_sql),
                 "INSERT INTO %s VALUES (%s);", $3, $5);
        free($3); free($5);
    }
    ;

/* ---------- UPDATE ---------- */
update_query:
    UPDATE IDENTIFIER SET IDENTIFIER EQUAL value WHERE condition_expr {
        snprintf(output_sql, sizeof(output_sql),
                 "UPDATE %s SET %s = %s WHERE %s;", $2, $4, $6, $8);
        free($2); free($4); free($6); free($8);
    }
    ;

/* ---------- DELETE ---------- */
delete_query:
    DELETE FROM IDENTIFIER WHERE condition_expr {
        snprintf(output_sql, sizeof(output_sql),
                 "DELETE FROM %s WHERE %s;", $3, $5);
        free($3); free($5);
    }
    | DELETE ALL FROM IDENTIFIER {
        snprintf(output_sql, sizeof(output_sql),
                 "DELETE FROM %s;", $4);
        free($4);
    }
    ;

/* ---------- conditions ---------- */
condition_expr:
    IDENTIFIER comparator value {
        snprintf(condition_buf, sizeof(condition_buf), "%s %s %s", $1, $2, $3);
        $$ = strdup(condition_buf);
        free($1); free($2); free($3);
    }
    | NOT condition_expr {
        snprintf(condition_buf, sizeof(condition_buf), "NOT (%s)", $2);
        $$ = strdup(condition_buf);
        free($2);
    }
    | condition_expr AND condition_expr {
        snprintf(condition_buf, sizeof(condition_buf), "(%s AND %s)", $1, $3);
        $$ = strdup(condition_buf);
        free($1); free($3);
    }
    | condition_expr OR condition_expr {
        snprintf(condition_buf, sizeof(condition_buf), "(%s OR %s)", $1, $3);
        $$ = strdup(condition_buf);
        free($1); free($3);
    }
    ;

comparator:
      GREATER THAN      { $$ = strdup(">"); }
    | LESS THAN         { $$ = strdup("<"); }
    | EQUAL             { $$ = strdup("="); }
    | NOT EQUAL         { $$ = strdup("!="); }
    | IS EQUAL          { $$ = strdup("="); }
    | IS NOT            { $$ = strdup("!="); }
    ;

value:
    NUMBER {
        char buffer[32];
        snprintf(buffer, sizeof(buffer), "%d", $1);
        $$ = strdup(buffer);
    }
    | STRING {
        char quoted[512];
        snprintf(quoted, sizeof(quoted), "'%s'", $1);
        $$ = strdup(quoted);
        free($1);
    }
    | IDENTIFIER {
        /* treat bare identifier as string literal for convenience */
        char quoted[512];
        snprintf(quoted, sizeof(quoted), "'%s'", $1);
        $$ = strdup(quoted);
        free($1);
    }
    ;

column_defs:
    column_defs column_def {
        char temp[1024];
        snprintf(temp, sizeof(temp), "%s, %s", $1, $2);
        $$ = strdup(temp);
        free($1); free($2);
    }
    | column_def {
        $$ = $1;
    }
    ;

column_def:
    IDENTIFIER INT_TYPE {
        char temp[128];
        snprintf(temp, sizeof(temp), "%s INT", $1);
        $$ = strdup(temp);
        free($1);
    }
    | IDENTIFIER VARCHAR_TYPE {
        char temp[128];
        snprintf(temp, sizeof(temp), "%s VARCHAR(255)", $1);
        $$ = strdup(temp);
        free($1);
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Parse error: %s\n", s);
}
