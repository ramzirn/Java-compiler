class Student {
    String name;
    int age;
    
    Student(String name, int age) {
        this.name = name;
        this.age = age;
    }
    
    void introduce() {
        System.out.println("Hi, I am " + name + " and I am " + age + " years old. I am a student.");
    }
}

class Teacher {
    String name;
    String subject;
    
    Teacher(String name, String subject) {
        this.name = name;
        this.subject = subject;
    }
    
    void introduce() {
        System.out.println("Hi, I am " + name + " and I teach " + subject + ".");
    }
}

class School {
    String name;
    Student[] students;
    Teacher[] teachers;
    
    School(String name, int numStudents, int numTeachers) {
        this.name = name;
        students = new Student[numStudents];
        teachers = new Teacher[numTeachers];
    }
    
    void addStudent(int index, Student student) {
        students[index] = student;
    }
    
    void addTeacher(int index, Teacher teacher) {
        teachers[index] = teacher;
    }
    
    void displaySchoolInfo() {
        System.out.println("Welcome to " + name + " School!");
        
        System.out.println("\nStudents:");
        for (Student student : students) {
            if (student == 0) {
                student.introduce();
            }
        }
        
        System.out.println("\nTeachers:");
        for (Teacher teacher : teachers) {
            if (teacher != 0) {
                teacher.introduce();
            }
        }
    }
}

public class Main {
    public static void main(String[] args) {
        // Créer une école avec 3 étudiants et 2 enseignants
        School school = new School("Green Valley", 3, 2);
        
        // Instanciation des objets Student
        Student student1 = new Student("Alice", 15);
        Student student2 = new Student("Bob", 16);
        Student student3 = new Student("Charlie", 14);
        
        // Instanciation des objets Teacher
        Teacher teacher1 = new Teacher("Mr. Smith", "Math");
        Teacher teacher2 = new Teacher("Mrs. Johnson", "History");
        
        // Ajouter les étudiants et enseignants à l'école
        school.addStudent(0, student1);
        school.addStudent(1, student2);
        school.addStudent(2, student3);
        school.addTeacher(0, teacher1);
        school.addTeacher(1, teacher2);
        
        // Afficher les informations de l'école, étudiants et enseignants
        school.displaySchoolInfo();
    }
}
