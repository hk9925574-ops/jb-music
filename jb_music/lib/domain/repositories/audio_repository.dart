// lib/domain/repositories/audio_repository.dart
import 'package:jb_music/domain/entities/jb_song.dart';

abstract class AudioRepository {
  /// Fetch all audio tracks from the device
  Future<List<JBSong>> fetchTracks();
}