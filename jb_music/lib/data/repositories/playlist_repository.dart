// lib/domain/repositories/playlist_repository.dart
import 'package:jb_music/domain/entities/playlist_model.dart';

abstract class PlaylistRepository {
  /// Fetch all saved playlists
  Future<List<PlaylistModel>> fetchAllPlaylists();

  /// Save or update a playlist (upsert by id)
  Future<void> savePlaylist(PlaylistModel playlist);

  /// Add a track to a playlist by name
  Future<void> addTrackToPlaylist(String playlistName, String trackId);

  /// Remove a track from a playlist by name
  Future<void> removeTrackFromPlaylist(String playlistName, String trackId);

  /// Delete an entire playlist by name
  Future<void> deletePlaylist(String playlistName);
}