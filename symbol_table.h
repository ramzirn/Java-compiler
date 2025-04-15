#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#define TYPE_UNKNOWN -1  // Ou un autre code qui représente "inconnu"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SYMBOL_TABLE_SIZE 211

// Types de symboles
typedef enum {
    SYM_VARIABLE,
    SYM_FUNCTION,
    SYM_CLASS,
    SYM_ARRAY,
    SYM_PARAMETER
} SymbolType;

// Types de données
typedef enum {
    TYPE_INT,
    TYPE_DOUBLE,
    TYPE_CHAR,
    TYPE_BOOLEAN,
    TYPE_STRING,
    TYPE_VOID,
    TYPE_CLASS,
    TYPE_ARRAY,
    TYPE_OBJECT ,
    TYPE_IDENTIFIER, // Ajoute ceci si tu n'as pas déjà un type pour les identifiants
} DataType;

// Structure représentant un symbole dans la table des symboles
typedef struct Symbol {
    char *name;             // Nom du symbole
    SymbolType sym_type;    // Type du symbole (variable, fonction, etc.)
    DataType data_type;     // Type de données
    int scope_level;        // Niveau de portée
    int is_constant;        // 1 si constant, 0 sinon
    int array_size;         // Taille si c'est un tableau
    char *class_name;       // Nom de la classe si c'est un membre
    struct Symbol *next;    // Pour la gestion des collisions
    int param_count;
char **param_names;
DataType *param_types;
} Symbol;

// Structure représentant la table des symboles
typedef struct SymbolTable {
    Symbol *table[SYMBOL_TABLE_SIZE]; // Tableau de symboles
    int current_scope;                // Niveau de portée actuel
} SymbolTable;

// Fonctions de gestion de la table des symboles
void init_symbol_table(SymbolTable *st);
unsigned int hash(const char *name);
Symbol *symbol_lookup(SymbolTable *st, const char *name, int current_scope);
Symbol *symbol_insert(SymbolTable *st, const char *name, SymbolType sym_type, 
                     DataType data_type, int is_constant, int array_size, 
                     const char *class_name);
void symbol_remove(SymbolTable *st, const char *name);
void print_symbol_table(SymbolTable *st);
void enter_scope(SymbolTable *st);
void exit_scope(SymbolTable *st);
Symbol *symbol_insert_function(SymbolTable *st, const char *name, DataType return_type, int param_count, char **param_names, DataType *param_types);
#endif // SYMBOL_TABLE_H
