/* Test pour vérifier la gestion des boucles for */
class TestFor {
    void main() {
        int sum = 0;
        for (int i = 0; i < 10; i = i + 1) {
            sum = sum + i;
        }
    }
}