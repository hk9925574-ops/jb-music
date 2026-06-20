// lib/presentation/widgets/jb_spectrum_view.dart
//
// 60fps-ish spectrum bar visualizer. Wraps JBFftVisualizerEngine.barsStream
// and applies simple attack/decay smoothing so bars don't look jittery
// between native FFT captures (Poweramp/Musicolet-style).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jb_music/core/audio/jb_fft_visualizer_engine.dart';

class JBSpectrumView extends StatefulWidget {
  final JBFftVisualizerEngine engine;
  final Color barColor;
  final double barSpacing;
  final double cornerRadius;

  /// How quickly bars rise to a new peak (0–1, higher = snappier).
  final double attack;

  /// How quickly bars fall after a peak (0–1, lower = longer trailing decay).
  final double decay;

  const JBSpectrumView({
    super.key,
    required this.engine,
    this.barColor = const Color(0xFF1ED760),
    this.barSpacing = 3.0,
    this.cornerRadius = 2.0,
    this.attack = 0.6,
    this.decay = 0.12,
  });

  @override
  State<JBSpectrumView> createState() => _JBSpectrumViewState();
}

class _JBSpectrumViewState extends State<JBSpectrumView>
    with SingleTickerProviderStateMixin {
  List<double> _target = const [];
  List<double> _smoothed = const [];
  late final Ticker _ticker;
  StreamSubscription<List<double>>? _sub;

  @override
  void initState() {
    super.initState();
    widget.engine.start();
    _sub = widget.engine.barsStream.listen((bars) {
      _target = bars;
      if (_smoothed.length != bars.length) {
        _smoothed = List.filled(bars.length, 0.0);
      }
    });

    // Drive smoothing every frame regardless of native capture rate, so
    // the UI stays buttery even if FFT callbacks arrive slower than 60fps.
    _ticker = createTicker((_) {
      if (_target.isEmpty) return;
      final next = List<double>.generate(_target.length, (i) {
        final t = _target[i];
        final s = i < _smoothed.length ? _smoothed[i] : 0.0;
        final rate = t > s ? widget.attack : widget.decay;
        return s + (t - s) * rate;
      });
      setState(() => _smoothed = next);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sub?.cancel();
    widget.engine.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpectrumPainter(
        bars: _smoothed,
        color: widget.barColor,
        spacing: widget.barSpacing,
        radius: widget.cornerRadius,
      ),
      size: Size.infinite,
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final List<double> bars;
  final Color color;
  final double spacing;
  final double radius;

  _SpectrumPainter({
    required this.bars,
    required this.color,
    required this.spacing,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final paint = Paint()..color = color;
    final barCount = bars.length;
    final totalSpacing = spacing * (barCount - 1);
    final barWidth = (size.width - totalSpacing) / barCount;

    for (var i = 0; i < barCount; i++) {
      final value = bars[i].clamp(0.0, 1.0);
      final barHeight = (value * size.height).clamp(2.0, size.height);
      final left = i * (barWidth + spacing);
      final top = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        Radius.circular(radius),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) => true;
}

