/* %option debug */

%{
#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include "liquid.tab.h"

bool ll_init = true;
void yyerror(char *msg);
%}

/* Initial state, where text is literally copied to output until we encounter
 * {{ or {% */
%state S_TEXT

/* After -%} or -}}, we drop whitespace before returning to TEXT */
%state S_EAT_WS

/* Interior of a {% tag %} */
%state S_TAG

/* Interior of an {{ output }} */
%state S_OUTPUT

%state S_RAW

%state S_COMMENT

ID_char [^[:space:]!"#%&'()*+,./;<=>[\\\]^`{|}~]
ID      {ID_char}+
space   [ \n\v\f\t\r]

%%
%{
  /* Start in the TEXT state */
  if (ll_init) {
    ll_init = false;
    BEGIN S_TEXT;
  }
%}

<S_TEXT>[^{]+        { printf("\x1b[32m<Text:%s>\x1b[0m\n", yytext); }
<S_TEXT>"{"          { yymore(); }
<S_TEXT>"{{"-?       { BEGIN S_OUTPUT; }
<S_TEXT>"{%"-?       { BEGIN S_TAG; }

 /* Leading whitespace trimming:
    When we see {%- or {{- in TEXT state, trim all the trailing spaces from the
    text preceding the {%- or {{-, and put the {%- or {{- back in the input
    stream to be reinterpreted.
  */
<S_TEXT>[^{]*"{%-"   |
<S_TEXT>[^{]*"{{-"   {
                       yyless(yyleng - 3); // put back the "{%-" or "{{-"

                       yy_size_t len = yyleng;
                       char *c = yytext + yyleng;
                       while (len > 0 && isspace(*(--c) )) --len;
                       if (len != 0) ++c;
                       *c = 0;
                       printf("\x1b[31m<Text:%s>\x1b[0m\n", yytext);
                     }

<S_OUTPUT,S_TAG>{ID} { printf("id: !!!%s!!!\n", yytext); }

<S_OUTPUT,S_TAG>{space}+ ;

<S_OUTPUT>"}}"       { BEGIN S_TEXT; }
<S_TAG>"%}"          { BEGIN S_TEXT; }

<S_TAG>"raw"{space}*-?"%}" { BEGIN S_RAW; }
<S_TAG>"comment"{space}*-?"%}" { BEGIN S_COMMENT; }

<S_COMMENT>"{%"-?{space}*"endcomment"{space}*"%}" { BEGIN S_TEXT; }
<S_COMMENT>"{%"-?{space}*"endcomment"{space}*"-%}" { BEGIN S_EAT_WS; }
<S_COMMENT>[^{]*     ;
<S_COMMENT>"{"       { yymore(); }

 /* TODO: remove the {%endraw%}
  * TODO: What does {%- endraw %} do?
  */
<S_RAW>.*"{%"-?{space}*"endraw"{space}*"%}" {
                       printf("\x1b[31m<Text:%s>\x1b[0m\n", yytext);
                       BEGIN S_TEXT;
                     }
<S_RAW>.*"{%"-?{space}*"endraw"{space}*"-%}" {
                       BEGIN S_EAT_WS;
                     }

 /* -}} and -%} don't go directly back to TEXT; they first go to an EAT_WS
  * state that drops leading spaces before returning to TEXT */
<S_OUTPUT>"-}}"      { BEGIN S_EAT_WS; }
<S_TAG>"-%}"         { BEGIN S_EAT_WS; }

 /* After -%} or -}}, drop contiguous whitespace */
<S_EAT_WS>{space}*   { BEGIN S_TEXT; }
<S_EAT_WS>.          { yyless(0); BEGIN S_TEXT; }


.                    { yyerror("unhandled character in input"); }

%%

void yyerror(char *msg) {
  fprintf(stderr, "error: %s", msg);
  exit(1);
}

int main() {
  yylex();
}
