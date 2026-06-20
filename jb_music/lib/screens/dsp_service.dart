import 'package:flutter/services.dart';

/// Wrapper around the native (Android) DSP MethodChannel.
///
/// NOTE: "enableEqualizer", "setBandLevel" and "getBandLevelRange" need
/// matching `when` branches added on the native (Kotlin) side of this
/// channel. Until they exist, calls to them are caught and ignored so
/// the rest of the UI still works while you wire up the native side.
class DspService {
  static const channel = MethodChannel("jb_music/dsp");

  Future<void> enableSpatial(bool enabled, int sessionId) async {
    await channel.invokeMethod("enableSpatialAudio", {
      "enabled": enabled,
      "sessionId": sessionId,
    });
  }

  Future<void> enableBass(bool enabled, int strength, int sessionId) async {
    await channel.invokeMethod("enableBassBoost", {
      "enabled": enabled,
      "strength": strength,
      "sessionId": sessionId,
    });
  }

  Future<void> enableReverb(bool enabled, int sessionId) async {
    await channel.invokeMethod("enableReverb", {
      "enabled": enabled,
      "sessionId": sessionId,
    });
  }

  // FIX: previously this never sent the loudness gain anywhere — the
  // slider on the screen wasn't actually wired to anything. Added the
  // `gain` param so it matches the bass boost pattern.
  Future<void> enableLoudness(bool enabled, int gain, int sessionId) async {
    await channel.invokeMethod("enableLoudnessEnhancer", {
      "enabled": enabled,
      "gain": gain,
      "sessionId": sessionId,
    });
  }

  // ---------------------------------------------------------------------
  // Equalizer
  // ---------------------------------------------------------------------

  Future<void> enableEqualizer(bool enabled, int sessionId) async {
    try {
      await channel.invokeMethod("enableEqualizer", {
        "enabled": enabled,
        "sessionId": sessionId,
      });
    } on MissingPluginException {
      // Native side not implemented yet — ignore.
    }
  }

  Future<void> setBandLevel(
    int band,
    int levelMillibels,
    int sessionId,
  ) async {
    try {
      await channel.invokeMethod("setBandLevel", {
        "band": band,
        "level": levelMillibels,
        "sessionId": sessionId,
      });
    } on MissingPluginException {
      // Native side not implemented yet — ignore.
    }
  }

  /// Returns [min, max] band level range in millibels. Falls back to
  /// Android's typical 5-band equalizer range if the native side
  /// hasn't implemented "getBandLevelRange" yet.
  Future<List<int>> getBandLevelRange(int sessionId) async {
    try {
      final result = await channel.invokeMethod(
        "getBandLevelRange",
        {"sessionId": sessionId},
      );
      final map = Map<String, dynamic>.from(result as Map);
      return [map["min"] as int, map["max"] as int];
    } catch (_) {
      return [-1500, 1500];
    }
  }
}