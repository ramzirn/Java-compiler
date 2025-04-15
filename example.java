class TestDoubleDeclaration {
    int a;              // OK
    int a;              // Erreur : redéclaration dans la même portée

    void methode1() {
        int b = 5;      // OK
        int b = 6;      // Erreur : redéclaration dans la même portée
    }

    void methode2() {
        int c = 10;     // OK
        {
            int c = 15; // OK : portée différente (bloc interne)
        }
        int c = 20;     // Erreur : redéclaration dans la même portée (methode2)
    }

    void methode3(int d, int d) { // Erreur : double déclaration des paramètres
        int e;           // OK
    }
}
