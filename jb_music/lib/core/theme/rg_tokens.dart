import 'package:flutter/material.dart';

class RG {
  RG._();

  // ───────────────── COLORS ─────────────────
  static const Color goldGlow = Color(0x33D4A847);
  static const Color black = Color(0xFF000000);
  static const Color blackDeep = Color(0xFF050505);

  static const Color gold = Color(0xFFD4A847);
  static const Color goldLight = Color(0xFFEDC96A);
  static const Color goldDim = Color(0xFF8A6A20);

  static const Color surface = Color(0xFF0F0F0F);
  static const Color surfaceHigh = Color(0xFF1A1A1A);
  static const Color surfacePop = Color(0xFF242424);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textMuted = Color(0xFF444444);
  static const Color textDisabled = Color(0xFF2A2A2A);

  static const Color border = Color(0xFF2A2A2A);
  static const Color borderGold = Color(0x55D4A847);

  static const Color success = Color(0xFFB388FF);
  static const Color error = Color(0xFFCF6679);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);

  // ───────── COMPATIBILITY ALIASES ─────────

  static const Color cyan = gold;
  static const Color pink = gold;

  static const Color roseMid = gold;
  static const Color roseDeep = goldDim;

  static const Color cardStroke = border;

  // ───────── GLOWS ─────────

  static List<BoxShadow> get goldGlowShadow => [
        BoxShadow(
          color: gold.withValues(alpha: 0.30),
          blurRadius: 20,
        ),
        BoxShadow(
          color: gold.withValues(alpha: 0.12),
          blurRadius: 40,
          spreadRadius: 4,
        ),
      ];

  static List<BoxShadow> get cyanGlow => goldGlowShadow;

  // ───────── SPACING ─────────

  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double spaceXL = 32;
  static const double spaceXXL = 48;

  // ───────── RADIUS ─────────

  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 22;
  static const double radiusFull = 999;

  // ───────── TEXT STYLES ─────────

  static const TextStyle displayStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: textSecondary,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    color: textSecondary,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 11,
    color: textMuted,
  );

  static const TextStyle goldTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: gold,
  );

  // ───────── DECORATIONS ─────────

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusLG),
        border: Border.all(color: border),
      );

  static BoxDecoration get activeCardDecoration => BoxDecoration(
        color: gold.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(radiusLG),
        border: Border.all(
          color: gold.withValues(alpha: 0.4),
        ),
      );

  static BoxDecoration get glassDecoration => BoxDecoration(
        color: surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(radiusXL),
        border: Border.all(color: borderGold),
      );

  static BoxDecoration get goldPill => BoxDecoration(
        color: gold,
        borderRadius: BorderRadius.circular(radiusFull),
      );

  static BoxDecoration playerBackground(Color dominantColor) =>
      BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            dominantColor.withValues(alpha: 0.2),
            black,
          ],
        ),
      );

  // ───────── THEME ─────────

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: black,
        primaryColor: gold,

        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: goldDim,
          surface: surface,
          onSurface: textPrimary,
          onPrimary: Colors.black,
          error: error,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),

        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLG),
            side: const BorderSide(color: border),
          ),
        ),

        tabBarTheme: const TabBarThemeData(
          labelColor: gold,
          unselectedLabelColor: textMuted,
          indicatorColor: gold,
          dividerColor: Colors.transparent,
        ),

        iconTheme: const IconThemeData(
          color: textSecondary,
        ),

        dividerTheme: const DividerThemeData(
          color: border,
        ),

        sliderTheme: SliderThemeData(
          activeTrackColor: gold,
          inactiveTrackColor: surfacePop,
          thumbColor: Colors.white,
          overlayColor: gold.withValues(alpha: 0.15),
        ),

        textTheme: const TextTheme(
          displayLarge: displayStyle,
          titleLarge: titleStyle,
          titleMedium: subtitleStyle,
          bodyLarge: bodyStyle,
          bodyMedium: bodyStyle,
          bodySmall: captionStyle,
          labelSmall: labelStyle,
        ),
      );
}