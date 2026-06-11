// lib/core/ai/shake_detector.dart
// JB Music — Shake to Skip
// Detects phone shake via accelerometer → fires onShake callback.
// Uses sensors_plus (add to pubspec if not present, or uses raw platform channel).
// Falls back gracefully if sensors unavailable.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHAKE DETECTOR
// ─────────────────────────────────────────────────────────────────────────────
// Uses sensors_plus: ^4.0.0 — add to pubspec.yaml:
//   sensors_plus: ^4.0.0

class JBShakeDetector {
  static const _prefsKey      = 'jb_shake_enabled';
  static const _thresholdKey  = 'jb_shake_threshold';

  // Sensitivity: higher = harder to trigger, lower = easier
  double _threshold      = 15.0; // m/s² delta
  bool   _enabled        = true;
  bool   get isEnabled   => _enabled;
  double get threshold   => _threshold;

  VoidCallback? onShake;

  // Internal state
  double _lastX = 0, _lastY = 0, _lastZ = 0;
  DateTime _lastShakeTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const _cooldownMs = 1500; // prevent double-triggers

  StreamSubscription<dynamic>? _sub;
  bool _initialized = false;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs     = await SharedPreferences.getInstance();
    _enabled        = prefs.getBool(_prefsKey) ?? true;
    _threshold      = prefs.getDouble(_thresholdKey) ?? 15.0;

    if (!_enabled) return;
    await _startListening();
  }

  Future<void> _startListening() async {
    if (_initialized) return;
    try {
      // Dynamic import to avoid hard dependency if package not added
      // In production: import 'package:sensors_plus/sensors_plus.dart';
      // and replace the dynamic call below with:
      //   _sub = accelerometerEventStream().listen(_onAccelerometer);

      // ── STUB: replace with real sensor stream ──
      // This file is ready — just add sensors_plus to pubspec.yaml
      // and uncomment the real listener:
      //
      // import 'package:sensors_plus/sensors_plus.dart';
      // _sub = accelerometerEvents.listen((AccelerometerEvent e) {
      //   _onAccelerometer(e.x, e.y, e.z);
      // });

      debugPrint('📳 ShakeDetector: add sensors_plus to pubspec to enable');
      _initialized = true;
    } catch (e) {
      debugPrint('⚠️ ShakeDetector init error: $e');
    }
  }

  // ── Accelerometer handler ──────────────────────────────────────────────────
  // Call this from your real sensors_plus listener:
  // accelerometerEvents.listen((e) => detector.onAccelerometer(e.x, e.y, e.z))

  void onAccelerometer(double x, double y, double z) {
    if (!_enabled) return;

    final dX = x - _lastX;
    final dY = y - _lastY;
    final dZ = z - _lastZ;

    final acceleration = math.sqrt(dX * dX + dY * dY + dZ * dZ);

    _lastX = x;
    _lastY = y;
    _lastZ = z;

    if (acceleration > _threshold) {
      final now = DateTime.now();
      if (now.difference(_lastShakeTime).inMilliseconds > _cooldownMs) {
        _lastShakeTime = now;
        debugPrint('📳 Shake detected! (${acceleration.toStringAsFixed(1)} m/s²)');
        onShake?.call();
      }
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);

    if (value) {
      await _startListening();
    } else {
      await _sub?.cancel();
      _sub = null;
      _initialized = false;
    }
  }

  Future<void> setThreshold(double value) async {
    _threshold = value.clamp(8.0, 30.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_thresholdKey, _threshold);
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _sub?.cancel();
  }
}
