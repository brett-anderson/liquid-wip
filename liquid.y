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
  int comparator;
}

%token <str> TEXT ID STRING ARGNAME
%token <ival> INT
%token <dval> FLOAT

/* Tag/Output mode operators, etc. */
%token EQUALS NOT_EQUALS GTE LTE SPACESHIP DOTDOT CONTAINS REVERSED

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
%token WITH AS IN EMPTY BLANK NONE WHEN BY OR AND TRUE FALSE

/* Misc */
%token BEGIN_OUTPUT END_OUTPUT BEGIN_TAG END_TAG

%type <ast> int float text id string bool member filter fexpr
  literal expr exprs start argname output indexation texpr tag
  liquid_texpr texpr0 texprs false true none empty blank arglist arglist0
  kwarglist kwarglist0 elsifs_else_endif elsifs_else_endunless whens_endcase

%type <comparator> compare and_or

%left AND OR
%left EQUALS NOT_EQUALS '>' '<' GTE LTE SPACESHIP CONTAINS
%left '.'
%left '['

%%

start:
  exprs                      { $$ = $1; dump($$); }
;

exprs:
  %empty                     { $$ = new_exprs_node(); }
| exprs fexpr                { $$ = add_expr_to_exprs($1, $2); }
;

filter:
  fexpr '|' id               { $$ = new_filter_node($1, $3); }
| fexpr '|' argname argname expr  {
    $$ = new_filter_node($1, $3);
    $$ = add_arg_to_filter($$, $4, $5);
  }
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

| BEGIN_TAG TABLEROW expr IN expr kwarglist END_TAG exprs endtablerow {
    $$ = new_tablerow_node($3, $5, $6, $8, NULL, false, false);
  }
| BEGIN_TAG TABLEROW expr IN expr REVERSED kwarglist END_TAG exprs endtablerow {
    $$ = new_tablerow_node($3, $5, $7, $9, NULL, true, false);
  }
| BEGIN_TAG TABLEROW expr IN '(' expr DOTDOT expr ')' kwarglist END_TAG exprs endtablerow {
    $$ = new_tablerow_node($3, $6, $10, $12, $8, false, true);
  }
| BEGIN_TAG TABLEROW expr IN '(' expr DOTDOT expr ')' REVERSED kwarglist END_TAG exprs endtablerow {
    $$ = new_tablerow_node($3, $6, $11, $13, $8, false, true);
  }

| BEGIN_TAG FOR expr IN expr kwarglist END_TAG exprs endfor {
    $$ = new_for_node($3, $5, $6, $8, NULL, false, false);
  }
| BEGIN_TAG FOR expr IN expr REVERSED kwarglist END_TAG exprs endfor {
    $$ = new_for_node($3, $5, $7, $9, NULL, true, false);
  }
| BEGIN_TAG FOR expr IN '(' expr DOTDOT expr ')' kwarglist END_TAG exprs endfor {
    $$ = new_for_node($3, $6, $10, $12, $8, false, true);
  }
| BEGIN_TAG FOR expr IN '(' expr DOTDOT expr ')' REVERSED kwarglist END_TAG exprs endfor {
    $$ = new_for_node($3, $6, $11, $13, $8, false, true);
  }

| BEGIN_TAG IF expr END_TAG exprs elsifs_else_endif {
    $$ = complete_if_node($3, $5, $6);
  }
| BEGIN_TAG UNLESS expr END_TAG exprs elsifs_else_endunless {
    $$ = complete_unless_node($3, $5, $6);
  }
| BEGIN_TAG CASE expr END_TAG maybe_text whens_endcase {
    /* The TEXT node here is invariably ignored. */
    $$ = complete_case_node($3, $6);
  }
| BEGIN_TAG FORM expr END_TAG exprs endform {
    /* obviously stupid redundancy in these form tag handlers, refactor would
     * be good... */
    $$ = new_form_node($3, NULL, NULL, $5);
  }
| BEGIN_TAG FORM expr ',' expr END_TAG exprs endform {
    $$ = new_form_node($3, $5, NULL, $7);
  }
| BEGIN_TAG FORM expr ',' kwarglist END_TAG exprs endform {
    $$ = new_form_node($3, NULL, $5, $7);
  }
| BEGIN_TAG FORM expr ',' expr ',' kwarglist END_TAG exprs endform {
    $$ = new_form_node($3, $5, $7, $9);
  }
;

maybe_text:
  %empty
| TEXT
;

whens_endcase:
  BEGIN_TAG WHEN expr END_TAG exprs whens_endcase {
    $$ = merge_case_node($3, $5, $6);
  }
| else exprs endcase         { $$ = new_case_node($2); }
| endcase                    { $$ = new_case_node(NULL); }
;

elsifs_else_endif:
  BEGIN_TAG ELSIF expr END_TAG exprs elsifs_else_endif {
    $$ = merge_elsif_node($3, $5, $6);
  }
| else exprs endif           { $$ = new_if_node(NULL, NULL, $2); }
| endif                      { $$ = new_if_node(NULL, NULL, NULL); }
;

elsifs_else_endunless:
  BEGIN_TAG ELSIF expr END_TAG exprs elsifs_else_endunless {
    $$ = merge_elsif_node($3, $5, $6);
  }
| else exprs endunless       { $$ = new_if_node(NULL, NULL, $2); }
| endunless                  { $$ = new_if_node(NULL, NULL, NULL); }
;

kwarglist:
  %empty                     { $$ = NULL; }
| kwarglist0
;

kwarglist0:
  argname expr               { $$ = add_expr_to_exprs(NULL, $1); }
  /* TODO: capture names */
| kwarglist0 ',' argname expr { $$ = add_expr_to_exprs($1, $3); }
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

endstyle:    BEGIN_TAG ENDSTYLE    END_TAG ;
endcapture:  BEGIN_TAG ENDCAPTURE  END_TAG ;
endpaginate: BEGIN_TAG ENDPAGINATE END_TAG ;
endtablerow: BEGIN_TAG ENDTABLEROW END_TAG ;
endfor:      BEGIN_TAG ENDFOR      END_TAG ;
endif:       BEGIN_TAG ENDIF       END_TAG ;
else:        BEGIN_TAG ELSE        END_TAG ;
endunless:   BEGIN_TAG ENDUNLESS   END_TAG ;
endcase:     BEGIN_TAG ENDCASE     END_TAG ;
endform:     BEGIN_TAG ENDFORM     END_TAG ;

texpr0:
  ASSIGN id '=' fexpr        { $$ = new_assign_node($2, $4); }
| S_ECHO fexpr               { $$ = new_echo_node($2); }
| INCREMENT id               { $$ = new_increment_node($2); }
| DECREMENT id               { $$ = new_decrement_node($2); }
| INCLUDE expr               { $$ = new_include_node($2); }
| LAYOUT expr                { $$ = new_layout_node($2); }
| SECTION expr               { $$ = new_section_node($2); }
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
  member            %prec '.'
| indexation        %prec '['
| literal
| id
| tag
| expr compare expr %prec EQUALS { $$ = new_compare_node($2, $1, $3); }
| expr and_or expr  %prec AND    { $$ = new_compare_node($2, $1, $3); }
;

and_or:
  AND        { $$ = COMP_AND; }
| OR         { $$ = COMP_OR; }
;

compare:
  EQUALS     { $$ = COMP_EQUALS; }
| NOT_EQUALS { $$ = COMP_NOT_EQUALS; }
| '<'        { $$ = COMP_LT; }
| '>'        { $$ = COMP_GT; }
| GTE        { $$ = COMP_GTE; }
| LTE        { $$ = COMP_LTE; }
| SPACESHIP  { $$ = COMP_SPACESHIP; }
| CONTAINS   { $$ = COMP_CONTAINS; }
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

node *new_tablerow_node(node *varname, node *array, node *arglist, node *exprs, node *range_end, bool reversed, bool range) {
  node *node = setup_node(NODE_TABLEROW);
  if (reversed) {
    node->flags = ND_FLAG_TABLEROW_REVERSED;
  }
  node->nd_tablerow_varname = varname->nd_string;
  node->nd_tablerow_arglist = arglist;
  node->nd_tablerow_ext = setup_node(NODE_TABLEROW_EXT);
  node->nd_tablerow_ext->nd_tablerow_ext_exprs = exprs;
  if (range) {
    node->flags &= ND_FLAG_TABLEROW_RANGE;
    node->nd_tablerow_ext->nd_tablerow_ext_range_begin = array;
    node->nd_tablerow_ext->nd_tablerow_ext_range_end = range_end;
  } else {
    node->nd_tablerow_ext->nd_tablerow_ext_array = array;
  }
  return node;
}

node *new_for_node(node *varname, node *array, node *arglist, node *exprs, node *range_end, bool reversed, bool range) {
  node *node = setup_node(NODE_FOR);
  if (reversed) {
    node->flags = ND_FLAG_FOR_REVERSED;
  }
  node->nd_for_varname = varname->nd_string;
  node->nd_for_arglist = arglist;
  node->nd_for_ext = setup_node(NODE_FOR_EXT);
  node->nd_for_ext->nd_for_ext_exprs = exprs;
  if (range) {
    node->flags &= ND_FLAG_FOR_RANGE;
    node->nd_for_ext->nd_for_ext_range_begin = array;
    node->nd_for_ext->nd_for_ext_range_end = range_end;
  } else {
    node->nd_for_ext->nd_for_ext_array = array;
  }
  return node;
}

node *new_if_node(node *cond, node *then_branch, node *else_branch) {
  node *node = setup_node(NODE_IF);
  node->nd_if_cond = cond;
  node->nd_if_then = then_branch;
  node->nd_if_else = else_branch;
  return node;
}

node *new_unless_node(node *cond, node *then_branch, node *else_branch) {
  node *node = setup_node(NODE_IF);
  node->nd_if_cond = cond;
  node->nd_if_then = else_branch;
  node->nd_if_else = then_branch;
  return node;
}

node *new_compare_node(enum comparator_t comp, node *left, node *right) {
  node *node = setup_node(NODE_COMPARE);
  node->nd_compare_type = comp;
  node->nd_compare_left = left;
  node->nd_compare_right = right;
  return node;
}

node *merge_elsif_node(node *cond, node *then, node *else_) {
  node *node = setup_node(NODE_IF);
  node->nd_if_cond = cond;
  node->nd_if_then = then;
  if (else_->node_type == NODE_IF && else_->nd_if_cond == NULL) {
    /* because the else node in an if/elsif/else chain builds an IF node with
     * NULL,NULL,exprs. It's a slightly confusing hack. Maybe we can do better.
     */
    node->nd_if_else = else_->nd_if_else;
  } else {
    node->nd_if_else = else_;
  }
  return node;
}

node *complete_unless_node(node *cond, node *then, node *else_) {
  if (else_ == NULL) {
    /* this was unless/endunless */
    node *node = setup_node(NODE_IF);
    node->nd_if_cond = cond;
    node->nd_if_else = then; // invert
    return node;
  }
  // else_ is guaranteed to be NODE_IF
  if (else_->nd_if_cond == NULL) {
    /* this was unless/else/endunless. Reuse the else_ node, but invert it
     * because this is an unless */
    else_->nd_if_cond = cond;
    else_->nd_if_then = else_->nd_if_else;
    else_->nd_if_else = then;
    return else_;
  }

  /* we had at least one elsif */
  node *node = setup_node(NODE_IF);
  node->nd_if_cond = cond;
  node->nd_if_then = else_;
  node->nd_if_else = then;
  return node;
}

node *complete_if_node(node *cond, node *then, node *else_) {
  if (else_ == NULL) {
    /* this was if/endif */
    node *node = setup_node(NODE_IF);
    node->nd_if_cond = cond;
    node->nd_if_then = then;
    return node;
  }
  // else_ is guaranteed to be NODE_IF
  if (else_->nd_if_cond == NULL) {
    /* this was if/else/endif. Reuse the else_ node */
    else_->nd_if_cond = cond;
    else_->nd_if_then = then;
    return else_;
  }

  /* we had at least one elsif */
  node *node = setup_node(NODE_IF);
  node->nd_if_cond = cond;
  node->nd_if_then = then;
  node->nd_if_else = else_;
  return node;
}

node *new_case_node(node *else_) {
  node *node = setup_node(NODE_CASE);
  node->nd_case_else = else_;
  return node;
}

node *merge_case_node(node *cond, node *then, node *case_node) {
  node *cw_node = setup_node(NODE_CASE_WHEN);
  cw_node->nd_case_when_cond = cond;
  cw_node->nd_case_when_then = then;
  cw_node->nd_case_when_next = case_node->nd_case_whens;
  case_node->nd_case_whens = cw_node;
  return case_node;
}

node *complete_case_node(node *var, node *case_node) {
  case_node->nd_case_var = var;
  return case_node;
}

node *new_form_node(node *type, node *obj, node *kwarglist, node *exprs) {
  node *node = setup_node(NODE_FORM);
  node->nd_form_type = type;
  node->nd_form_obj = obj;
  node->nd_form_ext = setup_node(NODE_FORM_EXT);
  node->nd_form_ext->nd_form_ext_kwarglist = kwarglist;
  node->nd_form_ext->nd_form_ext_exprs = exprs;
  return node;
}
