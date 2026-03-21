# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter deferred components use Play Core — suppress warnings when not used
-dontwarn com.google.android.play.core.**

# speech_to_text
-keep class com.csdcorp.speech_to_text.** { *; }

# share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# printing / pdf
-keep class com.example.printing.** { *; }

# Keep Kotlin metadata
-keepattributes *Annotation*
-keepattributes Signature
-dontwarn kotlinx.**
