public class TestVariablesNonDeclarees {
    // Cas 1: Variable membre valide
    int varMembre = 10;
    
    public static void main(String[] args) {
        // Cas 2: Variable locale valide
        int varLocale = 20;
        System.out.println(varLocale); // OK
        
        // Cas 3: Variable non déclarée (doit échouer)
        //System.out.println(varNonDeclaree); // Erreur attendue
        
        // Cas 4: Variable dans un bloc
        {
            int varBloc = 30;
            System.out.println(varBloc); // OK
        }
        
        // Cas 5: Utilisation hors scope (doit échouer)
        //System.out.println(varBloc); // Erreur attendue
        
        // Cas 6: Shadowing valide
        int x = 5;
        {
            int x = 10; // Shadowing autorisé
            System.out.println(x); // Doit afficher 10
        }
        System.out.println(x); // Doit afficher 5
        
        // Cas 7: Paramètre de méthode
        maMethode(15); // OK
    }
    
    public static void maMethode(int param) {
        System.out.println(param); // OK
        
        // Cas 8: Variable non déclarée dans méthode
        //System.out.println(varNonDeclareeDansMethode); // Erreur attendue
    }
}