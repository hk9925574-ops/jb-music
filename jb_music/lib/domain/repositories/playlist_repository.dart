import 'package:jb_music/domain/entities/playlist_model.dart';

abstract class PlaylistRepository {
  Future<List<PlaylistModel>> fetchAllPlaylists();
  Future<void> savePlaylist(PlaylistModel playlist);
  Future<void> addTrackToPlaylist(String playlistName, String trackId);
  Future<void> removeTrackFromPlaylist(String playlistName, String trackId);
  Future<void> deletePlaylist(String playlistName);
}