import 'dsp_service.dart';

/// Center frequencies (Hz) for the 5-band equalizer used in the UI.
/// These match Android's standard 5-band equalizer layout.
const List<int> kEqualizerBandFrequencies = [60, 230, 910, 3600, 14000];

/// A complete, serializable snapshot of every DSP effect value.
/// Used both as "the user's current settings" and as "a named preset".
class DspPreset {
  final String name;

  final bool bassEnabled;
  final int bassStrength; // 0–1000

  final bool reverbEnabled;

  final bool spatialEnabled;

  final bool loudnessEnabled;
  final int loudnessGain; // 0–10000

  final bool equalizerEnabled;
  final List<int> eqBands; // millibels, one per kEqualizerBandFrequencies

  const DspPreset({
    required this.name,
    required this.bassEnabled,
    required this.bassStrength,
    required this.reverbEnabled,
    required this.spatialEnabled,
    required this.loudnessEnabled,
    required this.loudnessGain,
    required this.equalizerEnabled,
    required this.eqBands,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "bassEnabled": bassEnabled,
        "bassStrength": bassStrength,
        "reverbEnabled": reverbEnabled,
        "spatialEnabled": spatialEnabled,
        "loudnessEnabled": loudnessEnabled,
        "loudnessGain": loudnessGain,
        "equalizerEnabled": equalizerEnabled,
        "eqBands": eqBands,
      };

  factory DspPreset.fromJson(Map<String, dynamic> json) {
    return DspPreset(
      name: json["name"] as String? ?? "Custom",
      bassEnabled: json["bassEnabled"] as bool? ?? false,
      bassStrength: json["bassStrength"] as int? ?? 700,
      reverbEnabled: json["reverbEnabled"] as bool? ?? false,
      spatialEnabled: json["spatialEnabled"] as bool? ?? false,
      loudnessEnabled: json["loudnessEnabled"] as bool? ?? false,
      loudnessGain: json["loudnessGain"] as int? ?? 3000,
      equalizerEnabled: json["equalizerEnabled"] as bool? ?? false,
      eqBands: (json["eqBands"] as List?)?.map((e) => e as int).toList() ??
          const [0, 0, 0, 0, 0],
    );
  }

  /// Pushes every value in this preset down to the native DSP engine.
  Future<void> applyTo(DspService service, int sessionId) async {
    await service.enableBass(bassEnabled, bassStrength, sessionId);
    await service.enableReverb(reverbEnabled, sessionId);
    await service.enableSpatial(spatialEnabled, sessionId);
    await service.enableLoudness(loudnessEnabled, loudnessGain, sessionId);
    await service.enableEqualizer(equalizerEnabled, sessionId);
    for (var i = 0; i < eqBands.length; i++) {
      await service.setBandLevel(i, eqBands[i], sessionId);
    }
  }

  static const DspPreset flat = DspPreset(
    name: "Flat",
    bassEnabled: false,
    bassStrength: 0,
    reverbEnabled: false,
    spatialEnabled: false,
    loudnessEnabled: false,
    loudnessGain: 0,
    equalizerEnabled: false,
    eqBands: [0, 0, 0, 0, 0],
  );

  // Tune these curves/values to taste — they're reasonable starting
  // points, not measured against real hardware.
  static const List<DspPreset> builtIn = [
    flat,
    DspPreset(
      name: "Rock",
      bassEnabled: true,
      bassStrength: 400,
      reverbEnabled: false,
      spatialEnabled: false,
      loudnessEnabled: false,
      loudnessGain: 0,
      equalizerEnabled: true,
      eqBands: [300, 200, -100, 200, 300],
    ),
    DspPreset(
      name: "Pop",
      bassEnabled: true,
      bassStrength: 200,
      reverbEnabled: false,
      spatialEnabled: false,
      loudnessEnabled: false,
      loudnessGain: 0,
      equalizerEnabled: true,
      eqBands: [-100, 100, 300, 100, -100],
    ),
    DspPreset(
      name: "Jazz",
      bassEnabled: false,
      bassStrength: 0,
      reverbEnabled: true,
      spatialEnabled: false,
      loudnessEnabled: false,
      loudnessGain: 0,
      equalizerEnabled: true,
      eqBands: [200, 100, 0, 100, 200],
    ),
    DspPreset(
      name: "Classical",
      bassEnabled: false,
      bassStrength: 0,
      reverbEnabled: true,
      spatialEnabled: true,
      loudnessEnabled: false,
      loudnessGain: 0,
      equalizerEnabled: true,
      eqBands: [200, 150, 0, 0, -100],
    ),
    DspPreset(
      name: "EDM",
      bassEnabled: true,
      bassStrength: 800,
      reverbEnabled: false,
      spatialEnabled: true,
      loudnessEnabled: false,
      loudnessGain: 0,
      equalizerEnabled: true,
      eqBands: [400, 300, 0, 200, 400],
    ),
    DspPreset(
      name: "Hip-Hop",
      bassEnabled: true,
      bassStrength: 900,
      reverbEnabled: false,
      spatialEnabled: false,
      loudnessEnabled: false,
      loudnessGain: 0,
      equalizerEnabled: true,
      eqBands: [500, 400, -200, 0, 200],
    ),
    DspPreset(
      name: "Vocal",
      bassEnabled: false,
      bassStrength: 0,
      reverbEnabled: false,
      spatialEnabled: false,
      loudnessEnabled: true,
      loudnessGain: 4000,
      equalizerEnabled: true,
      eqBands: [-200, 0, 300, 300, 0],
    ),
    DspPreset(
      name: "Movie",
      bassEnabled: false,
      bassStrength: 0,
      reverbEnabled: false,
      spatialEnabled: true,
      loudnessEnabled: true,
      loudnessGain: 3000,
      equalizerEnabled: true,
      eqBands: [100, 0, 0, 100, 200],
    ),
    DspPreset(
      name: "Gaming",
      bassEnabled: false,
      bassStrength: 0,
      reverbEnabled: false,
      spatialEnabled: true,
      loudnessEnabled: false,
      loudnessGain: 0,
      equalizerEnabled: true,
      eqBands: [0, 100, 200, 300, 300],
    ),
  ];
}