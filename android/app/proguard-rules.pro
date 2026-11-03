# ML Kit discovers Firebase component registrars by their names in the Android
# manifest and instantiates them through getDeclaredConstructor().newInstance().
# R8 full mode otherwise removes these no-argument constructors: debug detection
# works, but the optimized release cannot initialize the bundled face detector.
# Keep only this reflective entrypoint; the SDK implementation remains optimized.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
