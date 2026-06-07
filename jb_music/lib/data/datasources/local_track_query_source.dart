// lib/data/datasources/local_track_query_source.dart
import 'package:jb_music/data/datasources/audio_local_source.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/domain/repositories/audio_repository.dart';

class LocalTrackQuerySource implements AudioRepository {
  final AudioLocalSource _localSource = AudioLocalSource();

  @override
  Future<List<JBSong>> fetchTracks() async {
    return await _localSource.fetchAllSongs();
  }
}