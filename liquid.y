%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include "liquid.h"
#include "dump.h"

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

%token <str> TEXT ID STRING ARGNAME
%token <ival> INT
%token <dval> FLOAT

/* Tag/Output mode operators, etc. */
%token EQUALS NOT_EQUALS GTE LTE SPACESHIP DOTDOT

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

/* Misc */
%token BEGIN_OUTPUT END_OUTPUT

%type <ast> int float text id string bool member filter expr
  literal unfiltered_expr exprs start argname filter0 output
  indexation

%%

start:
  exprs                      { $$ = $1; dump($$); }
;

exprs:
  expr                       { $$ = add_expr_to_exprs(NULL, $1); }
| exprs expr                 { $$ = add_expr_to_exprs($1, $2); }
;

bool:
  TRUE                       { $$ = new_bool_node(true); }
| FALSE                      { $$ = new_bool_node(false); }
;

filter0:
  expr '|' id               { $$ = new_filter_node($1, $3); }
;

filter:
  filter0 argname unfiltered_expr    { $$ = add_arg_to_filter($1, $2, $3); }
| filter ',' argname unfiltered_expr { $$ = add_arg_to_filter($1, $3, $4); }
;

member:
  unfiltered_expr '.' id     { $$ = new_member_node($1, $3); }
;

indexation:
  unfiltered_expr '[' unfiltered_expr ']' { $$ = new_indexation_node($1, $3); }
;

output:
  BEGIN_OUTPUT expr END_OUTPUT { $$ = new_echo_node($2); }
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
| indexation
| literal
| id
;

expr:
  unfiltered_expr
| filter
| output
;

int:     INT     { $$ = new_int_node($1);     } ;
float:   FLOAT   { $$ = new_float_node($1);   } ;
text:    TEXT    { $$ = new_text_node($1);    } ;
id:      ID      { $$ = new_id_node($1);      } ;
argname: ARGNAME { $$ = new_argname_node($1); } ;
string:  STRING  { $$ = new_string_node($1);  } ;

%%

int main(int argc, char **argv) {
  if (argc == 2 && strcmp(argv[1], "-l") == 0) {
    while (yylex() != 0);
  } else {
    yyparse();
  }
  return 0;
}

node *setup_node(enum node_type_t type) {
  node *node = calloc(1, sizeof(struct node));
  if (node == NULL) {
    fprintf(stderr, "malloc failed\n");
    exit(1);
  }
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
  node->nd_string = strdup(val);
  return node;
}

node *new_bool_node(bool val) {
  node *node = setup_node(NODE_BOOL);
  node->nd_bool = val;
  return node;
}

node *new_id_node(char *val) {
  node *node = setup_node(NODE_ID);
  node->nd_string = strdup(val);
  return node;
}

node *new_argname_node(char *val) {
  node *node = setup_node(NODE_ARGNAME);
  node->nd_string = strdup(val);
  return node;
}

node *new_string_node(char *val) {
  node *node = setup_node(NODE_STRING);
  node->nd_string = strdup(val);
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
  return node;
}

node *add_arg_to_filter(node *filter, node *argname, node *argval) {
  node *argnode = setup_node(NODE_ARG);
  argnode->nd_name = argname->nd_string;
  argnode->nd_val = argval;

  node *curr = filter->nd_filter_args;
  if (curr == NULL) {
    filter->nd_filter_args = argnode;
  } else {
    curr->nd_nextarg = argnode;
  }

  return filter;
}

node *new_exprs_node() {
  node *node = setup_node(NODE_EXPRS);
  return node;
}

node *add_expr_to_exprs(node *exprs, node *expr) {
  if (exprs == NULL) {
    exprs = setup_node(NODE_EXPRS);
  }

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
      if (exprs->nd_expr_rest[i] == NULL) {
        exprs->nd_expr_rest[i] = expr;
        return exprs;
      }
    }
    yyerror("not yet supported");
  }
  return exprs;
}

node *new_echo_node(node *content) {
  node *node = setup_node(NODE_ECHO);
  node->nd_content = content;
  return node;
}

node *new_indexation_node(node *left, node *index) {
  node *node = setup_node(NODE_INDEXATION);
  node->nd_left = left;
  node->nd_index = index;
  return node;
}
