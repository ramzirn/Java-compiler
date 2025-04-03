# Makefile pour le compilateur Java

# Variables
CC = gcc
CFLAGS = -Wall
FLEX = flex
BISON = bison
TARGET = javacompiler
TEST_FILE = test.java
LEX_SRC = lex.l
BISON_SRC = parser.y
EXEC = javacompiler

# Fichiers générés
LEX_GEN = lex.yy.c
BISON_GEN = parser.tab.c parser.tab.h

# Cible par défaut
all: $(TARGET)

# Règles de génération
$(LEX_GEN): $(LEX_SRC)
	$(FLEX) $<

$(BISON_GEN): $(BISON_SRC)
	$(BISON) -d $<

# Compilation
$(TARGET): $(LEX_GEN) $(BISON_GEN)
	$(CC) $(CFLAGS) -o $@ $(LEX_GEN) $(BISON_GEN) -lfl

# Test (ne rebuild que si nécessaire)
test: $(TARGET)
	./$(TARGET) $(TEST_FILE)

# Nettoyage
clean:
	rm -f $(LEX_GEN) $(BISON_GEN) $(TARGET) $(EXEC)

.PHONY: all test clean