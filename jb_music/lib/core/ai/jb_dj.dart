// lib/core/ai/jb_dj.dart
// JB Music — AI DJ Engine
// Auto-selects next track based on mood + history, crossfades between tracks,
// and optionally speaks a DJ announcement via TTS.
// Works fully offline. Plugs into existing JBDspEngine + VoskVoiceEngine.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/core/ai/mood_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DJ CONFIG
// ─────────────────────────────────────────────────────────────────────────────

class JBDjConfig {
  final bool enabled;
  final bool announcements;       // TTS "Next up…" announcements
  final Duration crossfadeDuration;
  final double announcementVolume; // 0.0–1.0
  final String djPersonality;     // 'hype', 'chill', 'informative'

  const JBDjConfig({
    this.enabled = true,
    this.announcements = true,
    this.crossfadeDuration = const Duration(seconds: 3),
    this.announcementVolume = 0.8,
    this.djPersonality = 'chill',
  });

  JBDjConfig copyWith({
    bool? enabled,
    bool? announcements,
    Duration? crossfadeDuration,
    double? announcementVolume,
    String? djPersonality,
  }) => JBDjConfig(
    enabled: enabled ?? this.enabled,
    announcements: announcements ?? this.announcements,
    crossfadeDuration: crossfadeDuration ?? this.crossfadeDuration,
    announcementVolume: announcementVolume ?? this.announcementVolume,
    djPersonality: djPersonality ?? this.djPersonality,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DJ ENGINE
// ─────────────────────────────────────────────────────────────────────────────

class JBDjEngine {
  final JBMoodEngine _moodEngine;
  final FlutterTts _tts = FlutterTts();

  JBDjConfig config;

  JBDjEngine({
    required JBMoodEngine moodEngine,
    JBDjConfig? config,
  })  : _moodEngine = moodEngine,
        config = config ?? const JBDjConfig();

  // Queue of upcoming tracks (pre-computed)
  final List<JBSong> _upcomingQueue = [];
  List<JBSong> get upcomingQueue => List.unmodifiable(_upcomingQueue);

  bool _ttsReady = false;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(config.djPersonality == 'hype' ? 1.1 : 0.95);
    await _tts.setVolume(config.announcementVolume);
    _ttsReady = true;
  }

  // ── Queue building ─────────────────────────────────────────────────────────

  /// Call this whenever the track library or mood changes.
  /// Fills the upcoming queue with 10 mood-optimized tracks.
  void buildQueue(
    List<JBSong> library,
    Map<String, int> playCount,
    List<JBSong> likedSongs,
    JBSong? currentSong,
  ) {
    final filtered = _moodEngine.filterForMood(library, playCount, likedSongs);

    // Remove current song from queue
    final available = currentSong == null
        ? filtered
        : filtered.where((s) => s.id != currentSong.id).toList();

    _upcomingQueue
      ..clear()
      ..addAll(available.take(10));

    debugPrint('🎧 DJ queue rebuilt: ${_upcomingQueue.length} tracks '
        '| mood: ${_moodEngine.currentMood.label}');
  }

  // ── Next track selection ───────────────────────────────────────────────────

  /// Returns the next song to play. Removes it from queue and refills if low.
  JBSong? pickNext(
    List<JBSong> library,
    Map<String, int> playCount,
    List<JBSong> likedSongs,
    JBSong? currentSong,
  ) {
    if (_upcomingQueue.isEmpty) {
      buildQueue(library, playCount, likedSongs, currentSong);
    }
    if (_upcomingQueue.isEmpty) return null;

    final next = _upcomingQueue.removeAt(0);

    // Refill when queue drops below 3
    if (_upcomingQueue.length < 3) {
      buildQueue(library, playCount, likedSongs, next);
    }

    return next;
  }

  // ── TTS Announcement ───────────────────────────────────────────────────────

  Future<void> announceTrack(JBSong song) async {
    if (!config.announcements || !_ttsReady || !config.enabled) return;

    final line = _buildAnnouncementLine(song);
    debugPrint('📢 DJ: "$line"');

    try {
      await _tts.speak(line);
    } catch (e) {
      debugPrint('⚠️ TTS announcement failed: $e');
    }
  }

  String _buildAnnouncementLine(JBSong song) {
    final mood = _moodEngine.currentMood;
    final rng = math.Random();

    switch (config.djPersonality) {
      case 'hype':
        final hypes = [
          'LET\'S GO! Next up — ${song.title} by ${song.artist}!',
          'Keep the energy HIGH! ${song.title} is coming at you!',
          'YOU\'RE ON FIRE! Here\'s ${song.title}!',
        ];
        return hypes[rng.nextInt(hypes.length)];

      case 'informative':
        return 'Next track — ${song.title} by ${song.artist}, '
            'from the album ${song.album}.';

      case 'chill':
      default:
        final chills = [
          'Next up… ${song.title}.',
          'Keeping it ${mood.label.toLowerCase()}… ${song.title} by ${song.artist}.',
          'Here\'s one for the ${mood.label.toLowerCase()} vibes — ${song.title}.',
          '${song.title} by ${song.artist}, coming up.',
        ];
        return chills[rng.nextInt(chills.length)];
    }
  }

  // ── Crossfade timer ────────────────────────────────────────────────────────
  // Returns a stream that ticks every 100ms from 0.0 to 1.0 over the
  // configured crossfade duration. Callers use this to fade out old track
  // and fade in new track simultaneously.

  Stream<double> crossfadeStream() {
    final steps = config.crossfadeDuration.inMilliseconds ~/ 100;
    int tick = 0;
    late StreamController<double> ctrl;
    ctrl = StreamController<double>(
      onListen: () {
        Timer.periodic(const Duration(milliseconds: 100), (t) {
          tick++;
          final progress = tick / steps;
          ctrl.add(progress.clamp(0.0, 1.0));
          if (progress >= 1.0) {
            t.cancel();
            ctrl.close();
          }
        });
      },
    );
    return ctrl.stream;
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _tts.stop();
  }
}
