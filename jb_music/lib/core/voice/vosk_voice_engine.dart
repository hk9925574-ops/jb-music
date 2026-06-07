// lib/core/voice/vosk_voice_engine.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:jb_music/domain/entities/voice_intent.dart';
import 'package:jb_music/core/voice/model_unpacker.dart';

// ── Intent map ────────────────────────────────────────────────────────────────
// Each action maps to a list of trigger phrases (ordered by priority)
const _kIntentMap = <JbVoiceAction, List<String>>{
  JbVoiceAction.play:        ['play', 'start', 'resume', 'continue'],
  JbVoiceAction.pause:       ['pause', 'stop', 'hold', 'wait'],
  JbVoiceAction.next:        ['next', 'skip', 'forward'],
  JbVoiceAction.previous:    ['previous', 'back', 'before', 'rewind'],
  JbVoiceAction.checkSafety: ['safe', 'safety', 'status', 'volume check'],
  JbVoiceAction.volumeUp:    ['louder', 'volume up', 'increase volume'],
  JbVoiceAction.volumeDown:  ['quieter', 'volume down', 'decrease volume', 'lower'],
  JbVoiceAction.shuffle:     ['shuffle', 'random', 'mix'],
  JbVoiceAction.repeat:      ['repeat', 'loop', 'again'],
};

// ── Voice engine ──────────────────────────────────────────────────────────────
class VoskVoiceEngine {
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();

  Model?         _acousticModel;
  Recognizer?    _recognizer;
  SpeechService? _speechService;

  final StreamController<VoiceCommandIntent> _intentController =
      StreamController<VoiceCommandIntent>.broadcast();

  Stream<VoiceCommandIntent> get commandIntentStream => _intentController.stream;

  bool _isInitialized = false;
  bool _isListening   = false;

  bool get isReady     => _isInitialized;
  bool get isListening => _isListening;

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> initializeVoicePipeline() async {
    if (_isInitialized) return;

    try {
      debugPrint('🎤 Initializing Vosk voice pipeline...');

      final modelPath = await ModelUnpacker.getExtractedModelPath();
      _acousticModel  = await _vosk.createModel(modelPath);

      _recognizer = await _vosk.createRecognizer(
        model: _acousticModel!,
        sampleRate: 16000,
        grammar: _buildGrammar(),
      );

      _speechService = await _vosk.initSpeechService(_recognizer!);
      _isInitialized = true;

      await _startListening();

      debugPrint('✅ Voice pipeline ready');
    } catch (e, st) {
      debugPrint('❌ Voice pipeline init failed: $e');
      debugPrint(st.toString());
      // Don't rethrow — voice is non-critical, app should still work
    }
  }

  /// Builds a flat grammar list from all intent phrases
  List<String> _buildGrammar() {
    final words = <String>{};
    for (final phrases in _kIntentMap.values) {
      for (final phrase in phrases) {
        words.addAll(phrase.split(' '));
      }
    }
    return words.toList();
  }

  // ── Listening control ──────────────────────────────────────────────────────
  Future<void> _startListening() async {
    if (_speechService == null || _isListening) return;
    try {
      await _speechService!.start();
      _isListening = true;

      _speechService!.onPartial().listen(
        (p) => _processUtterance(p, isPartial: true),
        onError: (e) => debugPrint('⚠️ Voice partial stream error: $e'),
      );

      _speechService!.onResult().listen(
        (r) => _processUtterance(r, isPartial: false),
        onError: (e) => debugPrint('⚠️ Voice result stream error: $e'),
      );
    } catch (e) {
      debugPrint('❌ Failed to start speech service: $e');
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      await _speechService?.stop();
      _isListening = false;
      debugPrint('🎤 Voice listening stopped');
    } catch (e) {
      debugPrint('⚠️ stopListening error: $e');
    }
  }

  Future<void> resumeListening() async {
    if (_isListening || !_isInitialized) return;
    await _startListening();
    debugPrint('🎤 Voice listening resumed');
  }

  // ── Intent parsing ─────────────────────────────────────────────────────────
  void _processUtterance(String jsonString, {required bool isPartial}) {
    if (jsonString.trim().isEmpty) return;

    try {
      final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
      final text   = ((isPartial ? parsed['partial'] : parsed['text']) as String? ?? '').trim();

      if (text.isEmpty) return;

      final lower  = text.toLowerCase();
      final result = _matchIntent(lower);

      if (result != null) {
        debugPrint('🎙️ Voice intent: ${result.action.name} '
            '(confidence: ${result.confidenceScore.toStringAsFixed(2)}) '
            '— "$lower"${isPartial ? " [partial]" : ""}');

        // Only emit finals, or partials for time-sensitive actions
        if (!isPartial || _isTimeSensitive(result.action)) {
          _intentController.add(result);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Voice parse error: $e');
    }
  }

  /// Matches text against intent map, returns best match with confidence
  VoiceCommandIntent? _matchIntent(String text) {
    JbVoiceAction? bestAction;
    double         bestScore = 0.0;
    String?        matchedPhrase;

    for (final entry in _kIntentMap.entries) {
      for (int i = 0; i < entry.value.length; i++) {
        final phrase = entry.value[i];
        if (text.contains(phrase)) {
          // Score = phrase relevance × position weight (earlier = higher priority)
          final positionWeight = 1.0 - (i * 0.05);
          final lengthBonus    = phrase.split(' ').length > 1 ? 0.1 : 0.0;
          final score          = positionWeight + lengthBonus;

          if (score > bestScore) {
            bestScore     = score;
            bestAction    = entry.key;
            matchedPhrase = phrase;
          }
        }
      }
    }

    if (bestAction == null) return null;

    return VoiceCommandIntent(
      action:          bestAction,
      rawUtterance:    text,
      matchedPhrase:   matchedPhrase,
      confidenceScore: bestScore.clamp(0.0, 1.0),
    );
  }

  /// Time-sensitive actions should be emitted on partial results too
  bool _isTimeSensitive(JbVoiceAction action) => switch (action) {
        JbVoiceAction.pause    => true,
        JbVoiceAction.next     => true,
        JbVoiceAction.previous => true,
        _                      => false,
      };

  // ── Dispose ────────────────────────────────────────────────────────────────
  void dispose() {
    _speechService?.dispose();
    _recognizer?.dispose();
    _acousticModel?.dispose();
    _intentController.close();
    _isInitialized = false;
    _isListening   = false;
    debugPrint('🧹 Voice engine disposed');
  }
}