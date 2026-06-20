import 'package:flutter/services.dart';

class NativeDSP {
  static const MethodChannel _channel =
      MethodChannel('jb_music/dsp');

  static Future<void> enableSpatialAudio(
    bool enabled,
    int sessionId,
  ) async {
    await _channel.invokeMethod(
      'enableSpatialAudio',
      {
        'enabled': enabled,
        'sessionId': sessionId,
      },
    );
  }

  static Future<void> enableBassBoost(
    bool enabled,
    int sessionId, {
    int strength = 700,
  }) async {
    await _channel.invokeMethod(
      'enableBassBoost',
      {
        'enabled': enabled,
        'sessionId': sessionId,
        'strength': strength,
      },
    );
  }
}