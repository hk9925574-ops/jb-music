// lib/data/repositories/local_playlist_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jb_music/domain/entities/playlist_model.dart';
import 'package:jb_music/domain/repositories/playlist_repository.dart';

class LocalPlaylistRepository implements PlaylistRepository {
  static const String _kKey = 'jb_music_local_playlists';

  // ── Cache ──────────────────────────────────────────────────────────────────
  // Keeps playlists in memory so repeated reads don't hit SharedPreferences
  List<PlaylistModel>? _cache;

  // ── Read ───────────────────────────────────────────────────────────────────
  @override
  Future<List<PlaylistModel>> fetchAllPlaylists() async {
    if (_cache != null) return List.from(_cache!);

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw) as List<dynamic>;
      _cache = decoded
          .map((item) => PlaylistModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return List.from(_cache!);
    } catch (e) {
      debugPrint('⚠️ fetchAllPlaylists error: $e');
      return [];
    }
  }

  // ── Save / upsert ──────────────────────────────────────────────────────────
  @override
  Future<void> savePlaylist(PlaylistModel playlist) async {
    final list = await fetchAllPlaylists();
    final idx  = list.indexWhere((p) => p.id == playlist.id);
    if (idx != -1) {
      list[idx] = playlist;
    } else {
      list.add(playlist);
    }
    await _persist(list);
    debugPrint('💾 Playlist saved: "${playlist.name}"');
  }

  // ── Add track ──────────────────────────────────────────────────────────────
  @override
  Future<void> addTrackToPlaylist(String playlistName, String trackId) async {
    final list = await fetchAllPlaylists();
    final idx  = list.indexWhere((p) => p.name == playlistName);
    if (idx == -1) {
      debugPrint('⚠️ addTrack: playlist "$playlistName" not found');
      return;
    }

    // Prevent duplicate track entries
    if (list[idx].trackIds.contains(trackId)) {
      debugPrint('⚠️ Track $trackId already in "$playlistName"');
      return;
    }

    list[idx] = list[idx].copyWith(
      trackIds: [...list[idx].trackIds, trackId],
    );
    await _persist(list);
    debugPrint('➕ Track $trackId added to "$playlistName"');
  }

  // ── Remove track ───────────────────────────────────────────────────────────
  @override
  Future<void> removeTrackFromPlaylist(
      String playlistName, String trackId) async {
    final list = await fetchAllPlaylists();
    final idx  = list.indexWhere((p) => p.name == playlistName);
    if (idx == -1) return;

    list[idx] = list[idx].copyWith(
      trackIds: list[idx].trackIds.where((id) => id != trackId).toList(),
    );
    await _persist(list);
    debugPrint('➖ Track $trackId removed from "$playlistName"');
  }

  // ── Reorder tracks ─────────────────────────────────────────────────────────
  Future<void> reorderTracks(
      String playlistName, int oldIndex, int newIndex) async {
    final list = await fetchAllPlaylists();
    final idx  = list.indexWhere((p) => p.name == playlistName);
    if (idx == -1) return;

    final trackIds = List<String>.from(list[idx].trackIds);
    final item     = trackIds.removeAt(oldIndex);
    trackIds.insert(newIndex, item);

    list[idx] = list[idx].copyWith(trackIds: trackIds);
    await _persist(list);
  }

  // ── Rename playlist ────────────────────────────────────────────────────────
  Future<void> renamePlaylist(String oldName, String newName) async {
    final list = await fetchAllPlaylists();
    final idx  = list.indexWhere((p) => p.name == oldName);
    if (idx == -1) return;

    // Check new name not already taken
    if (list.any((p) => p.name == newName)) {
      debugPrint('⚠️ Playlist "$newName" already exists');
      return;
    }

    list[idx] = list[idx].copyWith(name: newName);
    await _persist(list);
    debugPrint('✏️ Playlist renamed: "$oldName" → "$newName"');
  }

  // ── Delete playlist ────────────────────────────────────────────────────────
  @override
  Future<void> deletePlaylist(String playlistName) async {
    final list = await fetchAllPlaylists();
    list.removeWhere((p) => p.name == playlistName);
    await _persist(list);
    debugPrint('🗑️ Playlist deleted: "$playlistName"');
  }

  // ── Check existence ────────────────────────────────────────────────────────
  Future<bool> playlistExists(String name) async {
    final list = await fetchAllPlaylists();
    return list.any((p) => p.name == name);
  }

  // ── Persist ────────────────────────────────────────────────────────────────
  Future<void> _persist(List<PlaylistModel> list) async {
    _cache = List.from(list); // update cache
    try {
      final prefs      = await SharedPreferences.getInstance();
      final serialized = jsonEncode(list.map((p) => p.toJson()).toList());
      await prefs.setString(_kKey, serialized);
    } catch (e) {
      debugPrint('❌ Playlist persist error: $e');
    }
  }

  // ── Clear cache (call if you suspect stale data) ───────────────────────────
  void invalidateCache() => _cache = null;
}