// lib/presentation/animations/page_transitions.dart
//
// JB MUSIC — NOVA PAGE TRANSITIONS
// ─────────────────────────────────────────────────────────────────────────────
// Premium physics-based page transitions used throughout the app.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:jb_music/core/theme/jb_design_system.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  VERTICAL SLIDE (used for Player screen)
// ─────────────────────────────────────────────────────────────────────────────
class VerticalSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  VerticalSlideRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 500),
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (ctx, anim, secondAnim, child) {
            final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curve),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: const Interval(0, 0.4)),
                ),
                child: child,
              ),
            );
          },
        );
}

// ─────────────────────────────────────────────────────────────────────────────
//  FADE + SCALE (used for secondary screens)
// ─────────────────────────────────────────────────────────────────────────────
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeScaleRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (ctx, anim, _, child) {
            final curve = CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic);
            return FadeTransition(
              opacity: curve,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(curve),
                child: child,
              ),
            );
          },
        );
}

// ─────────────────────────────────────────────────────────────────────────────
//  HORIZONTAL SLIDE (used for settings, library detail)
// ─────────────────────────────────────────────────────────────────────────────
class HorizontalSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  HorizontalSlideRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (ctx, anim, _, child) {
            final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            );
          },
        );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SPRING HERO TRANSITION (for album art → player)
// ─────────────────────────────────────────────────────────────────────────────
class SpringHeroRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final String heroTag;

  SpringHeroRoute({required this.page, required this.heroTag})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 550),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (ctx, anim, secondAnim, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: anim,
                curve: const Interval(0, 0.6),
              ),
              child: child,
            );
          },
        );
}

// ─────────────────────────────────────────────────────────────────────────────
//  BLUR DISMISS TRANSITION (bottom sheet style)
// ─────────────────────────────────────────────────────────────────────────────
class BlurDismissRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  BlurDismissRoute({required this.page})
      : super(
          opaque: false,
          barrierColor: Colors.black.withValues(alpha: 0.6),
          barrierDismissible: true,
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (ctx, anim, _, child) {
            final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curve,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(curve),
                child: child,
              ),
            );
          },
        );
}

// ─────────────────────────────────────────────────────────────────────────────
//  PRESS SCALE WRAPPER (elastic press for any widget)
// ─────────────────────────────────────────────────────────────────────────────
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final Duration duration;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 250),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHIMMER LOADING PLACEHOLDER
// ─────────────────────────────────────────────────────────────────────────────
class ShimmerBox extends StatefulWidget {
  final double width, height, radius;
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = JBRadius.md,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_shimmer.value - 0.5).clamp(0.0, 1.0),
                _shimmer.value.clamp(0.0, 1.0),
                (_shimmer.value + 0.5).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFF0D0D1A),
                Color(0xFF1C1C30),
                Color(0xFF0D0D1A),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STAGGERED LIST ANIMATION HELPER
// ─────────────────────────────────────────────────────────────────────────────

/// Wrap each list item with this to get automatic staggered entry.
///
/// Usage:
/// ```dart
/// ListView.builder(
///   itemBuilder: (ctx, i) => StaggeredListItem(
///     index: i,
///     child: MyListTile(...),
///   ),
/// )
/// ```
class StaggeredListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration itemDelay;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.itemDelay = const Duration(milliseconds: 20),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 20),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - v)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
