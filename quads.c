#include "quads.h"

void init_quad_table(QuadTable *table) {
    table->quad_count = 0;
    table->temp_count = 0;
    for (int i = 0; i < MAX_QUADS; i++) {
        table->quads[i] = NULL;
    }
}

void add_quad(QuadTable *table, const char *op, const char *arg1, const char *arg2, const char *result) {
    if (table->quad_count >= MAX_QUADS) {
        fprintf(stderr, "Erreur : Table des quadruplets pleine\n");
        return;
    }

    Quad *quad = malloc(sizeof(Quad));
    quad->op = op ? strdup(op) : NULL;
    quad->arg1 = arg1 ? strdup(arg1) : NULL;
    quad->arg2 = arg2 ? strdup(arg2) : NULL;
    quad->result = result ? strdup(result) : NULL;

    table->quads[table->quad_count++] = quad;
}

char *new_temp(QuadTable *table) {
    char *temp = malloc(16);
    snprintf(temp, 16, "t%d", table->temp_count++);
    return temp;
}

char *new_label(QuadTable *table) {
    static int label_counter = 0;
    char *label = malloc(16);
    snprintf(label, 16, "L%d", label_counter++);
    return label;
}

void print_quads(QuadTable *table) {
    printf("===== QUADRUPLETS =====\n");
    printf("Op         Arg1            Arg2            Result         \n");
    printf("--------------------------------------------\n");
    for (int i = 0; i < table->quad_count; i++) {
        Quad *q = table->quads[i];
        printf("%-10s %-15s %-15s %-15s\n", 
               q->op ? q->op : "-", 
               q->arg1 ? q->arg1 : "-", 
               q->arg2 ? q->arg2 : "-", 
               q->result ? q->result : "-");
    }
    printf("=======================\n");
}

void free_quad_table(QuadTable *table) {
    for (int i = 0; i < table->quad_count; i++) {
        Quad *q = table->quads[i];
        if (q->op) free(q->op);
        if (q->arg1) free(q->arg1);
        if (q->arg2) free(q->arg2);
        if (q->result) free(q->result);
        free(q);
    }
    table->quad_count = 0;
    table->temp_count = 0;
}