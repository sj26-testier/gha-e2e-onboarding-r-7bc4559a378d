public final class LabJavaProbe {
    public static void main(String[] args) {
        if (args.length != 2) throw new AssertionError("Expected two arguments");
        int value = Integer.parseInt(args[0]);
        System.out.println("LAB_JAVA_OK:" + (value * 7 + 3) + ":"
            + args[1].toUpperCase(java.util.Locale.ROOT));
    }
}
