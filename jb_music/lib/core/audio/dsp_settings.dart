class DSPSettings {
  final bool bassBoost;
  final int bassStrength;

  final bool reverb;
  final String reverbPreset;

  final bool spatialAudio;

  final bool equalizer;

  final bool loudness;
  final int loudnessGain;

  const DSPSettings({
    required this.bassBoost,
    required this.bassStrength,
    required this.reverb,
    required this.reverbPreset,
    required this.spatialAudio,
    required this.equalizer,
    required this.loudness,
    required this.loudnessGain,
  });

  factory DSPSettings.defaults() {
    return const DSPSettings(
      bassBoost: false,
      bassStrength: 700,
      reverb: false,
      reverbPreset: "hall",
      spatialAudio: false,
      equalizer: false,
      loudness: false,
      loudnessGain: 0,
    );
  }
}