%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdbool.h>

int yylex();
void yyerror(char *msg);
char* concatf(const char* fmt, ...);
%}

%union {
  char *str;
  uint32_t ival;
  double dval;
  bool boolval;
}

%token <str> TEXT ID STRING
%token <ival> INT
%token <dval> FLOAT

/* Tag/Output mode operators, etc. */
%token EQUALS NOT_EQUALS GREATER_THAN GREATER_THAN_EQUALS LESS_THAN
LESS_THAN_EQUALS SPACESHIP COMMA COLON SET DOT PIPE LPAREN RPAREN
RANGE_CTOR HASH

/* Conditional tags */
%token IF ENDIF ELSIF ELSE UNLESS ENDUNLESS CASE ENDCASE

/* HTML tags */
%token FORM ENDFORM STYLE ENDSTYLE

/* Iteration tags */
%token FOR ENDFOR /* ELSE */ BREAK CONTINUE CYCLE TABLEROW ENDTABLEROW PAGINATE
ENDPAGINATE

/* Syntax tags */
%token /* COMMENT ENDCOMMENT RAW ENDRAW */ S_ECHO LIQUID

/* Theme tags */
%token INCLUDE LAYOUT RENDER SECTION

/* Variable tags */
%token ASSIGN CAPTURE ENDCAPTURE DECREMENT INCREMENT

/* Other syntax */
%token WITH AS IN CONTAINS EMPTY BLANK NIL NONE WHEN BY OR AND TRUE FALSE

%type <str> text
%type <ival> int
%type <dval> float
%type <boolval> bool

%%
start: expr
     ;

expr: /* empty */
    | expr text                { printf("TEXT:   `%s`\n", $2); }
    | expr STRING              { printf("STRING: `%s`\n", $2); }
    | expr ID                  { printf("ID:     %s\n", $2); }
    | expr int                 { printf("INT:    %d\n", $2); }
    | expr float               { printf("FLOAT:  %f\n", $2); }
    | expr bool                { printf("BOOL:   %d\n", $2); }
    | expr EQUALS              { printf("EQUALS\n"); }
    | expr NOT_EQUALS          { printf("NOT_EQUALS\n"); }
    | expr GREATER_THAN        { printf("GREATER_THAN\n"); }
    | expr GREATER_THAN_EQUALS { printf("GREATER_THAN_EQUALS\n"); }
    | expr LESS_THAN           { printf("LESS_THAN\n"); }
    | expr LESS_THAN_EQUALS    { printf("LESS_THAN_EQUALS\n"); }
    | expr SPACESHIP           { printf("SPACESHIP\n"); }
    | expr COMMA               { printf("COMMA\n"); }
    | expr COLON               { printf("COLON\n"); }
    | expr SET                 { printf("SET\n"); }
    | expr DOT                 { printf("DOT\n"); }
    | expr PIPE                { printf("PIPE\n"); }
    | expr LPAREN              { printf("LPAREN\n"); }
    | expr RPAREN              { printf("RPAREN\n"); }
    | expr RANGE_CTOR          { printf("RANGE_CTOR\n"); }
    | expr HASH                { printf("HASH\n"); }
    | expr IF                  { printf("IF\n"); }
    | expr ENDIF               { printf("ENDIF\n"); }
    | expr ELSIF               { printf("ELSIF\n"); }
    | expr ELSE                { printf("ELSE\n"); }
    | expr UNLESS              { printf("UNLESS\n"); }
    | expr ENDUNLESS           { printf("ENDUNLESS\n"); }
    | expr CASE                { printf("CASE\n"); }
    | expr ENDCASE             { printf("ENDCASE\n"); }
    | expr FORM                { printf("FORM\n"); }
    | expr ENDFORM             { printf("ENDFORM\n"); }
    | expr STYLE               { printf("STYLE\n"); }
    | expr ENDSTYLE            { printf("ENDSTYLE\n"); }
    | expr FOR                 { printf("FOR\n"); }
    | expr ENDFOR              { printf("ENDFOR\n"); }
    | expr BREAK               { printf("BREAK\n"); }
    | expr CONTINUE            { printf("CONTINUE\n"); }
    | expr CYCLE               { printf("CYCLE\n"); }
    | expr TABLEROW            { printf("TABLEROW\n"); }
    | expr ENDTABLEROW         { printf("ENDTABLEROW\n"); }
    | expr PAGINATE            { printf("PAGINATE\n"); }
    | expr ENDPAGINATE         { printf("ENDPAGINATE\n"); }
    | expr S_ECHO              { printf("ECHO\n"); }
    | expr LIQUID              { printf("LIQUID\n"); }
    | expr INCLUDE             { printf("INCLUDE\n"); }
    | expr LAYOUT              { printf("LAYOUT\n"); }
    | expr RENDER              { printf("RENDER\n"); }
    | expr SECTION             { printf("SECTION\n"); }
    | expr ASSIGN              { printf("ASSIGN\n"); }
    | expr CAPTURE             { printf("CAPTURE\n"); }
    | expr ENDCAPTURE          { printf("ENDCAPTURE\n"); }
    | expr DECREMENT           { printf("DECREMENT\n"); }
    | expr INCREMENT           { printf("INCREMENT\n"); }
    | expr WITH                { printf("WITH\n"); }
    | expr AS                  { printf("AS\n"); }
    | expr IN                  { printf("IN\n"); }
    | expr CONTAINS            { printf("CONTAINS\n"); }
    | expr EMPTY               { printf("EMPTY\n"); }
    | expr BLANK               { printf("BLANK\n"); }
    | expr NIL                 { printf("NIL\n"); }
    | expr NONE                { printf("NONE\n"); }
    | expr WHEN                { printf("WHEN\n"); }
    | expr BY                  { printf("BY\n"); }
    | expr OR                  { printf("OR\n"); }
    | expr AND                 { printf("AND\n"); }
    ;

bool: TRUE  { $$ = true; }
    | FALSE { $$ = false; }
    ;

int: INT
   ;

float: FLOAT
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
