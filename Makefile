LEX = flex
YACC = bison
CC = cc
CFLAGS = -DYYDEBUG=1

# liquid-parser: lex.yy.o liquid.tab.o
# 	$(CC) $(CFLAGS) -o $@ $^ -ll -ly -lm

liquid-lexer: lex.yy.o
	$(CC) $(CFLAGS) -o $@ $^ -ll

lex.yy.c: liquid.l
	$(LEX) $<

# %.tab.c %.tab.h: %.y
# 	$(YACC) -d $<

lex.yy.o: liquid.tab.h

clean:
	rm -f *.o lex.yy.c liquid-parser liquid.tab.*
.PHONY: clean
