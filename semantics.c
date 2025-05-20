#include "semantics.h"
#include <stdio.h>
#include <string.h>

int check_variable_declared(SymbolTable *st, const char *name, int lineno) {
    Symbol *sym = symbol_lookup(st, name, st->current_scope);
    if (!sym) {
        fprintf(stderr, "Erreur ligne %d: Variable '%s' non déclarée\n", lineno, name);
        return 0;
    }
    return 1;
}

int check_array_access(SymbolTable *st, const char *name, int lineno) {
    Symbol *sym = symbol_lookup(st, name, st->current_scope);
    if (!sym) {
        fprintf(stderr, "Erreur ligne %d: Variable '%s' non déclarée\n", lineno, name);
        return 0;
    }
    if (sym->sym_type != SYM_ARRAY && sym->data_type != TYPE_ARRAY) {
        fprintf(stderr, "Erreur ligne %d: '%s' n'est pas un tableau\n", lineno, name);
        return 0;
    }
    return 1;
}

int check_type_compatibility(char *type1, char *type2) {
    if (type1 == NULL || type2 == NULL) return 0;
    return strcmp(type1, type2) == 0;
}

char *get_variable_type(SymbolTable *st, char *name) {
    Symbol *sym = symbol_lookup(st, name, st->current_scope);
    if (!sym) return NULL;
    switch (sym->data_type) {
        case TYPE_INT: return "int";
        case TYPE_DOUBLE: return "double";
        case TYPE_CHAR: return "char";
        case TYPE_BOOLEAN: return "boolean";
        case TYPE_STRING: return "String";
        case TYPE_ARRAY: return "array";
        case TYPE_FLOAT: return "float";
        case TYPE_OBJECT: return "object";
        case TYPE_CLASS: return "class";
        case TYPE_IDENTIFIER: return "identifier";
        default: return "unknown";
    }
}

const char* type_to_string(DataType type) {
    switch (type) {
        case TYPE_INT: return "int";
        case TYPE_DOUBLE: return "double";
        case TYPE_CHAR: return "char";
        case TYPE_BOOLEAN: return "boolean";
        case TYPE_STRING: return "String";
        case TYPE_VOID: return "void";
        case TYPE_CLASS: return "class";
        case TYPE_ARRAY: return "array";
        case TYPE_FLOAT: return "float";
        case TYPE_OBJECT: return "object";
        case TYPE_IDENTIFIER: return "identifier";
        default: return "unknown";
    }
}

void check_assignment_type(int expected_type, ExprAttr expr) {
    const char *expected_type_str = type_to_string(expected_type);
    if (expr.type && strcmp(expr.type, expected_type_str) != 0) {
        fprintf(stderr, "Erreur sémantique ligne %d: Type attendu '%s', obtenu '%s'\n", 
                yylineno, expected_type_str, expr.type);
    }
}

int check_array_element_type(DataType array_type, DataType element_type) {
    if (array_type != TYPE_ARRAY) return 0;
    return element_type != TYPE_UNKNOWN;
}