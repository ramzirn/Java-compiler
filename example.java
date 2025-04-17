public class TestTypes {
    public static void main(String[] args) {
        int a = 10;
        double b = 3.14;
        String s = "Hello";

        // Tentative d'addition d'un entier et d'une chaîne (incompatible)
        //s = a + s; // Erreur : incompatible types: int cannot be converted to String

        // Tentative d'affectation d'une chaîne à un entier (incompatible)
        a = s; // Erreur : incompatible types: String cannot be converted to int

        // Tentative de division d'un entier et d'une chaîne (incompatible)
        int c = a / s; // Erreur : incompatible types: String cannot be converted to int

        // Tentative d'addition d'un double et d'une chaîne (incompatible)
        s = s + b; // Erreur potentielle si gestion stricte des types (en fonction de ton implémentation)
        
        // Affichage du résultat
        System.out.println(a);
    }
}
