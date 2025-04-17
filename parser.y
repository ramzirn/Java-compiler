%{
#include "symbol_table.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int check_variable_declared(SymbolTable* table, char* name, int line);
int check_type_compatibility(char* type1, char* type2);
char* get_variable_type(SymbolTable* table, char* name);


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

      struct expr_attr {
        char* type;
    char* strval; // optionnel, utile pour garder le nom de la variable   
     }expr;
}

%token NULL_LITERAL PLUSPLUS MINUSMINUS QUESTION
%token STRING IMPORT PUBLIC CLASS STATIC VOID INT DOUBLE CHAR BOOLEAN
%token IF ELSE FOR WHILE SWITCH CASE DEFAULT TRY CATCH FINALLY
%token EXTENDS IMPLEMENTS NEW THIS SUPER RETURN BREAK CONTINUE
%token LBRACE RBRACE LPAREN RPAREN LBRACKET RBRACKET SEMICOLON COMMA DOT COLON STAR 
%token PLUS MINUS TIMES DIVIDE ASSIGN PLUS_ASSIGN MINUS_ASSIGN TIMES_ASSIGN DIVIDE_ASSIGN
%token EQ NEQ LT GT LTE GTE AND OR NOT
%token INTEGER_LITERAL DOUBLE_LITERAL CHAR_LITERAL BOOLEAN_LITERAL IDENTIFIER
%token PRIVATE PROTECTED FINAL 
%token SYSTEM OUT PRINTLN PRINT
%token LENGTH
%token <str> STRING_LITERAL
%token <expr_attr> FLOAT_LITERAL


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

%type <num> type
%type <param_list> param_list param_list_opt
%type <str> primary_expression IDENTIFIER 
%type <expr> expression

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
    modifiers type IDENTIFIER LPAREN param_list_opt RPAREN {
        printf("Déclaration de fonction: nom = %s, type retour = %d, nb params = %d\n", $3, $2, $5.count);
        
        // Insérer la fonction dans le scope actuel (généralement global)
        symbol_insert_function(&symbol_table, $3, $2, $5.count, $5.names, $5.types);
        
        // Entrer dans le scope de la fonction
        enter_scope(&symbol_table);

        // Insérer les paramètres comme variables locales dans ce scope
        for (int i = 0; i < $5.count; ++i) {
            Symbol *inserted = symbol_insert(&symbol_table, $5.names[i], SYM_VARIABLE, $5.types[i], 0, 0, NULL);
            if (inserted) {
                printf("Paramètre inséré : %s (Scope %d)\n", $5.names[i], symbol_table.current_scope);
            }
        }
    }
    method_body {
        // Sortie du scope de la fonction
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
expression:
      cast_expression
    | expression PLUS expression {
          if (!check_type_compatibility($1.type, $3.type)) {
              yyerror("Incompatibilité de types dans l'opération '+'");
          }
          $$ = (struct expr_attr){.type = $1.type}; // ou $3.type
      }
    | expression MINUS expression {
          if (!check_type_compatibility($1.type, $3.type)) {
              yyerror("Incompatibilité de types dans l'opération '-'");
          }
          $$ = (struct expr_attr){.type = $1.type};
      }
    | expression TIMES expression {
          if (!check_type_compatibility($1.type, $3.type)) {
              yyerror("Incompatibilité de types dans l'opération '*'");
          }
          $$ = (struct expr_attr){.type = $1.type};
      }
    | expression DIVIDE expression {
          if (!check_type_compatibility($1.type, $3.type)) {
              yyerror("Incompatibilité de types dans l'opération '/'");
          }
          $$ = (struct expr_attr){.type = $1.type};
      }
    | expression GT expression {
          if (!check_type_compatibility($1.type, $3.type)) {
              yyerror("Incompatibilité de types dans l'opération '>'");
          }
          $$ = (struct expr_attr){.type = "boolean"};
      }
    | expression LT expression {
          if (!check_type_compatibility($1.type, $3.type)) {
              yyerror("Incompatibilité de types dans l'opération '<'");
          }
          $$ = (struct expr_attr){.type = "boolean"};
      }
    | expression LTE expression {
          if (!check_type_compatibility($1.type, $3.type)) {
              yyerror("Incompatibilité de types dans l'opération '<='");
          }
          $$ = (struct expr_attr){.type = "boolean"};
      }
    | expression GTE expression {
          if (!check_type_compatibility($1.type, $3.type)) {
              yyerror("Incompatibilité de types dans l'opération '>='");
          }
          $$ = (struct expr_attr){.type = "boolean"};
      }
    | expression EQ expression {
          if (!check_type_compatibility($1.type, $3.type)) {
              yyerror("Incompatibilité de types dans l'opération '=='");
          }
          $$ = (struct expr_attr){.type = "boolean"};
      }
    | expression NEQ expression {
          if (!check_type_compatibility($1.type, $3.type)) {
              yyerror("Incompatibilité de types dans l'opération '!='");
          }
          $$ = (struct expr_attr){.type = "boolean"};
      }
    | expression AND expression {
          if (!check_type_compatibility($1.type, $3.type)) {
              yyerror("Incompatibilité de types dans l'opération '&&'");
          }
          $$ = (struct expr_attr){.type = "boolean"};
      }
    | expression OR expression {
          if (!check_type_compatibility($1.type, $3.type)) {
              yyerror("Incompatibilité de types dans l'opération '||'");
          }
          $$ = (struct expr_attr){.type = "boolean"};
      }
    | NOT expression {
          if (strcmp($2.type, "boolean") != 0) {
              yyerror("L'opérateur '!' attend un booléen");
          }
          $$ = (struct expr_attr){.type = "boolean"};
      }
    | assignment
    | IDENTIFIER PLUSPLUS {
          if (!check_variable_declared(&symbol_table, $1, yylineno)) {
              yyerror("Variable non déclarée");
          }
          $$ = (struct expr_attr){.type = get_variable_type(&symbol_table, $1), .strval = $1};
      }
    | IDENTIFIER MINUSMINUS {
          if (!check_variable_declared(&symbol_table, $1, yylineno)) {
              yyerror("Variable non déclarée");
          }
          $$ = (struct expr_attr){.type = get_variable_type(&symbol_table, $1), .strval = $1};
      }
    | NEW IDENTIFIER LPAREN argument_list RPAREN {
          // Tu peux ajouter ici une vérification de l’existence du constructeur
          $$ = (struct expr_attr){.type = $2};
      }
    | LPAREN type RPAREN expression {
          $$ = $4;
      }
    | IDENTIFIER DOT IDENTIFIER LPAREN argument_list RPAREN {
          // Vérifie si la méthode existe pour la classe $1
          $$ = (struct expr_attr){.type = "unknown"}; // ou un type réel si tu peux le déduire
      }
    ;

primary_expression:
    IDENTIFIER {
        // Vérification que la variable est déclarée avant d'y accéder
        if (!check_variable_declared(&symbol_table, $1, yylineno)) {
            YYERROR;
        }
        // Récupère le type de la variable à partir de la table des symboles
        $$ = get_type_of_identifier(&symbol_table, $1);
    }
    | INTEGER_LITERAL {
        // Type entier pour une valeur entière
        $$ = TYPE_INT;
    }
    | DOUBLE_LITERAL {
        // Type flottant pour une valeur à virgule
        $$ = TYPE_DOUBLE;
    }
    | STRING_LITERAL {
        // Type chaîne de caractères pour un littéral de type String
        $$ = TYPE_STRING;
    }
    | CHAR_LITERAL {
        // Type caractère pour un littéral de type char
        $$ = TYPE_CHAR;
    }
    | BOOLEAN_LITERAL {
        // Type booléen pour un littéral de type boolean
        $$ = TYPE_BOOLEAN;
    }
    | THIS {
        // Le type de `this` est spécifique à l'objet courant
        $$ = TYPE_OBJECT; 
    }
    | SUPER {
        // Le type de `super` est aussi lié à l'objet courant
        $$ = TYPE_OBJECT;
    }
    | NEW array_creation {
        // Lors de la création d'un tableau, le type est le type du tableau
        $$ = TYPE_ARRAY;
    }
    | LPAREN expression RPAREN {
        // Expression entre parenthèses, type d'une expression entre parenthèses est celui de l'expression
$$ = $2.strval;
    }
    | IDENTIFIER DOT LENGTH {
        // Pour l'accès à la longueur d'un tableau, renvoie un type entier
        $$ = TYPE_INT;
    }
    | IDENTIFIER DOT IDENTIFIER {
        // Accès à un membre d'objet, on récupère le type du membre
        $$ = get_type_of_identifier(&symbol_table, $3);
    }
    | CAST LPAREN type RPAREN primary_expression 
    | IDENTIFIER DOT IDENTIFIER LPAREN argument_list RPAREN {
        // Appel de fonction, le type retourné dépend de la fonction appelée
        $$ = get_function_return_type(&symbol_table, $3);
    }
    ;


cast_expression:
    unary_expression
    | CAST LPAREN type RPAREN cast_expression
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
 IDENTIFIER ASSIGN expression {
        if (!check_variable_declared(&symbol_table, $1, yylineno)) {
            YYERROR;
        }
    }    | IDENTIFIER PLUS_ASSIGN expression
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
      | IDENTIFIER ASSIGN expression SEMICOLON {
        if (!check_variable_declared(&symbol_table, $1, yylineno)) {
            YYERROR;
        }
    }

    ;

declaration:
    type IDENTIFIER {
        printf("Déclaration variable locale : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, $1, 0, 0, NULL);
    }
    | type IDENTIFIER ASSIGN expression {
        printf("Déclaration variable locale avec assignation : %s\n", $2);
        check_assignment_type($1, $4);  // Vérification de compatibilité de type
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, $1, 0, 0, NULL);
    }
    | type IDENTIFIER LBRACKET RBRACKET {
        printf("Déclaration tableau local : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);
    }
    | type IDENTIFIER LBRACKET RBRACKET ASSIGN array_init {
        printf("Déclaration tableau local avec initialisation : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);
    }
    | type IDENTIFIER ASSIGN NEW IDENTIFIER LPAREN argument_list RPAREN {
        printf("Déclaration variable avec instanciation d'objet : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, TYPE_OBJECT, 0, 0, NULL);
    }
    | type IDENTIFIER ASSIGN array_initializer {
        printf("Déclaration tableau avec initialisation : %s\n", $2);
        symbol_insert(&symbol_table, $2, SYM_VARIABLE, TYPE_ARRAY, 0, 0, NULL);
    }
;


block:
    LBRACE { enter_scope(&symbol_table); }
    statements 
    RBRACE { exit_scope(&symbol_table); }
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
