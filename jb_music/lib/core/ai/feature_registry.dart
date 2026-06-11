// lib/core/ai/feature_registry.dart
// JB Music — Feature Registry
// Single place to initialize and access all new AI/Audio engines.
// Wire this into your existing service_locator.dart or main.dart.
//
// USAGE in main.dart or service_locator.dart:
//   await JBFeatureRegistry.instance.init();
//
// Then access anywhere:
//   JBFeatureRegistry.instance.moodEngine
//   JBFeatureRegistry.instance.djEngine
//   JBFeatureRegistry.instance.athleteEngine
//   JBFeatureRegistry.instance.smartQueue
//   JBFeatureRegistry.instance.stats
//   JBFeatureRegistry.instance.crossfade
//   JBFeatureRegistry.instance.shakeDetector

import 'package:flutter/foundation.dart';
import 'package:jb_music/core/ai/mood_engine.dart';
import 'package:jb_music/core/ai/jb_dj.dart';
import 'package:jb_music/core/ai/smart_queue.dart';
import 'package:jb_music/core/ai/listening_stats.dart';
import 'package:jb_music/core/ai/shake_detector.dart';
import 'package:jb_music/core/athlete/athlete_engine.dart';
import 'package:jb_music/core/audio/crossfade_engine.dart';

class JBFeatureRegistry {
  JBFeatureRegistry._();
  static final JBFeatureRegistry instance = JBFeatureRegistry._();

  late final JBMoodEngine      moodEngine;
  late final JBDjEngine        djEngine;
  late final JBSmartQueue      smartQueue;
  late final JBListeningStats  stats;
  late final JBShakeDetector   shakeDetector;
  late final JBAthleteEngine   athleteEngine;
  late final JBCrossfadeEngine crossfade;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    debugPrint('🚀 JBFeatureRegistry: initializing...');

    // Mood engine (must come first — DJ depends on it)
    moodEngine = JBMoodEngine();
    await moodEngine.init();

    // AI DJ
    djEngine = JBDjEngine(moodEngine: moodEngine);
    await djEngine.init();

    // Smart Queue
    smartQueue = JBSmartQueue();
    await smartQueue.restore();

    // Listening Stats
    stats = JBListeningStats();
    await stats.init();

    // Athlete Engine
    athleteEngine = JBAthleteEngine();
    await athleteEngine.init();

    // Crossfade
    crossfade = JBCrossfadeEngine();
    await crossfade.init();

    // Shake Detector
    shakeDetector = JBShakeDetector();
    await shakeDetector.init();

    // Wire mood → DJ queue rebuild (mood changes trigger queue refresh)
    moodEngine.onMoodChanged = (mood) {
      debugPrint('🎭 Mood → DJ: rebuilding queue for ${mood.label}');
      // Queue rebuild happens when BLoC calls djEngine.buildQueue(...)
      // with the updated library — this just signals the change.
    };

    _initialized = true;
    debugPrint('✅ JBFeatureRegistry: all engines ready');
  }

  Future<void> dispose() async {
    djEngine.dispose();
    athleteEngine.dispose();
    crossfade.dispose();
    await shakeDetector.dispose();
  }
}
