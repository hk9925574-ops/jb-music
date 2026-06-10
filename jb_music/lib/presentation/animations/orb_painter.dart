// lib/presentation/animations/orb_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum OrbState { idle, listening, thinking, speaking }

class OrbPainter extends CustomPainter {
  final double    animValue;   // 0.0 → 1.0 from AnimationController
  final OrbState  orbState;
  final Color     baseColor;

  const OrbPainter({
    required this.animValue,
    required this.orbState,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.32;

    // ── Ripple rings (listening / speaking) ──────────────────────────────
    if (orbState == OrbState.listening || orbState == OrbState.speaking) {
      for (int r = 1; r <= 3; r++) {
        final rippleProgress = ((animValue + r * 0.25) % 1.0);
        final rippleRadius   = radius + radius * 0.6 * rippleProgress;
        final opacity        = (1.0 - rippleProgress).clamp(0.0, 1.0);
        final paint = Paint()
          ..color = baseColor.withOpacity(opacity * 0.35) 
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(centre, rippleRadius, paint);
      }
    }

    // ── Outer glow ───────────────────────────────────────────────────────
    final glowPulse = 0.5 + 0.5 * math.sin(animValue * 2 * math.pi);
    final glowPaint = Paint()
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        orbState == OrbState.idle ? 20 : 30 + 10 * glowPulse,
      )
      ..color = baseColor.withOpacity(
        orbState == OrbState.idle ? 0.25 : 0.5,
      );
    canvas.drawCircle(centre, radius * (1.0 + 0.06 * glowPulse), glowPaint);

    // ── Core orb gradient ────────────────────────────────────────────────
    final gradient = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.85,
      colors: [
        baseColor.withValues(alpha: 0.95),
        baseColor,
        _shiftHue(baseColor, 30),
      ],
    );
    final orbPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: centre, radius: radius),
      );
    canvas.drawCircle(centre, radius, orbPaint);

    // ── Specular highlight ───────────────────────────────────────────────
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      centre + Offset(-radius * 0.28, -radius * 0.28),
      radius * 0.28,
      highlightPaint,
    );

    // ── Waveform bars (speaking / thinking) ─────────────────────────────
    if (orbState == OrbState.speaking || orbState == OrbState.thinking) {
      _drawWaveBars(canvas, centre, radius, animValue);
    }
  }

  void _drawWaveBars(Canvas canvas, Offset centre, double radius, double t) {
    const barCount = 5;
    final barPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final totalWidth = barCount * 8.0;
    final startX     = centre.dx - totalWidth / 2;

    for (int i = 0; i < barCount; i++) {
      final phase  = (t * 2 * math.pi) + i * 0.8;
      final height = radius * 0.25 * (0.5 + 0.5 * math.sin(phase));
      final x      = startX + i * 8.0;
      canvas.drawLine(
        Offset(x, centre.dy - height),
        Offset(x, centre.dy + height),
        barPaint,
      );
    }
  }

  Color _shiftHue(Color color, double degrees) {
    final hsl  = HSLColor.fromColor(color);
    final hue  = (hsl.hue + degrees) % 360;
    return hsl.withHue(hue).toColor();
  }

  @override
  bool shouldRepaint(OrbPainter old) =>
      old.animValue != animValue || old.orbState != orbState;
}