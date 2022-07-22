%{
#include <stdio.h>
#include <stdlib.h>

int yylex();
void yyerror(char *msg);
%}

%token START 
%token RAW COMMENT

%%
start: START
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
