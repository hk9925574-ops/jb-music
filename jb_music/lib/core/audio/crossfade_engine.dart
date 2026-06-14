// lib/core/audio/crossfade_engine.dart
// JB Music — Crossfade Engine
// Smoothly fades out current track and fades in next track simultaneously.
// Uses just_audio's setVolume() API — no additional packages required.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CROSSFADE ENGINE
// ─────────────────────────────────────────────────────────────────────────────

class JBCrossfadeEngine {
  static const _prefsEnabled  = 'jb_crossfade_enabled';
  static const _prefsDuration = 'jb_crossfade_duration_ms';

  bool   _enabled          = true;
  int    _durationMs       = 3000; // default 3s
  bool   get isEnabled     => _enabled;
  int    get durationMs    => _durationMs;
  double get durationSecs  => _durationMs / 1000.0;

  Timer? _fadeTimer;
  bool   _isCrossfading = false;
  bool   get isCrossfading => _isCrossfading;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled     = prefs.getBool(_prefsEnabled) ?? true;
    _durationMs  = prefs.getInt(_prefsDuration) ?? 3000;
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabled, value);
  }

  Future<void> setDuration(int ms) async {
    _durationMs = ms.clamp(500, 8000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsDuration, _durationMs);
  }

  // ── Core crossfade ─────────────────────────────────────────────────────────
  // outPlayer: currently playing track (will fade out)
  // inPlayer:  next track (will fade in)
  // onComplete: called when fade finishes
  //
  // USAGE in audio_handler.dart:
  //   await crossfadeEngine.crossfade(
  //     outPlayer: _currentPlayer,
  //     inPlayer:  _nextPlayer,
  //     onComplete: () => _currentPlayer = _nextPlayer,
  //   );

  Future<void> crossfade({
    required AudioPlayer outPlayer,
    required AudioPlayer inPlayer,
    double masterVolume = 1.0,
    VoidCallback? onComplete,
  }) async {
    if (!_enabled) {
      // No crossfade — just swap
      await outPlayer.stop();
      await inPlayer.setVolume(masterVolume);
      onComplete?.call();
      return;
    }

    if (_isCrossfading) {
      // Previous fade still running — abort it
      _fadeTimer?.cancel();
      _isCrossfading = false;
    }

    _isCrossfading = true;
    debugPrint('🎚️ Crossfade start — ${_durationMs}ms');

    const tickMs = 50; // 20fps
    final steps  = _durationMs ~/ tickMs;
    int   step   = 0;

    // Start incoming track at volume 0 immediately
    await inPlayer.setVolume(0.0);
    await inPlayer.play();

    _fadeTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) async {
      step++;
      final progress = step / steps; // 0.0 → 1.0
      final fadeIn   = _easeInOut(progress);
      final fadeOut  = 1.0 - fadeIn;

      try {
        await outPlayer.setVolume((fadeOut * masterVolume).clamp(0.0, 1.0));
        await inPlayer.setVolume((fadeIn  * masterVolume).clamp(0.0, 1.0));
      } catch (_) {
        // Player may have been disposed
      }

      if (step >= steps) {
        timer.cancel();
        _isCrossfading = false;
        try {
          await outPlayer.stop();
          await inPlayer.setVolume(masterVolume);
        } catch (_) {}
        debugPrint('✅ Crossfade complete');
        onComplete?.call();
      }
    });
  }

  // ── Simple fade-out (end of playlist, sleep timer) ────────────────────────

  Future<void> fadeOut(AudioPlayer player, {VoidCallback? onComplete}) async {
    const tickMs = 50;
    final steps  = _durationMs ~/ tickMs;
    int   step   = 0;
    final startVol = player.volume;

    _fadeTimer?.cancel();

    _fadeTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) async {
      step++;
      final progress = step / steps;
      try {
        await player.setVolume((startVol * (1.0 - progress)).clamp(0.0, 1.0));
      } catch (_) {}

      if (step >= steps) {
        timer.cancel();
        try {
          await player.stop();
          await player.setVolume(startVol);
        } catch (_) {}
        onComplete?.call();
      }
    });
  }

  // ── Fade-in (app resume, unmute) ──────────────────────────────────────────

  Future<void> fadeIn(AudioPlayer player, {double targetVolume = 1.0}) async {
    const tickMs = 50;
    final steps  = _durationMs ~/ tickMs;
    int   step   = 0;

    await player.setVolume(0.0);

    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) async {
      step++;
      final progress = step / steps;
      try {
        await player.setVolume((targetVolume * progress).clamp(0.0, 1.0));
      } catch (_) {}
      if (step >= steps) {
        timer.cancel();
      }
    });
  }

  // ── Easing function (smooth S-curve) ─────────────────────────────────────

  double _easeInOut(double t) {
    return t < 0.5
        ? 2 * t * t
        : 1 - (-2 * t + 2) * (-2 * t + 2) / 2;
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  void dispose() {
    _fadeTimer?.cancel();
  }
}
