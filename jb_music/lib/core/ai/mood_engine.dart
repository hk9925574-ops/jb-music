// lib/core/ai/mood_engine.dart
// JB Music — AI Mood Engine
// Detects user emotional state from listening patterns, time of day,
// skip behaviour, replay count and adapts EQ + playlist in real time.
// No external API required — runs fully on-device.

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/core/audio/dsp_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOOD MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum JBMood {
  energetic,   // high BPM, low skips, gym/workout
  focused,     // steady mid-tempo, few skips, long session
  melancholic, // slow, high replays, night time
  happy,       // varied, few replays, morning/afternoon
  relaxed,     // slow, minimal skips, evening
  unknown,
}

extension JBMoodLabel on JBMood {
  String get label => switch (this) {
        JBMood.energetic   => 'Energetic',
        JBMood.focused     => 'Focused',
        JBMood.melancholic => 'Melancholic',
        JBMood.happy       => 'Happy',
        JBMood.relaxed     => 'Relaxed',
        JBMood.unknown     => 'Discovering…',
      };

  String get emoji => switch (this) {
        JBMood.energetic   => '⚡',
        JBMood.focused     => '🎯',
        JBMood.melancholic => '🌧️',
        JBMood.happy       => '😊',
        JBMood.relaxed     => '🌙',
        JBMood.unknown     => '🎵',
      };

  // Maps mood → best EQ preset
  EqPreset get eqPreset => switch (this) {
        JBMood.energetic   => EqPreset.electronic,
        JBMood.focused     => EqPreset.flat,
        JBMood.melancholic => EqPreset.vocal,
        JBMood.happy       => EqPreset.pop,
        JBMood.relaxed     => EqPreset.classical,
        JBMood.unknown     => EqPreset.flat,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// SESSION SIGNAL — collected per song play
// ─────────────────────────────────────────────────────────────────────────────

class SessionSignal {
  final JBSong song;
  final Duration listenedDuration;  // how long user actually listened
  final bool skipped;               // user skipped before 80%
  final bool replayed;              // user replayed within same session
  final DateTime timestamp;

  const SessionSignal({
    required this.song,
    required this.listenedDuration,
    required this.skipped,
    required this.replayed,
    required this.timestamp,
  });

  // Completion ratio: 0.0 – 1.0
  double get completionRatio {
    if (song.durationMs == 0) return 0;
    return (listenedDuration.inMilliseconds / song.durationMs).clamp(0.0, 1.0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOOD ENGINE
// ─────────────────────────────────────────────────────────────────────────────

class JBMoodEngine {
  static const _prefsKey = 'jb_mood_signals';
  static const _maxSignals = 30; // rolling window

  final List<SessionSignal> _signals = [];
  JBMood _currentMood = JBMood.unknown;
  JBMood get currentMood => _currentMood;

  // Callback fires whenever mood changes
  ValueChanged<JBMood>? onMoodChanged;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadSignals();
    _recompute();
  }

  // ── Signal intake ──────────────────────────────────────────────────────────

  void recordSignal(SessionSignal signal) {
    _signals.add(signal);
    if (_signals.length > _maxSignals) _signals.removeAt(0);
    _saveSignals();
    _recompute();
  }

  // ── Core inference ─────────────────────────────────────────────────────────

  void _recompute() {
    if (_signals.isEmpty) {
      _emit(JBMood.unknown);
      return;
    }

    final recent = _signals.length > 10
        ? _signals.sublist(_signals.length - 10)
        : _signals;

    final skipRate  = recent.where((s) => s.skipped).length / recent.length;
    final replayRate = recent.where((s) => s.replayed).length / recent.length;
    final avgCompletion = recent.map((s) => s.completionRatio).reduce((a, b) => a + b) / recent.length;

    // Time of day signal
    final hour = DateTime.now().hour;
    final isNight    = hour >= 22 || hour < 6;
    final isMorning  = hour >= 6 && hour < 12;
    final isEvening  = hour >= 18 && hour < 22;

    // Session duration signal — long session = focused
    final sessionStart = recent.first.timestamp;
    final sessionMins = DateTime.now().difference(sessionStart).inMinutes;

    JBMood mood;

    if (skipRate < 0.15 && avgCompletion > 0.85 && sessionMins > 20) {
      // Few skips, long session, high completion → focused
      mood = isMorning ? JBMood.happy : JBMood.focused;
    } else if (skipRate < 0.2 && replayRate > 0.3) {
      // Low skips + high replays → very engaged, energetic or melancholic
      mood = isNight ? JBMood.melancholic : JBMood.energetic;
    } else if (skipRate > 0.5) {
      // Many skips → browsing, searching for energy or mood
      mood = JBMood.happy;
    } else if (isNight && avgCompletion > 0.7) {
      mood = JBMood.melancholic;
    } else if (isEvening && skipRate < 0.3) {
      mood = JBMood.relaxed;
    } else {
      mood = JBMood.happy;
    }

    _emit(mood);
  }

  void _emit(JBMood mood) {
    if (_currentMood != mood) {
      _currentMood = mood;
      debugPrint('🎭 Mood changed → ${mood.label}');
      onMoodChanged?.call(mood);
    }
  }

  // ── Persistence (lightweight — just skip/replay booleans + timestamps) ─────

  Future<void> _saveSignals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store as compact CSV: "songId,skipBool,replayBool,completionInt,epoch"
      final rows = _signals.map((s) =>
        '${s.song.id},${s.skipped ? 1 : 0},${s.replayed ? 1 : 0},'
        '${(s.completionRatio * 100).round()},${s.timestamp.millisecondsSinceEpoch}'
      ).toList();
      await prefs.setStringList(_prefsKey, rows);
    } catch (_) {}
  }

  Future<void> _loadSignals() async {
    // We can't reconstruct full JBSong from prefs without the track library,
    // so we only restore the numeric signals for mood recomputation as a
    // lightweight proxy object.
    // In production, inject the track repository here.
    _signals.clear(); // cold start is fine — repopulates quickly during session
  }

  // ── Playlist filter ────────────────────────────────────────────────────────
  // Returns the best-fit songs from a library for the current mood.
  // Uses playCount + like status as proxies for user preference per mood.

  List<JBSong> filterForMood(
    List<JBSong> library,
    Map<String, int> playCount,
    List<JBSong> likedSongs,
  ) {
    final likedIds = likedSongs.map((s) => s.id).toSet();

    // Score each song
    final scored = library.map((song) {
      double score = 0;
      final plays = playCount[song.id] ?? 0;

      // Play count contribution
      score += math.min(plays * 0.3, 5.0);

      // Liked bonus
      if (likedIds.contains(song.id)) score += 3.0;

      // Mood-based title/artist heuristics (very lightweight)
      final combined = '${song.title} ${song.artist}'.toLowerCase();
      score += _moodTitleScore(combined, _currentMood);

      return MapEntry(song, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    // Return top 30 shuffled slightly for discovery
    final top = scored.take(30).map((e) => e.key).toList();
    top.shuffle(math.Random());
    return top;
  }

  double _moodTitleScore(String text, JBMood mood) {
    const keywords = <JBMood, List<String>>{
      JBMood.energetic:   ['energy', 'power', 'fire', 'run', 'pump', 'boost', 'beast'],
      JBMood.focused:     ['focus', 'deep', 'work', 'mind', 'flow', 'zone'],
      JBMood.melancholic: ['rain', 'alone', 'miss', 'heart', 'tears', 'gone', 'night'],
      JBMood.happy:       ['happy', 'love', 'dance', 'good', 'bright', 'sun', 'joy'],
      JBMood.relaxed:     ['chill', 'calm', 'peace', 'sleep', 'soft', 'gentle', 'slow'],
    };
    final words = keywords[mood] ?? [];
    return words.where((w) => text.contains(w)).length * 1.5;
  }
}
