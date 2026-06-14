// lib/presentation/animations/orb_painter.dart
//
// JB MUSIC — NOVA ORB PAINTER
// ─────────────────────────────────────────────────────────────────────────────
// A custom-painted animated orb for the JB AI Assistant screen.
// Draws flowing wave rings that respond to the current OrbState.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';

enum OrbState { idle, listening, thinking, responding }

class OrbPainter extends CustomPainter {
  final double t;
  final OrbState state;
  final Color color;

  const OrbPainter({
    required this.t,
    required this.state,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    switch (state) {
      case OrbState.idle:
        _drawIdleWaves(canvas, cx, cy, r);
      case OrbState.listening:
        _drawListeningWaves(canvas, cx, cy, r);
      case OrbState.thinking:
        _drawThinkingSpinner(canvas, cx, cy, r);
      case OrbState.responding:
        _drawRespondingPulse(canvas, cx, cy, r);
    }
  }

  // ── Idle: slow, gentle concentric rings ────────────────────────────────
  void _drawIdleWaves(Canvas canvas, double cx, double cy, double r) {
    for (int i = 0; i < 3; i++) {
      final phase  = t * math.pi * 2 + i * (math.pi * 2 / 3);
      final radius = r * (0.35 + 0.12 * math.sin(phase));
      final alpha  = 0.12 + 0.06 * math.sin(phase);

      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  // ── Listening: rapid outward rings ────────────────────────────────────
  void _drawListeningWaves(Canvas canvas, double cx, double cy, double r) {
    for (int i = 0; i < 4; i++) {
      final offset = (t + i * 0.25) % 1.0;
      final radius = r * 0.3 + r * 0.6 * offset;
      final alpha  = (1 - offset) * 0.35;

      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Waveform bars in the center
    final barPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const barCount = 7;
    final barW     = r * 0.7 / barCount;
    final startX   = cx - r * 0.35;

    for (int i = 0; i < barCount; i++) {
      final phase  = t * math.pi * 4 + i * 0.6;
      final height = r * 0.2 * (0.3 + 0.7 * math.sin(phase).abs());
      final x      = startX + i * barW;

      canvas.drawLine(
        Offset(x, cy - height),
        Offset(x, cy + height),
        barPaint,
      );
    }
  }

  // ── Thinking: rotating arcs ───────────────────────────────────────────
  void _drawThinkingSpinner(Canvas canvas, double cx, double cy, double r) {
    const arcCount = 3;
    for (int i = 0; i < arcCount; i++) {
      final startAngle = t * math.pi * 2 * (i % 2 == 0 ? 1 : -1)
          + (i * math.pi * 2 / arcCount);
      const sweep      = math.pi * 0.7;
      final ri         = r * (0.5 + i * 0.1);
      final alpha      = 0.25 - i * 0.06;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: ri),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 - i * 0.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ── Responding: pulsing fill rings ───────────────────────────────────
  void _drawRespondingPulse(Canvas canvas, double cx, double cy, double r) {
    for (int i = 0; i < 3; i++) {
      final phase  = t * math.pi * 2 + i * (math.pi * 2 / 3);
      final radius = r * (0.25 + 0.18 * math.sin(phase).abs());
      final alpha  = 0.08 + 0.08 * math.sin(phase).abs();

      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.fill,
      );
    }

    // Frequency dots around the perimeter
    const dotCount = 12;
    for (int i = 0; i < dotCount; i++) {
      final angle  = t * math.pi * 2 + i * (math.pi * 2 / dotCount);
      final ri     = r * (0.65 + 0.1 * math.sin(t * math.pi * 4 + i));
      final dx     = cx + ri * math.cos(angle);
      final dy     = cy + ri * math.sin(angle);
      final alpha  = 0.15 + 0.1 * math.sin(t * math.pi * 2 + i);

      canvas.drawCircle(
        Offset(dx, dy),
        2,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(OrbPainter old) =>
      old.t != t || old.state != state || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
//  ANIMATED ORB WIDGET (self-contained, reusable)
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedOrb extends StatefulWidget {
  final OrbState state;
  final Color color;
  final double size;
  final Widget? child;

  const AnimatedOrb({
    super.key,
    required this.state,
    required this.color,
    this.size = 100,
    this.child,
  });

  @override
  State<AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<AnimatedOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: OrbPainter(
            t: _ctrl.value,
            state: widget.state,
            color: widget.color,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
