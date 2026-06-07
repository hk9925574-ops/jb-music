// Domain-level SongModel used by MusicBloc and MusicTracksLoadedState.
// Kept separate from JBSong (which is the raw on_audio_query mapping).
class SongModel {
  final String id;
  final String title;
  final String path;
  final String artist;

  const SongModel({
    required this.id,
    required this.title,
    required this.path,
    this.artist = 'Unknown Artist',
  });

  factory SongModel.fromJBSong(dynamic song) {
    return SongModel(
      id: song.id,
      title: song.title,
      path: song.path,
      artist: song.artist ?? 'Unknown Artist',
    );
  }
}
