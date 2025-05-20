#ifndef QUADS_H
#define QUADS_H
#include <stdbool.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_QUADS 1000

typedef struct Quad {
    char *op;       // Opérateur (e.g., "+", ":=", "if_false", "goto", "label")
    char *arg1;     // Premier argument
    char *arg2;     // Deuxième argument
    char *result;   // Résultat ou destination
} Quad;

typedef struct QuadTable {
    Quad *quads[MAX_QUADS];
    int quad_count;
    int temp_count; // Pour générer des variables temporaires (e.g., t0, t1)
} QuadTable;

void init_quad_table(QuadTable *table);
void add_quad(QuadTable *table, const char *op, const char *arg1, const char *arg2, const char *result);
char *new_temp(QuadTable *table);
char *new_label(QuadTable *table);
void print_quads(QuadTable *table);
void free_quad_table(QuadTable *table);
void propagate_copies(QuadTable *table);
void propagate_expressions(QuadTable *table);
void remove_redundant_expressions(QuadTable *table);
void simplify_algebraic(QuadTable *table);
void remove_dead_code(QuadTable *table);
bool is_used(QuadTable *table, int start, const char *var) ;
void remove_dead_code(QuadTable *table) ;


#endif // QUADS_H