# ----------------------------------------------------------------------------
# Flutter Core Rules (Required for all Flutter apps)
# ----------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class * extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }

# ----------------------------------------------------------------------------
# Vosk Speech Recognition (Vosk Native JNI Interaction)
# ----------------------------------------------------------------------------
-keep class org.vosk.** { *; }
-keep class com.alphacephei.vosk.** { *; }
-dontwarn org.vosk.**

# ----------------------------------------------------------------------------
# Audio Service & Just Audio (Background Audio Plugins)
# ----------------------------------------------------------------------------
-keep class com.ryan.just_audio_background.** { *; }
-keep class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryan.just_audio_background.**
-dontwarn com.ryanheise.audioservice.**

# ----------------------------------------------------------------------------
# Native Method Preservation (Critical for JNI plugins)
# Prevents R8 from renaming or removing methods called from C++/C code
# ----------------------------------------------------------------------------
-keepclassmembers class * {
    native <methods>;
}

# ----------------------------------------------------------------------------
# General Keep Rules for Data Models (If using JSON serialization)
# If you use 'json_serializable' or 'freezed', keep your data models.
# Replace 'com.example.jb_music.models' with your actual package name.
# ----------------------------------------------------------------------------
# -keep class com.example.jb_music.models.** { *; }

# ----------------------------------------------------------------------------
# Suppress warnings for libraries with missing optional dependencies
# ----------------------------------------------------------------------------
-dontwarn sun.misc.Unsafe
-dontwarn javax.annotation.**