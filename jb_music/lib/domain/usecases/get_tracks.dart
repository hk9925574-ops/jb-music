// lib/domain/usecases/get_tracks.dart
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/domain/repositories/audio_repository.dart';

class GetTracks {
  final AudioRepository repository;

  const GetTracks({required this.repository});

  /// Fetch and return all tracks, sorted by title A→Z
  Future<List<JBSong>> call() async {
    final tracks = await repository.fetchTracks();

    // Filter out tracks with no duration (corrupt/unreadable files)
    final valid = tracks.where((t) => t.durationMs > 0).toList();

    // Sort alphabetically by title
    valid.sort((a, b) =>
        a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return valid;
  }
}