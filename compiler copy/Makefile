CC      = gcc
CFLAGS  = -Wall -O2
LEX     = flex
YACC    = bison

TARGET  = nlqp

.PHONY: all clean

all: $(TARGET)

$(TARGET): main.c nlqp.tab.c lex.yy.c
	$(CC) $(CFLAGS) -o $(TARGET) main.c nlqp.tab.c lex.yy.c -lfl

nlqp.tab.c nlqp.tab.h: nlqp.y
	$(YACC) -d nlqp.y

lex.yy.c: token.l nlqp.tab.h
	$(LEX) token.l

clean:
	rm -f $(TARGET) nlqp.tab.c nlqp.tab.h lex.yy.c nlqp.output
