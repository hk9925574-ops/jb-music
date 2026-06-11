// lib/core/ai/listening_stats.dart
// JB Music — Listening Statistics Engine
// Tracks: daily streaks, total listen time, top songs/artists,
// weekly wrapped report, milestones. 100% on-device.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jb_music/domain/entities/jb_song.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATS MODELS
// ─────────────────────────────────────────────────────────────────────────────

class SongStat {
  final JBSong song;
  int playCount;
  Duration totalListened;

  SongStat({
    required this.song,
    this.playCount = 0,
    this.totalListened = Duration.zero,
  });
}

class DailyRecord {
  final String date; // 'yyyy-MM-dd'
  Duration listened;
  int tracksPlayed;

  DailyRecord({
    required this.date,
    this.listened = Duration.zero,
    this.tracksPlayed = 0,
  });
}

class Milestone {
  final String id;
  final String title;
  final String description;
  final bool achieved;
  final DateTime? achievedAt;

  const Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.achieved,
    this.achievedAt,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS ENGINE
// ─────────────────────────────────────────────────────────────────────────────

class JBListeningStats {
  static const _prefsKey    = 'jb_stats_v2';
  static const _dailyKey    = 'jb_daily_records';
  static const _milestonesKey = 'jb_milestones';

  // Song-level stats
  final Map<String, SongStat> _songStats = {};

  // Daily records (last 90 days)
  final List<DailyRecord> _dailyRecords = [];

  // Achieved milestone IDs
  final Set<String> _achievedMilestones = {};

  // Callback for new milestone
  void Function(Milestone)? onMilestone;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadData();
  }

  // ── Record a play ──────────────────────────────────────────────────────────

  void recordPlay(JBSong song, Duration listenedDuration) {
    if (listenedDuration.inSeconds < 5) return; // ignore micro-plays

    // Song stat
    final stat = _songStats.putIfAbsent(
      song.id,
      () => SongStat(song: song),
    );
    stat.playCount++;
    stat.totalListened += listenedDuration;

    // Daily record
    final today = _todayKey();
    DailyRecord? record = _dailyRecords.isNotEmpty && _dailyRecords.last.date == today
        ? _dailyRecords.last
        : null;
    if (record == null) {
      record = DailyRecord(date: today);
      _dailyRecords.add(record);
      // Keep last 90 days
      if (_dailyRecords.length > 90) _dailyRecords.removeAt(0);
    }
    record.listened += listenedDuration;
    record.tracksPlayed++;

    _checkMilestones();
    _persist();
  }

  // ── Streak ────────────────────────────────────────────────────────────────

  int get currentStreak {
    if (_dailyRecords.isEmpty) return 0;

    int streak = 0;
    var checkDate = DateTime.now();

    for (int i = _dailyRecords.length - 1; i >= 0; i--) {
      final record = _dailyRecords[i];
      final expected = _dateKey(checkDate);

      if (record.date == expected && record.listened.inMinutes >= 1) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (record.date == _dateKey(checkDate.subtract(const Duration(days: 1)))) {
        // Allow gap of today (not yet listened today)
        break;
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Totals ─────────────────────────────────────────────────────────────────

  Duration get totalListenTime => _dailyRecords.fold(
        Duration.zero,
        (acc, r) => acc + r.listened,
      );

  Duration get thisWeekListenTime {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _dailyRecords
        .where((r) => DateTime.parse(r.date).isAfter(cutoff))
        .fold(Duration.zero, (acc, r) => acc + r.listened);
  }

  Duration get todayListenTime {
    final today = _todayKey();
    final record = _dailyRecords.where((r) => r.date == today).firstOrNull;
    return record?.listened ?? Duration.zero;
  }

  // ── Top songs ─────────────────────────────────────────────────────────────

  List<SongStat> get topSongs {
    final stats = _songStats.values.toList();
    stats.sort((a, b) => b.playCount.compareTo(a.playCount));
    return stats.take(10).toList();
  }

  // ── Top artists ───────────────────────────────────────────────────────────

  Map<String, int> get topArtists {
    final counts = <String, int>{};
    for (final stat in _songStats.values) {
      counts[stat.song.artist] = (counts[stat.song.artist] ?? 0) + stat.playCount;
    }
    final sorted = Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return Map.fromEntries(sorted.entries.take(5));
  }

  // ── Weekly Wrapped report ─────────────────────────────────────────────────

  Map<String, dynamic> weeklyWrapped() {
    final topSong = topSongs.isNotEmpty ? topSongs.first.song : null;
    final artists = topArtists;
    final topArtist = artists.isNotEmpty ? artists.keys.first : 'Unknown';

    return {
      'weekMinutes':  thisWeekListenTime.inMinutes,
      'streak':       currentStreak,
      'topSong':      topSong?.title ?? '—',
      'topArtist':    topArtist,
      'tracksPlayed': _dailyRecords
          .where((r) => DateTime.parse(r.date)
              .isAfter(DateTime.now().subtract(const Duration(days: 7))))
          .fold(0, (acc, r) => acc + r.tracksPlayed),
    };
  }

  // ── Milestones ────────────────────────────────────────────────────────────

  void _checkMilestones() {
    _tryMilestone(
      id:          'first_play',
      title:       'First Beat',
      description: 'Played your first track on JB Music.',
      condition:   totalListenTime.inSeconds > 0,
    );
    _tryMilestone(
      id:          'hour_1',
      title:       '1 Hour Club',
      description: 'Listened for 1 hour total.',
      condition:   totalListenTime.inHours >= 1,
    );
    _tryMilestone(
      id:          'hour_10',
      title:       '10 Hour Legend',
      description: 'Listened for 10 hours total.',
      condition:   totalListenTime.inHours >= 10,
    );
    _tryMilestone(
      id:          'streak_7',
      title:       'Week Warrior',
      description: '7-day listening streak.',
      condition:   currentStreak >= 7,
    );
    _tryMilestone(
      id:          'streak_30',
      title:       'Monthly Master',
      description: '30-day listening streak.',
      condition:   currentStreak >= 30,
    );
    _tryMilestone(
      id:          'songs_100',
      title:       'Century',
      description: 'Played 100 unique tracks.',
      condition:   _songStats.length >= 100,
    );
  }

  void _tryMilestone({
    required String id,
    required String title,
    required String description,
    required bool condition,
  }) {
    if (!_achievedMilestones.contains(id) && condition) {
      _achievedMilestones.add(id);
      final m = Milestone(
        id:          id,
        title:       title,
        description: description,
        achieved:    true,
        achievedAt:  DateTime.now(),
      );
      debugPrint('🏆 Milestone: $title');
      onMilestone?.call(m);
    }
  }

  List<Milestone> get allMilestones => [
    Milestone(id: 'first_play', title: 'First Beat',     description: 'Played your first track.',         achieved: _achievedMilestones.contains('first_play')),
    Milestone(id: 'hour_1',     title: '1 Hour Club',    description: 'Listened for 1 hour.',             achieved: _achievedMilestones.contains('hour_1')),
    Milestone(id: 'hour_10',    title: '10 Hour Legend', description: 'Listened for 10 hours.',           achieved: _achievedMilestones.contains('hour_10')),
    Milestone(id: 'streak_7',   title: 'Week Warrior',   description: '7-day streak.',                    achieved: _achievedMilestones.contains('streak_7')),
    Milestone(id: 'streak_30',  title: 'Monthly Master', description: '30-day streak.',                   achieved: _achievedMilestones.contains('streak_30')),
    Milestone(id: 'songs_100',  title: 'Century',        description: 'Played 100 unique tracks.',        achieved: _achievedMilestones.contains('songs_100')),
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _todayKey() => _dateKey(DateTime.now());
  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Song stats — store as map of songId → {plays, ms}
      final statsMap = Map.fromEntries(
        _songStats.entries.map((e) => MapEntry(e.key, {
          'plays': e.value.playCount,
          'ms':    e.value.totalListened.inMilliseconds,
          'title': e.value.song.title,
          'artist': e.value.song.artist,
          'path':   e.value.song.path,
        })),
      );
      await prefs.setString(_prefsKey, json.encode(statsMap));

      // Daily records
      final dailyList = _dailyRecords.map((r) => {
        'date': r.date,
        'ms':   r.listened.inMilliseconds,
        'tracks': r.tracksPlayed,
      }).toList();
      await prefs.setString(_dailyKey, json.encode(dailyList));

      // Milestones
      await prefs.setStringList(_milestonesKey, _achievedMilestones.toList());
    } catch (e) {
      debugPrint('⚠️ Stats persist error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final statsRaw = prefs.getString(_prefsKey);
      if (statsRaw != null) {
        final statsMap = json.decode(statsRaw) as Map<String, dynamic>;
        for (final entry in statsMap.entries) {
          final v = entry.value as Map<String, dynamic>;
          final song = JBSong(
            id:         entry.key,
            title:      v['title'] as String? ?? 'Unknown',
            artist:     v['artist'] as String? ?? 'Unknown',
            album:      '',
            path:       v['path'] as String? ?? '',
            durationMs: 0,
            format:     null,
          );
          _songStats[entry.key] = SongStat(
            song:          song,
            playCount:     (v['plays'] as int?) ?? 0,
            totalListened: Duration(milliseconds: (v['ms'] as int?) ?? 0),
          );
        }
      }

      final dailyRaw = prefs.getString(_dailyKey);
      if (dailyRaw != null) {
        final dailyList = json.decode(dailyRaw) as List<dynamic>;
        _dailyRecords.clear();
        for (final entry in dailyList) {
          final m = entry as Map<String, dynamic>;
          _dailyRecords.add(DailyRecord(
            date:         m['date'] as String,
            listened:     Duration(milliseconds: (m['ms'] as int?) ?? 0),
            tracksPlayed: (m['tracks'] as int?) ?? 0,
          ));
        }
      }

      final milestones = prefs.getStringList(_milestonesKey) ?? [];
      _achievedMilestones.addAll(milestones);

    } catch (e) {
      debugPrint('⚠️ Stats load error: $e');
    }
  }
}
