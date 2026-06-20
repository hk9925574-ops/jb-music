// lib/core/audio/dsp_storage.dart
//
// Persists DSP toggle/strength settings across app restarts.
// Backed by shared_preferences.

import 'package:shared_preferences/shared_preferences.dart';

class DspStorage {
  static const _kBassEnabled    = 'dsp_bass_enabled';
  static const _kBassStrength   = 'dsp_bass_strength';
  static const _kSpatialEnabled = 'dsp_spatial_enabled';

  // ── Bass Boost ──────────────────────────────────────────────────────────
  static Future<bool> getBassEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBassEnabled) ?? false;
  }

  static Future<void> setBassEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBassEnabled, enabled);
  }

  // Strength stored as an int 0–1000 (matches NativeDSP.enableBassBoost's
  // `strength` param, which dsp_engine.dart already builds as
  // (_bassBoostStrength * 1000).toInt()).
  static Future<int> getBassStrength() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kBassStrength) ?? 700; // default ~0.7
  }

  static Future<void> setBassStrength(int strength) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBassStrength, strength.clamp(0, 1000));
  }

  // ── Spatial (8D) Audio ──────────────────────────────────────────────────
  static Future<bool> getSpatialEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSpatialEnabled) ?? false;
  }

  static Future<void> setSpatialEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSpatialEnabled, enabled);
  }
}