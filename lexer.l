%option noyywrap
%option yylineno

%{
   #include <string>
   #include <stdlib.h>
 	#include "parser.tab.h"
    using namespace std;
%}

%%
[_a-z]+ {
   yylval.sval =(char*) malloc(strlen(yytext)+1);
   strcpy(yylval.sval, yytext);
   return PIDENTIFIER;
}
[0-9]+ {
   yylval.sval = (char*) malloc(strlen(yytext)+1);
   strcpy(yylval.sval, yytext);
   return NUM;
}

"DECLARE" {return DECLARE;}
"IN" {return IN;}
"END" {return END;}
"READ" {return READ;}
"WRITE" {return WRITE;}

"+" { return ADD;}
"-" { return SUB;}
"*" { return MUL;}
"/" { return DIV;}
"%" { return MOD;}

";" {return SEM;}
":" {return COL;}
"(" {return LB;}
")" {return RB;}
":=" {return ASN;}
"=" {return EQ;}

[\n\t" "] {}
%%
