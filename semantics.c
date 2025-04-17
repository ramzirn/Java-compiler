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

int check_type_compatibility(DataType type1, DataType type2) {
    if (type1 != type2) {
        // Vérification des types compatibles (par exemple entre int et double)
        if ((type1 == TYPE_INT && type2 == TYPE_DOUBLE) || (type1 == TYPE_DOUBLE && type2 == TYPE_INT)) {
            return 1; // Les types int et double sont compatibles
        } else {
            // Afficher un message d'erreur avec des noms de types plus compréhensibles
            printf("Erreur sémantique : incompatibilité de type entre '%s' et '%s'\n", 
                    type_to_string(type1), type_to_string(type2));
            return 0; // Les types ne sont pas compatibles
        }
    }
    return 1; // Les types sont compatibles
}
; // Les types sont compatibles

DataType get_variable_type(SymbolTable* table, const char* name, int current_scope) {
    Symbol* sym = symbol_lookup(table, name, current_scope);
    if (sym != NULL) {
        return sym->data_type;
    } else {
        fprintf(stderr, "Erreur: variable '%s' non déclarée.\n", name);
        return TYPE_UNKNOWN; // À définir dans ton enum DataType
    }
}
const char* type_to_string(DataType type) {
    switch(type) {
        case TYPE_INT: return "int";
        case TYPE_BOOLEAN: return "boolean";
        case TYPE_VOID: return "void";
        case TYPE_STRING: return "String";
        case TYPE_CHAR: return "char";
        default: return "unknown";
    }
}

void check_assignment_type(int declared_type, int expr_type) {
    if (declared_type != expr_type) {
        fprintf(stderr,
                "Erreur sémantique : assignation d'un type incompatible (attendu %d, reçu %d)\n",
                declared_type, expr_type);
        exit(1);
    }
}
