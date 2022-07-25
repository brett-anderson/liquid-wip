%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdbool.h>
#include "liquid.h"

int yylex();
void yyerror(const char *yymsgp);

%}

%define parse.trace
%define parse.error detailed

%union {
  struct node *ast;
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
RANGE_CTOR HASH LSQUARE RSQUARE

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

%type <ast> int float text id string bool member filter0 filter expr
  literal unfiltered_expr

%%
start: expr text expr text expr text
     ;

bool: TRUE  { $$ = new_bool_node(true); }
    | FALSE { $$ = new_bool_node(false); }
    ;

int: INT  { $$ = new_int_node($1); }
   ;

float: FLOAT { $$ = new_float_node($1); }
     ;

text: TEXT { $$ = new_text_node($1); }
    ;

id: ID { $$ = new_id_node($1); }
  ;

string: STRING { $$ = new_string_node($1); }
  ;

filter0: expr PIPE id { $$ = new_filter_node($1, $3); }
       ;

filter: filter0
      | filter0 id COLON unfiltered_expr { $$ = add_arg_to_filter($1, $2, $4); }
      | filter COMMA id COLON unfiltered_expr { $$ = add_arg_to_filter($1, $3, $5); }
      ;

member: id DOT id { $$ = new_member_node($1, $3); }
      ;

literal: int
       | float
       | string
       | text
       | bool /* NIL NONE EMPTY BLANK ? */
       ;

unfiltered_expr: member
               | literal
               | id
               ;

expr : unfiltered_expr
     | filter
     ;

%%

/* void yyerror(char *msg) { */
/*   fprintf(stderr, "error: %s\n", msg); */
/*   exit(1); */
/* } */

int main() {
  yylex();
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





  /*
id: ID
  | IF          { $$ = "if"; }
  | ENDIF       { $$ = "endif"; }
  | ELSIF       { $$ = "elsif"; }
  | ELSE        { $$ = "else"; }
  | UNLESS      { $$ = "unless"; }
  | ENDUNLESS   { $$ = "endunless"; }
  | CASE        { $$ = "case"; }
  | ENDCASE     { $$ = "endcase"; }
  | FORM        { $$ = "form"; }
  | ENDFORM     { $$ = "endform"; }
  | STYLE       { $$ = "style"; }
  | ENDSTYLE    { $$ = "endstyle"; }
  | FOR         { $$ = "for"; }
  | ENDFOR      { $$ = "endfor"; }
  | BREAK       { $$ = "break"; }
  | CONTINUE    { $$ = "continue"; }
  | CYCLE       { $$ = "cycle"; }
  | TABLEROW    { $$ = "tablerow"; }
  | ENDTABLEROW { $$ = "endtablerow"; }
  | PAGINATE    { $$ = "paginate"; }
  | ENDPAGINATE { $$ = "endpaginate"; }
  | S_ECHO      { $$ = "echo"; }
  | LIQUID      { $$ = "liquid"; }
  | INCLUDE     { $$ = "include"; }
  | LAYOUT      { $$ = "layout"; }
  | RENDER      { $$ = "render"; }
  | SECTION     { $$ = "section"; }
  | ASSIGN      { $$ = "assign"; }
  | CAPTURE     { $$ = "capture"; }
  | ENDCAPTURE  { $$ = "endcapture"; }
  | DECREMENT   { $$ = "decrement"; }
  | INCREMENT   { $$ = "increment"; }
  | WITH        { $$ = "with"; }
  | AS          { $$ = "as"; }
  | IN          { $$ = "in"; }
  | CONTAINS    { $$ = "contains"; }
  | EMPTY       { $$ = "empty"; }
  | BLANK       { $$ = "blank"; }
  | NIL         { $$ = "nil"; }
  | NONE        { $$ = "none"; }
  | WHEN        { $$ = "when"; }
  | BY          { $$ = "by"; }
  | OR          { $$ = "or"; }
  | AND         { $$ = "and"; }
  ;
*/

node *setup_node(enum node_type_t type) {
  printf("NODE%d\n", type);
  node *node = malloc(sizeof(node)); /* TODO check malloc */
  node->node_type = type;
  return node;
}

node *new_int_node(int val) {
  node *node = setup_node(NODE_INT);
  node->nd_int = val;
  return node;
}

node *new_float_node(double val) {
  node *node = setup_node(NODE_FLOAT);
  node->nd_double = val;
  return node;
}

node *new_text_node(char *val) {
  node *node = setup_node(NODE_TEXT);
  node->nd_string = val;
  return node;
}

node *new_bool_node(bool val) {
  node *node = setup_node(NODE_BOOL);
  node->nd_bool = val;
  return node;
}

node *new_id_node(char *val) {
  node *node = setup_node(NODE_ID);
  node->nd_string = val;
  return node;
}

node *new_string_node(char *val) {
  node *node = setup_node(NODE_STRING);
  node->nd_string = val;
  return node;
}

node *new_member_node(node *left, node *right) {
  node *node = setup_node(NODE_MEMBER);
  node->nd_left = left;
  /* TODO: assert that right is a compatible type */
  node->nd_member_name = right->nd_string;
  return node;
}

node *new_if_node(node *cond, node *then, node *else_) {
  node *node = setup_node(NODE_IF);
  node->nd_cond = cond;
  node->nd_then = then;
  node->nd_else = else_;
  return node;
}

node *new_assign_node(node *left, node *right) {
  node *node = setup_node(NODE_IF);
  /* TODO: assert compatible type */
  node->nd_name = left->nd_string;
  node->nd_val = right;
  return node;
}

node *new_filter_node(node *input, node *name) {
  node *node = setup_node(NODE_FILTER);
  node->nd_filter_input = input;
  node->nd_filter_name = name->nd_string;
  node->nd_filter_args = NULL;
  return node;
}

node *add_arg_to_filter(node *filter, node *argname, node *argval) {
  node *argnode = setup_node(NODE_ARG);
  argnode->nd_name = argname->nd_string;
  argnode->nd_val = argval;
  argnode->nd_nextarg = NULL;

  node *curr = filter->nd_filter_args;
  if (curr == NULL) {
    filter->nd_filter_args = argnode;
  } else {
    curr->nd_nextarg = argnode;
  }

  return filter;
}


    /* debg: %empty */
    /* | debg text                { printf("TEXT:   `%s`\n", $2->nd_string); } */
    /* | debg string              { printf("STRING: `%s`\n", $2->nd_string); } */
    /* | debg id                  { printf("ID:     %s\n", $2->nd_string); } */
    /* | debg int                 { printf("INT:    %d\n", $2->nd_int); } */
    /* | debg float               { printf("FLOAT:  %f\n", $2->nd_double); } */
    /* | debg bool                { printf("BOOL:   %d\n", $2->nd_bool); } */
    /* | debg member              { printf("MEMB:   (%p)\n", $2->u1.node); } */
    /* | debg filter              { printf("FILTER: (%p)\n", $2->u1.node); } */
    /* | debg EQUALS              { printf("EQUALS\n"); } */
    /* | debg NOT_EQUALS          { printf("NOT_EQUALS\n"); } */
    /* | debg GREATER_THAN        { printf("GREATER_THAN\n"); } */
    /* | debg GREATER_THAN_EQUALS { printf("GREATER_THAN_EQUALS\n"); } */
    /* | debg LESS_THAN           { printf("LESS_THAN\n"); } */
    /* | debg LESS_THAN_EQUALS    { printf("LESS_THAN_EQUALS\n"); } */
    /* | debg SPACESHIP           { printf("SPACESHIP\n"); } */
    /* | debg COMMA               { printf("COMMA\n"); } */
    /* | debg COLON               { printf("COLON\n"); } */
    /* | debg SET                 { printf("SET\n"); } */
    /* | debg DOT                 { printf("DOT\n"); } */
    /* | debg PIPE                { printf("PIPE\n"); } */
    /* | debg LPAREN              { printf("LPAREN\n"); } */
    /* | debg RPAREN              { printf("RPAREN\n"); } */
    /* | debg LSQUARE             { printf("LSQUARE\n"); } */
    /* | debg RSQUARE             { printf("RSQUARE\n"); } */
    /* | debg RANGE_CTOR          { printf("RANGE_CTOR\n"); } */
    /* | debg HASH                { printf("HASH\n"); } */
    /* | debg IF                  { printf("IF\n"); } */
    /* | debg ENDIF               { printf("ENDIF\n"); } */
    /* | debg ELSIF               { printf("ELSIF\n"); } */
    /* | debg ELSE                { printf("ELSE\n"); } */
    /* | debg UNLESS              { printf("UNLESS\n"); } */
    /* | debg ENDUNLESS           { printf("ENDUNLESS\n"); } */
    /* | debg CASE                { printf("CASE\n"); } */
    /* | debg ENDCASE             { printf("ENDCASE\n"); } */
    /* | debg FORM                { printf("FORM\n"); } */
    /* | debg ENDFORM             { printf("ENDFORM\n"); } */
    /* | debg STYLE               { printf("STYLE\n"); } */
    /* | debg ENDSTYLE            { printf("ENDSTYLE\n"); } */
    /* | debg FOR                 { printf("FOR\n"); } */
    /* | debg ENDFOR              { printf("ENDFOR\n"); } */
    /* | debg BREAK               { printf("BREAK\n"); } */
    /* | debg CONTINUE            { printf("CONTINUE\n"); } */
    /* | debg CYCLE               { printf("CYCLE\n"); } */
    /* | debg TABLEROW            { printf("TABLEROW\n"); } */
    /* | debg ENDTABLEROW         { printf("ENDTABLEROW\n"); } */
    /* | debg PAGINATE            { printf("PAGINATE\n"); } */
    /* | debg ENDPAGINATE         { printf("ENDPAGINATE\n"); } */
    /* | debg S_ECHO              { printf("ECHO\n"); } */
    /* | debg LIQUID              { printf("LIQUID\n"); } */
    /* | debg INCLUDE             { printf("INCLUDE\n"); } */
    /* | debg LAYOUT              { printf("LAYOUT\n"); } */
    /* | debg RENDER              { printf("RENDER\n"); } */
    /* | debg SECTION             { printf("SECTION\n"); } */
    /* | debg ASSIGN              { printf("ASSIGN\n"); } */
    /* | debg CAPTURE             { printf("CAPTURE\n"); } */
    /* | debg ENDCAPTURE          { printf("ENDCAPTURE\n"); } */
    /* | debg DECREMENT           { printf("DECREMENT\n"); } */
    /* | debg INCREMENT           { printf("INCREMENT\n"); } */
    /* | debg WITH                { printf("WITH\n"); } */
    /* | debg AS                  { printf("AS\n"); } */
    /* | debg IN                  { printf("IN\n"); } */
    /* | debg CONTAINS            { printf("CONTAINS\n"); } */
    /* | debg EMPTY               { printf("EMPTY\n"); } */
    /* | debg BLANK               { printf("BLANK\n"); } */
    /* | debg NIL                 { printf("NIL\n"); } */
    /* | debg NONE                { printf("NONE\n"); } */
    /* | debg WHEN                { printf("WHEN\n"); } */
    /* | debg BY                  { printf("BY\n"); } */
    /* | debg OR                  { printf("OR\n"); } */
    /* | debg AND                 { printf("AND\n"); } */
    ;

