#ifndef SEMANTICS_H
#define SEMANTICS_H

#include "symbol_table.h"
#include <stdio.h>
extern int yylineno;

// Vérifie si une variable est déclarée avant utilisation
int check_variable_declared(SymbolTable *st, const char *name, int lineno);

// Vérifie si un identifiant est un tableau lors de l'accès avec []
int check_array_access(SymbolTable *st, const char *name, int lineno);
int check_type_compatibility(DataType type1, DataType type2);
// semantics.h
DataType get_variable_type(SymbolTable* table, const char* name, int current_scope);
const char* type_to_string(DataType type) ;
void check_assignment_type(int declared_type, int expr_type) ;
int check_array_element_type(DataType array_type, DataType element_type) ;
#endif