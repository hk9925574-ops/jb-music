// lib/core/theme/jb_design_system.dart
//
// JB MUSIC — NOVA DESIGN SYSTEM
// ─────────────────────────────────────────────────────────────────────────────
// A complete design language built from scratch.
// Philosophy: Depth × Light × Motion × Emotion
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  COLOR SYSTEM — NOVA PALETTE
// ═══════════════════════════════════════════════════════════════════════════

class JBColors {
  JBColors._();

  // ── Void (Backgrounds) ──────────────────────────────────────────────────
  static const Color void0    = Color(0xFF000000); // Pure AMOLED
  static const Color void1    = Color(0xFF030308); // Deep cosmic
  static const Color void2    = Color(0xFF070712); // Near-black with blue hint
  static const Color void3    = Color(0xFF0D0D1A); // Dark surface
  static const Color void4    = Color(0xFF141426); // Elevated surface

  // ── Nova (Primary Accent — Ethereal Purple-Gold) ─────────────────────────
  static const Color nova     = Color(0xFFB08DFF); // Soft amethyst
  static const Color novaBright = Color(0xFFCFB2FF); // Bright highlight
  static const Color novaDim  = Color(0xFF6B4FC8); // Deep violet
  static const Color novaGlow = Color(0x40B08DFF); // Ambient glow
  static const Color novaFaint= Color(0x15B08DFF); // Near-transparent

  // ── Pulse (Secondary — Electric Rose-Gold) ───────────────────────────────
  static const Color pulse    = Color(0xFFFF6B9D); // Electric rose
  static const Color pulseSoft= Color(0xFFFFB3CD); // Blush
  static const Color pulseDim = Color(0xFFA0315A); // Deep rose
  static const Color pulseGlow= Color(0x35FF6B9D); // Rose ambient

  // ── Aurora (Tertiary — Cyan-Teal) ────────────────────────────────────────
  static const Color aurora   = Color(0xFF00E5CC); // Electric teal
  static const Color auroraSoft= Color(0xFF80F2E6); // Pale teal
  static const Color auroraDim= Color(0xFF007A6B); // Deep teal
  static const Color auroraGlow= Color(0x3000E5CC); // Teal ambient

  // ── Gold (Legacy/Compat) ─────────────────────────────────────────────────
  static const Color gold     = Color(0xFFD4A847);
  static const Color goldGlow = Color(0x33D4A847);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF2F0FF); // Off-white with hint of purple
  static const Color textSecondary = Color(0xFF8B89A8); // Muted lavender-grey
  static const Color textTertiary  = Color(0xFF4A4860); // Very muted
  static const Color textDisabled  = Color(0xFF2A2840); // Barely visible

  // ── Glass ────────────────────────────────────────────────────────────────
  static const Color glass10  = Color(0x1AFFFFFF);
  static const Color glass15  = Color(0x26FFFFFF);
  static const Color glass20  = Color(0x33FFFFFF);
  static const Color glass30  = Color(0x4DFFFFFF);
  static const Color glassBorder = Color(0x20FFFFFF);
  static const Color glassBorderBright = Color(0x40FFFFFF);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4FFFB0);
  static const Color error   = Color(0xFFFF4B7A);
  static const Color warning = Color(0xFFFFB830);
  static const Color info    = Color(0xFF30C5FF);

  // ── Compat aliases (rg_tokens.dart consumers) ────────────────────────────
  static const Color black       = void0;
  static const Color background  = void0;
  static const Color blackDeep   = void1;
  static const Color surface     = void3;
  static const Color surfaceHigh = void4;
  static const Color surfacePop  = Color(0xFF1C1C2E);
  static const Color border      = Color(0xFF1E1E30);
  static const Color borderGold  = Color(0x40B08DFF);
  static const Color cyan        = aurora;
  static const Color pink        = pulse;
  static const Color roseMid     = pulse;
  static const Color roseDeep    = pulseDim;
  static const Color cardStroke  = Color(0xFF1E1E30);
}

// ═══════════════════════════════════════════════════════════════════════════
//  SPACING SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class JBSpacing {
  JBSpacing._();

  static const double px2  = 2;
  static const double px4  = 4;
  static const double px6  = 6;
  static const double px8  = 8;
  static const double px10 = 10;
  static const double px12 = 12;
  static const double px16 = 16;
  static const double px20 = 20;
  static const double px24 = 24;
  static const double px28 = 28;
  static const double px32 = 32;
  static const double px40 = 40;
  static const double px48 = 48;
  static const double px56 = 56;
  static const double px64 = 64;

  // Named aliases
  static const double xs  = px4;
  static const double sm  = px8;
  static const double md  = px16;
  static const double lg  = px24;
  static const double xl  = px32;
  static const double xxl = px48;

  // Content area
  static const double screenPad = px20;
  static const double cardPad   = px16;
  static const double sectionGap = px32;
}

// ═══════════════════════════════════════════════════════════════════════════
//  RADIUS SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class JBRadius {
  JBRadius._();

  static const double xs   = 6;
  static const double sm   = 10;
  static const double md   = 14;
  static const double lg   = 18;
  static const double xl   = 24;
  static const double xxl  = 32;
  static const double full = 999;

  static BorderRadius get card     => BorderRadius.circular(lg);
  static BorderRadius get cardSm   => BorderRadius.circular(md);
  static BorderRadius get cardLg   => BorderRadius.circular(xl);
  static BorderRadius get pill     => BorderRadius.circular(full);
  static BorderRadius get hero     => BorderRadius.circular(xxl);
  static BorderRadius get sheet    => const BorderRadius.vertical(top: Radius.circular(28));
  static BorderRadius get sheetSm  => const BorderRadius.vertical(top: Radius.circular(20));
}

// ═══════════════════════════════════════════════════════════════════════════
//  TYPOGRAPHY SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class JBType {
  JBType._();

  // Display — for hero headlines
  static TextStyle get hero => GoogleFonts.inter(
    fontSize: 40, fontWeight: FontWeight.w900,
    color: JBColors.textPrimary, height: 1.1, letterSpacing: -1.5,
  );

  static TextStyle get display => GoogleFonts.inter(
    fontSize: 32, fontWeight: FontWeight.w800,
    color: JBColors.textPrimary, height: 1.15, letterSpacing: -1.0,
  );

  static TextStyle get h1 => GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: JBColors.textPrimary, height: 1.2, letterSpacing: -0.8,
  );

  static TextStyle get h2 => GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: JBColors.textPrimary, height: 1.25, letterSpacing: -0.5,
  );

  static TextStyle get h3 => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: JBColors.textPrimary, height: 1.3, letterSpacing: -0.3,
  );

  static TextStyle get h4 => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: JBColors.textPrimary, height: 1.35,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: JBColors.textSecondary, height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w500,
    color: JBColors.textPrimary, height: 1.5,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: JBColors.textSecondary, height: 1.4,
  );

  static TextStyle get captionMedium => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: JBColors.textSecondary, height: 1.4,
  );

  static TextStyle get label => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: JBColors.textTertiary, height: 1.3, letterSpacing: 0.5,
  );

  static TextStyle get micro => GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w500,
    color: JBColors.textTertiary, letterSpacing: 0.3,
  );

  // Accent styles
  static TextStyle get novaAccent => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: JBColors.nova, letterSpacing: 0.2,
  );

  static TextStyle get pulseAccent => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: JBColors.pulse,
  );

  static TextStyle get auroraAccent => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: JBColors.aurora,
  );

  static TextStyle get goldTitle => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: JBColors.gold,
  );

  // Player-specific
  static TextStyle get trackTitle => GoogleFonts.inter(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: JBColors.textPrimary, letterSpacing: -0.3,
  );

  static TextStyle get trackArtist => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w500,
    color: JBColors.textSecondary, letterSpacing: 0.1,
  );

  static TextStyle get lyricsActive => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: JBColors.textPrimary, height: 1.6,
  );

  static TextStyle get lyricsInactive => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w400,
    color: JBColors.textTertiary, height: 1.6,
  );

  // Compat
  static TextStyle get displayStyle => display;
  static TextStyle get titleStyle   => h2;
  static TextStyle get subtitleStyle => h4;
  static TextStyle get bodyStyle    => body;
  static TextStyle get captionStyle => caption;
  static TextStyle get labelStyle   => label;
}

// ═══════════════════════════════════════════════════════════════════════════
//  SHADOW & GLOW SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class JBShadow {
  JBShadow._();

  // Nova (purple) glow — player controls, active elements
  static List<BoxShadow> get nova => [
    const BoxShadow(color: JBColors.novaGlow, blurRadius: 24, spreadRadius: 0),
    const BoxShadow(color: JBColors.novaFaint, blurRadius: 48, spreadRadius: 8),
  ];

  static List<BoxShadow> get novaIntense => [
    const BoxShadow(color: Color(0x70B08DFF), blurRadius: 32, spreadRadius: 4),
    const BoxShadow(color: JBColors.novaGlow, blurRadius: 64, spreadRadius: 12),
  ];

  static List<BoxShadow> get novaSoft => [
    const BoxShadow(color: Color(0x20B08DFF), blurRadius: 16, spreadRadius: 0),
  ];

  // Pulse (rose) glow — liked tracks, hearts
  static List<BoxShadow> get pulse => [
    const BoxShadow(color: JBColors.pulseGlow, blurRadius: 20, spreadRadius: 0),
    const BoxShadow(color: Color(0x18FF6B9D), blurRadius: 40, spreadRadius: 6),
  ];

  // Aurora (teal) glow — play button, active state
  static List<BoxShadow> get aurora => [
    const BoxShadow(color: JBColors.auroraGlow, blurRadius: 24, spreadRadius: 0),
    const BoxShadow(color: Color(0x1800E5CC), blurRadius: 48, spreadRadius: 8),
  ];

  // Gold glow — compat
  static List<BoxShadow> get gold => [
    const BoxShadow(color: JBColors.goldGlow, blurRadius: 20),
    const BoxShadow(color: Color(0x12D4A847), blurRadius: 40, spreadRadius: 4),
  ];
  static List<BoxShadow> get goldGlowShadow => gold;
  static List<BoxShadow> get cyanGlow => aurora;

  // Card elevation — subtle depth
  static List<BoxShadow> get card => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.4),
      blurRadius: 16, offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardRaised => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.6),
      blurRadius: 32, offset: const Offset(0, 8),
    ),
    const BoxShadow(
      color: JBColors.novaFaint,
      blurRadius: 24, offset: Offset(0, 4),
    ),
  ];

  // Album art glow — dynamic, set programmatically
  static List<BoxShadow> albumGlow(Color dominantColor) => [
    BoxShadow(
      color: dominantColor.withValues(alpha: 0.45),
      blurRadius: 40, spreadRadius: 8, offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: dominantColor.withValues(alpha: 0.20),
      blurRadius: 80, spreadRadius: 20,
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  GLASS SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class JBGlass {
  JBGlass._();

  // Standard frosted glass card
  static BoxDecoration card({
    Color tint = JBColors.glass15,
    Color borderColor = JBColors.glassBorder,
    double radius = JBRadius.lg,
  }) => BoxDecoration(
    color: tint,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor, width: 0.5),
  );

  // Nova-tinted glass (for active/selected)
  static BoxDecoration novaCard({double radius = JBRadius.lg}) => BoxDecoration(
    color: const Color(0x18B08DFF),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0x35B08DFF), width: 0.8),
  );

  // Aurora-tinted glass (for play controls)
  static BoxDecoration auroraCard({double radius = JBRadius.lg}) => BoxDecoration(
    color: const Color(0x1200E5CC),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0x3000E5CC), width: 0.8),
  );

  // Dark glass (for overlays, menus)
  static BoxDecoration darkCard({double radius = JBRadius.lg}) => BoxDecoration(
    color: const Color(0xCC070712),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: JBColors.glassBorder, width: 0.5),
  );

  // Minimal: just a border glow
  static BoxDecoration borderOnly({
    Color borderColor = JBColors.glassBorder,
    double radius = JBRadius.lg,
  }) => BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor, width: 0.5),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  GRADIENT SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class JBGradients {
  JBGradients._();

  // Background gradients
  static const Gradient void_ = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [JBColors.void2, JBColors.void0],
  );

  static const Gradient cosmic = RadialGradient(
    center: Alignment(-0.5, -0.5),
    radius: 1.2,
    colors: [Color(0xFF0D0A1F), Color(0xFF000000)],
  );

  // Accent gradients
  static const Gradient nova = LinearGradient(
    colors: [JBColors.nova, JBColors.novaDim],
  );

  static const Gradient novaShimmer = LinearGradient(
    colors: [JBColors.novaDim, JBColors.nova, JBColors.novaBright, JBColors.nova],
    stops: [0.0, 0.3, 0.5, 1.0],
  );

  static const Gradient aurora = LinearGradient(
    colors: [JBColors.aurora, Color(0xFF00A896)],
  );

  static const Gradient pulse = LinearGradient(
    colors: [JBColors.pulse, JBColors.pulseDim],
  );

  static const Gradient neonTriad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [JBColors.nova, JBColors.pulse],
    stops: [0.0, 1.0],
  );

  // Player background — dynamic, generated from album
  static Gradient playerBg(Color dominant, {double intensity = 0.3}) =>
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        dominant.withValues(alpha: intensity),
        dominant.withValues(alpha: intensity * 0.5),
        JBColors.void0,
      ],
      stops: const [0.0, 0.4, 0.9],
    );

  static Gradient playerRadial(Color dominant) =>
    RadialGradient(
      center: Alignment.topCenter,
      radius: 1.0,
      colors: [
        dominant.withValues(alpha: 0.35),
        JBColors.void0,
      ],
    );

  // Card shimmers
  static const Gradient cardShimmer = LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0x08FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.5, 1.0],
  );

  // Mini player
  static const Gradient miniPlayer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F0F1F), Color(0xFF080812)],
  );

  // Section headers
  static const Gradient sectionTitle = LinearGradient(
    colors: [JBColors.textPrimary, JBColors.nova],
    stops: [0.7, 1.0],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  DECORATION SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class JBDecor {
  JBDecor._();

  // Standard card
  static BoxDecoration get card => BoxDecoration(
    color: JBColors.void3,
    borderRadius: JBRadius.card,
    border: Border.all(color: JBColors.glassBorder, width: 0.5),
    boxShadow: JBShadow.card,
  );

  // Active / now-playing card
  static BoxDecoration get activeCard => BoxDecoration(
    gradient: const LinearGradient(
      colors: [
        Color(0x22B08DFF),
        Color(0x0AB08DFF),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: JBRadius.card,
    border: Border.all(color: const Color(0x45B08DFF), width: 0.8),
    boxShadow: JBShadow.novaSoft,
  );

  // Glass card
  static BoxDecoration get glass => JBGlass.card();

  // Hero album art container
  static BoxDecoration get albumArt => BoxDecoration(
    borderRadius: JBRadius.cardLg,
    boxShadow: JBShadow.cardRaised,
  );

  // Player screen background
  static BoxDecoration playerBg(Color dominant) => BoxDecoration(
    gradient: JBGradients.playerBg(dominant),
  );

  // Pill badge
  static BoxDecoration get nova => BoxDecoration(
    color: JBColors.novaFaint,
    borderRadius: JBRadius.pill,
    border: Border.all(color: const Color(0x40B08DFF), width: 0.5),
  );

  static BoxDecoration get aurora => BoxDecoration(
    gradient: JBGradients.aurora,
    borderRadius: JBRadius.pill,
    boxShadow: JBShadow.aurora,
  );

  static BoxDecoration get gold => BoxDecoration(
    color: JBColors.gold,
    borderRadius: JBRadius.pill,
  );

  // Compat
  static BoxDecoration get cardDecoration => card;
  static BoxDecoration get activeCardDecoration => activeCard;
  static BoxDecoration get glassDecoration => glass;
  static BoxDecoration get goldPill => gold;

  static BoxDecoration playerBackground(Color dominantColor) => playerBg(dominantColor);
}

// ═══════════════════════════════════════════════════════════════════════════
//  ANIMATION SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

class JBAnim {
  JBAnim._();

  // Durations
  static const Duration fast    = Duration(milliseconds: 150);
  static const Duration normal  = Duration(milliseconds: 300);
  static const Duration slow    = Duration(milliseconds: 500);
  static const Duration slower  = Duration(milliseconds: 800);
  static const Duration slowest = Duration(milliseconds: 1200);
  static const Duration loop4s  = Duration(seconds: 4);
  static const Duration loop8s  = Duration(seconds: 8);
  static const Duration loop14s = Duration(seconds: 14);

  // Curves — physics-based
  static const Curve spring       = Curves.easeOutBack;
  static const Curve elastic      = Curves.elasticOut;
  static const Curve decelerate   = Curves.decelerate;
  static const Curve ease         = Curves.easeInOutCubic;
  static const Curve easeOut      = Curves.easeOutCubic;
  static const Curve easeIn       = Curves.easeInCubic;
  static const Curve bounce       = Curves.bounceOut;
  static const Curve smooth       = Curves.easeInOutQuart;

  // Page transitions
  static PageRouteBuilder<T> slideUp<T>(Widget child) => PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: easeOut)),
      child: child,
    ),
    transitionDuration: slow,
  );

  static PageRouteBuilder<T> fadeScale<T>(Widget child) => PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: (_, anim, __, child) {
      final curve = CurvedAnimation(parent: anim, curve: ease);
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(curve), child: child),
      );
    },
    transitionDuration: normal,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  THEME ENGINE
// ═══════════════════════════════════════════════════════════════════════════

class JBTheme {
  JBTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: JBColors.void0,
    primaryColor: JBColors.nova,
    textTheme: _buildTextTheme(),
    colorScheme: const ColorScheme.dark(
      primary: JBColors.nova,
      secondary: JBColors.pulse,
      tertiary: JBColors.aurora,
      surface: JBColors.void3,
      surfaceContainerHighest: JBColors.void4,
      onSurface: JBColors.textPrimary,
      onPrimary: JBColors.void0,
      error: JBColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: JBColors.void3,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: JBRadius.card,
        side: const BorderSide(color: JBColors.glassBorder, width: 0.5),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: JBColors.nova,
      unselectedLabelColor: JBColors.textTertiary,
      indicatorColor: JBColors.nova,
      dividerColor: Colors.transparent,
    ),
    iconTheme: const IconThemeData(color: JBColors.textSecondary),
    dividerTheme: const DividerThemeData(color: JBColors.glassBorder),
    sliderTheme: const SliderThemeData(
      activeTrackColor: JBColors.nova,
      inactiveTrackColor: JBColors.void4,
      thumbColor: Colors.white,
      overlayColor: JBColors.novaGlow,
      trackHeight: 2.5,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );

  static TextTheme _buildTextTheme() {
    final base = ThemeData.dark().textTheme;
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: JBType.display,
      titleLarge: JBType.h2,
      titleMedium: JBType.h4,
      bodyLarge: JBType.body,
      bodyMedium: JBType.body,
      bodySmall: JBType.caption,
      labelSmall: JBType.label,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  BACKWARD COMPAT — RG TOKEN ALIASES
// ═══════════════════════════════════════════════════════════════════════════

/// Drop-in replacement for rg_tokens.dart
/// All existing RG.xxx references continue to work.
class RG {
  RG._();

  // Colors
  static const Color black       = JBColors.void0;
  static const Color background  = JBColors.void0;
  static const Color blackDeep   = JBColors.void1;
  static const Color gold        = JBColors.gold;
  static const Color goldLight   = Color(0xFFCFB2FF); // maps to novaBright
  static const Color goldDim     = JBColors.novaDim;
  static const Color goldGlow    = JBColors.novaFaint;
  static const Color surface     = JBColors.void3;
  static const Color surfaceHigh = JBColors.void4;
  static const Color surfacePop  = Color(0xFF1C1C2E);
  static const Color textPrimary   = JBColors.textPrimary;
  static const Color textSecondary = JBColors.textSecondary;
  static const Color textMuted     = JBColors.textTertiary;
  static const Color textDisabled  = JBColors.textDisabled;
  static const Color border        = JBColors.glassBorder;
  static const Color borderGold    = Color(0x40B08DFF);
  static const Color success       = JBColors.success;
  static const Color error         = JBColors.error;
  static const Color warning       = JBColors.warning;
  static const Color info          = JBColors.info;
  static const Color cyan          = JBColors.aurora;
  static const Color pink          = JBColors.pulse;
  static const Color roseMid       = JBColors.pulse;
  static const Color roseDeep      = JBColors.pulseDim;
  static const Color cardStroke    = JBColors.glassBorder;

  // Spacing
  static const double spaceXS  = JBSpacing.xs;
  static const double spaceSM  = JBSpacing.sm;
  static const double spaceMD  = JBSpacing.md;
  static const double spaceLG  = JBSpacing.lg;
  static const double spaceXL  = JBSpacing.xl;
  static const double spaceXXL = JBSpacing.xxl;

  // Radius
  static const double radiusSM   = JBRadius.sm;
  static const double radiusMD   = JBRadius.md;
  static const double radiusLG   = JBRadius.lg;
  static const double radiusXL   = JBRadius.xl;
  static const double radiusFull = JBRadius.full;

  // Typography
  static TextStyle get displayStyle  => JBType.display;
  static TextStyle get titleStyle    => JBType.h2;
  static TextStyle get subtitleStyle => JBType.h4;
  static TextStyle get bodyStyle     => JBType.body;
  static TextStyle get captionStyle  => JBType.caption;
  static TextStyle get labelStyle    => JBType.label;
  static TextStyle get goldTitle     => JBType.goldTitle;

  // Decorations
  static BoxDecoration get cardDecoration       => JBDecor.card;
  static BoxDecoration get activeCardDecoration => JBDecor.activeCard;
  static BoxDecoration get glassDecoration      => JBDecor.glass;
  static BoxDecoration get goldPill             => JBDecor.gold;
  static BoxDecoration playerBackground(Color c) => JBDecor.playerBackground(c);

  // Glows
  static List<BoxShadow> get goldGlowShadow => JBShadow.gold;
  static List<BoxShadow> get cyanGlow       => JBShadow.aurora;

  // Theme
  static ThemeData get darkTheme => JBTheme.dark;
}

typedef RGTokens = RG;
