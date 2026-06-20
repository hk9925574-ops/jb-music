import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/dsp_settings.dart';

class DspStorage {
  static const _key = "dsp_settings";

  static Future<void> save(
    DspSettings settings,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _key,
      jsonEncode(
        settings.toJson(),
      ),
    );
  }

  static Future<DspSettings> load() async {
    final prefs =
        await SharedPreferences.getInstance();

    final data =
        prefs.getString(_key);

    if (data == null) {
      return const DspSettings(
        bassEnabled: false,
        bassStrength: 700,
        spatialEnabled: false,
        reverbEnabled: false,
        reverbPreset: 'hall',
        loudnessEnabled: false,
        loudnessGain: 0,
      );
    }

    return DspSettings.fromJson(
      jsonDecode(data),
    );
  }
}