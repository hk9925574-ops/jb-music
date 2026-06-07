// lib/core/voice/vosk_voice_engine.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:jb_music/domain/entities/voice_intent.dart';
import 'package:jb_music/core/voice/model_unpacker.dart';

// ── Intent map ────────────────────────────────────────────────────────────────
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

class VoskVoiceEngine {
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();

  Model?         _acousticModel;
  Recognizer?    _recognizer;
  SpeechService? _speechService;

  // ── Two streams:
  //    commandIntentStream — structured VoiceCommandIntent (used by MusicBloc)
  //    resultStream        — raw recognised text strings (used by SettingsScreen test)
  final StreamController<VoiceCommandIntent> _intentCtrl =
      StreamController<VoiceCommandIntent>.broadcast();
  final StreamController<String> _resultCtrl =
      StreamController<String>.broadcast();

  Stream<VoiceCommandIntent> get commandIntentStream => _intentCtrl.stream;

  /// Raw recognised text — use this for UI feedback (e.g. "Heard: next song")
  Stream<String> get resultStream => _resultCtrl.stream;

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
       _attachListeners();
      await _speechService!.start();
      _isListening = true;
      debugPrint('✅ Voice pipeline ready');
    } catch (e, st) {
      debugPrint('❌ Voice pipeline init failed: $e\n$st');
      // Non-critical — app continues without voice
    }
  }

  List<String> _buildGrammar() {
    final words = <String>{};
    for (final phrases in _kIntentMap.values) {
      for (final phrase in phrases) {
        words.addAll(phrase.split(' '));
      }
    }
    return words.toList();
  }

  // ── Start listening (also called from MusicBloc via StartVoiceListeningEvent) ─
  Future<void> startListening() async {
    if (_isListening) return;
    if (!_isInitialized) {
      await initializeVoicePipeline();
      return; // initializeVoicePipeline already starts listening
    }
    try {
       _attachListeners();
      await _speechService!.start();
      _isListening = true;
      debugPrint('🎤 Voice listening started');
    } catch (e) {
      debugPrint('❌ startListening error: $e');
      rethrow;
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
    await startListening();
  }

  void _attachListeners() {
    _speechService!.onPartial().listen(
      (p) => _processUtterance(p, isPartial: true),
      onError: (e) => debugPrint('⚠️ Voice partial error: $e'),
    );
    _speechService!.onResult().listen(
      (r) => _processUtterance(r, isPartial: false),
      onError: (e) => debugPrint('⚠️ Voice result error: $e'),
    );
  }

  // ── Intent parsing ─────────────────────────────────────────────────────────
  void _processUtterance(String jsonString, {required bool isPartial}) {
    if (jsonString.trim().isEmpty) return;
    try {
      final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
      final text = ((isPartial
                  ? parsed['partial']
                  : parsed['text']) as String? ??
              '')
          .trim()
          .toLowerCase();

      if (text.isEmpty) return;
       debugPrint('VOICE RAW: $text');
      // Always emit raw text to resultStream (for UI feedback)
      if (!isPartial) {
        _resultCtrl.add(text);
      }

      // Match and emit intent
      final intent = _matchIntent(text);
      if (intent != null) {
        debugPrint(
            '🎙️ Voice intent: ${intent.action.name} '
            '(${intent.confidenceScore.toStringAsFixed(2)}) — "$text"'
            '${isPartial ? " [partial]" : ""}');
        if (!isPartial || _isTimeSensitive(intent.action)) {
          _intentCtrl.add(intent);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Voice parse error: $e');
    }
  }

  VoiceCommandIntent? _matchIntent(String text) {
    JbVoiceAction? bestAction;
    double         bestScore = 0.0;
    String?        matchedPhrase;

    for (final entry in _kIntentMap.entries) {
      for (int i = 0; i < entry.value.length; i++) {
        final phrase = entry.value[i];
        if (text.contains(phrase)) {
          final score =
              (1.0 - i * 0.05) + (phrase.split(' ').length > 1 ? 0.1 : 0.0);
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
    _intentCtrl.close();
    _resultCtrl.close();
    _isInitialized = false;
    _isListening   = false;
    debugPrint('🧹 Voice engine disposed');
  }
}