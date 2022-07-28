#ifndef __LIQUID_H__
#define __LIQUID_H__

#include <stdbool.h>
#include <stdint.h>

/* More efficient implementation for AST:
 * Each level of the tree is a vector, and children point to element in next
 * level.
 */

#define nd_int u1._int
#define nd_bool u1._bool
#define nd_double u1._double
#define nd_string u1.str

/* assign, filter args */
#define nd_name u1.str
#define nd_val u2.node
#define nd_nextarg u3.node

/* member */
#define nd_left u1.node
#define nd_member_name u2.str

/* filter */
#define nd_filter_input u1.node
#define nd_filter_name u2.str
#define nd_filter_args u3.node

/* exprs */
#define nd_expr1 u1.node
#define nd_expr2 u2.node
#define nd_expr_rest u3.nodelist

/* echo */
#define nd_content u1.node

/* indexation (nd_left = u1.node) */
#define nd_index u2.node

/* cycle */
#define nd_groupname u1.str
#define nd_items u2.node

#define nd_paginate_array u1.node
#define nd_paginate_page_size u2.node
#define nd_paginate_exprs u3.node

/* tablerow and for need to hold (varname, array, arglist, exprs) Rather than
 * add a fourth union to _every_ node, we introduce an extension node: each
 * tablerow or for call is actually represented by at least two nodes. */
#define nd_tablerow_varname u1.str
#define nd_tablerow_arglist u2.node
#define nd_tablerow_ext u3.node
#define nd_tablerow_ext_exprs u1.node
#define nd_tablerow_ext_array u2.node
#define nd_tablerow_ext_range_begin u2.node
#define nd_tablerow_ext_range_end u3.node

#define ND_FLAG_TABLEROW_REVERSED 1<<0
#define ND_FLAG_TABLEROW_RANGE 1<<1

#define nd_for_varname u1.str
#define nd_for_arglist u2.node
#define nd_for_ext u3.node
#define nd_for_ext_exprs u1.node
#define nd_for_ext_array u2.node
#define nd_for_ext_range_begin u2.node
#define nd_for_ext_range_end u3.node

#define ND_FLAG_FOR_REVERSED 1<<0
#define ND_FLAG_FOR_RANGE 1<<1

/* unless is the same node type as if, just with then and else reversed */
#define nd_if_cond u1.node
#define nd_if_then u2.node
#define nd_if_else u3.node

#define nd_compare_type u1.comparator
#define nd_compare_left u2.node
#define nd_compare_right u3.node

#define nd_case_var u1.node
#define nd_case_whens u2.node
#define nd_case_else u3.node

#define nd_case_when_cond u1.node
#define nd_case_when_then u2.node
#define nd_case_when_next u3.node

#define nd_form_type u1.node
#define nd_form_obj u2.node
#define nd_form_ext u3.node
#define nd_form_ext_kwarglist u1.node
#define nd_form_ext_exprs u2.node

enum node_type_t {
  NODE_TEXT = 0,
  NODE_STRING = 1,
  NODE_ID = 2,
  NODE_INT = 3,
  NODE_FLOAT = 4,
  NODE_BOOL = 5,
  NODE_MEMBER = 6,
  NODE_IF = 7,
  NODE_ASSIGN = 8,
  NODE_FILTER = 9,
  NODE_ARG = 10,
  NODE_EXPRS = 11,
  NODE_ARGNAME = 12,
  NODE_ECHO = 13,
  NODE_INDEXATION = 14,
  NODE_INCREMENT = 15,
  NODE_DECREMENT = 16,
  NODE_INCLUDE = 17,
  NODE_NONE = 18,
  NODE_EMPTY = 19,
  NODE_BLANK = 20,
  NODE_LAYOUT = 21,
  NODE_SECTION = 22,
  NODE_STYLE = 23,
  NODE_CAPTURE = 24,
  NODE_CYCLE = 25,
  NODE_PAGINATE = 26,
  NODE_TABLEROW = 27,
  NODE_TABLEROW_EXT = 28,
  NODE_FOR = 29,
  NODE_FOR_EXT = 30,
  NODE_COMPARE = 31,
  NODE_AND_OR = 32,
  NODE_CASE = 33,
  NODE_CASE_WHEN = 34,
  NODE_FORM = 35,
  NODE_FORM_EXT = 36,
} __attribute__ ((__packed__)); /* uint8_t... assert? */

enum comparator_t {
  COMP_EQUALS = 0,
  COMP_NOT_EQUALS = 1,
  COMP_LT = 2,
  COMP_GT = 3,
  COMP_GTE = 4,
  COMP_LTE = 5,
  COMP_SPACESHIP = 6,
  COMP_CONTAINS = 7,
  COMP_AND = 8,
  COMP_OR = 9,
};

struct node {
  enum node_type_t node_type; /* 1 byte */
  uint8_t flags;
  /* 6 bytes of padding */
  union u1 {
    int _int;
    bool _bool;
    double _double;
    char *str;
    struct node *node;
    enum comparator_t comparator;
  } u1; /* 8 bytes */
  union u2 {
    char *str;
    struct node *node;
  } u2; /* 8 bytes */
  union u3 {
    struct node *node;
    struct node **nodelist;
  } u3; /* 8 bytes */
}; /* 32 bytes... assert? */
typedef struct node node;

node *new_int_node(int val);
node *new_float_node(double val);
node *new_text_node(char *val);
node *new_bool_node(bool val);
node *new_id_node(char *val);
node *new_string_node(char *val);
node *new_member_node(node *left, node *right);
node *new_filter_node(node *input, node *name);
node *new_argname_node(char *val);
node *new_echo_node(node *content);
node *new_indexation_node(node *left, node *index);
node *new_assign_node(node *id, node *fexpr);
node *new_increment_node(node *id);
node *new_decrement_node(node *id);
node *new_include_node(node *name);
node *new_none_node();
node *new_empty_node();
node *new_blank_node();
node *new_layout_node(node *arg);
node *new_section_node(node *arg);
node *new_style_node(node *exprs);
node *new_capture_node(node *varname, node *exprs);
node *new_cycle_node(node *groupname, node *arglist);
node *new_paginate_node(node *array, node *page_size, node *exprs);
node *new_tablerow_node(node *varname, node *array, node *arglist, node *exprs, node *range_end, bool reversed, bool range);
node *new_for_node(node *varname, node *array, node *arglist, node *exprs, node *range_end, bool reversed, bool range);
node *new_if_node(node *cond, node *then_branch, node *else_branch);
node *new_unless_node(node *cond, node *then_branch, node *else_branch);
node *new_compare_node(enum comparator_t comp, node *left, node *right);
node *new_case_node(node *else_);
node *new_form_node(node *type, node *obj, node *kwarglist, node *exprs);

node *add_arg_to_filter(node *filter, node *argname, node *argval);
node *new_exprs_node();
node *add_expr_to_exprs(node *exprs, node *expr);
node *merge_elsif_node(node *cond, node *then, node *else_);
node *complete_if_node(node *cond, node *then, node *else_);
node *complete_unless_node(node *cond, node *then, node *else_);
node *merge_case_node(node *cond, node *then, node *case_node);
node *complete_case_node(node *var, node *case_node);

void free_ast(node *ast);
#endif
