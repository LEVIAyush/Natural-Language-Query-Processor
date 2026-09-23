#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yyparse(void);
extern void yy_scan_string(const char *);
extern char output_sql[];

int main(void) {
    char input[2048];

    if (fgets(input, sizeof(input), stdin) == NULL) {
        fprintf(stderr, "Failed to read input.\n");
        return 1;
    }

    /* strip trailing newline */
    size_t len = strlen(input);
    if (len > 0 && input[len - 1] == '\n') {
        input[len - 1] = '\0';
    }

    if (input[0] == '\0') {
        fprintf(stderr, "Empty query.\n");
        return 1;
    }

    yy_scan_string(input);

    if (yyparse() == 0 && output_sql[0] != '\0') {
        /* print only the SQL — frontend expects clean output */
        printf("%s\n", output_sql);
        return 0;
    } else {
        fprintf(stderr, "Parsing failed. Check your natural-language query.\n");
        return 1;
    }
}
