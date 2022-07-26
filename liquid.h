#ifndef __LIQUID_H__
#define __LIQUID_H__

#include <stdbool.h>

/* More efficient implementation for AST:
 * Each level of the tree is a vector, and children point to element in next
 * level.
 */

#define nd_int u1._int
#define nd_bool u1._bool
#define nd_double u1._double
#define nd_string u1.str

/* if/unless */
#define nd_cond u1.node
#define nd_then u2.node
#define nd_else u3.node

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
};

struct node {
  enum node_type_t node_type;
  union u1 {
    int _int;
    bool _bool;
    double _double;
    char *str;
    struct node *node;
  } u1;
  union u2 {
    char *str;
    struct node *node;
  } u2;
  union u3 {
    struct node *node;
    struct node **nodelist;
  } u3; 
};
typedef struct node node;

node *new_int_node(int val);
node *new_float_node(double val);
node *new_text_node(char *val);
node *new_bool_node(bool val);
node *new_id_node(char *val);
node *new_string_node(char *val);
node *new_member_node(node *left, node *right);
node *new_if_node(node *cond, node *then, node *else_);
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

node *add_arg_to_filter(node *filter, node *argname, node *argval);
node *new_exprs_node();
node *add_expr_to_exprs(node *exprs, node *expr);
node *add_expr_to_cycle(node *cycle, node *item);

void free_ast(node *ast);
#endif
