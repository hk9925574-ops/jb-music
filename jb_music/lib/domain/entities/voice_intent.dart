// lib/domain/entities/voice_intent.dart

enum JbVoiceAction {
  play,
  pause,
  next,
  previous,
  checkSafety,
  volumeUp,
  volumeDown,
  shuffle,
  repeat,
  unknown,
}

class VoiceCommandIntent {
  final JbVoiceAction action;
  final String        rawUtterance;
  final String?       matchedPhrase;
  final double        confidenceScore;

  const VoiceCommandIntent({
    required this.action,
    required this.rawUtterance,
    this.matchedPhrase,
    required this.confidenceScore,
  });

  bool get isHighConfidence => confidenceScore >= 0.8;

  @override
  String toString() =>
      'VoiceCommandIntent(action: ${action.name}, '
      'phrase: "$matchedPhrase", '
      'confidence: ${confidenceScore.toStringAsFixed(2)})';
}