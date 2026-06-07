class EqualizerPreset {
  final String name;
  final List<double> gains; // Must map exactly 5 parameters structurally [60Hz, 230Hz, 910Hz, 4kHz, 14kHz]

  const EqualizerPreset({required this.name, required this.gains});
}

/// Static Repository Definition of Acoustic Presets
class EqualizerPresetBank {
  static const EqualizerPreset flat = EqualizerPreset(
    name: 'Flat Resonance',
    gains: [0.0, 0.0, 0.0, 0.0, 0.0],
  );

  static const EqualizerPreset bassBooster = EqualizerPreset(
    name: 'Bass Booster',
    gains: [8.5, 4.0, 0.0, -1.0, -2.5],
  );

  static const EqualizerPreset vocalClear = EqualizerPreset(
    name: 'Vocal Clear',
    gains: [-3.0, -1.5, 2.0, 6.0, 4.5],
  );

  static const EqualizerPreset electronic = EqualizerPreset(
    name: 'Electronic Pulse',
    gains: [6.0, 2.5, -1.0, 3.5, 5.0],
  );

  static const List<EqualizerPreset> profiles = [
    flat,
    bassBooster,
    vocalClear,
    electronic,
  ];
}