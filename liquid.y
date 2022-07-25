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

%token <str> TEXT ID STRING

%token EQUALS
%token NOT_EQUALS
%token GREATER_THAN
%token GREATER_THAN_EQUALS
%token LESS_THAN
%token LESS_THAN_EQUALS
%token SPACESHIP
%token COMMA
%token COLON
%token ASSIGN
%token DOT
%token PIPE
%token LPAREN
%token RPAREN
%token RANGE_CTOR
%token HASH

 /* TODO: for, if, etc., should probably be tokens without string contents from
  * the lexer. but are they reserved words? Can I trust that they won't also be vars?
  * Maybe not safely?
  */

%type <str> text

%%
start: expr
     ;

expr: /* empty */
    | expr text                { printf("TEXT:   [[%s]]\n", $2); }
    | expr STRING              { printf("STRING: [[%s]]\n", $2); }
    | expr EQUALS              { printf("EQUALS\n"); }
    | expr ASSIGN              { printf("ASSIGN\n"); }
    | expr DOT                 { printf("DOT\n"); }
    | expr NOT_EQUALS          { printf("NOT_EQUALS\n"); }
    | expr GREATER_THAN_EQUALS { printf("GREATER_THAN_EQUALS\n"); }
    | expr SPACESHIP           { printf("SPACESHIP\n"); }
    | expr LESS_THAN_EQUALS    { printf("LESS_THAN_EQUALS\n"); }
    | expr LESS_THAN           { printf("LESS_THAN\n"); }
    | expr GREATER_THAN        { printf("GREATER_THAN\n"); }
    | expr COLON               { printf("COLON\n"); }
    | expr COMMA               { printf("COMMA\n"); }
    | expr PIPE                { printf("PIPE\n"); }
    | expr DOT                 { printf("DOT\n"); }
    | expr RANGE_CTOR          { printf("RANGE_CTOR\n"); }
    | expr LPAREN              { printf("LPAREN\n"); }
    | expr RPAREN              { printf("RPAREN\n"); }
    | expr HASH                { printf("HASH\n"); }
    | expr ID                  { printf("ID:     [[%s]]\n", $2); }
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
