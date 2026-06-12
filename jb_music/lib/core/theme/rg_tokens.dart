// lib/core/theme/rg_tokens.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RG {
  RG._();

  // ── Core Palette ──────────────────────────────────────────────────────────
  static const Color black      = Color(0xFF000000);
  static const Color background = black;
  static const Color blackDeep  = Color(0xFF050505);
  static const Color gold       = Color(0xFFD4A847);
  static const Color goldLight  = Color(0xFFEDC96A);
  static const Color goldDim    = Color(0xFF8A6A20);
  static const Color goldGlow   = Color(0x33D4A847);

  static const Color surface     = Color(0xFF0F0F0F);
  static const Color surfaceHigh = Color(0xFF1A1A1A);
  static const Color surfacePop  = Color(0xFF242424);

  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textMuted     = Color(0xFF444444);
  static const Color textDisabled  = Color(0xFF2A2A2A);

  static const Color border     = Color(0xFF2A2A2A);
  static const Color borderGold = Color(0x55D4A847);

  static const Color success = Color(0xFF4CAF50);
  static const Color error   = Color(0xFFCF6679);
  static const Color warning = Color(0xFFF39C12);
  static const Color info    = Color(0xFF3498DB);

  // ── Compat aliases (kept to avoid breaking existing screens) ──────────────
  static const Color cyan    = gold;
  static const Color pink    = gold;
  static const Color roseMid = gold;
  static const Color roseDeep = goldDim;
  static const Color cardStroke = border;

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double spaceXS  = 4;
  static const double spaceSM  = 8;
  static const double spaceMD  = 16;
  static const double spaceLG  = 24;
  static const double spaceXL  = 32;
  static const double spaceXXL = 48;

  // ── Radius ────────────────────────────────────────────────────────────────
  static const double radiusSM   = 8;
  static const double radiusMD   = 12;
  static const double radiusLG   = 16;
  static const double radiusXL   = 22;
  static const double radiusFull = 999;

  // ── Typography (Google Fonts) ─────────────────────────────────────────────
  static TextStyle get displayStyle => GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.w800, color: textPrimary,
  );
  static TextStyle get titleStyle => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary,
  );
  static TextStyle get subtitleStyle => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
  );
  static TextStyle get bodyStyle => GoogleFonts.inter(
    fontSize: 14, color: textSecondary,
  );
  static TextStyle get captionStyle => GoogleFonts.inter(
    fontSize: 12, color: textSecondary,
  );
  static TextStyle get labelStyle => GoogleFonts.inter(
    fontSize: 11, color: textMuted,
  );
  static TextStyle get goldTitle => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w700, color: gold,
  );

  // ── Decorations ───────────────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusLG),
    border: Border.all(color: border),
  );

  static BoxDecoration get activeCardDecoration => BoxDecoration(
    color: gold.withValues(alpha: 0.07),
    borderRadius: BorderRadius.circular(radiusLG),
    border: Border.all(color: gold.withValues(alpha: 0.4)),
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

  static BoxDecoration playerBackground(Color dominantColor) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [dominantColor.withValues(alpha: 0.25), black],
    ),
  );

  // ── Glows ─────────────────────────────────────────────────────────────────
  static List<BoxShadow> get goldGlowShadow => [
    BoxShadow(color: gold.withValues(alpha: 0.30), blurRadius: 20),
    BoxShadow(color: gold.withValues(alpha: 0.12), blurRadius: 40, spreadRadius: 4),
  ];
  static List<BoxShadow> get cyanGlow => goldGlowShadow;

  // ── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: black,
    primaryColor: gold,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: displayStyle,
      titleLarge: titleStyle,
      titleMedium: subtitleStyle,
      bodyLarge: bodyStyle,
      bodyMedium: bodyStyle,
      bodySmall: captionStyle,
      labelSmall: labelStyle,
    ),
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
    iconTheme: const IconThemeData(color: textSecondary),
    dividerTheme: const DividerThemeData(color: border),
    sliderTheme: SliderThemeData(
      activeTrackColor: gold,
      inactiveTrackColor: surfacePop,
      thumbColor: Colors.white,
      overlayColor: gold.withValues(alpha: 0.15),
    ),
  );
}


typedef RGTokens = RG;