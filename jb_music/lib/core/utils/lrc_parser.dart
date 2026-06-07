import 'package:jb_music/domain/entities/lyric_line.dart';

class LrcParser {
  /// Transforms raw LRC string data into a sorted chronological array of timestamped lines
  static List<LyricLine> parse(String lrcContent) {
    final List<LyricLine> lines = [];
    final RegExp regExp = RegExp(r'\[(\d+):(\d+)\.(\d+)\](.*)');

    for (String line in lrcContent.split('\n')) {
      final match = regExp.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!) * 10; // Convert xx to ms
        final text = match.group(4)!.trim();

        final duration = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        lines.add(LyricLine(timeStamp: duration, text: text));
      }
    }
    
    // Sort chronologically by time placement
    lines.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
    return lines;
  }
}