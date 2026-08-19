# ---------------------------------------------------------------------
# ProGuard / R8 rules for the release build.
# Combined with minifyEnabled + shrinkResources (see android/app/build.gradle
# notes in README.md), this strips unused code, obfuscates it, and removes
# unused resources — the single biggest lever for a smaller APK.
# ---------------------------------------------------------------------

# Flutter's own engine/embedding classes must survive shrinking.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Provider / ChangeNotifier reflection-free, no special rules needed,
# but keep this project's model classes intact in case they're ever
# (de)serialized via reflection-based JSON later.
-keep class com.example.facility_app.** { *; }

# Standard Android rules
-dontwarn io.flutter.embedding.**
