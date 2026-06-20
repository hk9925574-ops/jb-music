import 'package:flutter/material.dart';
import '../core/audio/dsp_service.dart';
import '../core/audio/dsp_preset.dart';
import '../core/audio/dsp_storage.dart';

class DspScreen extends StatefulWidget {
  const DspScreen({super.key});

  @override
  State<DspScreen> createState() => _DspScreenState();
}

class _DspScreenState extends State<DspScreen> {
  final dspService = DspService();

  // TODO: replace with the real active player sessionId
  final int sessionId = 0;

  bool _loading = true;

  bool spatialEnabled = false;
  bool bassEnabled = false;
  double bassStrength = 700;
  bool reverbEnabled = false;
  bool loudnessEnabled = false;
  double loudnessGain = 3000;
  bool equalizerEnabled = false;
  List<double> eqBands = [0, 0, 0, 0, 0];

  String? selectedPreset; // null = custom / no preset matches

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final state = await DspStorage.restore(dspService, sessionId);
    setState(() {
      spatialEnabled = state.spatialEnabled;
      bassEnabled = state.bassEnabled;
      bassStrength = state.bassStrength.toDouble();
      reverbEnabled = state.reverbEnabled;
      loudnessEnabled = state.loudnessEnabled;
      loudnessGain = state.loudnessGain.toDouble();
      equalizerEnabled = state.equalizerEnabled;
      eqBands = state.eqBands.map((e) => e.toDouble()).toList();
      selectedPreset = _matchingPresetName(state);
      _loading = false;
    });
  }

  DspPreset _currentAsPreset() {
    return DspPreset(
      name: selectedPreset ?? "Custom",
      bassEnabled: bassEnabled,
      bassStrength: bassStrength.toInt(),
      reverbEnabled: reverbEnabled,
      spatialEnabled: spatialEnabled,
      loudnessEnabled: loudnessEnabled,
      loudnessGain: loudnessGain.toInt(),
      equalizerEnabled: equalizerEnabled,
      eqBands: eqBands.map((e) => e.toInt()).toList(),
    );
  }

  String? _matchingPresetName(DspPreset state) {
    for (final preset in DspPreset.builtIn) {
      if (preset.bassEnabled == state.bassEnabled &&
          preset.bassStrength == state.bassStrength &&
          preset.reverbEnabled == state.reverbEnabled &&
          preset.spatialEnabled == state.spatialEnabled &&
          preset.loudnessEnabled == state.loudnessEnabled &&
          preset.loudnessGain == state.loudnessGain &&
          preset.equalizerEnabled == state.equalizerEnabled &&
          _bandsEqual(preset.eqBands, state.eqBands)) {
        return preset.name;
      }
    }
    return null;
  }

  bool _bandsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _persist() async {
    await DspStorage.saveState(_currentAsPreset());
  }

  Future<void> _applyPreset(DspPreset preset) async {
    setState(() {
      spatialEnabled = preset.spatialEnabled;
      bassEnabled = preset.bassEnabled;
      bassStrength = preset.bassStrength.toDouble();
      reverbEnabled = preset.reverbEnabled;
      loudnessEnabled = preset.loudnessEnabled;
      loudnessGain = preset.loudnessGain.toDouble();
      equalizerEnabled = preset.equalizerEnabled;
      eqBands = preset.eqBands.map((e) => e.toDouble()).toList();
      selectedPreset = preset.name;
    });
    await preset.applyTo(dspService, sessionId);
    await _persist();
  }

  String _bandLabel(int index) {
    final freq = kEqualizerBandFrequencies[index];
    if (freq >= 1000) {
      final khz = freq / 1000;
      return "${khz % 1 == 0 ? khz.toStringAsFixed(0) : khz.toStringAsFixed(1)} kHz";
    }
    return "$freq Hz";
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Audio Effects")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Audio Effects")),
      body: ListView(
        children: [
          Card(
            child: Column(
              children: [
                const ListTile(title: Text("Audio Effects")),
                SwitchListTile(
                  title: const Text("Spatial Audio"),
                  value: spatialEnabled,
                  onChanged: (value) async {
                    setState(() {
                      spatialEnabled = value;
                      selectedPreset = null;
                    });
                    await dspService.enableSpatial(value, sessionId);
                    await _persist();
                  },
                ),
                SwitchListTile(
                  title: const Text("Bass Boost"),
                  value: bassEnabled,
                  onChanged: (value) async {
                    setState(() {
                      bassEnabled = value;
                      selectedPreset = null;
                    });
                    await dspService.enableBass(
                      value,
                      bassStrength.toInt(),
                      sessionId,
                    );
                    await _persist();
                  },
                ),
                Slider(
                  value: bassStrength,
                  min: 0,
                  max: 1000,
                  onChanged: (value) => setState(() => bassStrength = value),
                  onChangeEnd: (value) async {
                    selectedPreset = null;
                    await dspService.enableBass(
                      bassEnabled,
                      value.toInt(),
                      sessionId,
                    );
                    await _persist();
                  },
                ),
                SwitchListTile(
                  title: const Text("Reverb"),
                  value: reverbEnabled,
                  onChanged: (value) async {
                    setState(() {
                      reverbEnabled = value;
                      selectedPreset = null;
                    });
                    await dspService.enableReverb(value, sessionId);
                    await _persist();
                  },
                ),
                SwitchListTile(
                  title: const Text("Loudness"),
                  value: loudnessEnabled,
                  onChanged: (value) async {
                    setState(() {
                      loudnessEnabled = value;
                      selectedPreset = null;
                    });
                    await dspService.enableLoudness(
                      value,
                      loudnessGain.toInt(),
                      sessionId,
                    );
                    await _persist();
                  },
                ),
                Slider(
                  value: loudnessGain,
                  min: 0,
                  max: 10000,
                  onChanged: (value) => setState(() => loudnessGain = value),
                  onChangeEnd: (value) async {
                    selectedPreset = null;
                    await dspService.enableLoudness(
                      loudnessEnabled,
                      value.toInt(),
                      sessionId,
                    );
                    await _persist();
                  },
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Equalizer"),
                  value: equalizerEnabled,
                  onChanged: (value) async {
                    setState(() {
                      equalizerEnabled = value;
                      selectedPreset = null;
                    });
                    await dspService.enableEqualizer(value, sessionId);
                    await _persist();
                  },
                ),
                for (var i = 0; i < eqBands.length; i++)
                  ListTile(
                    title: Text(_bandLabel(i)),
                    subtitle: Slider(
                      value: eqBands[i],
                      min: -1500,
                      max: 1500,
                      onChanged: equalizerEnabled
                          ? (value) => setState(() => eqBands[i] = value)
                          : null,
                      onChangeEnd: equalizerEnabled
                          ? (value) async {
                              selectedPreset = null;
                              await dspService.setBandLevel(
                                i,
                                value.toInt(),
                                sessionId,
                              );
                              await _persist();
                            }
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                const ListTile(title: Text("Presets")),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DspPreset.builtIn.map((preset) {
                      return ChoiceChip(
                        label: Text(preset.name),
                        selected: selectedPreset == preset.name,
                        onSelected: (_) => _applyPreset(preset),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}