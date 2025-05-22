# Makefile pour le projet de compilateur

# Compilateurs et outils
CC = gcc
LEX = flex
YACC = bison
PYTHON = python3
CFLAGS = -Wall -g -I$(SRC_DIR)  # Inclut src/ pour les headers
LFLAGS =
YFLAGS = -d

# Dossiers
SRC_DIR = src
BUILD_DIR = build
BIN_DIR = bin
TEST_DIR = test

# Fichiers sources
SOURCES = $(SRC_DIR)/quads.c $(SRC_DIR)/symbol_table.c $(SRC_DIR)/semantics.c
OBJECTS = $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SOURCES))
LEX_SRC = $(SRC_DIR)/lex.l
YACC_SRC = $(SRC_DIR)/parser.y
LEX_C = $(BUILD_DIR)/lex.yy.c
YACC_C = $(BUILD_DIR)/parser.tab.c
YACC_H = $(BUILD_DIR)/parser.tab.h
GUI_SRC = $(SRC_DIR)/gui.py

# Nom de l'exécutable
TARGET = $(BIN_DIR)/compilateur

# Règle principale
all: $(TARGET)

# Règle pour build et lancer l'interface graphique
gui: $(TARGET)
	$(PYTHON) $(GUI_SRC)

# Compilation de l'exécutable
$(TARGET): $(OBJECTS) $(LEX_C) $(YACC_C)
	@mkdir -p $(BIN_DIR)
	$(CC) $(CFLAGS) $(OBJECTS) $(LEX_C) $(YACC_C) -o $(TARGET) -lfl

# Compilation des fichiers objets
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(SRC_DIR)/%.h $(YACC_H)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Génération du code C à partir de lex.l
$(LEX_C): $(LEX_SRC) $(YACC_H) $(SRC_DIR)/symbol_table.h
	@mkdir -p $(BUILD_DIR)
	$(LEX) $(LFLAGS) -o $(LEX_C) $(LEX_SRC)

# Génération du code C et du header à partir de parser.y
$(YACC_C) $(YACC_H): $(YACC_SRC) $(SRC_DIR)/symbol_table.h
	@mkdir -p $(BUILD_DIR)
	$(YACC) $(YFLAGS) -o $(YACC_C) $(YACC_SRC)

# Nettoyage des fichiers générés
clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR) $(TEST_DIR)/output.asm $(TEST_DIR)/quads.txt

# Nettoyage complet (y compris fichiers temporaires)
distclean: clean
	rm -rf $(SRC_DIR)/temp $(SRC_DIR)/venv

# Règle pour tester le compilateur (à utiliser une fois test/ créé)
test: $(TARGET)
	@if [ -f $(TEST_DIR)/test.java ]; then \
		./$(TARGET) $(TEST_DIR)/test.java > $(TEST_DIR)/output.asm; \
	else \
		echo "Erreur : $(TEST_DIR)/test.java n'existe pas. Créez le dossier test/ et ajoutez test.java."; \
		exit 1; \
	fi

.PHONY: all clean distclean test gui