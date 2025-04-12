#include "symbol_table.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

// Initialisation de la table des symboles
void init_symbol_table(SymbolTable *st) {
    for (int i = 0; i < SYMBOL_TABLE_SIZE; i++) {
        st->table[i] = NULL;
    }
    st->current_scope = 0;
}

// Fonction de hachage
unsigned int hash(const char *name) {
    unsigned int hashval = 0;
    for (; *name != '\0'; name++) {
        hashval = *name + 31 * hashval;
    }
    return hashval % SYMBOL_TABLE_SIZE;
}

// Recherche d'un symbole dans la table
Symbol *symbol_lookup(SymbolTable *st, const char *name, int current_scope) {
    unsigned int hashval = hash(name);
    Symbol *s = st->table[hashval];
    
    // Recherche dans la chaîne de collision
    while (s != NULL) {
        if (strcmp(s->name, name) == 0 && s->scope_level <= current_scope) {
            return s;
        }
        s = s->next;
    }
    
    return NULL; // Symbole non trouvé
}

// Insertion d'un nouveau symbole
Symbol *symbol_insert(SymbolTable *st, const char *name, SymbolType sym_type, 
                     DataType data_type, int is_constant, int array_size, 
                     const char *class_name) {
    // Vérifier si le symbole existe déjà dans le scope courant
    Symbol *s = symbol_lookup(st, name, st->current_scope);
    if (s != NULL && s->scope_level == st->current_scope) {
        return NULL; // Erreur: symbole déjà déclaré dans ce scope
    }
    
    // Allocation du nouveau symbole
    Symbol *new_sym = (Symbol *)malloc(sizeof(Symbol));
    if (new_sym == NULL) {
        return NULL; // Erreur d'allocation
    }
    
    // Initialisation des champs
    new_sym->name = strdup(name);
    new_sym->sym_type = sym_type;
    new_sym->data_type = data_type;
    new_sym->scope_level = st->current_scope;
    new_sym->is_constant = is_constant;
    new_sym->array_size = array_size;
    new_sym->class_name = class_name ? strdup(class_name) : NULL;
    
    // Insertion dans la table de hachage
    unsigned int hashval = hash(name);
    new_sym->next = st->table[hashval];
    st->table[hashval] = new_sym;
    printf("Insertion: %s, Type: %d, Scope: %d\n", name, sym_type, st->current_scope);
    return new_sym;
}

// Suppression d'un symbole
void symbol_remove(SymbolTable *st, const char *name) {
    unsigned int hashval = hash(name);
    Symbol *prev = NULL;
    Symbol *s = st->table[hashval];
    
    // Recherche dans la chaîne de collision
    while (s != NULL && strcmp(s->name, name) != 0) {
        prev = s;
        s = s->next;
    }
    
    if (s == NULL) return; // Symbole non trouvé
    
    // Réorganisation de la chaîne
    if (prev == NULL) {
        st->table[hashval] = s->next;
    } else {
        prev->next = s->next;
    }
    
    // Libération de la mémoire
    free(s->name);
    if (s->class_name) free(s->class_name);
    free(s);
}

// Affichage de la table des symboles
void print_symbol_table(SymbolTable *st) {
    printf("\n===== TABLE DES SYMBOLES =====\n");
    printf("%-20s %-12s %-12s %-8s %-10s %-8s %-10s\n", 
           "Nom", "Type", "Data Type", "Scope", "Constant", "Taille", "Classe");
    printf("------------------------------------------------------------\n");
    
    for (int i = 0; i < SYMBOL_TABLE_SIZE; i++) {
        Symbol *s = st->table[i];
        while (s != NULL) {
            const char *sym_type_str;
            switch (s->sym_type) {
                case SYM_VARIABLE: sym_type_str = "Variable"; break;
                case SYM_FUNCTION: sym_type_str = "Fonction"; break;
                case SYM_CLASS: sym_type_str = "Classe"; break;
                case SYM_ARRAY: sym_type_str = "Tableau"; break;
                case SYM_PARAMETER: sym_type_str = "Parametre"; break;
                default: sym_type_str = "Inconnu"; break;
            }
            
            const char *data_type_str;
            switch (s->data_type) {
                case TYPE_INT: data_type_str = "int"; break;
                case TYPE_DOUBLE: data_type_str = "double"; break;
                case TYPE_CHAR: data_type_str = "char"; break;
                case TYPE_BOOLEAN: data_type_str = "boolean"; break;
                case TYPE_STRING: data_type_str = "String"; break;
                case TYPE_VOID: data_type_str = "void"; break;
                case TYPE_CLASS: data_type_str = s->class_name ? s->class_name : "class"; break;
                case TYPE_ARRAY: data_type_str = "array"; break;
                default: data_type_str = "inconnu"; break;
            }
            
            printf("%-20s %-12s %-12s %-8d %-10s %-8d %-10s\n", 
                   s->name, sym_type_str, data_type_str, s->scope_level,
                   s->is_constant ? "oui" : "non", s->array_size,
                   s->class_name ? s->class_name : "-");
            
            s = s->next;
        }
    }
    printf("============================================================\n\n");
}

// Entrée dans un nouveau scope
void enter_scope(SymbolTable *st) {
    st->current_scope++;
}

// Sortie du scope courant
void exit_scope(SymbolTable *st) {
    // Suppression de tous les symboles du scope courant
    for (int i = 0; i < SYMBOL_TABLE_SIZE; i++) {
        Symbol *prev = NULL;
        Symbol *s = st->table[i];
        
        while (s != NULL) {
            if (s->scope_level == st->current_scope) {
                // Suppression du symbole
                Symbol *to_delete = s;
                if (prev == NULL) {
                    st->table[i] = s->next;
                } else {
                    prev->next = s->next;
                }
                s = s->next;
                
                free(to_delete->name);
                if (to_delete->class_name) free(to_delete->class_name);
                free(to_delete);
            } else {
                prev = s;
                s = s->next;
            }
        }
    }
    
    st->current_scope--;
}
