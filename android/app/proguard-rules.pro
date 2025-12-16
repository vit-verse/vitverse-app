# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# ❌ ML Kit rules removed - no longer using ML Kit
# ML Kit dependencies have been removed from the project
# Stage 1 custom captcha model is sufficient (>70% confidence)
# QR scanning uses mobile_scanner only

# Keep Flutter wrapper classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep WebView classes
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keep class android.webkit.** { *; }
-keep class androidx.webkit.** { *; }

# Keep Gson classes
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# CRITICAL: Keep GSON TypeToken to prevent reflection errors
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers class * extends com.google.gson.reflect.TypeToken {
    *;
}

# Keep generic signatures for GSON (fixes TypeToken error)
-keepattributes Signature
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep all notification payload classes
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep WorkManager for background sync
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Keep SharedPreferences for Flutter
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep Crashlytics custom keys
-keepclassmembers class com.google.firebase.crashlytics.** { *; }

# Keep R8 from removing used code
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Keep all model classes (if you have any)
-keep class com.divanshupatel.vitconnect.** { *; }

# Keep Google Play Core library classes for Flutter deferred components
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }

# Suppress warnings for Google Play Core classes
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# ❌ ML Kit warnings removed - no longer needed

# Performance optimizations - Balanced approach for production safety
# Avoid arithmetic/cast simplification that can break reflection
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 2
-allowaccessmodification
-dontpreverify
-repackageclasses ''

# ❌ ML Kit rules removed - no longer needed
# -keep class com.google.mlkit.** { *; }
# -keep interface com.google.mlkit.** { *; }
# -keepclassmembers class com.google.mlkit.** { *; }
# -dontwarn com.google.mlkit.**

# Keep native methods for older devices
-keepclasseswithmembernames class * {
    native <methods>;
}

# Removed aggressive optimization flags to prevent stripping inner classes used via reflection
# Previous flags: -overloadaggressively, -mergeinterfacesaggressively
# These can break Firebase, WorkManager, and other reflection-heavy libraries

# Remove debug information for smaller APK
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Remove logging in release builds
-assumenosideeffects class java.io.PrintStream {
    public void println(%);
    public void println(**);
}

# Remove assertions in release
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    static void checkParameterIsNotNull(java.lang.Object, java.lang.String);
}

# Keep line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Firebase optimizations
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Crashlytics NDK
-keepattributes *Annotation*
-keep class com.crashlytics.** { *; }
-dontwarn com.crashlytics.**
