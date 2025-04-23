#include "quads.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

IntermediateCode* create_intermediate_code() {
    IntermediateCode *ic = malloc(sizeof(IntermediateCode));
    ic->head = NULL;
    ic->tail = NULL;
    ic->temp_count = 0;
    ic->label_count = 0;
    return ic;
}

void emit(IntermediateCode *ic, QuadOp op, char *arg1, char *arg2, char *result) {
    Quadruplet *quad = malloc(sizeof(Quadruplet));
    quad->op = op;
    quad->arg1 = arg1 ? strdup(arg1) : NULL;
    quad->arg2 = arg2 ? strdup(arg2) : NULL;
    quad->result = result ? strdup(result) : NULL;
    quad->next = NULL;

    if (ic->tail == NULL) {
        ic->head = ic->tail = quad;
    } else {
        ic->tail->next = quad;
        ic->tail = quad;
    }
}



void print_quads(IntermediateCode *ic, FILE *output) {
    Quadruplet *current = ic->head;
    while (current != NULL) {
        fprintf(output, "(");
        switch(current->op) {
            case Q_ASSIGN: fprintf(output, "="); break;
            case Q_PLUS: fprintf(output, "+"); break;
            case Q_MINUS: fprintf(output, "-"); break;
            case Q_MULT: fprintf(output, "*"); break;
            case Q_DIV: fprintf(output, "/"); break;
            case Q_GOTO: fprintf(output, "goto"); break;
            case Q_IF_LT: fprintf(output, "if<"); break;
            case Q_IF_GT: fprintf(output, "if>"); break;
            case Q_IF_EQ: fprintf(output, "if=="); break;
            case Q_IF_NEQ: fprintf(output, "if!="); break;
            case Q_LABEL: fprintf(output, "label"); break;
            case Q_PARAM: fprintf(output, "param"); break;
            case Q_CALL: fprintf(output, "call"); break;
            case Q_RETURN: fprintf(output, "return"); break;
            case Q_INDEX: fprintf(output, "index"); break;
            case Q_PRINT: fprintf(output, "print"); break;
        }
        
        fprintf(output, ", %s, %s, %s)\n",
                current->arg1 ? current->arg1 : "_",
                current->arg2 ? current->arg2 : "_",
                current->result ? current->result : "_");
        
        current = current->next;
    }
}

void free_intermediate_code(IntermediateCode *ic) {
    Quadruplet *current = ic->head;
    while (current != NULL) {
        Quadruplet *next = current->next;
        if (current->arg1) free(current->arg1);
        if (current->arg2) free(current->arg2);
        if (current->result) free(current->result);
        free(current);
        current = next;
    }
    free(ic);
}