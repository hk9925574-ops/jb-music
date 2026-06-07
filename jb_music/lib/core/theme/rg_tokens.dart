// lib/core/theme/rg_tokens.dart
import 'package:flutter/material.dart';

class RG {
  RG._();

  // ── Core colors ────────────────────────────────────────────────────────────
  static const Color black       = Color(0xFF080B14);
  static const Color blackPure   = Color(0xFF000000);
  static const Color blackDeep   = Color(0xFF050709);

  // ── Neon accent (cyan) ─────────────────────────────────────────────────────
  static const Color gold        = Color(0xFF00F5FF); // cyan neon — primary accent
  static const Color goldLight   = Color(0xFF6FFCFF);
  static const Color goldDim     = Color(0xFF008F99);

  // ── Convenience aliases (use these where semantic clarity matters) ──────────
  static const Color cyan        = Color(0xFF00F5FF); // same as gold
  static const Color pink        = Color(0xFFFF2D78); // same as roseMid

  // ── Hot pink — secondary accent ────────────────────────────────────────────
  static const Color roseDeep    = Color(0xFF8B0040);
  static const Color roseMid     = Color(0xFFFF2D78);
  static const Color roseLight   = Color(0xFFFF6BA8);

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color surface     = Color(0xFF0F1220);
  static const Color surfaceHigh = Color(0xFF151A2E);
  static const Color surfacePop  = Color(0xFF1C2340);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8D0);
  static const Color textMuted     = Color(0xFF4A5270);
  static const Color textDisabled  = Color(0xFF2A2F45);

  // ── Borders & strokes ──────────────────────────────────────────────────────
  static const Color cardStroke  = Color(0xFF1E2440);
  static const Color strokeMuted = Color(0xFF151930);
  static const Color strokeGold  = Color(0x4400F5FF);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF1DB954);
  static const Color error   = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info    = Color(0xFF3498DB);

  // ── Neon glow shadows ──────────────────────────────────────────────────────
  static List<BoxShadow> get cyanGlow => [
        BoxShadow(
          color: gold.withValues(alpha: 0.35),
          blurRadius: 20,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: gold.withValues(alpha: 0.15),
          blurRadius: 40,
          spreadRadius: 4,
        ),
      ];

  static List<BoxShadow> get pinkGlow => [
        BoxShadow(
          color: roseMid.withValues(alpha: 0.4),
          blurRadius: 20,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: roseMid.withValues(alpha: 0.15),
          blurRadius: 40,
          spreadRadius: 4,
        ),
      ];

  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double spaceXS  = 4.0;
  static const double spaceSM  = 8.0;
  static const double spaceMD  = 16.0;
  static const double spaceLG  = 24.0;
  static const double spaceXL  = 32.0;
  static const double spaceXXL = 48.0;

  // ── Border radius ──────────────────────────────────────────────────────────
  static const double radiusSM   = 8.0;
  static const double radiusMD   = 12.0;
  static const double radiusLG   = 16.0;
  static const double radiusXL   = 22.0;
  static const double radiusFull = 999.0;

  // ── Text styles ────────────────────────────────────────────────────────────
  static const TextStyle displayStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: 1.2,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textMuted,
    letterSpacing: 0.5,
  );

  static const TextStyle goldTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: gold,
    letterSpacing: 0.3,
  );

  // ── Decoration helpers ─────────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(radiusLG),
        border: Border.all(color: cardStroke, width: 0.5),
      );

  static BoxDecoration get activeCardDecoration => BoxDecoration(
        color: gold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(radiusLG),
        border: Border.all(color: gold.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: gold.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      );

  static BoxDecoration get glassDecoration => BoxDecoration(
        color: surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(radiusXL),
        border: Border.all(color: strokeGold),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      );

  static BoxDecoration get goldPill => BoxDecoration(
        color: gold,
        borderRadius: BorderRadius.circular(radiusFull),
        boxShadow: cyanGlow,
      );

  static BoxDecoration playerBackground(Color dominantColor) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            dominantColor.withValues(alpha: 0.6),
            black.withValues(alpha: 0.95),
            black,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      );

  // ── Theme data ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: black,
        primaryColor: gold,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: roseMid,
          surface: surface,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimary),
          titleTextStyle: titleStyle,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: gold,
          inactiveTrackColor: surfacePop,
          thumbColor: gold,
          overlayColor: gold.withValues(alpha: 0.15),
          trackHeight: 3,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? gold : textMuted),
          trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? gold.withValues(alpha: 0.3)
                  : surfacePop),
        ),
        iconTheme: const IconThemeData(color: textSecondary),
        textTheme: const TextTheme(
          displayLarge: displayStyle,
          titleLarge: titleStyle,
          titleMedium: subtitleStyle,
          bodyLarge: bodyStyle,
          bodySmall: captionStyle,
          labelSmall: labelStyle,
        ),
      );
}