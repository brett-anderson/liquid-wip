/* %option debug */

%{
#include <ctype.h>
#include <stdbool.h>
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

 /* TODO: find the correct set of valid chars */
ID_char [^[:space:]:!"#%&'()*+,./;<=>[\\\]^`{|}~]
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

 /* Liquid parsing/lexing has two big conceptual "modes":
  * 1. Text mode, outside of {{}}/{%%} pairs; and
  * 2. Tag/Output mode, inside of those blocks.
  *
  * In Tag/Output mode, we have a rudimentary programming language with sort of
  * typical programming language syntax and semantics, and in Text mode, we
  * have text emitted directly, until we encounter something that puts us in
  * Tag/Output mode.
  *
  * The tags {%raw%} and {%comment%} are handled via special cases here in
  * the lexer, since they require us to disable interpretation of their
  * contents. The parser never sees comments, and receives the contents of
  * {%raw%} blocks just like any other text from Text mode.
  */

 /**** TEXT MODE *************************************************************/

 /* Text mode is mainly concerned with figuring out when we're no longer in
  * Text mode. We read until '{', then force another character read to evaluate
  * whether we're looking at a {{/{%.
  *
  * This is kind of sub-optimal in that when we encounter a '{' that doesn't
  * indicate Tag/Output mode, we split unnecessarily into a new TEXT token.
  */
<S_TEXT>[^{]+        { yylval.str = yytext; return TEXT; }
<S_TEXT>"{"          { yymore(); }

 /* TODO: {% raw -%} probably trims space inside */
<S_TEXT>"{%"-?{space}*"raw"{space}*-?"%}"     { BEGIN S_RAW; }
<S_TEXT>"{%"-?{space}*"comment"{space}*-?"%}" { BEGIN S_COMMENT; }

<S_TEXT>"{{"-?       { BEGIN S_OUTPUT; }
<S_TEXT>"{%"-?       { BEGIN S_TAG; }

 /* Leading whitespace trimming:
    When we see {%- or {{- in TEXT state, trim all the trailing spaces from the
    text preceding the {%- or {{-, and put the {%- or {{- back in the input
    stream to be reinterpreted (by the rules immediately prior to this one).
  */
<S_TEXT>[^{]*"{%-"   |
<S_TEXT>[^{]*"{{-"   {
                       yyless(yyleng - 3); // put back the "{%-" or "{{-"

                       yy_size_t len = yyleng;
                       char *c = yytext + yyleng;
                       while (len > 0 && isspace(*(--c) )) --len;
                       if (len != 0) ++c;
                       *c = 0;
                       yylval.str = yytext;
                       return TEXT;
                     }

<S_OUTPUT>"}}"       { BEGIN S_TEXT; }
<S_TAG>"%}"          { BEGIN S_TEXT; }

 /* -}} and -%} don't go directly back to TEXT; they first go to an EAT_WS
  * state that drops leading spaces before returning to TEXT */
<S_OUTPUT>"-}}"      { BEGIN S_EAT_WS; }
<S_TAG>"-%}"         { BEGIN S_EAT_WS; }

 /* Comments are dropped here in the lexer: they don't make it to the parser.
  */
<S_COMMENT>"{%"-?{space}*"endcomment"{space}*"%}" { BEGIN S_TEXT; }
<S_COMMENT>"{%"-?{space}*"endcomment"{space}*"-%}" { BEGIN S_EAT_WS; }
<S_COMMENT>[^{]*     ;
<S_COMMENT>"{"       { yymore(); }

 /* TODO: remove the {%endraw%}
  * TODO: What does {%- endraw %} do?
  *
  * TODO next: get this passing. Consume chars until we have what we're looking
  * for.
  */
<S_RAW>"{%"-?{space}*"endraw"{space}*"%}" { BEGIN S_TEXT; }
<S_RAW>"{%"-?{space}*"endraw"{space}*"-%}" { BEGIN S_EAT_WS; }
<S_RAW>[^{]+         { yylval.str = yytext; return TEXT; }
<S_RAW>"{"           { yymore(); }

 /* After -%} or -}}, drop contiguous whitespace */
<S_EAT_WS>{space}*   { BEGIN S_TEXT; }
<S_EAT_WS>.          { yyless(0); BEGIN S_TEXT; }

 /**** TAG/OUTPUT MODE *******************************************************/

<S_OUTPUT,S_TAG>{ID} { yylval.str = yytext; return ID; }
<S_OUTPUT,S_TAG>{space}+ ;

<S_OUTPUT,S_TAG>"==" { return EQUALS; }
<S_OUTPUT,S_TAG>"!=" { return NOT_EQUALS; }
<S_OUTPUT,S_TAG>"<>" { return SPACESHIP; }
<S_OUTPUT,S_TAG>"<=" { return LESS_THAN_EQUALS; }
<S_OUTPUT,S_TAG>">=" { return GREATER_THAN_EQUALS; }
<S_OUTPUT,S_TAG>".." { return RANGE_CTOR; }
<S_OUTPUT,S_TAG>"<"  { return LESS_THAN; }
<S_OUTPUT,S_TAG>">"  { return GREATER_THAN; }
<S_OUTPUT,S_TAG>","  { return COMMA; }
<S_OUTPUT,S_TAG>":"  { return COLON; }
<S_OUTPUT,S_TAG>"="  { return ASSIGN; }
<S_OUTPUT,S_TAG>"."  { return DOT; }
<S_OUTPUT,S_TAG>"|"  { return PIPE; }
<S_OUTPUT,S_TAG>"("  { return LPAREN; }
<S_OUTPUT,S_TAG>")"  { return RPAREN; }
<S_OUTPUT,S_TAG>"#"  { return HASH; }

<S_OUTPUT,S_TAG>\"[^"\n]*\" |
<S_OUTPUT,S_TAG>'[^'\n]*'   {
                        yylval.str = yytext;
                        return STRING;
                      }

 /**** GENERIC ***************************************************************/

.                    { yyerror("unhandled character in input"); }

%%
