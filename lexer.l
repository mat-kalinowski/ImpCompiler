%option noyywrap
%option yylineno

%{
   #include "data.h"
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
"IF" {return IF;}
"THEN" {return THEN;}
"ELSE" {return ELSE;}
"ENDIF" {return ENDIF;}
"WHILE" {return WHILE;}
"DO" {return DO;}
"ENDDO" {return ENDDO;}
"ENDWHILE" {return ENDWHILE;}
"FOR" {return FOR;}
"FROM" {return FROM;}
"TO" {return TO;}
"DOWNTO" {return DOWNTO;}
"ENDFOR" {return ENDFOR;}

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
"!=" {return NEQ;}
"<" {return LE;}
">" {return GE;}
"<=" {return EQL;}
">=" {return EQG;}

[\n\t" "] {}
%%
