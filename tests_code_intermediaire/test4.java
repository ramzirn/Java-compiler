/* Test pour vérifier la gestion des structures switch */
class TestSwitch {
    void main() {
        int x = 2;
        int y;
        switch (x) {
            case 1:
                y = 10;
                break;
            case 2:
                y = 20;
                break;
            default:
                y = 30;
        }
    }
}