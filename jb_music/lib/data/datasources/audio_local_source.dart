import 'package:on_audio_query/on_audio_query.dart';
import 'package:jb_music/domain/entities/jb_song.dart';

class AudioLocalSource {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<List<JBSong>> fetchAllSongs() async {
    List<SongModel> songs = await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    return songs.map((song) => JBSong.fromAudioQuery(song)).toList();
  }
}