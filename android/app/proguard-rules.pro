# Keep the flutter_local_notifications classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep Gson's types which are used internally by the plugin
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }
