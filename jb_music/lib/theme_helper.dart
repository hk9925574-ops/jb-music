// lib/theme_helper.dart
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

// ✅ FIX: Colors.gold doesn't exist in Flutter — use Colors.amber
Future<Color> getDominantColor(ImageProvider image) async {
  final PaletteGenerator palette =
      await PaletteGenerator.fromImageProvider(image);
  return palette.dominantColor?.color ?? Colors.amber;
}