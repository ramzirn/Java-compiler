public class TestOptimizations5 {
    public static void main(String[] args) {
        int a = 10;
        int b = a + 0;
        int c = b + 5;
        int d = c - 0;
    }
}