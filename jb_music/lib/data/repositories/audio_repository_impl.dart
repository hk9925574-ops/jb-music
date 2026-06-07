import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/domain/repositories/audio_repository.dart';
import 'package:jb_music/data/datasources/audio_local_source.dart';

class AudioRepositoryImpl implements AudioRepository {
  final AudioLocalSource localSource;

  AudioRepositoryImpl({required this.localSource});

  @override
  Future<List<JBSong>> fetchTracks() async {
    // FIX: Was calling queryDeviceAudioTracks() which doesn't exist.
    // AudioLocalSource exposes fetchAllSongs() which already returns List<JBSong>.
    return await localSource.fetchAllSongs();
  }
}
