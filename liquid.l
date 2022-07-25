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
int     -?[0-9]+
float   -?[0-9]+.[0-9]+
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

<S_OUTPUT,S_TAG>{space}+ ;

 /* TODO: most of these are only valid in S_TAG */
<S_OUTPUT,S_TAG>"=="        { return EQUALS; }
<S_OUTPUT,S_TAG>"!="        { return NOT_EQUALS; }
<S_OUTPUT,S_TAG>"<>"        { return SPACESHIP; }
<S_OUTPUT,S_TAG>"<="        { return LESS_THAN_EQUALS; }
<S_OUTPUT,S_TAG>">="        { return GREATER_THAN_EQUALS; }
<S_OUTPUT,S_TAG>".."        { return RANGE_CTOR; }
<S_OUTPUT,S_TAG>"<"         { return LESS_THAN; }
<S_OUTPUT,S_TAG>">"         { return GREATER_THAN; }
<S_OUTPUT,S_TAG>","         { return COMMA; }
<S_OUTPUT,S_TAG>":"         { return COLON; }
<S_OUTPUT,S_TAG>"="         { return SET; }
<S_OUTPUT,S_TAG>"."         { return DOT; }
<S_OUTPUT,S_TAG>"|"         { return PIPE; }
<S_OUTPUT,S_TAG>"("         { return LPAREN; }
<S_OUTPUT,S_TAG>")"         { return RPAREN; }
<S_OUTPUT,S_TAG>"#"         { return HASH; }
<S_OUTPUT,S_TAG>if          { return IF; }
<S_OUTPUT,S_TAG>endif       { return ENDIF; }
<S_OUTPUT,S_TAG>elsif       { return ELSIF; }
<S_OUTPUT,S_TAG>else        { return ELSE; }
<S_OUTPUT,S_TAG>unless      { return UNLESS; }
<S_OUTPUT,S_TAG>endunless   { return ENDUNLESS; }
<S_OUTPUT,S_TAG>case        { return CASE; }
<S_OUTPUT,S_TAG>endcase     { return ENDCASE; }
<S_OUTPUT,S_TAG>form        { return FORM; }
<S_OUTPUT,S_TAG>endform     { return ENDFORM; }
<S_OUTPUT,S_TAG>style       { return STYLE; }
<S_OUTPUT,S_TAG>endstyle    { return ENDSTYLE; }
<S_OUTPUT,S_TAG>for         { return FOR; }
<S_OUTPUT,S_TAG>endfor      { return ENDFOR; }
<S_OUTPUT,S_TAG>break       { return BREAK; }
<S_OUTPUT,S_TAG>continue    { return CONTINUE; }
<S_OUTPUT,S_TAG>cycle       { return CYCLE; }
<S_OUTPUT,S_TAG>tablerow    { return TABLEROW; }
<S_OUTPUT,S_TAG>endtablerow { return ENDTABLEROW; }
<S_OUTPUT,S_TAG>paginate    { return PAGINATE; }
<S_OUTPUT,S_TAG>endpaginate { return ENDPAGINATE; }
<S_OUTPUT,S_TAG>echo        { return S_ECHO; }
<S_OUTPUT,S_TAG>liquid      { return LIQUID; }
<S_OUTPUT,S_TAG>include     { return INCLUDE; }
<S_OUTPUT,S_TAG>layout      { return LAYOUT; }
<S_OUTPUT,S_TAG>render      { return RENDER; }
<S_OUTPUT,S_TAG>section     { return SECTION; }
<S_OUTPUT,S_TAG>assign      { return ASSIGN; }
<S_OUTPUT,S_TAG>capture     { return CAPTURE; }
<S_OUTPUT,S_TAG>endcapture  { return ENDCAPTURE; }
<S_OUTPUT,S_TAG>decrement   { return DECREMENT; }
<S_OUTPUT,S_TAG>increment   { return INCREMENT; }
<S_OUTPUT,S_TAG>with        { return WITH; }
<S_OUTPUT,S_TAG>as          { return AS; }
<S_OUTPUT,S_TAG>in          { return IN; }
<S_OUTPUT,S_TAG>contains    { return CONTAINS; }
<S_OUTPUT,S_TAG>empty       { return EMPTY; }
<S_OUTPUT,S_TAG>blank       { return BLANK; }
<S_OUTPUT,S_TAG>nil         { return NONE; }
<S_OUTPUT,S_TAG>none        { return NIL; }
<S_OUTPUT,S_TAG>when        { return WHEN; }
<S_OUTPUT,S_TAG>by          { return BY; }
<S_OUTPUT,S_TAG>or          { return OR; }
<S_OUTPUT,S_TAG>and         { return AND; }
<S_OUTPUT,S_TAG>true        { return TRUE; }
<S_OUTPUT,S_TAG>false       { return FALSE; }

<S_OUTPUT,S_TAG>{int}   { yylval.ival = atoi(yytext); return INT; }
<S_OUTPUT,S_TAG>{float} { yylval.dval = atof(yytext); return FLOAT; }
<S_OUTPUT,S_TAG>{ID}    { yylval.str = yytext; return ID; }
 /* TODO: interpret correctly */
<S_OUTPUT,S_TAG>\"[^"\n]*\" |
<S_OUTPUT,S_TAG>'[^'\n]*'   {
                        yylval.str = yytext;
                        return STRING;
                      }

 /**** GENERIC ***************************************************************/

.                    { yyerror("unhandled character in input"); }

%%
