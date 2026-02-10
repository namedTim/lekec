# Flutter default rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Flutter embedding
-keep class io.flutter.embedding.** { *; }

# Drift / SQLite
-keep class org.sqlite.** { *; }
-keep class sqlite3.** { *; }

# Alarm plugin
-keep class com.gdelataillade.alarm.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# Google ML Kit (Text Recognition)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**

# Google Generative AI
-keep class com.google.ai.** { *; }

# WorkManager
-keep class androidx.work.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Camera
-keep class io.flutter.plugins.camera.** { *; }

# Gson (used by various plugins)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Keep annotations
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations

# AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }

# Prevent stripping of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
