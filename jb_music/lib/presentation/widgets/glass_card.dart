// lib/presentation/widgets/glass_card.dart
//
// JB MUSIC — NOVA GLASS CARD
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:jb_music/core/theme/jb_design_system.dart';

/// A versatile frosted-glass card widget.
/// Supports nova/pulse/aurora tints, blur, border, shadow, and press effects.
class GlassCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? tint;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final double blurSigma;
  final bool pressable;
  final VoidCallback? onTap;
  final bool novaAccent;
  final bool auroraAccent;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.radius = JBRadius.lg,
    this.tint,
    this.borderColor,
    this.borderWidth = 0.5,
    this.shadows,
    this.blurSigma = 20,
    this.pressable = false,
    this.onTap,
    this.novaAccent = false,
    this.auroraAccent = false,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Color get _tint {
    if (widget.tint != null) return widget.tint!;
    if (widget.novaAccent) return const Color(0x18B08DFF);
    if (widget.auroraAccent) return const Color(0x1200E5CC);
    return JBColors.glass15;
  }

  Color get _border {
    if (widget.borderColor != null) return widget.borderColor!;
    if (widget.novaAccent) return const Color(0x35B08DFF);
    if (widget.auroraAccent) return const Color(0x3000E5CC);
    return JBColors.glassBorder;
  }

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurSigma,
          sigmaY: widget.blurSigma,
        ),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _tint,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: _border, width: widget.borderWidth),
            boxShadow: widget.shadows,
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    if (widget.pressable || widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// A simple non-blur tinted card (lighter weight, better perf for lists)
class NovaCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool active;

  const NovaCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.radius = JBRadius.lg,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: active ? JBDecor.activeCard : JBDecor.card,
      child: child,
    );
  }
}
