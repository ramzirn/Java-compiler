#ifndef SEMANTICS_H
#define SEMANTICS_H

#include "symbol_table.h"
#include <stdio.h>

extern int yylineno;

// Vérifie si une variable est déclarée avant utilisation
int check_variable_declared(SymbolTable *st, const char *name, int lineno);

// Vérifie si un identifiant est un tableau lors de l'accès avec []
int check_array_access(SymbolTable *st, const char *name, int lineno);

// Vérifie la compatibilité des types
int check_type_compatibility(char *type1, char *type2);

// Obtient le type d'une variable
char *get_variable_type(SymbolTable *st, char *name);

// Convertit un DataType en chaîne pour les messages d'erreur
const char* type_to_string(DataType type);

// Vérifie la compatibilité de type pour une assignation
void check_assignment_type(int expected_type, ExprAttr expr);

// Vérifie le type des éléments d'un tableau
int check_array_element_type(DataType array_type, DataType element_type);

#endif // SEMANTICS_H