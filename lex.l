%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>

#define YY_NO_UNPUT
extern int yylineno;  // Supprimez la redéfinition ici
%}

%option noyywrap

%option yylineno  

%%

"import"       { return IMPORT; }
"public"       { return PUBLIC; }
"class"        { return CLASS; }
"static"       { return STATIC; }
"void"         { return VOID; }
"int"          { return INT; }
"double"       { return DOUBLE; }
"String"       { return STRING; }  // Changé de STRING_TYPE à STRING
"char"         { return CHAR; }
"boolean"      { return BOOLEAN; }
"if"           { return IF; }
"else"         { return ELSE; }
"for"          { return FOR; }
"while"        { return WHILE; }
"switch"       { return SWITCH; }
"case"         { return CASE; }
"default"      { return DEFAULT; }
"try"          { return TRY; }
"catch"        { return CATCH; }
"finally"      { return FINALLY; }
"System.out.println" { return PRINTLN; }
"true"         { return BOOLEAN_LITERAL; }
"false"        { return BOOLEAN_LITERAL; }
"null"         { return NULL_LITERAL; }
"new"          { return NEW; }
"extends"      { return EXTENDS; }
"implements"   { return IMPLEMENTS; }
"this"         { return THIS; }
"super"        { return SUPER; }
"return"       { return RETURN; }
"break"        { return BREAK; }
"continue"     { return CONTINUE; }

"+"            { return PLUS; }
"-"            { return MINUS; }
"*"            { return STAR; }  // Utilisez STAR au lieu de WILDCARD
"/"            { return DIVIDE; }
"="            { return ASSIGN; }
"=="           { return EQ; }
"!="           { return NEQ; }
">"            { return GT; }
"<"            { return LT; }
">="           { return GTE; }
"<="           { return LTE; }
"++"           { return PLUSPLUS; }  // Changé de INC à PLUSPLUS
"--"           { return MINUSMINUS; } // Changé de DEC à MINUSMINUS
"&&"           { return AND; }
"||"           { return OR; }
"!"            { return NOT; }
"{"            { return LBRACE; }
"}"            { return RBRACE; }
"("            { return LPAREN; }
")"            { return RPAREN; }
"["            { return LBRACKET; }
"]"            { return RBRACKET; }
";"            { return SEMICOLON; }
","            { return COMMA; }
"."            { return DOT; }
":"            { return COLON; }
"?"            { return QUESTION; }

[0-9]+         { yylval.num = atoi(yytext); return INTEGER_LITERAL; }
[0-9]+\.[0-9]+ { yylval.dbl = atof(yytext); return FLOAT_LITERAL; }  // Changé fnum en dbl
\"[^"\n]*\"    { yylval.str = strdup(yytext); return STRING_LITERAL; }
\'[^'\n]\'     { yylval.chr = yytext[1]; return CHAR_LITERAL; }  // Changé ch en chr
[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); return IDENTIFIER; }

[ \t\r]+       ;  // Ignore whitespace
\n             ;  // Les nouvelles lignes sont gérées par yylineno
"//".*         ;  // Ignore single-line comments
"/*"(.|\n)*"*/" ; // Ignore multi-line comments

.              { printf("Unknown token: %s\n", yytext); }

%%

