class Person {
    // Attributs de la classe
    int age;
    char gender; // 'M' pour masculin, 'F' pour féminin
    boolean isStudent;
    int[] grades; // Tableau pour stocker les notes

    // Constructeur
    Person(int age, char gender, boolean isStudent, int[] grades) {
        this.age = age;
        this.gender = gender;
        this.isStudent = isStudent;
        this.grades = grades;
    }

    // Méthode pour afficher les informations
    void displayInfo() {
        System.out.println("Age: " + age);
        System.out.println("Gender: " + gender);
        System.out.println("Student: " + isStudent);
        System.out.print("Grades: ");
        for (int grade : grades) {
            System.out.print(grade + " ");
        }
        System.out.println();
    }

    // Méthode pour tester une condition
    void checkEligibility() {
        if (age >= 18) {
            System.out.println("Eligible for voting.");
        } else {
            System.out.println("Not eligible for voting.");
        }
    }

    // Méthode qui retourne la moyenne des notes
    double getAverageGrade() {
        if (grades.length == 0) return 0; // Eviter la division par zéro
        int sum = 0;
        for (int grade : grades) {
            sum += grade;
        }
        return (double) sum / grades.length;
    }
}

// Classe principale pour tester Person
class Main {
    public static void main() {
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
    }
}



