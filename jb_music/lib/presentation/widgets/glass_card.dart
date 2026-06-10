// lib/presentation/widgets/glass_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = RG.radiusLG,
    this.borderColor,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(RG.spaceMD),
          decoration: BoxDecoration(
            color: RG.surfaceHigh.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? RG.borderGold,
              width: 0.8,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}