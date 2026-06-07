// lib/core/safety/ear_safety_monitor.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

enum SafetyLevel { safe, caution, warning, danger }

class EarSafetyReport {
  final SafetyLevel level;
  final double volumeLevel;       // 0.0 – 1.0
  final Duration listenDuration;
  final String message;

  const EarSafetyReport({
    required this.level,
    required this.volumeLevel,
    required this.listenDuration,
    required this.message,
  });
}

class EarSafetyMonitor {
  // WHO recommends max 80dB for extended listening
  static const double _cautionThreshold = 0.65;  // ~75dB equivalent
  static const double _warningThreshold  = 0.80;  // ~80dB equivalent
  static const double _dangerThreshold   = 0.95;  // ~85dB+ equivalent

  // Max safe continuous listening durations
  static const Duration _cautionDuration = Duration(hours: 2);
  static const Duration _warningDuration = Duration(hours: 1);
  static const Duration _dangerDuration  = Duration(minutes: 30);

  Duration _totalListenTime = Duration.zero;
  double   _currentVolume   = 0.5;
  bool     _isMonitoring    = false;
  Timer?   _ticker;

  final StreamController<EarSafetyReport> _reportController =
      StreamController<EarSafetyReport>.broadcast();

  Stream<EarSafetyReport> get safetyReportStream => _reportController.stream;

  bool get isMonitoring => _isMonitoring;
  Duration get totalListenTime => _totalListenTime;

  // ── Start / Stop ───────────────────────────────────────────────────────────
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Tick every 60 seconds to accumulate listen time
    _ticker = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_currentVolume > 0.1) {
        _totalListenTime += const Duration(seconds: 60);
        _evaluate();
      }
    });

    debugPrint('👂 Ear safety monitor started');
  }

  void stopMonitoring() {
    _ticker?.cancel();
    _ticker = null;
    _isMonitoring = false;
    debugPrint('👂 Ear safety monitor stopped');
  }

  // ── Update volume ──────────────────────────────────────────────────────────
  void updateVolume(double volume) {
    _currentVolume = volume.clamp(0.0, 1.0);
    _evaluate();
  }

  // ── Reset ──────────────────────────────────────────────────────────────────
  void resetListenTimer() {
    _totalListenTime = Duration.zero;
    debugPrint('👂 Listen timer reset');
  }

  // ── Evaluate safety ────────────────────────────────────────────────────────
  void _evaluate() {
    final report = getReport();
    if (report.level != SafetyLevel.safe) {
      _reportController.add(report);
    }
  }

  EarSafetyReport getReport() {
    final level   = _computeLevel();
    final message = _buildMessage(level);

    return EarSafetyReport(
      level:          level,
      volumeLevel:    _currentVolume,
      listenDuration: _totalListenTime,
      message:        message,
    );
  }

  SafetyLevel _computeLevel() {
    if (_currentVolume >= _dangerThreshold ||
        _totalListenTime >= _dangerDuration && _currentVolume >= _warningThreshold) {
      return SafetyLevel.danger;
    }
    if (_currentVolume >= _warningThreshold ||
        _totalListenTime >= _warningDuration && _currentVolume >= _cautionThreshold) {
      return SafetyLevel.warning;
    }
    if (_currentVolume >= _cautionThreshold ||
        _totalListenTime >= _cautionDuration) {
      return SafetyLevel.caution;
    }
    return SafetyLevel.safe;
  }

  String _buildMessage(SafetyLevel level) => switch (level) {
        SafetyLevel.safe    => 'Volume is at a safe level.',
        SafetyLevel.caution => 'Consider lowering the volume or taking a short break.',
        SafetyLevel.warning => 'High volume detected. Prolonged listening may damage hearing.',
        SafetyLevel.danger  => '⚠️ Dangerously high volume! Please lower immediately.',
      };

  // ── Dispose ────────────────────────────────────────────────────────────────
  void dispose() {
    stopMonitoring();
    _reportController.close();
    debugPrint('🧹 Ear safety monitor disposed');
  }
}