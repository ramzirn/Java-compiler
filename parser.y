%{
#include "symbol_table.h"
#include "quads.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
extern FILE *yyin;
extern int yylineno;
SymbolTable symbol_table;
QuadTable quad_table;

void yyerror(const char *s) {
    fprintf(stderr, "Erreur syntaxique ligne %d: %s\n", yylineno, s);
}
%}

%code requires {
    #include "symbol_table.h"
}

%union {
    char *str;
    int num;
    double dbl;
    char chr;
    struct {
        int count;
        char **names;
        DataType *types;
    } param_list;
    struct {
        int count;
        char **places;
        char **types;
    } arg_list;
    ExprAttr expr;
}

%token <str> IDENTIFIER STRING_LITERAL
%token <num> INTEGER_LITERAL
%token <dbl> DOUBLE_LITERAL
%token <chr> CHAR_LITERAL
%token <str> BOOLEAN_LITERAL
%token <expr> FLOAT_LITERAL
%token NULL_LITERAL PLUSPLUS MINUSMINUS QUESTION
%token STRING IMPORT PUBLIC CLASS STATIC VOID INT DOUBLE CHAR BOOLEAN
%token IF ELSE FOR WHILE SWITCH CASE DEFAULT TRY CATCH FINALLY
%token EXTENDS IMPLEMENTS NEW THIS SUPER RETURN BREAK CONTINUE
%token LBRACE RBRACE LPAREN RPAREN LBRACKET RBRACKET SEMICOLON COMMA DOT COLON STAR 
%token PLUS MINUS TIMES DIVIDE MOD ASSIGN PLUS_ASSIGN MINUS_ASSIGN TIMES_ASSIGN DIVIDE_ASSIGN
%token EQ NEQ LT GT LTE GTE AND OR NOT
%token PRIVATE PROTECTED FINAL 
%token SYSTEM OUT PRINTLN PRINT
%token LENGTH

%left OR
%left AND
%left EQ NEQ
%left LT GT LTE GTE
%left PLUS MINUS
%right CAST
%left TIMES DIVIDE MOD
%right NOT
%nonassoc UMINUS
%right ASSIGN PLUS_ASSIGN MINUS_ASSIGN TIMES_ASSIGN DIVIDE_ASSIGN

%type <num> type
%type <param_list> param_list param_list_opt
%type <arg_list> argument_list
%type <expr> expression primary_expression assignment array_creation
%type <expr> array_access method_invocation cast_expression unary_expression
%type <expr> postfix_expression array_init println_args
%type <expr> for_init_opt for_cond_opt for_update_opt for_init expression_list
%type <str> qualified_name qualified_access

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
        add_quad(&quad_table, ":=", $5.place, NULL, $3);
    }
    | modifiers type IDENTIFIER LBRACKET RBRACKET SEMICOLON {
        printf("Règle field_decl tableau: nom = %s, type = tableau de %d\n", $3, $2);
        symbol_insert(&symbol_table, $3, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);
    }
    | modifiers type IDENTIFIER LBRACKET RBRACKET ASSIGN array_init SEMICOLON {
        printf("Règle field_decl tableau initialisé: nom = %s, type = tableau de %d\n", $3, $2);
        symbol_insert(&symbol_table, $3, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);
        add_quad(&quad_table, ":=", $7.place, NULL, $3);
    }
    | modifiers type IDENTIFIER ASSIGN array_init SEMICOLON {
        printf("Règle field_decl tableau (sans []) avec init: nom = %s, type = tableau de %d\n", $3, $2);
        symbol_insert(&symbol_table, $3, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);
        add_quad(&quad_table, ":=", $5.place, NULL, $3);
    }
    ;

method_decl:
    modifiers type IDENTIFIER LPAREN param_list_opt RPAREN {
        printf("Déclaration de fonction: nom = %s, type retour = %d, nb params = %d\n", $3, $2, $5.count);
        symbol_insert_function(&symbol_table, $3, $2, $5.count, $5.names, $5.types);
        enter_scope(&symbol_table);
        char *label = malloc(strlen($3) + 10);
        sprintf(label, "func_%s", $3);
        add_quad(&quad_table, "label", label, NULL, NULL);
        free(label);
        for (int i = 0; i < $5.count; ++i) {
            Symbol *inserted = symbol_insert(&symbol_table, $5.names[i], SYM_PARAMETER, $5.types[i], 0, 0, NULL);
            if (inserted) {
                printf("Paramètre inséré : %s (Scope %d)\n", $5.names[i], symbol_table.current_scope);
                add_quad(&quad_table, "param_receive", $5.names[i], NULL, NULL);
            }
        }
    }
    method_body {
        add_quad(&quad_table, "return", NULL, NULL, NULL);
        exit_scope(&symbol_table);
    }
    ;

param_list_opt:
    /* empty */ {
        $$.count = 0;
        $$.names = NULL;
        $$.types = NULL;
    }
    | param_list { $$ = $1; }
    ;

param_list:
    type IDENTIFIER {
        $$.count = 1;
        $$.names = malloc(sizeof(char *));
        $$.types = malloc(sizeof(DataType));
        $$.names[0] = strdup($2);
        $$.types[0] = $1;
    }
    | param_list COMMA type IDENTIFIER {
        $$ = $1;
        $$.count++;
        $$.names = realloc($$.names, $$.count * sizeof(char *));
        $$.types = realloc($$.types, $$.count * sizeof(DataType));
        $$.names[$$.count - 1] = strdup($4);
        $$.types[$$.count - 1] = $3;
    }
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
    INT { $$ = TYPE_INT; }
    | DOUBLE { $$ = TYPE_DOUBLE; }
    | CHAR { $$ = TYPE_CHAR; }
    | BOOLEAN { $$ = TYPE_BOOLEAN; }
    | STRING { $$ = TYPE_STRING; }
    | VOID { $$ = TYPE_VOID; }
    | IDENTIFIER { $$ = TYPE_OBJECT; }
    | type LBRACKET RBRACKET { $$ = TYPE_ARRAY; }
    ;

expression:
    cast_expression { $$ = $1; }
    | expression PLUS expression {
        if (!check_type_compatibility($1.type, $3.type)) {
            yyerror("Incompatibilité de types dans l'opération '+'");
        }
        $$.type = $1.type;
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "+", $1.place, $3.place, $$.place);
    }
    | expression MINUS expression {
        if (!check_type_compatibility($1.type, $3.type)) {
            yyerror("Incompatibilité de types dans l'opération '-'");
        }
        $$.type = $1.type;
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "-", $1.place, $3.place, $$.place);
    }
    | expression TIMES expression {
        if (!check_type_compatibility($1.type, $3.type)) {
            yyerror("Incompatibilité de types dans l'opération '*'");
        }
        $$.type = $1.type;
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "*", $1.place, $3.place, $$.place);
    }
    | expression DIVIDE expression {
        if (!check_type_compatibility($1.type, $3.type)) {
            yyerror("Incompatibilité de types dans l'opération '/'");
        }
        $$.type = $1.type;
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "/", $1.place, $3.place, $$.place);
    }
    | expression MOD expression {
        if (!check_type_compatibility($1.type, $3.type)) {
            yyerror("Incompatibilité de types dans l'opération '%'");
        }
        $$.type = $1.type;
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "%", $1.place, $3.place, $$.place);
    }
    | expression GT expression {
        if (!check_type_compatibility($1.type, $3.type)) {
            yyerror("Incompatibilité de types dans l'opération '>'");
        }
        $$.type = strdup("boolean");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, ">", $1.place, $3.place, $$.place);
    }
    | expression LT expression {
        if (!check_type_compatibility($1.type, $3.type)) {
            yyerror("Incompatibilité de types dans l'opération '<'");
        }
        $$.type = strdup("boolean");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "<", $1.place, $3.place, $$.place);
    }
    | expression LTE expression {
        if (!check_type_compatibility($1.type, $3.type)) {
            yyerror("Incompatibilité de types dans l'opération '<='");
        }
        $$.type = strdup("boolean");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "<=", $1.place, $3.place, $$.place);
    }
    | expression GTE expression {
        if (!check_type_compatibility($1.type, $3.type)) {
            yyerror("Incompatibilité de types dans l'opération '>='");
        }
        $$.type = strdup("boolean");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, ">=", $1.place, $3.place, $$.place);
    }
    | expression EQ expression {
        if (!check_type_compatibility($1.type, $3.type)) {
            yyerror("Incompatibilité de types dans l'opération '=='");
        }
        $$.type = strdup("boolean");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "==", $1.place, $3.place, $$.place);
    }
    | expression NEQ expression {
        if (!check_type_compatibility($1.type, $3.type)) {
            yyerror("Incompatibilité de types dans l'opération '!='");
        }
        $$.type = strdup("boolean");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "!=", $1.place, $3.place, $$.place);
    }
    | expression AND expression {
        if (strcmp($1.type, "boolean") != 0 || strcmp($3.type, "boolean") != 0) {
            yyerror("L'opérateur '&&' attend des booléens");
        }
        $$.type = strdup("boolean");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "&&", $1.place, $3.place, $$.place);
    }
    | expression OR expression {
        if (strcmp($1.type, "boolean") != 0 || strcmp($3.type, "boolean") != 0) {
            yyerror("L'opérateur '||' attend des booléens");
        }
        $$.type = strdup("boolean");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "||", $1.place, $3.place, $$.place);
    }
    | NOT expression {
        if (strcmp($2.type, "boolean") != 0) {
            yyerror("L'opérateur '!' attend un booléen");
        }
        $$.type = strdup("boolean");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "!", $2.place, NULL, $$.place);
    }
    | assignment { $$ = $1; }
    | IDENTIFIER PLUSPLUS {
        if (!check_variable_declared(&symbol_table, $1, yylineno)) {
            yyerror("Variable non déclarée");
        }
        $$.type = get_variable_type(&symbol_table, $1);
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "+", $1, "1", $$.place);
        add_quad(&quad_table, ":=", $$.place, NULL, $1);
    }
    | IDENTIFIER MINUSMINUS {
        if (!check_variable_declared(&symbol_table, $1, yylineno)) {
            yyerror("Variable non déclarée");
        }
        $$.type = get_variable_type(&symbol_table, $1);
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "-", $1, "1", $$.place);
        add_quad(&quad_table, ":=", $$.place, NULL, $1);
    }
    | NEW IDENTIFIER LPAREN argument_list RPAREN {
        $$.type = strdup($2);
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "new", $2, NULL, $$.place);
    }
    | LPAREN type RPAREN expression {
        $$ = $4;
    }
    | IDENTIFIER DOT IDENTIFIER LPAREN argument_list RPAREN {
        char *method_call = malloc(strlen($1) + strlen($3) + 2);
        sprintf(method_call, "%s.%s", $1, $3);
        Symbol *func = symbol_lookup_all(&symbol_table, method_call);
        if (!func || func->sym_type != SYM_FUNCTION) {
            yyerror("Méthode non déclarée");
        }
        if ($5.count != func->param_count) {
            yyerror("Nombre d'arguments incorrect");
        }
        for (int i = 0; i < $5.count; i++) {
            if (!check_type_compatibility($5.types[i], get_data_type_string(func->param_types[i]))) {
                yyerror("Incompatibilité de type pour l'argument");
            }
        }
        $$.type = get_data_type_string(func->data_type);
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "call", method_call, NULL, $$.place);
        free(method_call);
    }
    ;

primary_expression:
    IDENTIFIER {
        if (!check_variable_declared(&symbol_table, $1, yylineno)) {
            yyerror("Variable non déclarée");
        }
        $$.type = get_variable_type(&symbol_table, $1);
        $$.place = strdup($1);
    }
    | INTEGER_LITERAL {
        $$.type = strdup("int");
        char *literal = malloc(32);
        snprintf(literal, 32, "%d", $1);
        $$.place = literal;
    }
    | DOUBLE_LITERAL {
        $$.type = strdup("double");
        char *literal = malloc(32);
        snprintf(literal, 32, "%f", $1);
        $$.place = literal;
    }
    | STRING_LITERAL {
        $$.type = strdup("String");
        $$.place = strdup($1);
    }
    | CHAR_LITERAL {
        $$.type = strdup("char");
        char *literal = malloc(4);
        snprintf(literal, 4, "'%c'", $1);
        $$.place = literal;
    }
    | BOOLEAN_LITERAL {
        $$.type = strdup("boolean");
        $$.place = strdup($1);
    }
    | THIS {
        $$.type = strdup("object");
        $$.place = strdup("this");
    }
    | SUPER {
        $$.type = strdup("object");
        $$.place = strdup("super");
    }
    | NEW array_creation {
        $$ = $2;
    }
    | LPAREN expression RPAREN {
        $$ = $2;
    }
    | IDENTIFIER DOT LENGTH {
        $$.type = strdup("int");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "length", $1, NULL, $$.place);
    }
    | IDENTIFIER DOT IDENTIFIER {
        $$.type = get_variable_type(&symbol_table, $3);
        $$.place = new_temp(&quad_table);
        char *access = malloc(strlen($1) + strlen($3) + 2);
        sprintf(access, "%s.%s", $1, $3);
        add_quad(&quad_table, ".", access, NULL, $$.place);
        free(access);
    }
    | CAST LPAREN type RPAREN primary_expression {
        $$ = $5;
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "cast", $5.place, NULL, $$.place);
    }
    | IDENTIFIER DOT IDENTIFIER LPAREN argument_list RPAREN {
        char *method_call = malloc(strlen($1) + strlen($3) + 2);
        sprintf(method_call, "%s.%s", $1, $3);
        Symbol *func = symbol_lookup_all(&symbol_table, method_call);
        if (!func || func->sym_type != SYM_FUNCTION) {
            yyerror("Méthode non déclarée");
        }
        if ($5.count != func->param_count) {
            yyerror("Nombre d'arguments incorrect");
        }
        for (int i = 0; i < $5.count; i++) {
            if (!check_type_compatibility($5.types[i], get_data_type_string(func->param_types[i]))) {
                yyerror("Incompatibilité de type pour l'argument");
            }
        }
        $$.type = get_data_type_string(func->data_type);
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "call", method_call, NULL, $$.place);
        free(method_call);
    }
    ;

cast_expression:
    unary_expression { $$ = $1; }
    | CAST LPAREN type RPAREN cast_expression {
        $$ = $5;
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "cast", $5.place, NULL, $$.place);
    }
    ;

unary_expression:
    postfix_expression { $$ = $1; }
    | MINUS unary_expression {
        $$.type = $2.type;
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "-", "0", $2.place, $$.place);
    }
    | NOT unary_expression {
        if (strcmp($2.type, "boolean") != 0) {
            yyerror("L'opérateur '!' attend un booléen");
        }
        $$.type = strdup("boolean");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "!", $2.place, NULL, $$.place);
    }
    ;

postfix_expression:
    primary_expression { $$ = $1; }
    | postfix_expression LBRACKET expression RBRACKET {
        $$.type = strdup("unknown");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "array_access", $1.place, $3.place, $$.place);
    }
    | postfix_expression DOT LENGTH {
        $$.type = strdup("int");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "length", $1.place, NULL, $$.place);
    }
    | postfix_expression DOT IDENTIFIER LPAREN argument_list RPAREN {
        char *method_call = malloc(strlen($1.place) + strlen($3) + 2);
        sprintf(method_call, "%s.%s", $1.place, $3);
        Symbol *func = symbol_lookup_all(&symbol_table, method_call);
        if (!func || func->sym_type != SYM_FUNCTION) {
            yyerror("Méthode non déclarée");
        }
        if ($5.count != func->param_count) {
            yyerror("Nombre d'arguments incorrect");
        }
        for (int i = 0; i < $5.count; i++) {
            if (!check_type_compatibility($5.types[i], get_data_type_string(func->param_types[i]))) {
                yyerror("Incompatibilité de type pour l'argument");
            }
        }
        $$.type = get_data_type_string(func->data_type);
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "call", method_call, NULL, $$.place);
        free(method_call);
    }
    ;

assignment:
    IDENTIFIER ASSIGN expression {
        if (!check_variable_declared(&symbol_table, $1, yylineno)) {
            yyerror("Variable non déclarée");
        }
        $$.type = get_variable_type(&symbol_table, $1);
        $$.place = strdup($1);
        add_quad(&quad_table, ":=", $3.place, NULL, $1);
    }
    | IDENTIFIER PLUS_ASSIGN expression {
        if (!check_variable_declared(&symbol_table, $1, yylineno)) {
            yyerror("Variable non déclarée");
        }
        $$.type = get_variable_type(&symbol_table, $1);
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "+", $1, $3.place, $$.place);
        add_quad(&quad_table, ":=", $$.place, NULL, $1);
    }
    | IDENTIFIER MINUS_ASSIGN expression {
        if (!check_variable_declared(&symbol_table, $1, yylineno)) {
            yyerror("Variable non déclarée");
        }
        $$.type = get_variable_type(&symbol_table, $1);
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "-", $1, $3.place, $$.place);
        add_quad(&quad_table, ":=", $$.place, NULL, $1);
    }
    | IDENTIFIER TIMES_ASSIGN expression {
        if (!check_variable_declared(&symbol_table, $1, yylineno)) {
            yyerror("Variable non déclarée");
        }
        $$.type = get_variable_type(&symbol_table, $1);
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "*", $1, $3.place, $$.place);
        add_quad(&quad_table, ":=", $$.place, NULL, $1);
    }
    | IDENTIFIER DIVIDE_ASSIGN expression {
        if (!check_variable_declared(&symbol_table, $1, yylineno)) {
            yyerror("Variable non déclarée");
        }
        $$.type = get_variable_type(&symbol_table, $1);
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "/", $1, $3.place, $$.place);
        add_quad(&quad_table, ":=", $$.place, NULL, $1);
    }
    | array_access ASSIGN expression {
        $$.type = strdup("unknown");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "array_assign", $1.place, $3.place, $$.place);
    }
    | array_access PLUS_ASSIGN expression {
        $$.type = strdup("unknown");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "+", $1.place, $3.place, $$.place);
        add_quad(&quad_table, "array_assign", $$.place, NULL, $1.place);
    }
    | array_access MINUS_ASSIGN expression {
        $$.type = strdup("unknown");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "-", $1.place, $3.place, $$.place);
        add_quad(&quad_table, "array_assign", $$.place, NULL, $1.place);
    }
    | array_access TIMES_ASSIGN expression {
        $$.type = strdup("unknown");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "*", $1.place, $3.place, $$.place);
        add_quad(&quad_table, "array_assign", $$.place, NULL, $1.place);
    }
    | array_access DIVIDE_ASSIGN expression {
        $$.type = strdup("unknown");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "/", $1.place, $3.place, $$.place);
        add_quad(&quad_table, "array_assign", $$.place, NULL, $1.place);
    }
    | THIS DOT IDENTIFIER ASSIGN expression {
        $$.type = strdup("unknown");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, ":=", $5.place, NULL, $3);
    }
    | THIS DOT IDENTIFIER PLUS_ASSIGN expression {
        $$.type = strdup("unknown");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "+", $3, $5.place, $$.place);
        add_quad(&quad_table, ":=", $$.place, NULL, $3);
    }
    | THIS DOT IDENTIFIER MINUS_ASSIGN expression {
        $$.type = strdup("unknown");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "-", $3, $5.place, $$.place);
        add_quad(&quad_table, ":=", $$.place, NULL, $3);
    }
    | THIS DOT IDENTIFIER TIMES_ASSIGN expression {
        $$.type = strdup("unknown");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "*", $3, $5.place, $$.place);
        add_quad(&quad_table, ":=", $$.place, NULL, $3);
    }
    | THIS DOT IDENTIFIER DIVIDE_ASSIGN expression {
        $$.type = strdup("unknown");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "/", $3, $5.place, $$.place);
        add_quad(&quad_table, ":=", $$.place, NULL, $3);
    }
    ;

array_creation:
    type LBRACKET expression RBRACKET {
        if ($3.type && strcmp($3.type, "int") != 0) {
            printf("Erreur sémantique: la taille du tableau doit être de type int.\n");
        }
        $$.type = strdup("array");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "new_array", $3.place, NULL, $$.place);
    }
    | type LBRACKET RBRACKET array_initializer {
        $$.type = strdup("array");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "new_array", NULL, NULL, $$.place);
    }
    | type LBRACKET expression RBRACKET array_dimensions {
        if ($3.type && strcmp($3.type, "int") != 0) {
            printf("Erreur sémantique: la taille du tableau doit être de type int.\n");
        }
        $$.type = strdup("array");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "new_array", $3.place, NULL, $$.place);
    }
    ;

array_initializer:
    LBRACE expression_list RBRACE
    | LBRACE RBRACE
    ;

array_init:
    NEW array_creation {
        $$ = $2;
    }
    | LBRACE expression_list RBRACE {
        $$.type = strdup("array");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "array_init", NULL, NULL, $$.place);
    }
    ;

array_access:
    IDENTIFIER LBRACKET expression RBRACKET {
        if (!check_variable_declared(&symbol_table, $1, yylineno)) {
            yyerror("Variable non déclarée");
        }
        $$.type = strdup("unknown");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "array_access", $1, $3.place, $$.place);
    }
    | array_access LBRACKET expression RBRACKET {
        $$.type = strdup("unknown");
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "array_access", $1.place, $3.place, $$.place);
    }
    ;

array_dimensions:
    LBRACKET expression RBRACKET
    | array_dimensions LBRACKET expression RBRACKET
    ;

expression_list:
    expression { $$ = $1; }
    | expression_list COMMA expression { $$ = $3; }
    ;

method_invocation:
    IDENTIFIER LPAREN argument_list RPAREN {
        Symbol *func = symbol_lookup_all(&symbol_table, $1);
        if (!func || func->sym_type != SYM_FUNCTION) {
            yyerror("Méthode non déclarée");
        }
        if ($3.count != func->param_count) {
            yyerror("Nombre d'arguments incorrect");
        }
        for (int i = 0; i < $3.count; i++) {
            if (!check_type_compatibility($3.types[i], get_data_type_string(func->param_types[i]))) {
                yyerror("Incompatibilité de type pour l'argument");
            }
        }
        $$.type = get_data_type_string(func->data_type);
        $$.place = new_temp(&quad_table);
        char *func_label = malloc(strlen($1) + 10);
        sprintf(func_label, "func_%s", $1);
        add_quad(&quad_table, "call", func_label, NULL, $$.place);
        free(func_label);
    }
    | qualified_access LPAREN argument_list RPAREN {
        Symbol *func = symbol_lookup_all(&symbol_table, $1);
        if (!func || func->sym_type != SYM_FUNCTION) {
            yyerror("Méthode non déclarée");
        }
        if ($3.count != func->param_count) {
            yyerror("Nombre d'arguments incorrect");
        }
        for (int i = 0; i < $3.count; i++) {
            if (!check_type_compatibility($3.types[i], get_data_type_string(func->param_types[i]))) {
                yyerror("Incompatibilité de type pour l'argument");
            }
        }
        $$.type = get_data_type_string(func->data_type);
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "call", $1, NULL, $$.place);
    }
    | primary_expression DOT IDENTIFIER LPAREN argument_list RPAREN {
        char *method_call = malloc(strlen($1.place) + strlen($3) + 2);
        sprintf(method_call, "%s.%s", $1.place, $3);
        Symbol *func = symbol_lookup_all(&symbol_table, method_call);
        if (!func || func->sym_type != SYM_FUNCTION) {
            yyerror("Méthode non déclarée");
        }
        if ($5.count != func->param_count) {
            yyerror("Nombre d'arguments incorrect");
        }
        for (int i = 0; i < $5.count; i++) {
            if (!check_type_compatibility($5.types[i], get_data_type_string(func->param_types[i]))) {
                yyerror("Incompatibilité de type pour l'argument");
            }
        }
        $$.type = get_data_type_string(func->data_type);
        $$.place = new_temp(&quad_table);
        add_quad(&quad_table, "call", method_call, NULL, $$.place);
        free(method_call);
    }
    ;

qualified_access:
    IDENTIFIER DOT IDENTIFIER {
        char *access = malloc(strlen($1) + strlen($3) + 2);
        sprintf(access, "%s.%s", $1, $3);
        $$ = access;
    }
    | qualified_access DOT IDENTIFIER {
        char *access = malloc(strlen($1) + strlen($3) + 2);
        sprintf(access, "%s.%s", $1, $3);
        free($1);
        $$ = access;
    }
    | SYSTEM DOT OUT DOT PRINTLN {
        $$ = strdup("System.out.println");
    }
    ;

argument_list:
    /* empty */ {
        $$.count = 0;
        $$.places = NULL;
        $$.types = NULL;
    }
    | expression {
        $$.count = 1;
        $$.places = malloc(sizeof(char*));
        $$.types = malloc(sizeof(char*));
        $$.places[0] = strdup($1.place);
        $$.types[0] = strdup($1.type);
        add_quad(&quad_table, "param", $1.place, NULL, NULL);
    }
    | argument_list COMMA expression {
        $$ = $1;
        $$.count++;
        $$.places = realloc($$.places, $$.count * sizeof(char*));
        $$.types = realloc($$.types, $$.count * sizeof(char*));
        $$.places[$$.count-1] = strdup($3.place);
        $$.types[$$.count-1] = strdup($3.type);
        add_quad(&quad_table, "param", $3.place, NULL, NULL);
    }
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
    | RETURN expression SEMICOLON {
        add_quad(&quad_table, "return", $2.place, NULL, NULL);
    }
    | RETURN SEMICOLON {
        add_quad(&quad_table, "return", NULL, NULL, NULL);
    }
    | BREAK SEMICOLON {
        add_quad(&quad_table, "break", NULL, NULL, NULL);
    }
    | CONTINUE SEMICOLON {
        add_quad(&quad_table, "continue", NULL, NULL, NULL);
    }
    | PRINTLN LPAREN println_args RPAREN SEMICOLON {
        add_quad(&quad_table, "println", $3.place ? $3.place : "null", NULL, NULL);
    }
    | PRINT LPAREN println_args RPAREN SEMICOLON {
        add_quad(&quad_table, "print", $3.place ? $3.place : "null", NULL, NULL);
    }
    | IDENTIFIER LPAREN argument_list RPAREN SEMICOLON {
        Symbol *func = symbol_lookup_all(&symbol_table, $1);
        if (!func || func->sym_type != SYM_FUNCTION) {
            yyerror("Méthode non déclarée");
        }
        if ($3.count != func->param_count) {
            yyerror("Nombre d'arguments incorrect");
        }
        for (int i = 0; i < $3.count; i++) {
            if (!check_type_compatibility($3.types[i], get_data_type_string(func->param_types[i]))) {
                yyerror("Incompatibilité de type pour l'argument");
            }
        }
        char *func_label = malloc(strlen($1) + 10);
        sprintf(func_label, "func_%s", $1);
        add_quad(&quad_table, "call", func_label, NULL, NULL);
        free(func_label);
    }
    | IDENTIFIER ASSIGN expression SEMICOLON {
        if (!check_variable_declared(&symbol_table, $1, yylineno)) {
            yyerror("Variable non déclarée");
        }
        add_quad(&quad_table, ":=", $3.place, NULL, $1);
    }
    ;

declaration:
    type IDENTIFIER {
        printf("Déclaration variable locale : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, $1, 0, 0, NULL);
    }
    | type IDENTIFIER ASSIGN expression {
        printf("Déclaration variable locale avec assignation : %s\n", $2);
        check_assignment_type($1, $4);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, $1, 0, 0, NULL);
        add_quad(&quad_table, ":=", $4.place, NULL, $2);
    }
    | type IDENTIFIER LBRACKET RBRACKET {
        printf("Déclaration tableau local : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);
    }
    | type IDENTIFIER LBRACKET RBRACKET ASSIGN array_init {
        printf("Déclaration tableau local avec initialisation : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);
        add_quad(&quad_table, ":=", $6.place, NULL, $2);
    }
    | type IDENTIFIER ASSIGN NEW IDENTIFIER LPAREN argument_list RPAREN {
        printf("Déclaration variable avec instanciation d'objet : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, TYPE_OBJECT, 0, 0, NULL);
        char *temp = new_temp(&quad_table);
        add_quad(&quad_table, "new", $5, NULL, temp);
        add_quad(&quad_table, ":=", temp, NULL, $2);
    }
    | type IDENTIFIER ASSIGN array_init {
        printf("Déclaration tableau avec initialisation : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);
        add_quad(&quad_table, ":=", $4.place, NULL, $2);
    }
    ;

block:
    LBRACE { enter_scope(&symbol_table); }
    statements 
    RBRACE { exit_scope(&symbol_table); }
    ;

if_statement:
    IF LPAREN expression RPAREN statement {
        if (strcmp($3.type, "boolean") != 0) {
            yyerror("L'expression du if doit être booléenne");
        }
        char *label_end = new_label(&quad_table);
        add_quad(&quad_table, "if_false", $3.place, label_end, NULL);
        add_quad(&quad_table, "label", label_end, NULL, NULL);
    }
    | IF LPAREN expression RPAREN statement ELSE statement {
        if (strcmp($3.type, "boolean") != 0) {
            yyerror("L'expression du if doit être booléenne");
        }
        char *label_else = new_label(&quad_table);
        char *label_end = new_label(&quad_table);
        add_quad(&quad_table, "if_false", $3.place, label_else, NULL);
        add_quad(&quad_table, "goto", label_end, NULL, NULL);
        add_quad(&quad_table, "label", label_else, NULL, NULL);
        add_quad(&quad_table, "label", label_end, NULL, NULL);
    }
    ;

for_statement:
    FOR LPAREN for_init_opt SEMICOLON for_cond_opt SEMICOLON for_update_opt RPAREN {
        if ($5.type && strcmp($5.type, "boolean") != 0) {
            yyerror("L'expression de condition du for doit être booléenne");
        }
        char *label_start = new_label(&quad_table);
        char *label_end = new_label(&quad_table);
        add_quad(&quad_table, "label", label_start, NULL, NULL);
        if ($5.place) {
            add_quad(&quad_table, "if_false", $5.place, label_end, NULL);
        }
        $<expr>$.place = label_start;
        $<expr>$.type = label_end;
    }
    statement {
        add_quad(&quad_table, "goto", $<expr>9.place, NULL, NULL);
        add_quad(&quad_table, "label", $<expr>9.type, NULL, NULL);
    }
    ;

for_init_opt:
    /* empty */ {
        $$.place = NULL;
        $$.type = NULL;
    }
    | for_init { $$ = $1; }
    ;

for_cond_opt:
    /* empty */ {
        $$.place = NULL;
        $$.type = strdup("boolean");
    }
    | expression { $$ = $1; }
    ;

for_update_opt:
    /* empty */ {
        $$.place = NULL;
        $$.type = NULL;
    }
    | expression_list { $$ = $1; }
    ;

for_init:
    declaration { $$.place = NULL; $$.type = NULL; }
    | expression_list { $$ = $1; }
    ;

enhanced_for_statement:
    FOR LPAREN type IDENTIFIER COLON expression RPAREN statement
    ;

while_statement:
    WHILE LPAREN expression RPAREN statement {
        if (strcmp($3.type, "boolean") != 0) {
            yyerror("L'expression du while doit être booléenne");
        }
        char *label_start = new_label(&quad_table);
        char *label_end = new_label(&quad_table);
        add_quad(&quad_table, "label", label_start, NULL, NULL);
        add_quad(&quad_table, "if_false", $3.place, label_end, NULL);
        $<expr>$.place = label_start;
        $<expr>$.type = label_end;
        add_quad(&quad_table, "goto", label_start, NULL, NULL);
        add_quad(&quad_table, "label", label_end, NULL, NULL);
    }
    ;

switch_statement:
    SWITCH LPAREN expression RPAREN switch_block {
        if (strcmp($3.type, "int") != 0) {
            yyerror("L'expression du switch doit être de type int");
        }
        char *label_end = new_label(&quad_table);
        $<expr>$.type = label_end;
        add_quad(&quad_table, "label", label_end, NULL, NULL);
    }
    ;

switch_block:
    LBRACE switch_cases RBRACE
    ;

switch_cases:
    /* empty */
    | switch_cases switch_case
    ;

switch_case:
    CASE expression COLON statements {
        if (strcmp($2.type, "int") != 0) {
            yyerror("L'expression du case doit être de type int");
        }
        char *label_next = new_label(&quad_table);
        add_quad(&quad_table, "if_neq", $<expr>-2.place, $2.place, label_next);
        add_quad(&quad_table, "label", label_next, NULL, NULL);
    }
    | DEFAULT COLON statements {
        char *label_next = new_label(&quad_table);
        add_quad(&quad_table, "label", label_next, NULL, NULL);
    }
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
    /* empty */ {
        $$.type = NULL;
        $$.place = NULL;
    }
    | expression {
        $$ = $1;
    }
    | println_args COMMA expression {
        $$ = $3;
    }
    ;

%%

int main(int argc, char *argv[]) {
    init_symbol_table(&symbol_table);
    init_quad_table(&quad_table);
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

    printf("\n=== Quadruplets avant optimisation ===\n");
    print_quads(&quad_table);

    propagate_copies(&quad_table);
    printf("\n=== Après propagate_copies ===\n");
    print_quads(&quad_table);

    propagate_expressions(&quad_table);
    printf("\n=== Après propagate_expressions ===\n");
    print_quads(&quad_table);

    remove_redundant_expressions(&quad_table);
    printf("\n=== Après remove_redundant_expressions ===\n");
    print_quads(&quad_table);

    simplify_algebraic(&quad_table);
    printf("\n=== Après simplify_algebraic ===\n");
    print_quads(&quad_table);

    remove_dead_code(&quad_table);
    printf("\n=== Après remove_dead_code ===\n");
    print_quads(&quad_table);
    generate_8086_code(&quad_table, "output.asm");

    print_symbol_table(&symbol_table);
    free_quad_table(&quad_table);
    return 0;
}