// lib/domain/entities/voice_intent.dart

enum JbVoiceAction {
  // Playback
  play,
  pause,
  togglePlayPause,
  next,
  previous,
  shuffle,
  repeat,
  // Volume
  volumeUp,
  volumeDown,
  // Search
  searchSong,       // payload: songQuery
  playSong,         // payload: songQuery (search + immediately play)
  // Playlist
  playPlaylist,     // payload: playlistName
  // Timer
  setSleepTimer,    // payload: minutes (as string)
  cancelSleepTimer,
  // Safety
  checkSafety,
  // Unknown
  unknown,
}

class VoiceCommandIntent {
  final JbVoiceAction action;
  final String        rawUtterance;
  final String?       matchedPhrase;
  final double        confidenceScore;
  final String?       payload; // e.g. song name, playlist name, timer minutes

  const VoiceCommandIntent({
    required this.action,
    required this.rawUtterance,
    this.matchedPhrase,
    required this.confidenceScore,
    this.payload,
  });

  bool get isHighConfidence => confidenceScore >= 0.7;

  @override
  String toString() =>
      'VoiceCommandIntent(action: ${action.name}, '
      'payload: "$payload", '
      'phrase: "$matchedPhrase", '
      'confidence: ${confidenceScore.toStringAsFixed(2)})';
}
