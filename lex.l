%option noyywrap
%option yylineno

%{
#include <stdio.h>
#include <stdlib.h>
#define YY_NO_UNPUT

// Déclarations pour les couleurs (si supporté)
#define RED "\x1b[31m"
#define GREEN "\x1b[32m"
#define BLUE "\x1b[34m"
#define YELLOW "\x1b[33m"
#define MAGENTA "\x1b[35m"
#define CYAN "\x1b[36m"
#define RESET "\x1b[0m"

int yylex(void);
%}

%%

"abstract"|"assert"|"boolean"|"break"|"byte"|"case"|"catch"|"char"|"class"|"const"|"continue"|"default"|"do"|"double"|"else"|"enum"|"extends"|"final"|"finally"|"float"|"for"|"goto"|"if"|"implements"|"import"|"instanceof"|"int"|"interface"|"long"|"native"|"new"|"package"|"private"|"protected"|"public"|"return"|"short"|"static"|"strictfp"|"super"|"switch"|"synchronized"|"this"|"throw"|"throws"|"transient"|"try"|"void"|"volatile"|"while"|"true"|"false" { 
    printf(GREEN "MOT_CLÉ" RESET " : %s (ligne %d)\n", yytext, yylineno); 
}

"String"|"boolean"|"byte"|"char"|"double"|"float"|"int"|"long"|"short"|"ArithmeticException"|"NullPointerException"|"IOException" { 
    printf(BLUE "TYPE" RESET " : %s (ligne %d)\n", yytext, yylineno); 
}

System\.out\.println|System\.out\.print { 
    printf(MAGENTA "APPEL_METHODE" RESET " : %s (ligne %d)\n", yytext, yylineno); 
}

[a-zA-Z_][a-zA-Z0-9_]* { 
    printf("IDENTIFICATEUR : %s (ligne %d)\n", yytext, yylineno); 
}

[0-9]+ { 
    printf(CYAN "NOMBRE_ENTIER" RESET " : %s (ligne %d)\n", yytext, yylineno); 
}

[0-9]+\.[0-9]+ { 
    printf(CYAN "NOMBRE_DECIMAL" RESET " : %s (ligne %d)\n", yytext, yylineno); 
}

"+"|"-"|"*"|"/"|"%"|"="|"=="|"!="|">"|"<"|">="|"<="|"&&"|"||"|"!"|"++"|"--"|"+="|"-="|"*="|"/=" { 
    printf(YELLOW "OPÉRATEUR" RESET " : %s (ligne %d)\n", yytext, yylineno); 
}

":"|";"|"{"|"}"|"("|")"|"["|"]"|","|"." { 
    printf(RED "SÉPARATEUR" RESET " : %s (ligne %d)\n", yytext, yylineno); 
}

\"([^\"\\]|\\.)*\" { 
    printf("CHAINE_DE_CARACTERES : %s (ligne %d)\n", yytext, yylineno); 
}

\'.\'|\'\\.\' { 
    printf("CARACTERE : %s (ligne %d)\n", yytext, yylineno); 
}

"//".*    { 
    printf("COMMENTAIRE_LIGNE : %s (ligne %d)\n", yytext, yylineno); 
}

"/*"([^*]|"*"+[^*/])*"*"+"/" { 
    printf("COMMENTAIRE_BLOC : trouvé (ligne %d)\n", yylineno); 
}

[ \t]+    { /* Ignorer les espaces et tabulations */ }

\n        { /* Ignorer les nouvelles lignes mais incrémenter yylineno */ }

. { 
    printf("TOKEN_NON_RECONNU : %s (ligne %d)\n", yytext, yylineno); 
}

%%

int main() {
    yylex();
    return 0;
}