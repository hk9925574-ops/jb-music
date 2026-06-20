// lib/core/audio/jb_fft_visualizer_engine.dart
//
// Flutter-side counterpart to JBVisualizerManager.kt. Listens on the
// 'jb_music/fft' EventChannel and exposes:
//   - a raw bar stream (List<double>, 0.0–1.0) for spectrum UI
//   - convenience getters for bass / mid / treble energy (e.g. for
//     pulsing album art, beat-reactive backgrounds, etc.)
//
// Sits next to your existing JBDspEngine — same session lifecycle.

import 'dart:async';
import 'package:flutter/services.dart';

class JBFftVisualizerEngine {
  static const EventChannel _channel = EventChannel('jb_music/fft');

  StreamSubscription<dynamic>? _nativeSub;
  final StreamController<List<double>> _barsController =
      StreamController<List<double>>.broadcast();

  List<double> _lastBars = const [];

  /// Raw bar stream — one List<double> (length = BAR_COUNT from Kotlin,
  /// currently 32) per native FFT capture, values normalized 0.0–1.0.
  Stream<List<double>> get barsStream => _barsController.stream;

  List<double> get lastBars => _lastBars;

  /// Average energy across the low third of bars — useful for bass-reactive
  /// UI (pulsing artwork, glow effects, etc.)
  double get bassEnergy => _bandAverage(0.0, 1 / 3);

  double get midEnergy => _bandAverage(1 / 3, 2 / 3);

  double get trebleEnergy => _bandAverage(2 / 3, 1.0);

  bool _listening = false;
  bool get isListening => _listening;

  void start() {
    if (_listening) return;
    _listening = true;
    _nativeSub = _channel.receiveBroadcastStream().listen(
      (event) {
        if (event is List) {
          final bars = event.map((e) => (e as num).toDouble()).toList();
          _lastBars = bars;
          if (!_barsController.isClosed) {
            _barsController.add(bars);
          }
        }
      },
      onError: (e) {
        // Native side throws if the visualizer/session isn't ready yet —
        // safe to ignore, next capture will come through once attached.
      },
      cancelOnError: false,
    );
  }

  void stop() {
    _nativeSub?.cancel();
    _nativeSub = null;
    _listening = false;
  }

  double _bandAverage(double startFrac, double endFrac) {
    if (_lastBars.isEmpty) return 0.0;
    final start = (startFrac * _lastBars.length).floor();
    final end = (endFrac * _lastBars.length).ceil().clamp(0, _lastBars.length);
    if (end <= start) return 0.0;
    final slice = _lastBars.sublist(start, end);
    return slice.reduce((a, b) => a + b) / slice.length;
  }

  Future<void> dispose() async {
    stop();
    await _barsController.close();
  }
}