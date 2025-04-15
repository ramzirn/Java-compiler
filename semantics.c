#include "semantics.h"
#include <stdio.h>
#include <stdlib.h>

int extern yylineno;
// Définition de la fonction check_declared
void check_declared(SymbolTable* table, const char* name) {
    if (!symbol_lookup_all(table, name)) {
        fprintf(stderr, "Erreur à la ligne %d : variable '%s' non déclarée.\n", yylineno, name);
        exit(1);
    }
}
