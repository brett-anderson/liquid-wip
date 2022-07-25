%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

int yylex();
void yyerror(char *msg);
char* concatf(const char* fmt, ...);
%}

%union {
  char *str;
}

%token <str> TEXT ID

%token START 

%type <str> text

%%
start: expr
     ;

expr: /* empty */
    | expr text      { printf("TEXT: [[%s]]\n", $2); }
    | expr ID        { printf("ID:   [[%s]]\n", $2); }
    ;

text: TEXT
    ;

%%

void yyerror(char *msg) {
  fprintf(stderr, "error: %s\n", msg);
  exit(1);
}

int main() {
  yyparse();
  return 0;
}

/*
text: text TEXT      { $$ = concatf("%s%s", $1, $2); }
    | TEXT
    ;
char* concatf(const char* fmt, ...) {
  va_list args;
  char* buf = NULL;
  va_start(args, fmt);
  int n = vasprintf(&buf, fmt, args);
  va_end(args);
  if (n < 0) { free(buf); buf = NULL; }
  return buf;
}
*/
