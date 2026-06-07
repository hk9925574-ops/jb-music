// lib/core/utils/theme_extractor.dart
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ThemeExtractor {
  static Future<ColorScheme> extractFromImage(
      ImageProvider imageProvider) async {
    final PaletteGenerator palette =
        await PaletteGenerator.fromImageProvider(imageProvider);

    // ✅ FIX: Colors.gold doesn't exist — use amber as fallback
    return ColorScheme.fromSeed(
      seedColor: palette.dominantColor?.color ?? Colors.blue,
      brightness: Brightness.dark,
      primary: palette.vibrantColor?.color ?? Colors.amber,
      surface: palette.mutedColor?.color ?? Colors.grey[900]!,
    );
  }
}