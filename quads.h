#ifndef QUADS_H
#define QUADS_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Structure pour un quadruplet
typedef struct Quad {
    char *op;       // Opérateur (e.g., "+", ":=", "goto")
    char *arg1;     // Premier opérande
    char *arg2;     // Deuxième opérande
    char *result;   // Résultat
} Quad;

// Structure pour gérer la liste des quadruplets
typedef struct QuadTable {
    Quad *quads;        // Tableau dynamique de quadruplets
    int quad_count;     // Nombre de quadruplets
    int quad_capacity;  // Capacité du tableau
    int temp_count;     // Compteur pour variables temporaires
} QuadTable;

// Fonctions pour gérer les quadruplets
void init_quad_table(QuadTable *qt);
void add_quad(QuadTable *qt, const char *op, const char *arg1, const char *arg2, const char *result);
char *new_temp(QuadTable *qt);
void print_quads(QuadTable *qt);
void free_quad_table(QuadTable *qt);

#endif // QUADS_H