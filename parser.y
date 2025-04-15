%{
#include "symbol_table.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
extern FILE *yyin;
extern int yylineno;
SymbolTable symbol_table;

void yyerror(const char *s) {
    fprintf(stderr, "Erreur syntaxique ligne %d: %s\n", yylineno, s);
}
%}
%code requires {
    #include "symbol_table.h"
}
%union {
    char* str;
    int num;
    double dbl;
    char chr;
     struct {
        int count;
        char **names;
        DataType *types;
    } param_list;
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

%type <str> IDENTIFIER
%type <num> type
%type <param_list> param_list param_list_opt

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
    modifiers type IDENTIFIER SEMICOLON {
        printf("Règle field_decl atteinte: nom = %s, type = %d\n", $3, $2);
        symbol_insert(&symbol_table, $3, SYM_VARIABLE, $2, 0, 0, NULL);
    }
  | modifiers type IDENTIFIER ASSIGN expression SEMICOLON {
        printf("Règle field_decl avec initialisation: nom = %s, type = %d\n", $3, $2);
        symbol_insert(&symbol_table, $3, SYM_VARIABLE, $2, 0, 0, NULL);
    }
  | modifiers type IDENTIFIER LBRACKET RBRACKET SEMICOLON {
        printf("Règle field_decl tableau: nom = %s, type = tableau de %d\n", $3, $2);
        symbol_insert(&symbol_table, $3, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);
    }
  | modifiers type IDENTIFIER LBRACKET RBRACKET ASSIGN array_init SEMICOLON {
        printf("Règle field_decl tableau initialisé: nom = %s, type = tableau de %d\n", $3, $2);
        symbol_insert(&symbol_table, $3, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);
    }
  | modifiers type IDENTIFIER ASSIGN array_init SEMICOLON {
        printf("Règle field_decl tableau (sans []) avec init: nom = %s, type = tableau de %d\n", $3, $2);
        symbol_insert(&symbol_table, $3, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);
    }
  ;

method_decl:
    modifiers type IDENTIFIER LPAREN param_list_opt RPAREN method_body {
        printf("Déclaration de fonction: nom = %s, type retour = %d, nb params = %d\n", $3, $2, $5.count);
        symbol_insert_function(&symbol_table, $3, $2, $5.count, $5.names, $5.types);
        
        // Entrez dans le scope de la fonction
        enter_scope(&symbol_table);

        // Insère les paramètres comme variables locales
        for (int i = 0; i < $5.count; ++i) {
            symbol_insert(&symbol_table, $5.names[i], SYM_VARIABLE, $5.types[i], 0, 0, NULL);
        }

        // Le corps de la méthode a déjà été géré par method_body
        exit_scope(&symbol_table);  // ou place-le ailleurs selon ta logique de blocs
    }

param_list_opt:
    /* empty */ {
        $$.count = 0;
        $$.names = NULL;
        $$.types = NULL;
    }
  | param_list { $$ = $1; }


param_list:
    type IDENTIFIER {
        $$ = (typeof($$)){ .count = 1 };
        $$ .names = malloc(sizeof(char*));
        $$ .types = malloc(sizeof(DataType));
        $$ .names[0] = strdup($2);
        $$ .types[0] = $1;
    }
  | param_list COMMA type IDENTIFIER {
        $$ = $1;
        $$ .count++;
        $$ .names = realloc($$.names, $$ .count * sizeof(char*));
        $$ .types = realloc($$.types, $$ .count * sizeof(DataType));
        $$ .names[$$.count - 1] = strdup($4);
        $$ .types[$$.count - 1] = $3;
    }


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
    INT { $$ = TYPE_INT; }
  | DOUBLE { $$ = TYPE_DOUBLE; }
  | CHAR { $$ = TYPE_CHAR; }
  | BOOLEAN { $$ = TYPE_BOOLEAN; }
  | STRING { $$ = TYPE_STRING; }
  | VOID { $$ = TYPE_VOID; }
  | IDENTIFIER { $$ = TYPE_OBJECT; } 
  | type LBRACKET RBRACKET { $$ = TYPE_ARRAY; }
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
    | CAST LPAREN type RPAREN primary_expression
    | IDENTIFIER DOT IDENTIFIER LPAREN argument_list RPAREN
    ;

cast_expression:
    unary_expression
    | CAST LPAREN type RPAREN cast_expression
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
    | LPAREN type RPAREN expression
    | IDENTIFIER DOT IDENTIFIER LPAREN argument_list RPAREN
    ;

unary_expression:
    postfix_expression
    | MINUS unary_expression
    | NOT unary_expression
    ;

postfix_expression:
    primary_expression
    | postfix_expression LBRACKET expression RBRACKET
    | postfix_expression DOT LENGTH
    | postfix_expression DOT IDENTIFIER LPAREN argument_list RPAREN
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
    
    | IDENTIFIER LPAREN argument_list RPAREN SEMICOLON

    ;

declaration:
    type IDENTIFIER {  // Déclaration simple : type + nom de variable
        printf("Déclaration variable locale : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, $1, 0, 0, NULL);  // Insère la variable dans la table des symboles
    }
    | type IDENTIFIER ASSIGN expression {  // Déclaration avec assignation : type + nom + valeur
        printf("Déclaration variable locale avec assignation : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, $1, 0, 0, NULL);  // Insère la variable avec la valeur assignée
    }
    | type IDENTIFIER LBRACKET RBRACKET {  // Déclaration de tableau
        printf("Déclaration tableau local : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);  // Insère un tableau dans la table des symboles
    }
    | type IDENTIFIER LBRACKET RBRACKET ASSIGN array_init {  // Déclaration de tableau avec initialisation
        printf("Déclaration tableau local avec initialisation : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);  // Insère un tableau initialisé dans la table des symboles
    }
    | type IDENTIFIER ASSIGN NEW IDENTIFIER LPAREN argument_list RPAREN {  // Déclaration avec nouvel objet
        printf("Déclaration variable avec instanciation d'objet : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, TYPE_OBJECT, 0, 0, NULL);  // Insère un objet dans la table des symboles
    }
    | type IDENTIFIER ASSIGN array_initializer {  // Déclaration avec initialisation (tableau)
        printf("Déclaration tableau avec initialisation : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);  // Insère un tableau initialisé dans la table des symboles
    }
    ;


block:
    LBRACE statements RBRACE {
        enter_scope(&symbol_table);  // Entrée dans un scope interne
        // Traite toutes les déclarations dans le bloc
        exit_scope(&symbol_table);  // Sortie du scope du bloc
    }
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

int main(int argc, char *argv[]) {
    init_symbol_table(&symbol_table);
    printf("Début du parsing\n");

    if (argc > 1) {
        FILE *source_code = fopen(argv[1], "r");
        if (!source_code) {
            fprintf(stderr, "Impossible d'ouvrir le fichier %s\n", argv[1]);
            return 1;
        }

        yyin = source_code;
        yyparse();
        fclose(source_code);
    } else {
        fprintf(stderr, "Usage: %s <fichier_source>\n", argv[0]);
        return 1;
    }

    print_symbol_table(&symbol_table);
    return 0;
}
