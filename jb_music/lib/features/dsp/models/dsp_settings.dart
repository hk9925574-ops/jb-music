class DspSettings {
  final bool bassEnabled;
  final int bassStrength;

  final bool spatialEnabled;

  final bool reverbEnabled;
  final String reverbPreset;

  final bool loudnessEnabled;
  final int loudnessGain;

  const DspSettings({
    required this.bassEnabled,
    required this.bassStrength,
    required this.spatialEnabled,
    required this.reverbEnabled,
    required this.reverbPreset,
    required this.loudnessEnabled,
    required this.loudnessGain,
  });

  Map<String, dynamic> toJson() {
    return {
      'bassEnabled': bassEnabled,
      'bassStrength': bassStrength,
      'spatialEnabled': spatialEnabled,
      'reverbEnabled': reverbEnabled,
      'reverbPreset': reverbPreset,
      'loudnessEnabled': loudnessEnabled,
      'loudnessGain': loudnessGain,
    };
  }

  factory DspSettings.fromJson(
    Map<String, dynamic> json,
  ) {
    return DspSettings(
      bassEnabled: json['bassEnabled'] ?? false,
      bassStrength: json['bassStrength'] ?? 700,
      spatialEnabled: json['spatialEnabled'] ?? false,
      reverbEnabled: json['reverbEnabled'] ?? false,
      reverbPreset: json['reverbPreset'] ?? 'hall',
      loudnessEnabled: json['loudnessEnabled'] ?? false,
      loudnessGain: json['loudnessGain'] ?? 0,
    );
  }
}