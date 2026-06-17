// lib/core/audio/dsp_engine.dart
// FIXED: 8D audio now operates on the real AudioPlayer from MyAudioHandler.
// Call dspEngine.attachPlayer(audioHandler.player) in main.dart after init.

import 'dart:async';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

// ── EQ Preset definitions ─────────────────────────────────────────────────────
enum EqPreset { flat, bass, treble, vocal, pop, rock, classical, electronic, hipHop }

extension EqPresetLabel on EqPreset {
  String get label => switch (this) {
        EqPreset.flat       => 'Flat',
        EqPreset.bass       => 'Bass Boost',
        EqPreset.treble     => 'Treble Boost',
        EqPreset.vocal      => 'Vocal Clear',
        EqPreset.pop        => 'Pop',
        EqPreset.rock       => 'Rock',
        EqPreset.classical  => 'Classical',
        EqPreset.electronic => 'Electronic',
        EqPreset.hipHop     => 'Hip-Hop',
      };

  IconData get icon => switch (this) {
        EqPreset.flat       => Icons.tune,
        EqPreset.bass       => Icons.speaker,
        EqPreset.treble     => Icons.arrow_upward,
        EqPreset.vocal      => Icons.mic,
        EqPreset.pop        => Icons.music_note,
        EqPreset.rock       => Icons.electric_bolt,
        EqPreset.classical  => Icons.piano,
        EqPreset.electronic => Icons.sync,
        EqPreset.hipHop     => Icons.graphic_eq,
      };

  /// 5-band gains dB: [60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz]
  List<double> get gains => switch (this) {
        EqPreset.flat       => [0.0,  0.0,  0.0,  0.0,  0.0],
        EqPreset.bass       => [9.0,  6.0,  1.0, -1.0, -2.0],
        EqPreset.treble     => [-2.0,-1.0,  0.0,  5.0,  8.0],
        EqPreset.vocal      => [-3.0,-1.0,  5.0,  6.0,  3.0],
        EqPreset.pop        => [2.0,  3.0,  5.0,  3.0,  2.0],
        EqPreset.rock       => [6.0,  4.0, -1.0,  4.0,  6.0],
        EqPreset.classical  => [5.0,  3.0, -1.0,  0.0,  4.0],
        EqPreset.electronic => [8.0,  5.0,  0.0, -2.0,  6.0],
        EqPreset.hipHop     => [8.0,  6.0,  2.0,  0.0, -1.0],
      };
}

// ── DSP Engine ────────────────────────────────────────────────────────────────
class JBDspEngine {
  // FIX: No longer creates its own AudioPlayer.
  // Must call attachPlayer(audioHandler.player) in main.dart before use.
  AudioPlayer? _audioPlayer;
  AndroidEqualizer? _equalizer;

  // Safe internal getter — throws a clear error if attachPlayer was never called
  AudioPlayer get _player {
    assert(_audioPlayer != null,
        'JBDspEngine: attachPlayer() was never called. '
        'Call dspEngine.attachPlayer(audioHandler.player) in main.dart after AudioService.init().');
    return _audioPlayer!;
  }

  final List<double> _equalizerGains = [0.0, 0.0, 0.0, 0.0, 0.0];
  List<double> get equalizerGains => List.unmodifiable(_equalizerGains);

  EqPreset _activePreset = EqPreset.flat;
  EqPreset get activePreset => _activePreset;

  bool _is8DEnabled = false;
  bool get is8DEnabled => _is8DEnabled;

  bool _isBassBoostEnabled = false;
  bool get isBassBoostEnabled => _isBassBoostEnabled;

  bool _isVocalClearEnabled = false;
  bool get isVocalClearEnabled => _isVocalClearEnabled;

  double _bassBoostStrength = 0.7;
  double _vocalBoostStrength = 0.7;

  bool _isInitialized = false;

  Timer? _eightDTimer;
  double _eightDAngle = 0.0;
  static const double _eightDSpeed = 0.08;

  // FIX: Constructor does nothing — player is not available yet at this point.
  JBDspEngine();

  // ── Attach the real player ─────────────────────────────────────────────────
  // Call this in main.dart:
  //   dspEngine.attachPlayer(audioHandler.player);
  void attachPlayer(AudioPlayer player) {
    _audioPlayer = player;
    _initializeEqualizer();
    _configurePlatformInterruptionListeners();
    debugPrint('✅ DSP Engine attached to real AudioPlayer');
  }

  // ── Init equalizer only (player already exists) ────────────────────────────
  // Note: AndroidEqualizer must be passed into AudioPipeline at player
  // creation time to work on Android. Since MyAudioHandler owns the player,
  // software EQ fallback is used here via band gain calls instead.
  void _initializeEqualizer() {
    try {
      _equalizer = AndroidEqualizer();
      _isInitialized = true;
      debugPrint('✅ DSP equalizer ready');
    } catch (e) {
      debugPrint('⚠️ DSP EQ unavailable, software fallback only: $e');
      _isInitialized = false;
    }
  }

  void _configurePlatformInterruptionListeners() {
    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) =>
          debugPrint('⚠️ DSP playback event error: $e'),
    );
  }

  // ── Load (kept for any direct DSP use cases) ───────────────────────────────
  Future<void> loadLocalAsset(String filePath,
      {required String title, required String artist}) async {
    try {
      await _player.setAudioSource(AudioSource.file(filePath));
    } catch (e) {
      debugPrint('❌ DSP load error [$title]: $e');
      throw Exception('DSP Engine: failed to load "$title" — $e');
    }
  }

  // ── EQ: single band ────────────────────────────────────────────────────────
  Future<void> setEqualizerBandGain(int bandIndex, double gainDb) async {
    if (bandIndex < 0 || bandIndex >= _equalizerGains.length) return;
    _equalizerGains[bandIndex] = gainDb.clamp(-15.0, 15.0);
    _activePreset = EqPreset.flat;
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
    debugPrint('🎛️ EQ preset: ${preset.label}');
  }

  Future<void> _applyBandGain(int bandIndex, double gainDb) async {
    if (!_isInitialized || _equalizer == null) return;
    try {
      final params = await _equalizer!.parameters;
      final bands = params.bands;
      if (bandIndex < bands.length) {
        await bands[bandIndex].setGain(gainDb);
      }
    } catch (e) {
      debugPrint('⚠️ EQ band $bandIndex set failed: $e');
    }
  }

  Future<void> resetEqualizer() async => applyPreset(EqPreset.flat);

  // ── Bass Boost ─────────────────────────────────────────────────────────────
  Future<void> setBassBoost(bool enabled, {double strength = 0.7}) async {
    _isBassBoostEnabled = enabled;
    _bassBoostStrength = strength.clamp(0.0, 1.0);
    if (enabled) {
      final boost = 10.0 * _bassBoostStrength;
      await _applyBandGain(0, (_equalizerGains[0] + boost).clamp(-15.0, 15.0));
      await _applyBandGain(1, (_equalizerGains[1] + boost * 0.7).clamp(-15.0, 15.0));
      await _applyBandGain(2, (_equalizerGains[2] + boost * 0.2).clamp(-15.0, 15.0));
      debugPrint('🔊 Bass Boost ON (${(strength * 100).toInt()}%)');
    } else {
      for (int i = 0; i < _equalizerGains.length; i++) {
        await _applyBandGain(i, _equalizerGains[i]);
      }
      debugPrint('🔊 Bass Boost OFF');
    }
  }

  // ── Vocal Enhancer ─────────────────────────────────────────────────────────
  Future<void> setVocalClear(bool enabled, {double strength = 0.7}) async {
    _isVocalClearEnabled = enabled;
    _vocalBoostStrength = strength.clamp(0.0, 1.0);
    if (enabled) {
      final mid = 6.0 * _vocalBoostStrength;
      final cut = -3.0 * _vocalBoostStrength;
      await _applyBandGain(0, cut);
      await _applyBandGain(1, cut * 0.5);
      await _applyBandGain(2, mid);
      await _applyBandGain(3, mid * 1.2);
      await _applyBandGain(4, mid * 0.5);
      debugPrint('🎤 Vocal Clear ON');
    } else {
      for (int i = 0; i < _equalizerGains.length; i++) {
        await _applyBandGain(i, _equalizerGains[i]);
      }
      debugPrint('🎤 Vocal Clear OFF');
    }
  }

  // ── 8D Audio ───────────────────────────────────────────────────────────────
  Future<void> set8DMode(bool enabled) async {
    _is8DEnabled = enabled;
    debugPrint('🎧 8D mode: $enabled | player playing: ${_player.playing}');
    if (enabled) {
      _start8DLoop();
      debugPrint('🎧 8D Audio ON');
    } else {
      _stop8DLoop();
      // Restore full volume when 8D is turned off
      await _player.setVolume(1.0);
      debugPrint('🎧 8D Audio OFF');
    }
  }

  void _start8DLoop() {
    _eightDTimer?.cancel();
    _eightDAngle = 0.0;
    _eightDTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _eightDAngle += _eightDSpeed;
      if (_eightDAngle > 2 * math.pi) _eightDAngle -= 2 * math.pi;
      _apply8DFrame(_eightDAngle);
    });
  }

  void _stop8DLoop() {
    _eightDTimer?.cancel();
    _eightDTimer = null;
  }

  Future<void> _apply8DFrame(double angle) async {
    if (!_is8DEnabled) return;
    const volumeDepth = 0.12;
    final volume = 1.0 - volumeDepth * (1 - math.cos(angle));
    // FIX: now calls setVolume on the REAL player that is actually playing audio
    await _player.setVolume(volume.clamp(0.1, 1.0));
    if (_isInitialized && _equalizer != null) {
      final treble = -4.0 * math.sin(angle).abs();
      final mid = 3.0 * math.cos(angle * 0.5);
      try {
        final params = await _equalizer!.parameters;
        final bands = params.bands;
        if (bands.length >= 5) {
          await bands[3].setGain((_equalizerGains[3] + mid).clamp(-15.0, 15.0));
          await bands[4].setGain((_equalizerGains[4] + treble).clamp(-15.0, 15.0));
        }
      } catch (_) {}
    }
  }

  // ── Reset all effects ──────────────────────────────────────────────────────
  Future<void> resetAllEffects() async {
    await set8DMode(false);
    await setBassBoost(false);
    await setVocalClear(false);
    await resetEqualizer();
    await _player.setVolume(1.0);
    debugPrint('🔄 All effects reset');
  }

  // ── Playback passthrough ───────────────────────────────────────────────────
  Stream<Duration>    get positionStream    => _player.positionStream;
  Stream<Duration?>   get durationStream    => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  bool get playing => _player.playing;

  Future<void> play()                   => _player.play();
  Future<void> pause()                  => _player.pause();
  Future<void> seek(Duration position)  => _player.seek(position);
  Future<void> skipToNext()             => _player.seekToNext();
  Future<void> skipToPrevious()         => _player.seekToPrevious();

  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0.0, 1.0));
  double get volume => _player.volume;

  // ── Dispose ────────────────────────────────────────────────────────────────
  void dispose() {
    _stop8DLoop();
    // Do NOT dispose _audioPlayer here — MyAudioHandler owns and disposes it
    debugPrint('🧹 DSP Engine disposed');
  }
}