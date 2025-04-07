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
%token EXTENDS IMPLEMENTS NEW THIS SUPER RETURN BREAK CONTINUE
%token LBRACE RBRACE LPAREN RPAREN LBRACKET RBRACKET SEMICOLON COMMA DOT COLON STAR 
%token PLUS MINUS TIMES DIVIDE ASSIGN PLUS_ASSIGN MINUS_ASSIGN TIMES_ASSIGN DIVIDE_ASSIGN
%token EQ NEQ LT GT LTE GTE AND OR NOT
%token INTEGER_LITERAL FLOAT_LITERAL STRING_LITERAL CHAR_LITERAL BOOLEAN_LITERAL IDENTIFIER
%token PRIVATE PROTECTED FINAL 
%token SYSTEM OUT PRINTLN PRINT
%token LENGTH

%left OR
%left AND
%left EQ NEQ
%left LT GT LTE GTE
%left PLUS MINUS
%right CAST
%left TIMES DIVIDE
%right NOT
%nonassoc UMINUS
%right ASSIGN PLUS_ASSIGN MINUS_ASSIGN TIMES_ASSIGN DIVIDE_ASSIGN

%start program

%%

program:
    import_decls class_decls
    ;

import_decls:
    /* empty */
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
    /* empty */
    | class_modifiers class_modifier
    ;

class_modifier:
    PUBLIC
    | STATIC
    | PRIVATE
    | PROTECTED
    | FINAL
    ;

class_body:
    LBRACE class_members RBRACE
    ;

class_members:
    /* empty */
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
    | modifiers type IDENTIFIER LBRACKET RBRACKET SEMICOLON
    | modifiers type IDENTIFIER LBRACKET RBRACKET ASSIGN array_init SEMICOLON
    | modifiers type IDENTIFIER ASSIGN array_init SEMICOLON
    ;

method_decl:
    modifiers type IDENTIFIER LPAREN param_list_opt RPAREN method_body
    ;

param_list_opt:
    /* empty */
    | param_list
    ;

param_list:
    type IDENTIFIER
    | param_list COMMA type IDENTIFIER
    ;

constructor_decl:
    modifiers IDENTIFIER LPAREN param_list RPAREN constructor_body
    ;

modifiers:
    /* empty */
    | modifiers modifier
    ;

modifier:
    PUBLIC
    | PRIVATE
    | PROTECTED
    | STATIC
    | FINAL
    ;

type:
    INT
    | DOUBLE
    | CHAR
    | BOOLEAN
    | STRING
    | VOID
    | IDENTIFIER
    | type LBRACKET RBRACKET
    ;
primary_expression:
    IDENTIFIER
    | INTEGER_LITERAL
    | FLOAT_LITERAL
    | STRING_LITERAL
    | CHAR_LITERAL
    | BOOLEAN_LITERAL
    | THIS
    | SUPER
    | NEW array_creation
    | LPAREN expression RPAREN
    | IDENTIFIER DOT LENGTH
    | IDENTIFIER DOT IDENTIFIER
    | CAST LPAREN type RPAREN primary_expression %prec CAST
        | IDENTIFIER DOT IDENTIFIER LPAREN argument_list RPAREN  // <-- Ajout ici
    ;
cast_expression:
    unary_expression
    | CAST LPAREN type RPAREN cast_expression %prec CAST
    ;

expression:
    cast_expression
    | expression PLUS expression
    | expression MINUS expression
    | expression TIMES expression
    | expression DIVIDE expression
    | expression GT expression
    | expression LT expression
    | expression LTE expression
    | expression GTE expression
    | expression EQ expression
    | expression NEQ expression
    | expression AND expression
    | expression OR expression
    | NOT expression
    | assignment
    | IDENTIFIER PLUSPLUS
    | IDENTIFIER MINUSMINUS
    | NEW IDENTIFIER LPAREN argument_list RPAREN
    | LPAREN type RPAREN expression %prec CAST
    | IDENTIFIER DOT IDENTIFIER LPAREN argument_list RPAREN  // <-- Ajout ici
    ;


unary_expression:
    postfix_expression
    | MINUS unary_expression %prec UMINUS
    | NOT unary_expression
    ;

postfix_expression:
    primary_expression
    | postfix_expression LBRACKET expression RBRACKET
    | postfix_expression DOT LENGTH
    | postfix_expression DOT IDENTIFIER LPAREN argument_list RPAREN  // <-- Ajout ici
    ;


assignment:
    IDENTIFIER ASSIGN expression
    | IDENTIFIER PLUS_ASSIGN expression
    | IDENTIFIER MINUS_ASSIGN expression
    | IDENTIFIER TIMES_ASSIGN expression
    | IDENTIFIER DIVIDE_ASSIGN expression
    | array_access ASSIGN expression
    | array_access PLUS_ASSIGN expression
    | array_access MINUS_ASSIGN expression
    | array_access TIMES_ASSIGN expression
    | array_access DIVIDE_ASSIGN expression
        | THIS DOT IDENTIFIER ASSIGN expression
    | THIS DOT IDENTIFIER PLUS_ASSIGN expression
    | THIS DOT IDENTIFIER MINUS_ASSIGN expression
    | THIS DOT IDENTIFIER TIMES_ASSIGN expression
    | THIS DOT IDENTIFIER DIVIDE_ASSIGN expression
    ;

array_creation:
    type LBRACKET expression RBRACKET
    | type LBRACKET RBRACKET array_initializer
    | type LBRACKET expression RBRACKET array_dimensions
    ;

array_initializer:
    LBRACE expression_list RBRACE
    | LBRACE RBRACE
    ;

array_access:
    IDENTIFIER LBRACKET expression RBRACKET
    | array_access LBRACKET expression RBRACKET
    ;

array_dimensions:
    LBRACKET expression RBRACKET
    | array_dimensions LBRACKET expression RBRACKET
    ;

array_init:
    NEW array_creation
    | LBRACE expression_list RBRACE
    ;

expression_list:
    expression
    | expression_list COMMA expression
    ;

method_invocation:
    IDENTIFIER LPAREN argument_list RPAREN
    | qualified_access LPAREN argument_list RPAREN
    | PRIMARY DOT IDENTIFIER LPAREN argument_list RPAREN
;
qualified_access:
    IDENTIFIER DOT IDENTIFIER
    | qualified_access DOT IDENTIFIER
    | SYSTEM DOT OUT DOT PRINTLN
    ;

PRIMARY:
    THIS
    | SUPER
    | INTEGER_LITERAL
    | FLOAT_LITERAL
    | CHAR_LITERAL
    | STRING_LITERAL
    | BOOLEAN_LITERAL
    | NEW array_creation
    | LPAREN expression RPAREN
    ;

argument_list:
    /* empty */
    | expression
    | argument_list COMMA expression
    ;

method_body:
    LBRACE RBRACE
    | LBRACE statements RBRACE
    ;

constructor_body:
    LBRACE RBRACE
    | LBRACE statements RBRACE
    ;

statements:
    statement
    | statements statement
    ;

statement:
    expression SEMICOLON
    | declaration SEMICOLON
    | SEMICOLON
    | block
    | if_statement
    | for_statement
    | enhanced_for_statement
    | while_statement
    | switch_statement
    | try_statement
    | RETURN expression SEMICOLON
    | RETURN SEMICOLON
    | BREAK SEMICOLON
    | CONTINUE SEMICOLON
    | PRINTLN LPAREN println_args RPAREN SEMICOLON
        | PRINT LPAREN println_args RPAREN SEMICOLON
    ;
    ;

declaration:
    type IDENTIFIER
    | type IDENTIFIER ASSIGN expression
    | type IDENTIFIER LBRACKET RBRACKET
    | type IDENTIFIER LBRACKET RBRACKET ASSIGN array_init
        | type IDENTIFIER ASSIGN NEW IDENTIFIER LPAREN argument_list RPAREN  // Ajout pour les constructeurs
    | type IDENTIFIER ASSIGN array_initializer

    ;

block:
    LBRACE statements RBRACE
    ;

if_statement:
    IF LPAREN expression RPAREN statement
    | IF LPAREN expression RPAREN statement ELSE statement
    ;

for_statement:
    FOR LPAREN for_init_opt SEMICOLON for_cond_opt SEMICOLON for_update_opt RPAREN statement
    ;

enhanced_for_statement:
    FOR LPAREN type IDENTIFIER COLON expression RPAREN statement
    ;

for_init_opt:
    /* empty */
    | for_init
    ;

for_init:
    declaration
    | expression_list
    ;

for_cond_opt:
    /* empty */
    | expression
    ;

for_update_opt:
    /* empty */
    | expression_list
    ;

while_statement:
    WHILE LPAREN expression RPAREN statement
    ;

switch_statement:
    SWITCH LPAREN expression RPAREN switch_block
    ;

switch_block:
    LBRACE switch_cases RBRACE
    ;

switch_cases:
    /* empty */
    | switch_cases switch_case
    ;

switch_case:
    CASE expression COLON statements
    | DEFAULT COLON statements
    ;

try_statement:
    TRY block catch_clauses finally_clause_opt
    ;

catch_clauses:
    catch_clause
    | catch_clauses catch_clause
    ;

catch_clause:
    CATCH LPAREN type IDENTIFIER RPAREN block
    ;

finally_clause_opt:
    /* empty */
    | FINALLY block
    ;

println_args:
    /* empty */
    | expression
    | println_args COMMA expression
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