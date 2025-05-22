# Java Subset Compiler

Un **compilateur pour un sous-ensemble du langage Java**, développé en **Flex** et **Bison**, écrit en **C**.  
Ce projet implémente toutes les étapes classiques de la compilation, de l'analyse lexicale jusqu'à la génération de code objet.

## 📌 Fonctionnalités

Ce compilateur prend en charge :

- ✅ Analyse lexicale avec Flex
- ✅ Analyse syntaxique avec Bison
- ✅ Table des symboles avec gestion des scopes
- ✅ Analyse sémantique (déclaration, types, etc.)
- ✅ Génération de code intermédiaire
- ✅ Génération de code objet (pseudo assembleur ou instructions proches de la machine cible)

## 🧱 Structure du projet

.
├── src/ # Fichiers source C, Flex et Bison
│ ├── lexer.l # Analyse lexicale (Flex)
│ ├── parser.y # Analyse syntaxique (Bison)
│ ├── semantics.c # Analyse sémantique
│ ├── codegen.c # Génération de code
│ └── ...
├── test/ # Fichiers de tests
├── Makefile # Script de compilation
└── README.md # Ce fichier

## ⚙️ Installation

### 📦 Prérequis

- GCC
- Flex
- Bison
- GNU Make

### 🐧 Setup sur Linux / Ubuntu

```bash
# Cloner le dépôt
git clone https://github.com/ton-utilisateur/mon-compiler-java.git
cd mon-compiler-java

# Compiler le projet
make build

# Lancer les tests
make test

# Nettoyer les fichiers générés
make clean
```

### 🪟 Setup sur Windows

Installer MSYS2 ou Cygwin (MSYS2 recommandé).

Ouvrir le terminal MSYS2 et installer les paquets nécessaires :

```bash
pacman -Syu
pacman -S make gcc flex bison
```

Cloner et compiler le projet comme sous Linux :

```bash
git clone https://github.com/ton-utilisateur/mon-compiler-java.git
cd mon-compiler-java
make build
```

⚠️ Sur Windows, assure-toi que les fichiers .l et .y utilisent les sauts de ligne Unix (LF), pas Windows (CRLF). Utilise un éditeur comme VSCode pour convertir si besoin.

🚀 Utilisation

Une fois compilé, tu peux exécuter le compilateur avec :

```bash
./compiler monProgramme.java
```

Il affichera les étapes de la compilation et générera un fichier output.obj (ou équivalent).

🧪 Tests

Les tests se trouvent dans le dossier test/. Tu peux lancer les tests via :

```bash
make test
```

🧹 Nettoyage

Pour supprimer tous les fichiers objets, binaires et intermédiaires :

```bash
make clean
```

📄 Licence

Ce projet est distribué sous licence MIT.  
N'hésite pas à proposer des améliorations ou à signaler des bugs via des issues ou des pull requests !
