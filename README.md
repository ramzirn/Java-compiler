# Compilateur Java 2025

Ce projet est un compilateur pour le langage Java, développé dans le cadre du cours de compilation 2025. Il analyse des programmes Java en entrée, effectue une analyse lexicale, syntaxique et sémantique, génère des quads (code intermédiaire), et produit un fichier assembleur. Le projet inclut également une interface graphique développée avec Tkinter pour faciliter l'interaction avec le compilateur.

## Structure du projet

- `src/` : Contient tous les fichiers sources.
  - `lex.l` : Analyseur lexical (Lex/Flex).
  - `parser.y` : Analyseur syntaxique (Yacc/Bison).
  - `quads.c`, `quads.h` : Gestion des quads (code intermédiaire).
  - `symbol_table.c`, `symbol_table.h` : Gestion de la table des symboles.
  - `semantics.c`, `semantics.h` : Analyse sémantique.
  - `gui.py` : Interface graphique en Tkinter.
- `build/` : Fichiers objets générés (ignoré dans Git).
- `bin/` : Exécutable généré (`compilateur`) (ignoré dans Git).
- `test/` : Dossier pour les fichiers de test (non inclus actuellement).
- `Projet_compil_2025-1.pdf` : Documentation du projet.

## Prérequis

Pour compiler et exécuter ce projet, vous aurez besoin des outils suivants :

- **GCC** : Compilateur C.
- **Flex** : Pour générer l'analyseur lexical.
- **Bison** : Pour générer l'analyseur syntaxique.
- **Python 3** : Avec la bibliothèque Tkinter pour l'interface graphique.
  - Installez Tkinter si nécessaire : `pip install tk`
- **Make** : Pour automatiser la compilation.

Sur Ubuntu/WSL, vous pouvez installer ces dépendances avec :

```bash
sudo apt update
sudo apt install build-essential flex bison python3 python3-pip
pip install tk
```

## Installation

1. Clonez le dépôt GitHub :
   ```bash
   git clone https://github.com/ramzirn/Java-compiler
   ```
2. Accédez au dossier du projet :
   ```bash
   cd Java-compiler
   ```

## Utilisation

### Compiler et lancer l'interface graphique

La commande suivante compile le compilateur et lance l'interface graphique Tkinter :

```bash
make gui
```

L'interface graphique vous permettra d'interagir avec le compilateur, par exemple en sélectionnant un fichier Java à compiler.

### Tester le compilateur (optionnel)

1. Créez un dossier `test/` et ajoutez un fichier Java de test (ex. `test.java`) :
   ```bash
   mkdir test
   touch test/test.java
   ```
2. Ajoutez un programme Java simple dans `test.java`, par exemple :
   ```java
   class Test {
       public static void main(String[] args) {
           System.out.println("Hello, World!");
       }
   }
   ```
3. Exécutez le compilateur sur ce fichier :
   ```bash
   make test
   ```
   Cela générera un fichier `test/output.asm` contenant le code assembleur.

## Nettoyage

Pour supprimer les fichiers générés (objets, exécutables, fichiers de test) :

```bash
make clean
```

Pour un nettoyage complet (y compris les dossiers temporaires comme `venv/`) :

```bash
make distclean
```

## Contribuer

1. Forkez le dépôt et clonez-le localement.
2. Créez une branche pour vos modifications :
   ```bash
   git checkout -b ma-nouvelle-fonctionnalite
   ```
3. Faites vos modifications et testez-les.
4. Poussez vos changements et créez une Pull Request.

## Problèmes connus

- Le dossier `test/` n'est pas inclus par défaut. Vous devez le créer manuellement pour utiliser la règle `make test`.
- Assurez-vous que l'heure de votre système est synchronisée pour éviter des avertissements avec `make` (sous WSL, synchronisez l'heure avec `sudo ntpdate pool.ntp.org`).

## Auteurs

- Ramzi Bouter

## Licence

Ce projet est sous licence MIT (à confirmer selon vos préférences).
