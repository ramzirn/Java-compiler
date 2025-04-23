#ifndef QUADS_H
#define QUADS_H

typedef enum {
    Q_ASSIGN,       // =
    Q_PLUS,         // +
    Q_MINUS,        // -
    Q_MULT,         // *
    Q_DIV,          // /
    Q_GOTO,         // goto
    Q_IF_LT,        // if <
    Q_IF_GT,        // if >
    Q_IF_EQ,        // if ==
    Q_IF_NEQ,       // if !=
    Q_LABEL,        // label
    Q_PARAM,        // param
    Q_CALL,         // call
    Q_RETURN,       // return
    Q_INDEX,        // array index
    Q_PRINT         // print
} QuadOp;

typedef struct Quadruplet {
    QuadOp op;
    char *arg1;
    char *arg2;
    char *result;
    struct Quadruplet *next;
} Quadruplet;

typedef struct {
    Quadruplet *head;
    Quadruplet *tail;
    int temp_count;
    int label_count;
} IntermediateCode;

// Fonctions pour gérer le code intermédiaire
IntermediateCode* create_intermediate_code();
void emit(IntermediateCode *ic, QuadOp op, char *arg1, char *arg2, char *result);
void print_quads(IntermediateCode *ic, FILE *output);
void free_intermediate_code(IntermediateCode *ic);

#endif