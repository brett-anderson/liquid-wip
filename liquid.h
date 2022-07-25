#include <stdbool.h>

/* More efficient implementation for AST:
 * Each level of the tree is a vector, and children point to element in next
 * level.
 */

enum node_type_t {
  nt_text = 0,
  nt_string = 1,
  nt_id = 2,
  nt_int = 3,
  nt_float = 4,
};

struct node {
  enum node_type_t node_type;
  struct node **children;
  union as {
    int _int;
    bool _bool;
    double _double;
    char *str;
    void *ptr;
  } as;
};
typedef struct node node;

node new_node0(enum node_type_t type);
node new_node1(enum node_type_t type, node *child0);
node new_node2(enum node_type_t type, node *child0, node *child1);

node *new_int_node(int val);
node *new_float_node(double val);
node *new_text_node(char *val);
node *new_bool_node(bool val);

void free_ast(node *ast);
