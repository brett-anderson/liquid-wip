LEX    = flex
YACC   = bison
CC     = cc
CFLAGS = -DYYDEBUG=1 -Werror
LFLAGS = -ll -ly -lm

liquid-parser: lex.yy.o liquid.tab.o
	$(CC) $(CFLAGS) $(LFLAGS) -o $@ $^

lex.yy.c: liquid.l liquid.tab.h
	$(LEX) $<

%.tab.c %.tab.h: %.y %.h
	$(YACC) -d $<

lex.yy.o: liquid.tab.h

clean:
	rm -f *.o lex.yy.c liquid-parser liquid.tab.*
.PHONY: clean
