#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yyparse(void);
extern void yy_scan_string(const char *);
extern char output_sql[];

/*
 * Contract with the Node server (server/index.js):
 *   - stdin:  one line, the natural-language query
 *   - stdout: exactly one of
 *       OK:<sql statement>
 *       ERR:<message>
 *   The OK:/ERR: prefix lets the server tell success from failure
 *   without relying on the process exit code alone, and without
 *   any risk of a stray printf("Unknown character...") (the old
 *   lexer did this) leaking into what's shown to the user as SQL.
 */

#define INPUT_BUF_SIZE 4096

int main(void) {
    char input[INPUT_BUF_SIZE];

    if (fgets(input, sizeof(input), stdin) == NULL) {
        printf("ERR:No input received\n");
        return 1;
    }

    yy_scan_string(input);

    if (yyparse() == 0 && output_sql[0] != '\0') {
        printf("OK:%s\n", output_sql);
    } else {
        printf("ERR:Could not understand that query. Try phrasing like "
               "\"show all from users where age greater than 30\".\n");
    }

    return 0;
}
