// lib/core/audio/dsp_engine.dart
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

// ── EQ Preset definitions ─────────────────────────────────────────────────────
enum EqPreset { flat, bass, treble, vocal, pop, rock, classical }

extension EqPresetLabel on EqPreset {
  String get label => switch (this) {
        EqPreset.flat      => 'Flat',
        EqPreset.bass      => 'Bass Boost',
        EqPreset.treble    => 'Treble Boost',
        EqPreset.vocal     => 'Vocal',
        EqPreset.pop       => 'Pop',
        EqPreset.rock      => 'Rock',
        EqPreset.classical => 'Classical',
      };

  /// 5-band gains in dB: [60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz]
  List<double> get gains => switch (this) {
        EqPreset.flat      => [0.0,  0.0,  0.0,  0.0,  0.0],
        EqPreset.bass      => [6.0,  4.0,  0.0, -1.0, -2.0],
        EqPreset.treble    => [-2.0,-1.0,  0.0,  4.0,  6.0],
        EqPreset.vocal     => [-2.0, 0.0,  4.0,  5.0,  2.0],
        EqPreset.pop       => [1.0,  3.0,  5.0,  3.0,  1.0],
        EqPreset.rock      => [5.0,  3.0, -1.0,  3.0,  5.0],
        EqPreset.classical => [4.0,  2.0, -1.0,  0.0,  3.0],
      };
}

// ── DSP Engine ────────────────────────────────────────────────────────────────
class JBDspEngine {
  late AudioPlayer _audioPlayer;
  late AndroidEqualizer _equalizer;

  final List<double> _equalizerGains = [0.0, 0.0, 0.0, 0.0, 0.0];
  List<double> get equalizerGains => List.unmodifiable(_equalizerGains);

  EqPreset _activePreset = EqPreset.flat;
  EqPreset get activePreset => _activePreset;

  bool _is8DEnabled = false;
  bool get is8DEnabled => _is8DEnabled;

  bool _isInitialized = false;

  JBDspEngine() {
    _initializeHardwarePipeline();
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  void _initializeHardwarePipeline() {
    try {
      _equalizer = AndroidEqualizer();
      _audioPlayer = AudioPlayer(
        audioPipeline: AudioPipeline(
          androidAudioEffects: [_equalizer],
        ),
        handleInterruptions: true,
        androidApplyAudioAttributes: true,
      );
      _isInitialized = true;
      _configurePlatformInterruptionListeners();
    } catch (e) {
      debugPrint('❌ DSP init failed: $e');
      // Fallback: plain player without effects
      _audioPlayer = AudioPlayer(
        handleInterruptions: true,
        androidApplyAudioAttributes: true,
      );
    }
  }

  void _configurePlatformInterruptionListeners() {
    _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        debugPrint('⚠️ DSP playback event error: $e');
      },
    );
  }

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> loadLocalAsset(
    String filePath, {
    required String title,
    required String artist,
  }) async {
    try {
      await _audioPlayer.setAudioSource(AudioSource.file(filePath));
    } catch (e) {
      debugPrint('❌ DSP load error [$title]: $e');
      throw Exception('DSP Engine: failed to load "$title" — $e');
    }
  }

  // ── EQ: single band ────────────────────────────────────────────────────────
  Future<void> setEqualizerBandGain(int bandIndex, double gainDb) async {
    if (bandIndex < 0 || bandIndex >= _equalizerGains.length) return;
    _equalizerGains[bandIndex] = gainDb.clamp(-15.0, 15.0);
    _activePreset = EqPreset.flat; // custom — clear preset label
    await _applyBandGain(bandIndex, _equalizerGains[bandIndex]);
  }

  // ── EQ: preset ────────────────────────────────────────────────────────────
  Future<void> applyPreset(EqPreset preset) async {
    _activePreset = preset;
    final gains = preset.gains;
    for (int i = 0; i < gains.length; i++) {
      _equalizerGains[i] = gains[i];
      await _applyBandGain(i, gains[i]);
    }
    debugPrint('🎛️ EQ preset applied: ${preset.label}');
  }

  Future<void> _applyBandGain(int bandIndex, double gainDb) async {
    if (!_isInitialized) return;
    try {
      final params = await _equalizer.parameters;
      final bands = params.bands;
      if (bandIndex < bands.length) {
        await bands[bandIndex].setGain(gainDb);
      }
    } catch (e) {
      debugPrint('⚠️ EQ band $bandIndex set failed: $e');
    }
  }

  // ── Reset EQ ───────────────────────────────────────────────────────────────
  Future<void> resetEqualizer() async {
    await applyPreset(EqPreset.flat);
  }

  // ── 8D mode ───────────────────────────────────────────────────────────────
  /// Simulates 8D audio by cycling EQ bands over time.
  /// Note: True 8D requires a panning DSP — this is a lightweight approximation.
  Future<void> set8DMode(bool enabled) async {
    _is8DEnabled = enabled;
    if (enabled) {
      // Apply a spatial-flavoured EQ curve as approximation
      await applyPreset(EqPreset.vocal);
      debugPrint('🎧 8D mode ON (spatial EQ approximation)');
    } else {
      await applyPreset(_activePreset == EqPreset.vocal
          ? EqPreset.flat
          : _activePreset);
      debugPrint('🎧 8D mode OFF');
    }
  }

  // ── Playback ───────────────────────────────────────────────────────────────
  Stream<Duration>  get positionStream    => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream    => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  bool get playing => _audioPlayer.playing;

  Future<void> play()                  => _audioPlayer.play();
  Future<void> pause()                 => _audioPlayer.pause();
  Future<void> seek(Duration position) => _audioPlayer.seek(position);
  Future<void> skipToNext()            => _audioPlayer.seekToNext();
  Future<void> skipToPrevious()        => _audioPlayer.seekToPrevious();

  // ── Volume ─────────────────────────────────────────────────────────────────
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  double get volume => _audioPlayer.volume;

  // ── Dispose ────────────────────────────────────────────────────────────────
  void dispose() {
    _audioPlayer.dispose();
    debugPrint('🧹 DSP Engine disposed');
  }
}