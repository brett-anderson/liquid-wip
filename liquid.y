%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include "liquid.h"

int yylex();
void yyerror(const char *yymsgp);
void dump(node *n);

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

%token <str> TEXT ID STRING ARGNAME
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

%type <ast> int float text id string bool member filter expr
  literal unfiltered_expr exprs start argname filter0

%%

start:
  exprs                      { $$ = $1; dump($$); }
;

exprs:
  %empty                     { $$ = new_exprs_node(); }
| exprs expr                 { $$ = add_expr_to_exprs($1, $2); }
;

bool:
  TRUE                       { $$ = new_bool_node(true); }
| FALSE                      { $$ = new_bool_node(false); }
;

int:
  INT                        { $$ = new_int_node($1); }
;

float:
  FLOAT                      { $$ = new_float_node($1); }
;

text:
  TEXT                       { $$ = new_text_node($1); }
;

id:
  ID                         { $$ = new_id_node($1); }
;

argname:
  ARGNAME                    { $$ = new_argname_node($1); }
;

string:
  STRING                     { $$ = new_string_node($1); }
;

filter0:
  expr PIPE id               { $$ = new_filter_node($1, $3); }
;

filter:
  filter0 argname unfiltered_expr      { $$ = add_arg_to_filter($1, $2, $3); }
| filter COMMA argname unfiltered_expr { $$ = add_arg_to_filter($1, $3, $4); }
;

member:
  id DOT id                  { $$ = new_member_node($1, $3); }
;

literal:
  int
| float
| string
| text
| bool /* NIL NONE EMPTY BLANK ? */
;

unfiltered_expr:
  member
| literal
| id
;

expr:
  unfiltered_expr
| filter
;

%%

/* void yyerror(char *msg) { */
/*   fprintf(stderr, "error: %s\n", msg); */
/*   exit(1); */
/* } */

int main(int argc, char **argv) {
  if (argc == 2 && strcmp(argv[1], "-l") == 0) {
    while (yylex() != 0);
  } else {
    yyparse();
  }
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

node *new_argname_node(char *val) {
  node *node = setup_node(NODE_ARGNAME);
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

  /* TODO: what am I doing wrong? this is corrupting the input */

  /* node *curr = filter->nd_filter_args; */
  /* if (curr == NULL) { */
  /*   filter->nd_filter_args = argnode; */
  /* } else { */
  /*   curr->nd_nextarg = argnode; */
  /* } */

  return filter;
}

node *new_exprs_node() {
  node *node = setup_node(NODE_EXPRS);
  node->nd_expr1 = NULL;
  node->nd_expr2 = NULL;
  node->nd_expr_rest = NULL;
  return node;
}

node *add_expr_to_exprs(node *exprs, node *expr) {
  if (exprs->nd_expr1 == NULL) {
    exprs->nd_expr1 = expr;
  } else if (exprs->nd_expr2 == NULL) {
    exprs->nd_expr2 = expr;
  } else {
    if (exprs->nd_expr_rest == NULL) {
      // TODO: obviously this is wildly shitty
      exprs->nd_expr_rest = calloc(16, sizeof(void*));
    }
    for (int i = 0; i < 16; i++) {
      if (exprs->nd_expr_rest != NULL) {
        exprs->nd_expr_rest = &expr;
        return exprs;
      }
    }
    yyerror("not yet supported");
  }
  return exprs;
}

void dump(node *n) {
  switch (n->node_type) {
  case NODE_TEXT:
    printf("REALTEXT\n");
    break;
  case NODE_STRING:
    printf("TEXT\n");
    break;
  case NODE_ID:
    printf("TEXT\n");
    break;
  case NODE_INT:
    printf("TEXT\n");
    break;
  case NODE_FLOAT:
    printf("TEXT\n");
    break;
  case NODE_BOOL:
    printf("TEXT\n");
    break;
  case NODE_MEMBER:
    printf("TEXT\n");
    break;
  case NODE_IF:
    printf("TEXT\n");
    break;
  case NODE_ASSIGN:
    printf("TEXT\n");
    break;
  case NODE_FILTER:
    printf("FILTER\n");
    break;
  case NODE_ARG:
    printf("ARG\n");
    break;
  case NODE_EXPRS:
    printf("EXPRS\n");
    break;
  default:
    break;
  }
}

    /* /1* debg: %empty *1/ */
    /* /1* | debg text                { printf("TEXT:   `%s`\n", $2->nd_string); } *1/ */
    /* /1* | debg string              { printf("STRING: `%s`\n", $2->nd_string); } *1/ */
    /* /1* | debg id                  { printf("ID:     %s\n", $2->nd_string); } *1/ */
    /* /1* | debg int                 { printf("INT:    %d\n", $2->nd_int); } *1/ */
    /* /1* | debg float               { printf("FLOAT:  %f\n", $2->nd_double); } *1/ */
    /* /1* | debg bool                { printf("BOOL:   %d\n", $2->nd_bool); } *1/ */
    /* /1* | debg member              { printf("MEMB:   (%p)\n", $2->u1.node); } *1/ */
    /* /1* | debg filter              { printf("FILTER: (%p)\n", $2->u1.node); } *1/ */
    /* /1* | debg EQUALS              { printf("EQUALS\n"); } *1/ */
    /* /1* | debg NOT_EQUALS          { printf("NOT_EQUALS\n"); } *1/ */
    /* /1* | debg GREATER_THAN        { printf("GREATER_THAN\n"); } *1/ */
    /* /1* | debg GREATER_THAN_EQUALS { printf("GREATER_THAN_EQUALS\n"); } *1/ */
    /* /1* | debg LESS_THAN           { printf("LESS_THAN\n"); } *1/ */
    /* /1* | debg LESS_THAN_EQUALS    { printf("LESS_THAN_EQUALS\n"); } *1/ */
    /* /1* | debg SPACESHIP           { printf("SPACESHIP\n"); } *1/ */
    /* /1* | debg COMMA               { printf("COMMA\n"); } *1/ */
    /* /1* | debg COLON               { printf("COLON\n"); } *1/ */
    /* /1* | debg SET                 { printf("SET\n"); } *1/ */
    /* /1* | debg DOT                 { printf("DOT\n"); } *1/ */
    /* /1* | debg PIPE                { printf("PIPE\n"); } *1/ */
    /* /1* | debg LPAREN              { printf("LPAREN\n"); } *1/ */
    /* /1* | debg RPAREN              { printf("RPAREN\n"); } *1/ */
    /* /1* | debg LSQUARE             { printf("LSQUARE\n"); } *1/ */
    /* /1* | debg RSQUARE             { printf("RSQUARE\n"); } *1/ */
    /* /1* | debg RANGE_CTOR          { printf("RANGE_CTOR\n"); } *1/ */
    /* /1* | debg HASH                { printf("HASH\n"); } *1/ */
    /* /1* | debg IF                  { printf("IF\n"); } *1/ */
    /* /1* | debg ENDIF               { printf("ENDIF\n"); } *1/ */
    /* /1* | debg ELSIF               { printf("ELSIF\n"); } *1/ */
    /* /1* | debg ELSE                { printf("ELSE\n"); } *1/ */
    /* /1* | debg UNLESS              { printf("UNLESS\n"); } *1/ */
    /* /1* | debg ENDUNLESS           { printf("ENDUNLESS\n"); } *1/ */
    /* /1* | debg CASE                { printf("CASE\n"); } *1/ */
    /* /1* | debg ENDCASE             { printf("ENDCASE\n"); } *1/ */
    /* /1* | debg FORM                { printf("FORM\n"); } *1/ */
    /* /1* | debg ENDFORM             { printf("ENDFORM\n"); } *1/ */
    /* /1* | debg STYLE               { printf("STYLE\n"); } *1/ */
    /* /1* | debg ENDSTYLE            { printf("ENDSTYLE\n"); } *1/ */
    /* /1* | debg FOR                 { printf("FOR\n"); } *1/ */
    /* /1* | debg ENDFOR              { printf("ENDFOR\n"); } *1/ */
    /* /1* | debg BREAK               { printf("BREAK\n"); } *1/ */
    /* /1* | debg CONTINUE            { printf("CONTINUE\n"); } *1/ */
    /* /1* | debg CYCLE               { printf("CYCLE\n"); } *1/ */
    /* /1* | debg TABLEROW            { printf("TABLEROW\n"); } *1/ */
    /* /1* | debg ENDTABLEROW         { printf("ENDTABLEROW\n"); } *1/ */
    /* /1* | debg PAGINATE            { printf("PAGINATE\n"); } *1/ */
    /* /1* | debg ENDPAGINATE         { printf("ENDPAGINATE\n"); } *1/ */
    /* /1* | debg S_ECHO              { printf("ECHO\n"); } *1/ */
    /* /1* | debg LIQUID              { printf("LIQUID\n"); } *1/ */
    /* /1* | debg INCLUDE             { printf("INCLUDE\n"); } *1/ */
    /* /1* | debg LAYOUT              { printf("LAYOUT\n"); } *1/ */
    /* /1* | debg RENDER              { printf("RENDER\n"); } *1/ */
    /* /1* | debg SECTION             { printf("SECTION\n"); } *1/ */
    /* /1* | debg ASSIGN              { printf("ASSIGN\n"); } *1/ */
    /* /1* | debg CAPTURE             { printf("CAPTURE\n"); } *1/ */
    /* /1* | debg ENDCAPTURE          { printf("ENDCAPTURE\n"); } *1/ */
    /* /1* | debg DECREMENT           { printf("DECREMENT\n"); } *1/ */
    /* /1* | debg INCREMENT           { printf("INCREMENT\n"); } *1/ */
    /* /1* | debg WITH                { printf("WITH\n"); } *1/ */
    /* /1* | debg AS                  { printf("AS\n"); } *1/ */
    /* /1* | debg IN                  { printf("IN\n"); } *1/ */
    /* /1* | debg CONTAINS            { printf("CONTAINS\n"); } *1/ */
    /* /1* | debg EMPTY               { printf("EMPTY\n"); } *1/ */
    /* /1* | debg BLANK               { printf("BLANK\n"); } *1/ */
    /* /1* | debg NIL                 { printf("NIL\n"); } *1/ */
    /* /1* | debg NONE                { printf("NONE\n"); } *1/ */
    /* /1* | debg WHEN                { printf("WHEN\n"); } *1/ */
    /* /1* | debg BY                  { printf("BY\n"); } *1/ */
    /* /1* | debg OR                  { printf("OR\n"); } *1/ */
    /* /1* | debg AND                 { printf("AND\n"); } *1/ */
    /* ; */

