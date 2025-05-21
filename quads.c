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

    const char *valid_ops[] = {"+", "-", "*", "/", "%", ":=", "if_false", "goto", "label", "call", "param", "param_receive", "return", "array_access", "array_assign", "new", "new_array", "length", "cast", "==", "!=", "<", ">", "<=", ">=", "&&", "||", "!"};
    int is_valid = 0;
    for (int i = 0; i < sizeof(valid_ops) / sizeof(valid_ops[0]); i++) {
        if (strcmp(op, valid_ops[i]) == 0) {
            is_valid = 1;
            break;
        }
    }
    if (!is_valid) {
        fprintf(stderr, "Erreur : opérateur quadruplet invalide '%s'\n", op);
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



void propagate_expressions(QuadTable *table) {
    for (int i = 0; i < table->quad_count; i++) {
        Quad *q1 = table->quads[i];
        if (q1->op && strcmp(q1->op, "+") == 0 && q1->arg1 && q1->arg2 && q1->result) {
            for (int j = i + 1; j < table->quad_count; j++) {
                Quad *q2 = table->quads[j];
                if (q2->op && strcmp(q2->op, "+") == 0 && 
                    q2->arg1 && q2->arg2 && q2->result &&
                    strcmp(q1->arg1, q2->arg1) == 0 && strcmp(q1->arg2, q2->arg2) == 0) {
                    for (int k = j + 1; k < table->quad_count; k++) {
                        Quad *next = table->quads[k];
                        if (next->arg1 && strcmp(next->arg1, q2->result) == 0) {
                            free(next->arg1);
                            next->arg1 = strdup(q1->result);
                        }
                        if (next->arg2 && strcmp(next->arg2, q2->result) == 0) {
                            free(next->arg2);
                            next->arg2 = strdup(q1->result);
                        }
                    }
                    free(q2->op);
                    q2->op = strdup("NOP");
                }
            }
        }
    }
}

void remove_redundant_expressions(QuadTable *table) {
    int new_count = 0;
    for (int i = 0; i < table->quad_count; i++) {
        Quad *q = table->quads[i];
        if (q->op && strcmp(q->op, "NOP") != 0) {
            table->quads[new_count] = q;
            new_count++;
        } else {
            if (q->op) free(q->op);
            if (q->arg1) free(q->arg1);
            if (q->arg2) free(q->arg2);
            if (q->result) free(q->result);
            free(q);
        }
    }
    table->quad_count = new_count;
}


void simplify_algebraic(QuadTable *table) {
    for (int i = 0; i < table->quad_count; i++) {
        Quad *q = table->quads[i];
        if (q->op && q->arg1 && q->arg2 && q->result) {
            if ((strcmp(q->op, "+") == 0 || strcmp(q->op, "-") == 0) && strcmp(q->arg2, "0") == 0) {
                char *value = q->arg1;
                char *temp = q->result;
                // Transformer en assignation
                free(q->op);
                q->op = strdup(":=");
                free(q->arg2);
                q->arg2 = NULL;
                // Vérifier si la temporaire est utilisée dans une assignation directe
                if (i + 1 < table->quad_count) {
                    Quad *next = table->quads[i + 1];
                    if (next->op && strcmp(next->op, ":=") == 0 && next->arg1 && strcmp(next->arg1, temp) == 0 && next->result) {
                        // Propager la valeur directement dans l'assignation suivante
                        free(next->arg1);
                        next->arg1 = strdup(value);
                        // Propager la valeur dans les quadruplets suivants
                        for (int j = i + 2; j < table->quad_count; j++) {
                            Quad *future = table->quads[j];
                            if (future->arg1 && strcmp(future->arg1, temp) == 0) {
                                free(future->arg1);
                                future->arg1 = strdup(value);
                            }
                            if (future->arg2 && strcmp(future->arg2, temp) == 0) {
                                free(future->arg2);
                                future->arg2 = strdup(value);
                            }
                        }
                        // Marquer le quadruplet actuel comme NOP
                        free(q->op);
                        q->op = strdup("NOP");
                    }
                }
            }
        }
    }
}


#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include "quads.h"



bool is_used(QuadTable *table, int start, const char *var) {
    for (int i = start; i < table->quad_count; i++) {
        Quad *q = table->quads[i];
        if (q->arg1 && strcmp(q->arg1, var) == 0) return true;
        if (q->arg2 && strcmp(q->arg2, var) == 0) return true;
        if (q->result && strcmp(q->result, var) == 0) return false;
    }
    return false;
}

bool is_temporary(const char *var) {
    return var && var[0] == 't';
}

void propagate_copies(QuadTable *table) {
    for (int i = 0; i < table->quad_count; i++) {
        Quad *q = table->quads[i];
        if (q->op && strcmp(q->op, ":=") == 0 && q->arg1 && q->result) {
            char *temp = q->result;
            char *value = q->arg1;
            bool is_temp = is_temporary(temp);
            for (int j = i + 1; j < table->quad_count; j++) {
                Quad *next = table->quads[j];
                if (next->result && strcmp(next->result, temp) == 0) break;
                if (next->arg1 && strcmp(next->arg1, temp) == 0) {
                    free(next->arg1);
                    next->arg1 = strdup(value);
                }
                if (next->arg2 && strcmp(next->arg2, temp) == 0) {
                    free(next->arg2);
                    next->arg2 = strdup(value);
                }
            }
            // Marquer comme NOP si temp est une temporaire utilisée dans une assignation directe
            if (is_temp && is_used(table, i + 1, temp)) {
                int use_count = 0;
                bool is_direct_assign = false;
                for (int j = i + 1; j < table->quad_count; j++) {
                    Quad *next = table->quads[j];
                    if ((next->arg1 && strcmp(next->arg1, temp) == 0) || 
                        (next->arg2 && strcmp(next->arg2, temp) == 0)) {
                        use_count++;
                    }
                    if (next->op && strcmp(next->op, ":=") == 0 && next->arg1 && strcmp(next->arg1, temp) == 0) {
                        is_direct_assign = true;
                    }
                }
                if (use_count == 1 && is_direct_assign) {
                    free(q->op);
                    q->op = strdup("NOP");
                }
            }
        }
    }
}
void remove_dead_code(QuadTable *table) {
    int new_count = 0;
    for (int i = 0; i < table->quad_count; i++) {
        Quad *q = table->quads[i];
        if (q->op && (strcmp(q->op, "NOP") == 0 || 
                     (q->result && is_temporary(q->result) && !is_used(table, i + 1, q->result)))) {
            if (q->op) free(q->op);
            if (q->arg1) free(q->arg1);
            if (q->arg2) free(q->arg2);
            if (q->result) free(q->result);
            free(q);
        } else {
            table->quads[new_count] = q;
            new_count++;
        }
    }
    table->quad_count = new_count;
}

#include <stdio.h>
#include <string.h>
#include "quads.h"

// Fonction pour générer le code assembleur 8086
void generate_8086_code(QuadTable *table, const char *filename) {
    FILE *fp = fopen(filename, "w");
    if (!fp) {
        printf("Erreur : impossible d'ouvrir %s\n", filename);
        return;
    }

    // Segment de données
    fprintf(fp, "; Segment de données\n");
    fprintf(fp, "DATA SEGMENT\n");
    for (int i = 0; i < table->quad_count; i++) {
        Quad *q = table->quads[i];
        if (q->result && (strcmp(q->op, ":=") == 0 || strcmp(q->op, "-") == 0 || strcmp(q->op, "+") == 0 || strcmp(q->op, "cmp") == 0)) {
            fprintf(fp, "    %s DW 0\n", q->result);
        }
    }
    fprintf(fp, "DATA ENDS\n\n");

    // Segment de code
    fprintf(fp, "; Segment de code\n");
    fprintf(fp, "CODE SEGMENT\n");
    fprintf(fp, "    ASSUME CS:CODE, DS:DATA\n");
    fprintf(fp, "main:\n");
    fprintf(fp, "    MOV AX, DATA\n");
    fprintf(fp, "    MOV DS, AX\n\n");

    for (int i = 0; i < table->quad_count; i++) {
        Quad *q = table->quads[i];
        printf("Traite quadruplet : %s %s %s %s\n", q->op, q->arg1 ? q->arg1 : "-", q->arg2 ? q->arg2 : "-", q->result ? q->result : "-");
        if (strcmp(q->op, "label") == 0) {
            fprintf(fp, "%s:\n", q->arg1);
        } else if (strcmp(q->op, "param_receive") == 0) {
            continue;
        } else if (strcmp(q->op, ":=") == 0) {
            fprintf(fp, "    ; := %s - %s\n", q->arg1, q->result);
            fprintf(fp, "    MOV AX, %s\n", q->arg1);
            fprintf(fp, "    MOV %s, AX\n\n", q->result);
        } else if (strcmp(q->op, "+") == 0) {
            fprintf(fp, "    ; + %s %s %s\n", q->arg1, q->arg2, q->result);
            fprintf(fp, "    MOV AX, %s\n", q->arg1);
            fprintf(fp, "    ADD AX, %s\n", q->arg2);
            fprintf(fp, "    MOV %s, AX\n\n", q->result);
        } else if (strcmp(q->op, "-") == 0) {
            fprintf(fp, "    ; - %s %s %s\n", q->arg1, q->arg2, q->result);
            fprintf(fp, "    MOV AX, %s\n", q->arg1);
            fprintf(fp, "    SUB AX, %s\n", q->arg2);
            fprintf(fp, "    MOV %s, AX\n\n", q->result);
        } else if (strcmp(q->op, "cmp") == 0) {
            fprintf(fp, "    ; cmp %s %s %s\n", q->arg1, q->arg2, q->result);
            fprintf(fp, "    MOV AX, %s\n", q->arg1);
            fprintf(fp, "    CMP AX, %s\n", q->arg2);
            fprintf(fp, "    MOV %s, 0\n", q->result);
            fprintf(fp, "    JGE $+6\n");
            fprintf(fp, "    MOV %s, 1\n", q->result);
            fprintf(fp, "\n");
        } else if (strcmp(q->op, "jf") == 0) {
            fprintf(fp, "    ; jf %s %s\n", q->arg1, q->result);
            fprintf(fp, "    CMP %s, 0\n", q->arg1);
            fprintf(fp, "    JE %s\n\n", q->result);
        } else if (strcmp(q->op, "goto") == 0) {
            fprintf(fp, "    ; goto %s\n", q->result);
            fprintf(fp, "    JMP %s\n\n", q->result);
        } else if (strcmp(q->op, "return") == 0) {
            fprintf(fp, "    ; return\n");
            fprintf(fp, "    MOV AX, 4C00h\n");
            fprintf(fp, "    INT 21h\n");
        }
    }

    fprintf(fp, "CODE ENDS\n");
    fprintf(fp, "END main\n");

    fclose(fp);
    printf("Code assembleur généré dans %s\n", filename);
}