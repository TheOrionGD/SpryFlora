# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# SpryFlora App Components
-keep class com.theoriongd.spryflora_app.** { *; }

# Home Widget
-keep class es.antonborri.home_widget.** { *; }

# Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Image Picker & Media
-keep class io.flutter.plugins.imagepicker.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Preserve standard attributes
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-dontwarn io.flutter.**
-dontwarn es.antonborri.home_widget.**
