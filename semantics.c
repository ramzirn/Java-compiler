#include "semantics.h"
#include "symbol_table.h"
#include <stdio.h>

int check_variable_declared(SymbolTable *st, const char *name, int lineno) {
    Symbol *s = symbol_lookup_all(st, name);
    if (s == NULL) {
        fprintf(stderr, "Erreur sémantique ligne %d: Variable non déclarée '%s'\n", lineno, name);
        return 0; // Erreur
    }
    return 1; // OK
}

int check_array_access(SymbolTable *st, const char *name, int lineno) {
    if (!check_variable_declared(st, name, lineno)) {
        return 0; // Erreur déjà signalée
    }
    
    Symbol *s = symbol_lookup_all(st, name);
    if (s->data_type != TYPE_ARRAY) {
        fprintf(stderr, "Erreur sémantique ligne %d: '%s' n'est pas un tableau\n", lineno, name);
        return 0;
    }
    return 1;
}