# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class plugins.flutter.io.**  { *; }
-keep class * extends io.flutter.plugin.common.PluginRegistry$PluginRegistrantCallback
-keep class * extends io.flutter.plugin.common.PluginRegistry$ActivityResultListener
-keep class * extends io.flutter.app.FlutterApplication

# Play Core Warnings
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
