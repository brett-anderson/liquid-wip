#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "liquid.h"
#include "dump.h"

void yyerror(const char *yymsgp);

void dump_indent(node *n, int indent);
void dump_exprs(node *n, int indent);
void dump_filter(node *n, int indent);
void dump_member(node *n, int indent);
void dump_echo(node *n, int indent);
void dump_indexation(node *n, int indent);
void dump_assign(node *n, int indent);
void dump_include(node *n, int indent);
void dump_layout(node *n, int indent);
void dump_section(node *n, int indent);
void dump_bool(node *n, int indent);
void dump_style(node *n, int indent);
void dump_capture(node *n, int indent);
void dump_cycle(node *n, int indent);
void dump_paginate(node *n, int indent);
void dump_tablerow(node *n, int indent);
void dump_for(node *n, int indent);
void dump_compare(node *n, int indent);
void dump_if(node *n, int indent);
void dump_case(node *n, int indent);
void dump_form(node *n, int indent);
char *escape(char *buffer);

void dump(node *n) {
  dump_indent(n, 0);
}

void dump_indent(node *n, int indent) {
  switch (n->node_type) {
    case NODE_TEXT:
      printf("%*s(TEXT) `%s`\n", indent, "", escape(n->nd_string));
      break;
    case NODE_STRING:
      printf("%*s(STRING) `%s`\n", indent, "", escape(n->nd_string));
      break;
    case NODE_ID:
      printf("%*s(ID) %s\n", indent, "", n->nd_string);
      break;
    case NODE_INT:
      printf("%*s(INT) %d\n", indent, "", n->nd_int);
      break;
    case NODE_FLOAT:
      printf("%*s(FLOAT) %f\n", indent, "", n->nd_double);
      break;
    case NODE_BOOL:
      dump_bool(n, indent);
      break;
    case NODE_MEMBER:
      dump_member(n, indent);
      break;
    case NODE_IF:
      dump_if(n, indent);
      break;
    case NODE_ASSIGN:
      dump_assign(n, indent);
      break;
    case NODE_FILTER:
      dump_filter(n, indent);
      break;
    case NODE_ARG:
      printf("%*s%s\n", indent, "", "<ARG>");
      break;
    case NODE_EXPRS:
      dump_exprs(n, indent);
      break;
    case NODE_ARGNAME:
      printf("%*s(ARGNAME) %s\n", indent, "", n->nd_string);
      break;
    case NODE_ECHO:
      dump_echo(n, indent);
      break;
    case NODE_INDEXATION:
      dump_indexation(n, indent);
      break;
    case NODE_INCREMENT:
      printf("%*sIncrement (%s)\n", indent, "", n->nd_name);
      break;
    case NODE_DECREMENT:
      printf("%*sDecrement (%s)\n", indent, "", n->nd_name);
      break;
    case NODE_INCLUDE:
      dump_include(n, indent);
      break;
    case NODE_NONE:
      printf("%*s<none>\n", indent, "");
      break;
    case NODE_EMPTY:
      printf("%*s<empty>\n", indent, "");
      break;
    case NODE_BLANK:
      printf("%*s<blank>\n", indent, "");
      break;
    case NODE_LAYOUT:
      dump_layout(n, indent);
      break;
    case NODE_SECTION:
      dump_section(n, indent);
      break;
    case NODE_STYLE:
      dump_style(n, indent);
      break;
    case NODE_CAPTURE:
      dump_capture(n, indent);
      break;
    case NODE_CYCLE:
      dump_cycle(n, indent);
      break;
    case NODE_PAGINATE:
      dump_paginate(n, indent);
      break;
    case NODE_TABLEROW:
      dump_tablerow(n, indent);
      break;
    case NODE_FOR:
      dump_for(n, indent);
      break;
    case NODE_COMPARE:
      dump_compare(n, indent);
      break;
    case NODE_CASE:
      dump_case(n, indent);
      break;
    case NODE_FORM:
      dump_form(n, indent);
      break;
    default:
      yyerror("dump not written for node type!");
      break;
  }
}

void dump_exprs(node *n, int indent) {
  printf("%*s%s\n", indent, "", "Exprs:");

  node *sub = n->nd_expr1;
  if (sub != NULL) {
    /* printf("%*s%s\n", indent + 2, "", "Expr[0]"); */
    dump_indent(sub, indent + 2);
  }

  sub = n->nd_expr2;
  if (sub != NULL) {
    /* printf("%*s%s\n", indent + 2, "", "Expr[1]"); */
    dump_indent(sub, indent + 2);
  }

  node **subs = n->nd_expr_rest;
  if (subs != NULL) {
    for (int i = 0; i < 128; i++) {
      sub = subs[i];
      if (sub == NULL) break;
      /* printf("%*sExpr[%d]\n", indent + 2, "", i + 2); */
      dump_indent(sub, indent + 2);
    }
  }
}

void dump_echo(node *n, int indent) {
  printf("%*s%s\n", indent, "", "Echo:");
  dump_indent(n->nd_content, indent + 2);
}

void dump_member(node *n, int indent) {
  printf("%*sMember '%s' of:\n", indent, "", n->nd_member_name);
  dump_indent(n->nd_left, indent + 2);
}

void dump_if(node *n, int indent) {
  printf("%*sIf:\n", indent, "");
  printf("%*sCond:\n", indent + 2, "");
  dump_indent(n->nd_if_cond, indent + 4);
  if (n->nd_if_then != NULL) {
    printf("%*sThen:\n", indent + 2, "");
    dump_indent(n->nd_if_then, indent + 4);
  }
  if (n->nd_if_else != NULL) {
    printf("%*sElse:\n", indent + 2, "");
    dump_indent(n->nd_if_else, indent + 4);
  }
}

void dump_indexation(node *n, int indent) {
  printf("%*sIndexation:\n", indent, "");
  printf("%*sOf:\n", indent + 2, "");
  dump_indent(n->nd_left, indent + 4);
  printf("%*sIndex:\n", indent + 2, "");
  dump_indent(n->nd_index, indent + 4);
}

void dump_assign(node *n, int indent) {
  printf("%*sAssign (%s):\n", indent, "", n->nd_name);
  dump_indent(n->nd_val, indent + 2);
}

void dump_include(node *n, int indent) {
  printf("%*sInclude:\n", indent, "");
  dump_indent(n->nd_expr1, indent + 2);
}

void dump_layout(node *n, int indent) {
  printf("%*sLayout:\n", indent, "");
  dump_indent(n->nd_expr1, indent + 2);
}

void dump_section(node *n, int indent) {
  printf("%*sSection:\n", indent, "");
  dump_indent(n->nd_expr1, indent + 2);
}

void dump_bool(node *n, int indent) {
  if (n->nd_bool) {
    printf("%*s<true>\n", indent, "");
  } else {
    printf("%*s<false>\n", indent, "");
  }
}

void dump_style(node *n, int indent) {
  printf("%*sStyle:\n", indent, "");
  dump_indent(n->nd_expr1, indent + 2);
}

void dump_capture(node *n, int indent) {
  printf("%*sCapture (%s):\n", indent, "", n->nd_string);
  dump_indent(n->nd_expr2, indent + 2);
}

void dump_cycle(node *n, int indent) {
  if (n->nd_groupname == NULL) {
    printf("%*sCycle (default):\n", indent, "");
  } else {
    printf("%*sCycle (%s):\n", indent, "", n->nd_groupname);
  }
  dump_indent(n->nd_items, indent + 2);
}

void dump_paginate(node *n, int indent) {
  printf("%*sPaginate:\n", indent, "");
  printf("%*sArray:\n", indent + 2, "");
  dump_indent(n->nd_paginate_array, indent + 4);
  printf("%*sPage Size:\n", indent + 2, "");
  dump_indent(n->nd_paginate_page_size, indent + 4);
  printf("%*sExprs:\n", indent + 2, "");
  dump_indent(n->nd_paginate_exprs, indent + 4);
}

void dump_tablerow(node *n, int indent) {
  printf("%*sTablerow (%s) (reverse=%d):\n", indent, "", n->nd_tablerow_varname, n->flags & ND_FLAG_TABLEROW_REVERSED);

  if (0 == (n->flags & ND_FLAG_TABLEROW_RANGE)) {
    printf("%*sArray:\n", indent + 2, "");
    dump_indent(n->nd_tablerow_ext->nd_tablerow_ext_array, indent + 4);
  } else {
    printf("%*sRangeBegin:\n", indent + 2, "");
    dump_indent(n->nd_tablerow_ext->nd_tablerow_ext_range_begin, indent + 4);
    printf("%*sRangeEnd:\n", indent + 2, "");
    dump_indent(n->nd_tablerow_ext->nd_tablerow_ext_range_end, indent + 4);
  }

  printf("%*sArgs:\n", indent + 2, "");
  if (NULL == n->nd_tablerow_arglist) {
    printf("%*s(none)\n", indent + 4, "");
  } else {
    dump_indent(n->nd_tablerow_arglist, indent + 4);
  }
  printf("%*sExprs:\n", indent + 2, "");
  dump_indent(n->nd_tablerow_ext->nd_tablerow_ext_exprs, indent + 4);
}

void dump_for(node *n, int indent) {
  printf("%*sFor (%s) (reverse=%d):\n", indent, "", n->nd_for_varname, n->flags & ND_FLAG_FOR_REVERSED);

  if (0 == (n->flags & ND_FLAG_FOR_RANGE)) {
    printf("%*sArray:\n", indent + 2, "");
    dump_indent(n->nd_for_ext->nd_for_ext_array, indent + 4);
  } else {
    printf("%*sRangeBegin:\n", indent + 2, "");
    dump_indent(n->nd_for_ext->nd_for_ext_range_begin, indent + 4);
    printf("%*sRangeEnd:\n", indent + 2, "");
    dump_indent(n->nd_for_ext->nd_for_ext_range_end, indent + 4);
  }

  printf("%*sArgs:\n", indent + 2, "");
  if (NULL == n->nd_for_arglist) {
    printf("%*s(none)\n", indent + 4, "");
  } else {
    dump_indent(n->nd_for_arglist, indent + 4);
  }
  printf("%*sExprs:\n", indent + 2, "");
  dump_indent(n->nd_for_ext->nd_for_ext_exprs, indent + 4);
}

void dump_compare(node *n, int indent) {
  printf("%*sCompare (%d):\n", indent, "", n->nd_compare_type);
  printf("%*sLeft:\n", indent + 2, "");
  dump_indent(n->nd_compare_left, indent + 4);
  printf("%*sRight:\n", indent + 2, "");
  dump_indent(n->nd_compare_right, indent + 4);
}

void dump_case(node *n, int indent) {
  printf("%*sCase:\n", indent, "");
  printf("%*sOf:\n", indent + 2, "");
  dump_indent(n->nd_case_var, indent + 4);

  printf("%*sWhens:\n", indent + 2, "");
  node *curr = n->nd_case_whens;
  while (curr != NULL) {
    printf("%*sCond:\n", indent + 4, "");
    dump_indent(curr->nd_case_when_cond, indent + 6);
    printf("%*sThen:\n", indent + 4, "");
    dump_indent(curr->nd_case_when_then, indent + 6);
    curr = curr->nd_case_when_next;
  }

  if (n->nd_case_else != NULL) {
    printf("%*sElse:\n", indent + 2, "");
    dump_indent(n->nd_case_else, indent + 4);
  }
}

void dump_form(node *n, int indent) {
  printf("%*sForm:\n", indent, "");
  printf("%*sType:\n", indent + 2, "");
  dump_indent(n->nd_form_type, indent + 4);

  if (n->nd_form_obj != NULL) {
    printf("%*sObj:\n", indent + 2, "");
    dump_indent(n->nd_form_obj, indent + 4);
  }

  node *ext = n->nd_form_ext;
  if (ext->nd_form_ext_kwarglist != NULL) {
    printf("%*sKwarglist:\n", indent + 2, "");
    dump_indent(ext->nd_form_ext_kwarglist, indent + 4);
  }

  printf("%*sExprs:\n", indent + 2, "");
  dump_indent(ext->nd_form_ext_exprs, indent + 4);
}

void dump_filter(node *n, int indent) {
  printf("%*sFilter (%s):\n", indent, "", n->nd_filter_name);

  printf("%*s%s\n", indent + 2, "", "Input");
  dump_indent(n->nd_filter_input, indent + 4);

  node *argp = n->nd_filter_args;
  while (argp != NULL) {
    printf("%*sArg(%s):\n", indent + 2, "", argp->nd_name);
    dump_indent(argp->nd_val, indent + 4);
    argp = argp->nd_nextarg;
  }
}

char* escape(char* buffer){
  int i,j;
  int l = strlen(buffer) + 1;
  char esc_char[]= { '\a','\b','\f','\n','\r','\t','\v','\\'};
  char essc_str[]= {  'a', 'b', 'f', 'n', 'r', 't', 'v','\\'};
  char* dest  =  (char*)calloc( l*2,sizeof(char));
  char* ptr=dest;
  for(i=0;i<l;i++){
    for(j=0; j< 8 ;j++){
      if( buffer[i]==esc_char[j] ){
        *ptr++ = '\\';
        *ptr++ = essc_str[j];
        break;
      }
    }
    if(j == 8 )
      *ptr++ = buffer[i];
  }
  *ptr='\0';
  return dest;
}
