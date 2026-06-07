import 'dart:io';
import 'package:jb_music/core/utils/lrc_parser.dart';
import 'package:jb_music/domain/entities/lyric_line.dart';

class LyricsFileManager {
  /// Swaps the extension of an audio file path to check for and load an accompanying .lrc file
  static Future<List<LyricLine>> fetchLocalLyrics(String audioPath) async {
    try {
      final int lastDotIndex = audioPath.lastIndexOf('.');
      if (lastDotIndex == -1) return [];

      final String expectedLrcPath = '${audioPath.substring(0, lastDotIndex)}.lrc';
      final File lrcFile = File(expectedLrcPath);

      if (await lrcFile.exists()) {
        final String contents = await lrcFile.readAsString();
        return LrcParser.parse(contents);
      }
    } catch (_) {
      // Return empty array gracefully if disk parsing blocks
    }
    return [];
  }
}