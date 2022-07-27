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
extern int yydebug;

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
%token WITH AS IN CONTAINS EMPTY BLANK NONE WHEN BY OR AND TRUE FALSE

/* Misc */
%token BEGIN_OUTPUT END_OUTPUT BEGIN_TAG END_TAG

%type <ast> int float text id string bool member filter fexpr
  literal expr exprs start argname filter0 output indexation texpr tag
  liquid_texpr texpr0 texprs false true none empty blank arglist arglist0

%%

start:
  exprs                      { $$ = $1; dump($$); }
;

exprs:
  %empty                     { $$ = new_exprs_node(); }
| exprs fexpr                { $$ = add_expr_to_exprs($1, $2); }
;

filter0:
  fexpr '|' id               { $$ = new_filter_node($1, $3); }
;

filter:
  filter0
| filter0 argname expr       { $$ = add_arg_to_filter($1, $2, $3); }
| filter ',' argname expr    { $$ = add_arg_to_filter($1, $3, $4); }
;

output:
  BEGIN_OUTPUT fexpr END_OUTPUT { $$ = new_echo_node($2); }
;

tag:
  BEGIN_TAG texpr END_TAG    { $$ = $2; }
| BEGIN_TAG STYLE END_TAG exprs endstyle {
    $$ = new_style_node($4);
  }
| BEGIN_TAG CAPTURE id END_TAG exprs endcapture {
    $$ = new_capture_node($3, $5);
  }
| BEGIN_TAG CYCLE argname arglist END_TAG {
    $$ = new_cycle_node($3, $4);
  }
| BEGIN_TAG CYCLE arglist END_TAG {
    $$ = new_cycle_node(NULL, $3);
  }
| BEGIN_TAG PAGINATE expr BY expr END_TAG exprs endpaginate {
    $$ = new_paginate_node($3, $5, $7);
  }
;

arglist:
  %empty                     { $$ = NULL; }
| arglist0
;

arglist0:
  expr                       { $$ = add_expr_to_exprs(NULL, $1); }
| arglist0 ',' expr          { $$ = add_expr_to_exprs($1, $3); }
;

texpr: /* _T_ag expression: contents of a {% %} */
  texpr0
| liquid_texpr
;

endstyle:
  BEGIN_TAG ENDSTYLE END_TAG
;

endcapture:
  BEGIN_TAG ENDCAPTURE END_TAG
;

endpaginate:
  BEGIN_TAG ENDPAGINATE END_TAG
;

texpr0:
  ASSIGN id '=' fexpr        { $$ = new_assign_node($2, $4); }
| S_ECHO fexpr               { $$ = new_echo_node($2); }
| INCREMENT id               { $$ = new_increment_node($2); }
| DECREMENT id               { $$ = new_decrement_node($2); }
| INCLUDE expr               { $$ = new_include_node($2); }
| LAYOUT expr                { $$ = new_layout_node($2); }
| SECTION expr               { $$ = new_section_node($2); }
/* | IF */
/* | UNLESS */
/* | CASE */
/* | FORM */
/* | FOR */
/* | TABLEROW */
/* | PAGINATE */
;

texprs:
  %empty                     { $$ = new_exprs_node(); }
| texprs texpr0              { $$ = add_expr_to_exprs($1, $2); }
;

liquid_texpr:
  LIQUID texprs              { $$ = $2; }
;

fexpr: /* (maybe) _F_iltered expr */
  expr
| filter
| output
;

member:
  expr '.' id                { $$ = new_member_node($1, $3); }
;

indexation:
  expr '[' expr ']'          { $$ = new_indexation_node($1, $3); }
;

expr:
  member
| indexation
| literal
| id
| tag
;

literal:
  int
| float
| string
| text
| bool
| none
| empty
| blank
;

bool:
  true
| false
;

id: /* TODO: list more */
  ID             { $$ = new_id_node($1);         }
| PAGINATE       { $$ = new_id_node("paginate"); }
;

int:     INT     { $$ = new_int_node($1);     } ;
float:   FLOAT   { $$ = new_float_node($1);   } ;
text:    TEXT    { $$ = new_text_node($1);    } ;
string:  STRING  { $$ = new_string_node($1);  } ;
argname: ARGNAME { $$ = new_argname_node($1); } ;
none:    NONE    { $$ = new_none_node();      } ;
true:    TRUE    { $$ = new_bool_node(true);  } ;
false:   FALSE   { $$ = new_bool_node(false); } ;
empty:   EMPTY   { $$ = new_empty_node();     } ;
blank:   BLANK   { $$ = new_blank_node();     } ;

%%

int main(int argc, char **argv) {
  if (argc == 2 && strcmp(argv[1], "-l") == 0) {
    while (yylex() != 0);
  } else if (argc == 2 && strcmp(argv[1], "-d") == 0) {
    yydebug=1;
    yyparse();
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
      exprs->nd_expr_rest = calloc(128, sizeof(void*));
    }
    for (int i = 0; i < 128; i++) {
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

node *new_assign_node(node *id, node *fexpr) {
  node *node = setup_node(NODE_ASSIGN);
  node->nd_name = id->nd_string;
  node->nd_val = fexpr;
  return node;
}

node *new_increment_node(node *id) {
  node *node = setup_node(NODE_INCREMENT);
  node->nd_name = id->nd_string;
  return node;
}

node *new_decrement_node(node *id) {
  node *node = setup_node(NODE_DECREMENT);
  node->nd_name = id->nd_string;
  return node;
}

node *new_include_node(node *name) {
  node *node = setup_node(NODE_INCLUDE);
  node->nd_expr1 = name;
  return node;
}

node *new_none_node() {
  node *node = setup_node(NODE_NONE);
  return node;
}

node *new_empty_node() {
  node *node = setup_node(NODE_EMPTY);
  return node;
}

node *new_blank_node() {
  node *node = setup_node(NODE_BLANK);
  return node;
}

node *new_layout_node(node *name) {
  node *node = setup_node(NODE_LAYOUT);
  node->nd_expr1 = name;
  return node;
}

node *new_section_node(node *name) {
  node *node = setup_node(NODE_SECTION);
  node->nd_expr1 = name;
  return node;
}

node *new_style_node(node *exprs) {
  node *node = setup_node(NODE_STYLE);
  node->nd_expr1 = exprs;
  return node;
}

node *new_capture_node(node *varname, node *exprs) {
  node *node = setup_node(NODE_CAPTURE);
  node->nd_string = varname->nd_string;
  node->nd_expr2 = exprs;
  return node;
}

node *new_cycle_node(node *groupname, node *items) {
  node *node = setup_node(NODE_CYCLE);
  if (groupname != NULL) {
    node->nd_groupname = groupname->nd_string;
  }
  node->nd_items = items;
  return node;
}

node *new_paginate_node(node *array, node *page_size, node *exprs) {
  node *node = setup_node(NODE_PAGINATE);
  node->nd_paginate_array = array;
  node->nd_paginate_page_size = page_size;
  node->nd_paginate_exprs = exprs;
  return node;
}
