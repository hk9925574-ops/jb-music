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
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryan.just_audio_background.**
-dontwarn com.ryanheise.audioservice.**

# ----------------------------------------------------------------------------
# Flutter Secure Storage
# ----------------------------------------------------------------------------
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ----------------------------------------------------------------------------
# On Audio Query
# ----------------------------------------------------------------------------
-keep class com.lucasjosino.on_audio_query.** { *; }

# ----------------------------------------------------------------------------
# Speech to Text
# ----------------------------------------------------------------------------
-keep class com.csdcorp.speech_to_text.** { *; }

# ----------------------------------------------------------------------------
# JB Music model classes
# ----------------------------------------------------------------------------
-keep class com.jbmusic.** { *; }

# ----------------------------------------------------------------------------
# Gson (if used indirectly)
# ----------------------------------------------------------------------------
-keepattributes Signature
-keepattributes *Annotation*

# ----------------------------------------------------------------------------
# Native Method Preservation (Critical for JNI plugins)
# Prevents R8 from renaming or removing methods called from C++/C code
# ----------------------------------------------------------------------------
-keepclassmembers class * {
    native <methods>;
}

# ----------------------------------------------------------------------------
# General Keep Rules for Data Models (If using JSON serialization)
# ----------------------------------------------------------------------------
# -keep class com.example.jb_music.models.** { *; }

# ----------------------------------------------------------------------------
# Suppress warnings for libraries with missing optional dependencies
# ----------------------------------------------------------------------------
-dontwarn sun.misc.Unsafe
-dontwarn javax.annotation.**