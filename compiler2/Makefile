# Builds the natural-language -> SQL compiler.
# Produces ./nlqp (no .exe suffix - this is a POSIX binary meant to
# run on whatever Linux container/host the server runs on).

CC = gcc
CFLAGS = -O2 -Wall

all: nlqp

nlqp: nlqp.tab.c lex.yy.c main.c
	$(CC) $(CFLAGS) -o nlqp main.c nlqp.tab.c lex.yy.c -lfl

nlqp.tab.c nlqp.tab.h: nlqp.y
	bison -d nlqp.y

lex.yy.c: token.l nlqp.tab.h
	flex token.l

clean:
	rm -f nlqp nlqp.tab.c nlqp.tab.h lex.yy.c nlqp.output

.PHONY: all clean
