/* Fichier Flex corrigé */
%{
    #include "symbol_table.h"
    #include "semantics.h"

#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>
extern SymbolTable symbol_table;  // 👈 on dit "cette variable existe ailleurs"
#define YY_NO_UNPUT
extern int yylineno;
%}

%option noyywrap
%option yylineno  

%%

"import"       { return IMPORT; }
"public"       { return PUBLIC; }
"class"        { return CLASS; }
"static"       { return STATIC; }
"void"         { return VOID; }
"int"     { printf(">> TOKEN: int\n"); return INT; }
"double"       { printf("Found double\n"); return DOUBLE; }
"String"       { return STRING; }
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
"System.out.print"   { return PRINT; }
"length"    { return LENGTH; }
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
"private"      { return PRIVATE; }
"protected"    { return PROTECTED; }
"final"        { return FINAL; }

"+"            { return PLUS; }
"-"            { return MINUS; }
"*"            { return STAR; }
"/"            { return DIVIDE; }
"="            { return ASSIGN; }
"=="           { return EQ; }
"!="           { return NEQ; }
">"            { return GT; }
"<"            { return LT; }
">="           { return GTE; }
"<="           { return LTE; }
"++"           { return PLUSPLUS; }
"--"           { return MINUSMINUS; }
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
"+="    { return PLUS_ASSIGN; }
"-="    { return MINUS_ASSIGN; }
"*="    { return TIMES_ASSIGN; }
"/="    { return DIVIDE_ASSIGN; }
"%"         { return MOD; }

[0-9]+         { yylval.num = atoi(yytext); return INTEGER_LITERAL; }
[0-9]+\.[0-9]+ { yylval.dbl = atof(yytext); return DOUBLE_LITERAL; }
\"[^"\n]*\"  { yylval.str = strdup(yytext); return STRING_LITERAL; }
\'[^'\n]\'   { yylval.chr = yytext[1]; return CHAR_LITERAL; }
[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.str = strdup(yytext);
    return IDENTIFIER;
}


[ \t\r]+       ;
\n             ;
"//".*         ;
"/*"(.|\n)*"*/" ;

.              { printf("Unknown token: %s\n", yytext); }

%%

