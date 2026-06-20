import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dsp_preset.dart';
import 'dsp_service.dart';

/// Persists the full DSP state (toggles, slider values, EQ bands, and
/// which preset is active) as a single JSON blob — one read/write
/// instead of several separate prefs keys.
class DspStorage {
  static const _key = 'dsp_active_state';

  static Future<void> saveState(DspPreset state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  static Future<DspPreset> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return DspPreset.flat;
    try {
      return DspPreset.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return DspPreset.flat;
    }
  }

  /// Loads the saved state and immediately pushes it down to the
  /// native DSP engine for the given session. Call this from
  /// main()/JBFeatureRegistry init, or from the AudioHandler right
  /// after a new playback session starts, so effects survive an
  /// app restart or a session id change.
  static Future<DspPreset> restore(DspService service, int sessionId) async {
    final state = await loadState();
    await state.applyTo(service, sessionId);
    return state;
  }
}