class Test {
    int x; // OK
int x ;
    void myMethod(int a) {
        int x; // ❌ Erreur ! a est déjà déclaré comme paramètre -> même scope
        {
            int a; // ✅ OK ! Nouveau scope imbriqué
        }
    }
}
