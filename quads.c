#include "quads.h"

// Initialisation de la table des quadruplets
void init_quad_table(QuadTable *qt) {
    qt->quad_capacity = 100; // Capacité initiale
    qt->quads = (Quad *)malloc(qt->quad_capacity * sizeof(Quad));
    if (!qt->quads) {
        fprintf(stderr, "Erreur : échec de l'allocation pour la table des quadruplets\n");
        exit(1);
    }
    qt->quad_count = 0;
    qt->temp_count = 0;
}

// Ajouter un quadruplet
void add_quad(QuadTable *qt, const char *op, const char *arg1, const char *arg2, const char *result) {
    if (qt->quad_count >= qt->quad_capacity) {
        qt->quad_capacity *= 2;
        qt->quads = (Quad *)realloc(qt->quads, qt->quad_capacity * sizeof(Quad));
        if (!qt->quads) {
            fprintf(stderr, "Erreur : échec de la réallocation pour la table des quadruplets\n");
            exit(1);
        }
    }
    Quad *q = &qt->quads[qt->quad_count++];
    q->op = strdup(op);
    q->arg1 = arg1 ? strdup(arg1) : NULL;
    q->arg2 = arg2 ? strdup(arg2) : NULL;
    q->result = result ? strdup(result) : NULL;
}

// Générer un nouveau temporaire
char *new_temp(QuadTable *qt) {
    char *temp = (char *)malloc(10);
    if (!temp) {
        fprintf(stderr, "Erreur : échec de l'allocation pour un temporaire\n");
        exit(1);
    }
    snprintf(temp, 10, "t%d", qt->temp_count++);
    return temp;
}

// Afficher les quadruplets
void print_quads(QuadTable *qt) {
    printf("\n===== QUADRUPLETS =====\n");
    printf("%-10s %-15s %-15s %-15s\n", "Op", "Arg1", "Arg2", "Result");
    printf("--------------------------------------------\n");
    for (int i = 0; i < qt->quad_count; i++) {
        Quad *q = &qt->quads[i];
        printf("%-10s %-15s %-15s %-15s\n", 
               q->op, 
               q->arg1 ? q->arg1 : "-", 
               q->arg2 ? q->arg2 : "-", 
               q->result ? q->result : "-");
    }
    printf("=======================\n\n");
}

// Libérer la table des quadruplets
void free_quad_table(QuadTable *qt) {
    for (int i = 0; i < qt->quad_count; i++) {
        Quad *q = &qt->quads[i];
        free(q->op);
        if (q->arg1) free(q->arg1);
        if (q->arg2) free(q->arg2);
        if (q->result) free(q->result);
    }
    free(qt->quads);
    qt->quads = NULL;
    qt->quad_count = 0;
    qt->quad_capacity = 0;
    qt->temp_count = 0;
}