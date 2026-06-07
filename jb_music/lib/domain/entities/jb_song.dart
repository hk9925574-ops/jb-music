import 'package:on_audio_query/on_audio_query.dart';

class JBSong {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final int durationMs;
  final String? format;

  JBSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.durationMs,
    required this.format,
  });

  factory JBSong.fromAudioQuery(SongModel model) {
    return JBSong(
      id: model.id.toString(),
      title: _cleanTitle(model.title, model.data),
      artist: _cleanTag(model.artist),
      album: _cleanTag(model.album),
      path: model.data,
      durationMs: model.duration ?? 0,
      format: model.fileExtension,
    );
  }

  /// Cleans artist/album — handles "<unknown>", null, empty
  static String _cleanTag(String? value) {
    if (value == null) return 'Unknown';
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '<unknown>') return 'Unknown';
    return trimmed;
  }

  /// Cleans title — removes timestamp patterns from filenames
  /// e.g. "song_20231012_143022" → "song"
  static String _cleanTitle(String? title, String filePath) {
    if (title != null) {
      final trimmed = title.trim();
      if (trimmed.isNotEmpty && trimmed != '<unknown>') return trimmed;
    }
    // Fall back to filename without extension
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final withoutExt = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    // Strip trailing timestamp patterns like _20231012_143022
    return withoutExt
        .replaceAll(RegExp(r'_\d{8}_\d{6}$'), '')
        .replaceAll('_', ' ')
        .trim();
  }
}