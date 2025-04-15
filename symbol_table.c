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


Symbol *symbol_insert_function(SymbolTable *st, const char *name, 
    DataType return_type, int param_count, 
    char **param_names, DataType *param_types) {
Symbol *s = symbol_insert(st, name, SYM_FUNCTION, return_type, 0, -1, NULL);
if (s == NULL) return NULL;

s->param_count = param_count;
s->param_names = param_names;
s->param_types = param_types;

return s;
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
        fprintf(stderr, "Erreur sémantique : la variable '%s' est déjà déclarée dans le scope %d\n", name, st->current_scope);
        return NULL;
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
Symbol *symbol_lookup_all(SymbolTable *st, const char *name) {
    for (int scope = st->current_scope; scope >= 0; scope--) {
        Symbol *s = symbol_lookup(st, name, scope);
        if (s != NULL) {
            return s;
        }
    }
    return NULL; // Non trouvé dans aucun scope
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
                case TYPE_OBJECT: data_type_str = "objet"; break;

                default: data_type_str = "inconnu"; break;
            }

            // Afficher les symboles classiques
            printf("%-20s %-12s %-12s %-8d %-10s %-8d %-10s\n", 
                   s->name, sym_type_str, data_type_str, s->scope_level,
                   s->is_constant ? "oui" : "non", s->array_size,
                   s->class_name ? s->class_name : "-");
            
            // Si c'est une fonction, afficher les paramètres associés
            if (s->sym_type == SYM_FUNCTION && s->param_names != NULL) {
                for (int i = 0; i < s->param_count; i++) {
                    const char *param_data_type_str;
                    switch (s->param_types[i]) {
                        case TYPE_INT: param_data_type_str = "int"; break;
                        case TYPE_DOUBLE: param_data_type_str = "double"; break;
                        case TYPE_CHAR: param_data_type_str = "char"; break;
                        case TYPE_BOOLEAN: param_data_type_str = "boolean"; break;
                        case TYPE_STRING: param_data_type_str = "String"; break;
                        case TYPE_VOID: param_data_type_str = "void"; break;
                        case TYPE_CLASS: param_data_type_str = s->class_name ? s->class_name : "class"; break;
                        case TYPE_ARRAY: param_data_type_str = "array"; break;
                        case TYPE_OBJECT: data_type_str = "objet"; break;

                        default: param_data_type_str = "inconnu"; break;
                    }
                    printf("%-20s %-12s %-12s %-8d %-10s %-8d %-10s (Paramètre de Fonction)\n",
                           s->param_names[i], "Parametre", param_data_type_str, s->scope_level + 1,
                           "non", -1, "-");
                }
            }
            
            s = s->next;
        }
    }
    printf("============================================================\n\n");
}

// Entrée dans un nouveau scope
void enter_scope(SymbolTable *st) {
    st->current_scope++;
printf("enter");
}

// Sortie du scope courant
void exit_scope(SymbolTable *st) {
    printf("exit");

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



