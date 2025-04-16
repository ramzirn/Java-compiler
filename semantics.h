#ifndef SEMANTICS_H
#define SEMANTICS_H

#include "symbol_table.h"
#include <stdio.h>

// Vérifie si une variable est déclarée avant utilisation
int check_variable_declared(SymbolTable *st, const char *name, int lineno);

// Vérifie si un identifiant est un tableau lors de l'accès avec []
int check_array_access(SymbolTable *st, const char *name, int lineno);

#endif