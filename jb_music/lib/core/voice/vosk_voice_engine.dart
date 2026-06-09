// lib/core/voice/vosk_voice_engine.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:jb_music/domain/entities/voice_intent.dart';
import 'package:jb_music/core/voice/model_unpacker.dart';

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

  final StreamController<VoiceCommandIntent> _intentCtrl =
      StreamController<VoiceCommandIntent>.broadcast();
  final StreamController<String> _resultCtrl =
      StreamController<String>.broadcast();

  Stream<VoiceCommandIntent> get commandIntentStream => _intentCtrl.stream;
  Stream<String>             get resultStream        => _resultCtrl.stream;

  bool _isInitialized  = false;
  bool _isListening    = false;
  bool _isInitializing = false;

  bool get isReady     => _isInitialized;
  bool get isListening => _isListening;

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> initializeVoicePipeline() async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;
    try {
      debugPrint('🎤 Initializing Vosk voice pipeline...');
      final modelPath = await ModelUnpacker.getExtractedModelPath();
      _acousticModel = await _vosk.createModel(modelPath);
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
      debugPrint('✅ Voice pipeline ready and listening');
    } catch (e, st) {
      debugPrint('❌ Voice pipeline init failed: $e\n$st');
      _isInitialized = false;
      Future.delayed(const Duration(seconds: 5), () {
        _isInitializing = false;
        initializeVoicePipeline();
      });
      return;
    }
    _isInitializing = false;
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

  void _attachListeners() {
    // FIX: onError() does not exist on SpeechService — handle errors via
    // the onError callback of the onResult() stream subscription instead.
    _speechService?.onResult().listen(
      (result) {
        try {
          final map = jsonDecode(result) as Map<String, dynamic>;
          final text = (map['text'] as String? ?? '').trim().toLowerCase();
          if (text.isNotEmpty) {
            debugPrint('🎤 Heard: "$text"');
            _resultCtrl.add(text);
            final intent = _parseIntent(text);
            if (intent.action != JbVoiceAction.unknown) {
              _intentCtrl.add(intent);
            }
          }
        } catch (e) {
          debugPrint('⚠️ Voice result parse error: $e');
        }
      },
      onError: (e) {
        debugPrint('❌ Voice result stream error: $e — restarting...');
        _scheduleRestart();
      },
      cancelOnError: false,
    );
  }

  void _scheduleRestart() {
    _isInitialized  = false;
    _isListening    = false;
    _isInitializing = false;
    _speechService  = null;
    _recognizer     = null;
    Future.delayed(const Duration(seconds: 3), initializeVoicePipeline);
  }

  VoiceCommandIntent _parseIntent(String text) {
    for (final entry in _kIntentMap.entries) {
      for (final phrase in entry.value) {
        if (text.contains(phrase)) {
          return VoiceCommandIntent(
            action:          entry.key,
            rawUtterance:    text,
            matchedPhrase:   phrase,
            confidenceScore: 1.0,
          );
        }
      }
    }
    return VoiceCommandIntent(
      action:          JbVoiceAction.unknown,
      rawUtterance:    text,
      confidenceScore: 0.0,
    );
  }

  // ── Start / Stop ───────────────────────────────────────────────────────────
  Future<void> startListening() async {
    if (!_isInitialized) {
      await initializeVoicePipeline();
      return;
    }
    if (_isListening) return;
    try {
      await _speechService?.start();
      _isListening = true;
      debugPrint('🎤 Voice listening started');
    } catch (e) {
      debugPrint('❌ Voice start error: $e');
      _scheduleRestart();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      await _speechService?.stop();
      _isListening = false;
      debugPrint('🎤 Voice listening stopped');
    } catch (e) {
      debugPrint('⚠️ Voice stop error: $e');
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    await stopListening();
    await _intentCtrl.close();
    await _resultCtrl.close();
    _speechService = null;
    _recognizer    = null;
    _acousticModel = null;
    _isInitialized = false;
  }
}