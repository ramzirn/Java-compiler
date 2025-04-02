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
    double dbl;  // Changé fnum en dbl
    char chr;    // Changé ch en chr
}

/* Déclaration des tokens */
%token NULL_LITERAL PLUSPLUS MINUSMINUS QUESTION
%token STRING  // Assurez-vous que c'est déclaré
%token IMPORT PUBLIC CLASS STATIC VOID INT DOUBLE STRING CHAR BOOLEAN
%token IF ELSE FOR WHILE SWITCH CASE DEFAULT TRY CATCH FINALLY
%token EXTENDS IMPLEMENTS NEW THIS SUPER
%token PRINTLN RETURN BREAK CONTINUE
%token LBRACE RBRACE LPAREN RPAREN LBRACKET RBRACKET
%token SEMICOLON COMMA DOT COLON STAR QUESTION
%token PLUS MINUS TIMES DIVIDE ASSIGN
%token EQ NEQ LT GT LTE GTE
%token AND OR NOT
%token PLUSPLUS MINUSMINUS QUESTION
%token INTEGER_LITERAL FLOAT_LITERAL STRING_LITERAL CHAR_LITERAL BOOLEAN_LITERAL
%token IDENTIFIER

/* Priorités des opérateurs */
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
    /* vide */
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
    /* vide */
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
    /* vide */
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
    modifiers type IDENTIFIER LPAREN param_list RPAREN method_body
    ;

constructor_decl:
    modifiers IDENTIFIER LPAREN param_list RPAREN constructor_body
    ;

modifiers:
    /* vide */
    | PUBLIC
    | STATIC
    | modifiers modifier
    ;

modifier:
    PUBLIC
    | STATIC
    ;

type:
    primitive_type
    | reference_type
    | array_type
    ;

primitive_type:
    INT
    | DOUBLE
    | BOOLEAN
    | CHAR
    ;

reference_type:
    IDENTIFIER
    ;

array_type:
    type LBRACKET RBRACKET
    ;

param_list:
    /* vide */
    | params
    ;

params:
    param
    | params COMMA param
    ;

param:
    type IDENTIFIER
    ;

method_body:
    SEMICOLON
    | block
    ;

constructor_body:
    block
    ;

block:
    LBRACE block_stmts RBRACE
    ;

block_stmts:
    /* vide */
    | block_stmts block_stmt
    ;

block_stmt:
    local_var_decl SEMICOLON
    | statement
    ;

local_var_decl:
    type IDENTIFIER
    | type IDENTIFIER ASSIGN expression
    ;

statement:
    block
    | IF LPAREN expression RPAREN statement
    | IF LPAREN expression RPAREN statement ELSE statement
    | FOR LPAREN for_init SEMICOLON expr_opt SEMICOLON expr_opt RPAREN statement
    | WHILE LPAREN expression RPAREN statement
    | RETURN expression SEMICOLON
    | PRINTLN LPAREN expression RPAREN SEMICOLON
    | expression SEMICOLON
    ;

for_init:
    /* vide */
    | local_var_decl
    | expression
    ;

expr_opt:
    /* vide */
    | expression
    ;

expression:
    assignment
    ;

assignment:
    conditional
    | IDENTIFIER ASSIGN assignment
    ;

conditional:
    logical_or
    | logical_or '?' expression ':' conditional
    ;

logical_or:
    logical_and
    | logical_or OR logical_and
    ;

logical_and:
    equality
    | logical_and AND equality
    ;

equality:
    relational
    | equality EQ relational
    | equality NEQ relational
    ;

relational:
    additive
    | relational LT additive
    | relational GT additive
    | relational LTE additive
    | relational GTE additive
    ;

additive:
    multiplicative
    | additive PLUS multiplicative
    | additive MINUS multiplicative
    ;

multiplicative:
    unary
    | multiplicative TIMES unary
    | multiplicative DIVIDE unary
    ;

unary:
    postfix
    | PLUS unary
    | MINUS unary %prec UMINUS
    | NOT unary
    ;

postfix:
    primary
    | postfix LBRACKET expression RBRACKET
    | postfix DOT IDENTIFIER
    | postfix LPAREN argument_list RPAREN
    ;

primary:
    INTEGER_LITERAL
    | FLOAT_LITERAL
    | STRING_LITERAL
    | CHAR_LITERAL
    | BOOLEAN_LITERAL
    | IDENTIFIER
    | THIS
    | SUPER
    | NEW creator
    | LPAREN expression RPAREN
    ;

creator:
    IDENTIFIER LPAREN argument_list RPAREN
    | primitive_type LBRACKET expression RBRACKET
    ;

argument_list:
    /* vide */
    | arguments
    ;

arguments:
    expression
    | arguments COMMA expression
    ;

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