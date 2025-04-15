
// Classe principale pour tester Person
class Main {
    public static void main(int a ) {
        // Création d'un objet avec un tableau de notes
        int[] notes = {85, 90, 78, 92};
        Person p = new Person(20, 'M', true, notes);

        // Appel des méthodes
        p.displayInfo();
        p.checkEligibility();
        System.out.println("Average Grade: " + p.getAverageGrade());

        // Structure de contrôle switch
        int choice = 1;
        switch (choice) {
            case 1:
                System.out.println("Choice is 1");
                break;
            case 2:
                System.out.println("Choice is 2");
                break;
            default:
                System.out.println("Invalid choice");
        }

        // Boucle while
        int i = 0;
        while (i < 3) {
            System.out.println("Iteration: " + i);
            i++;
        }

        // Gestion des exceptions avec le type d'exception précisé
        try {
            int result = 10 / 0; // Division par zéro
        } catch (ArithmeticException e) {
            System.out.println("An error occurred: " + e.getMessage());
        } finally {
            System.out.println("Execution completed.");
        }
    }}