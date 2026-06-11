// lib/core/ai/smart_queue.dart
// JB Music — Smart Queue Engine
// Play Next, Play Later, Queue reorder, Skip ahead, Clear queue.
// Integrates with BLoC via events. Persists queue across app restarts.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jb_music/domain/entities/jb_song.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QUEUE ITEM — wraps a song with its queue origin
// ─────────────────────────────────────────────────────────────────────────────

enum QueueSource { manual, aiDj, athlete, mood, history }

class QueueItem {
  final JBSong song;
  final QueueSource source;
  final DateTime addedAt;

  const QueueItem({
    required this.song,
    required this.source,
    required this.addedAt,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SMART QUEUE
// ─────────────────────────────────────────────────────────────────────────────

class JBSmartQueue {
  static const _prefsKey = 'jb_smart_queue';

  final List<QueueItem> _items = [];
  List<QueueItem> get items => List.unmodifiable(_items);
  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;

  // Called when queue changes (BLoC listens)
  VoidCallback? onQueueChanged;

  // ── Play Next ──────────────────────────────────────────────────────────────
  // Inserts song at front of queue — plays immediately after current song.

  void playNext(JBSong song, {QueueSource source = QueueSource.manual}) {
    // Remove if already queued to avoid duplicates
    _items.removeWhere((item) => item.song.id == song.id);
    _items.insert(0, QueueItem(song: song, source: source, addedAt: DateTime.now()));
    debugPrint('▶️ Play Next: ${song.title}');
    _notify();
  }

  // ── Add to Queue (Play Later) ──────────────────────────────────────────────

  void addToQueue(JBSong song, {QueueSource source = QueueSource.manual}) {
    // Avoid duplicates
    if (_items.any((item) => item.song.id == song.id)) return;
    _items.add(QueueItem(song: song, source: source, addedAt: DateTime.now()));
    debugPrint('➕ Queued: ${song.title}');
    _notify();
  }

  // ── Add multiple (from AI DJ / Athlete / Mood) ────────────────────────────

  void addAll(List<JBSong> songs, {QueueSource source = QueueSource.aiDj}) {
    final existing = _items.map((i) => i.song.id).toSet();
    for (final song in songs) {
      if (!existing.contains(song.id)) {
        _items.add(QueueItem(song: song, source: source, addedAt: DateTime.now()));
      }
    }
    debugPrint('🎵 Queue filled: ${_items.length} tracks');
    _notify();
  }

  // ── Remove ─────────────────────────────────────────────────────────────────

  void remove(String songId) {
    _items.removeWhere((item) => item.song.id == songId);
    _notify();
  }

  // ── Reorder (drag and drop) ────────────────────────────────────────────────

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _items.length) return;
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = _items.removeAt(oldIndex);
    _items.insert(adjusted.clamp(0, _items.length), item);
    debugPrint('🔀 Reordered: ${item.song.title} → position $adjusted');
    _notify();
  }

  // ── Consume (called when a track starts playing) ───────────────────────────

  JBSong? consumeNext() {
    if (_items.isEmpty) return null;
    final item = _items.removeAt(0);
    _notify();
    return item.song;
  }

  // ── Peek ──────────────────────────────────────────────────────────────────

  JBSong? peek() => _items.isEmpty ? null : _items.first.song;

  // ── Clear ─────────────────────────────────────────────────────────────────

  void clear() {
    _items.clear();
    _notify();
  }

  // ── Clear AI-generated items only ─────────────────────────────────────────

  void clearAiItems() {
    _items.removeWhere((item) =>
        item.source == QueueSource.aiDj ||
        item.source == QueueSource.mood ||
        item.source == QueueSource.athlete);
    _notify();
  }

  // ── Move to top ───────────────────────────────────────────────────────────

  void moveToTop(String songId) {
    final idx = _items.indexWhere((item) => item.song.id == songId);
    if (idx <= 0) return;
    final item = _items.removeAt(idx);
    _items.insert(0, item);
    _notify();
  }

  // ── Shuffle remaining ─────────────────────────────────────────────────────

  void shuffleRemaining() {
    if (_items.length <= 1) return;
    // Keep first item in place (currently "next up"), shuffle the rest
    final rest = _items.sublist(1)..shuffle();
    _items
      ..removeRange(1, _items.length)
      ..addAll(rest);
    _notify();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store as JSON array of song IDs + titles (enough to restore display)
      final data = _items.map((item) => {
        'id':     item.song.id,
        'title':  item.song.title,
        'artist': item.song.artist,
        'path':   item.song.path,
        'src':    item.source.index,
      }).toList();
      await prefs.setString(_prefsKey, json.encode(data));
    } catch (e) {
      debugPrint('⚠️ Queue persist error: $e');
    }
  }

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final data = json.decode(raw) as List<dynamic>;
      _items.clear();
      for (final entry in data) {
        final map = entry as Map<String, dynamic>;
        final song = JBSong(
          id:         map['id'] as String,
          title:      map['title'] as String,
          artist:     map['artist'] as String,
          album:      '',
          path:       map['path'] as String,
          durationMs: 0,
          format:     null,
        );
        final srcIdx = (map['src'] as int? ?? 0)
            .clamp(0, QueueSource.values.length - 1);
        _items.add(QueueItem(
          song:    song,
          source:  QueueSource.values[srcIdx],
          addedAt: DateTime.now(),
        ));
      }
      debugPrint('📂 Queue restored: ${_items.length} tracks');
      _notify();
    } catch (e) {
      debugPrint('⚠️ Queue restore error: $e');
    }
  }

  void _notify() {
    onQueueChanged?.call();
    persist();
  }
}
