public class TestTypes {
    public static void main(String[] args) {
        double a = 2.05;           // ✅ OK : int ← int
        int b = 3;      // ✅ OK : double ← double
        double c = a;         // ✅ OK : double ← int (compatible)

        String s = "hello";   // ✅ OK : String ← String
        String t = s;         // ✅ OK : String ← String

        int d = b;            // ❌ Erreur : int ← double
        String u = 42;        // ❌ Erreur : String ← int
        double e = "pi";      // ❌ Erreur : double ← String
        int f = s;            // ❌ Erreur : int ← String
    }
}
