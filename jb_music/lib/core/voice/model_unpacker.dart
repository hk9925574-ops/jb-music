// lib/core/voice/model_unpacker.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

class ModelUnpacker {
  static const String _modelAssetDir  = 'assets/voice/vosk-model-small-en-us-0.15';
  static const String _modelOutputDir = 'vosk-model-small-en-us-0.15';

  // ── Main entry point ───────────────────────────────────────────────────────
  /// Returns the local filesystem path to the extracted Vosk model.
  /// Extracts from assets on first run; returns cached path on subsequent runs.
  static Future<String> getExtractedModelPath() async {
    final appDir    = await getApplicationDocumentsDirectory();
    final modelPath = p.join(appDir.path, _modelOutputDir);
    final modelDir  = Directory(modelPath);

    if (await modelDir.exists() && await _isModelComplete(modelDir)) {
      debugPrint('📦 Vosk model found at: $modelPath');
      return modelPath;
    }

    debugPrint('📦 Extracting Vosk model to: $modelPath');
    await _extractModel(modelDir);
    debugPrint('✅ Vosk model extraction complete');

    return modelPath;
  }

  // ── Extraction ─────────────────────────────────────────────────────────────
  static Future<void> _extractModel(Directory targetDir) async {
    await targetDir.create(recursive: true);

    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest =
        jsonDecode(manifestContent) as Map<String, dynamic>;

    final modelAssets = manifest.keys
        .where((key) => key.startsWith(_modelAssetDir))
        .toList();

    if (modelAssets.isEmpty) {
      throw Exception(
        'ModelUnpacker: No assets found under $_modelAssetDir. '
        'Check pubspec.yaml assets declaration.',
      );
    }

    for (final assetPath in modelAssets) {
      await _extractAsset(assetPath, targetDir);
    }
  }

  static Future<void> _extractAsset(
      String assetPath, Directory targetDir) async {
    try {
      final data         = await rootBundle.load(assetPath);
      final bytes        = data.buffer.asUint8List();
      final relativePath = assetPath.replaceFirst('$_modelAssetDir/', '');
      final outFile      = File(p.join(targetDir.path, relativePath));

      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(bytes, flush: true);
    } catch (e) {
      debugPrint('⚠️ ModelUnpacker: failed to extract "$assetPath": $e');
    }
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  static Future<bool> _isModelComplete(Directory dir) async {
    try {
      final contents = await dir.list().toList();
      return contents.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Clean up ───────────────────────────────────────────────────────────────
  static Future<void> clearExtractedModel() async {
    final appDir    = await getApplicationDocumentsDirectory();
    final modelPath = p.join(appDir.path, _modelOutputDir);
    final modelDir  = Directory(modelPath);

    if (await modelDir.exists()) {
      await modelDir.delete(recursive: true);
      debugPrint('🧹 Vosk model cache cleared');
    }
  }
}