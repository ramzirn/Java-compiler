%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
extern FILE *yyin;
extern int yylineno;

void yyerror(const char *s) {
    fprintf(stderr, "Erreur syntaxique ligne %d: %s\n", yylineno, s);
}
%}

%union {
    char* str;
    int num;
    double dbl;
    char chr;
}

%token NULL_LITERAL PLUSPLUS MINUSMINUS QUESTION
%token STRING IMPORT PUBLIC CLASS STATIC VOID INT DOUBLE CHAR BOOLEAN
%token IF ELSE FOR WHILE SWITCH CASE DEFAULT TRY CATCH FINALLY
%token EXTENDS IMPLEMENTS NEW THIS SUPER PRINTLN RETURN BREAK CONTINUE
%token LBRACE RBRACE LPAREN RPAREN LBRACKET RBRACKET SEMICOLON COMMA DOT COLON STAR 
%token PLUS MINUS TIMES DIVIDE ASSIGN EQ NEQ LT GT LTE GTE AND OR NOT
%token INTEGER_LITERAL FLOAT_LITERAL STRING_LITERAL CHAR_LITERAL BOOLEAN_LITERAL IDENTIFIER

%left OR
%left AND
%left EQ NEQ
%left LT GT LTE GTE
%left PLUS MINUS
%left TIMES DIVIDE
%right NOT
%nonassoc UMINUS

%start program

%%

program:
    import_decls class_decls
    ;

import_decls:
    | import_decls import_decl
    ;

import_decl:
    IMPORT qualified_name SEMICOLON
    | IMPORT qualified_name DOT STAR SEMICOLON
    ;

qualified_name:
    IDENTIFIER
    | qualified_name DOT IDENTIFIER
    ;

class_decls:
    class_decl
    | class_decls class_decl
    ;

class_decl:
    class_modifiers CLASS IDENTIFIER class_body
    | class_modifiers CLASS IDENTIFIER EXTENDS IDENTIFIER class_body
    ;

class_modifiers:
    | PUBLIC
    | STATIC
    | class_modifiers class_modifier
    ;

class_modifier:
    PUBLIC
    | STATIC
    ;

class_body:
    LBRACE class_members RBRACE
    ;

class_members:
    | class_members class_member
    ;

class_member:
    field_decl
    | method_decl
    | constructor_decl
    ;

field_decl:
    modifiers type IDENTIFIER SEMICOLON
    | modifiers type IDENTIFIER ASSIGN expression SEMICOLON
    ;


method_decl:
    modifiers type IDENTIFIER LPAREN param_list_opt RPAREN method_body
    ;

param_list_opt:
    /* vide */
    | param_list
    ;

constructor_decl:
    modifiers IDENTIFIER LPAREN param_list RPAREN constructor_body
    ;

modifiers:
    | PUBLIC
    | STATIC
    | modifiers modifier
    ;

modifier:
    PUBLIC
    | STATIC
    ;

type:
    INT
    | DOUBLE
    | CHAR
    | BOOLEAN
    | STRING
    | VOID
    | IDENTIFIER   // Pour les types définis par l'utilisateur
    ;

expression:
    IDENTIFIER
    | INTEGER_LITERAL
    | FLOAT_LITERAL
    | STRING_LITERAL
    | expression PLUS expression
    | expression MINUS expression
    | expression STAR expression
    | expression DIVIDE expression
    ;

param_list:
    /* Liste vide */
    | type IDENTIFIER
    | param_list COMMA type IDENTIFIER
    ;

method_body:
    LBRACE RBRACE
    | LBRACE statement_list RBRACE
    ;

constructor_body:
    LBRACE RBRACE
    | LBRACE statement_list RBRACE
    ;

statement_list:
    statement
    | statement_list statement
    ;

statement:
    expression SEMICOLON
    | type IDENTIFIER SEMICOLON
    | type IDENTIFIER ASSIGN expression SEMICOLON
    | SEMICOLON   // Pour les déclarations vides
    ;

/* Ajout d'autres règles ici pour compléter... */

%%

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <fichier.java>\n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("Erreur ouverture fichier");
        return 1;
    }
    return yyparse();
}
