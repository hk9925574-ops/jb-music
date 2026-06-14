// lib/presentation/widgets/section_header.dart
//
// JB MUSIC — NOVA SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jb_music/core/theme/jb_design_system.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? leadingIcon;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.leadingIcon,
    this.accentColor,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 10),
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? JBColors.nova;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(JBRadius.sm),
                border: Border.all(color: accent.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Icon(leadingIcon, color: accent, size: 16),
            ),
            const SizedBox(width: 10),
          ],

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: JBType.h3),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(subtitle!, style: JBType.caption),
                ],
              ],
            ),
          ),

          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onAction!();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: JBRadius.pill,
                  border: Border.all(color: accent.withValues(alpha: 0.35), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: JBType.captionMedium.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 10),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
