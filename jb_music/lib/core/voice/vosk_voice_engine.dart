// lib/core/voice/vosk_voice_engine.dart
// Powerful voice command engine — play/pause, search by name,
// playlist control, sleep timer, volume, shuffle, repeat.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:jb_music/domain/entities/voice_intent.dart';

class VoskVoiceEngine {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Timer? _restartTimer;
  Timer? _sessionTimer;

  final StreamController<VoiceCommandIntent> _intentCtrl =
      StreamController<VoiceCommandIntent>.broadcast();

  final StreamController<String> _resultCtrl =
      StreamController<String>.broadcast();

  Stream<VoiceCommandIntent> get commandIntentStream => _intentCtrl.stream;
  Stream<String> get resultStream => _resultCtrl.stream;

  bool _isInitialized = false;
  bool _isListening = false;
  bool _shouldListen = false;

  bool get isReady => _isInitialized;
  bool get isListening => _isListening;

  // ─────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────
  Future<void> initializeVoicePipeline() async {
    if (_isInitialized) return;

    try {
      debugPrint('🎤 Initializing voice engine...');

      final available = await _speech.initialize(
        onError: (error) {
          debugPrint('⚠️ Voice error: ${error.errorMsg}');
          _isListening = false;
          if (!error.permanent && _shouldListen) {
            _scheduleRestart();
          }
        },
        onStatus: (status) {
          debugPrint('🎤 Status: $status');
          if ((status == 'done' || status == 'notListening') &&
              _shouldListen) {
            _isListening = false;
            _scheduleRestart(delay: const Duration(milliseconds: 300));
          }
        },
      );

      _isInitialized = available;
      debugPrint(available
          ? '✅ Voice engine ready'
          : '❌ Voice engine not available');
    } catch (e) {
      debugPrint('❌ Voice init error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // START LISTENING
  // ─────────────────────────────────────────────────────────────
  Future<void> startListening() async {
    if (!_isInitialized) await initializeVoicePipeline();
    if (!_isInitialized) return;

    _shouldListen = true;
    await _startSession();
  }

  Future<void> _startSession() async {
    if (_isListening || !_shouldListen) return;

    _restartTimer?.cancel();

    try {
      _isListening = true;

      _sessionTimer?.cancel();
      _sessionTimer = Timer(const Duration(seconds: 30), () {
        if (_shouldListen) {
          _speech.stop().then((_) {
            _isListening = false;
            _scheduleRestart(delay: const Duration(milliseconds: 200));
          });
        }
      });

      await _speech.listen(
        onResult: (result) {
          if (!result.finalResult) return;

          final text =
              result.recognizedWords.trim().toLowerCase();

          if (text.isEmpty) return;

          debugPrint('🎤 Heard: "$text"');

          _resultCtrl.add(text);

          final intent = _parseIntent(text);

          if (intent.action != JbVoiceAction.unknown) {
            debugPrint(
                '✅ Intent: ${intent.action} | payload: ${intent.payload}');
            _intentCtrl.add(intent);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      );
    } catch (e) {
      debugPrint('❌ Session error: $e');
      _isListening = false;
      _scheduleRestart();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // RESTART HANDLER
  // ─────────────────────────────────────────────────────────────
  void _scheduleRestart({Duration delay = const Duration(seconds: 1)}) {
    _restartTimer?.cancel();
    _restartTimer = Timer(delay, () {
      if (_shouldListen && !_isListening) {
        _startSession();
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // STOP LISTENING
  // ─────────────────────────────────────────────────────────────
  Future<void> stopListening() async {
    _shouldListen = false;

    _restartTimer?.cancel();
    _sessionTimer?.cancel();

    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
    } catch (e) {
      debugPrint('⚠️ Stop error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // INTENT PARSER
  // ─────────────────────────────────────────────────────────────
  VoiceCommandIntent _parseIntent(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'\bhey\s+jb\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bjb\b', caseSensitive: false), '')
        .trim();

    // ── SLEEP TIMER ──
    final timerRegex = RegExp(
      r'(set.*(timer|sleep)|sleep.*(in|after|for)|stop.*(in|after)|timer)\s+(\d+)\s*(min|minute|minutes|m\b)',
      caseSensitive: false,
    );

    final timerMatch = timerRegex.firstMatch(cleaned);

    if (timerMatch != null) {
      final numMatch =
          RegExp(r'(\d+)').firstMatch(cleaned.substring(timerMatch.start));

      final mins = numMatch?.group(1) ?? '30';

      return VoiceCommandIntent(
        action: JbVoiceAction.setSleepTimer,
        rawUtterance: cleaned,
        matchedPhrase: timerMatch.group(0),
        confidenceScore: 1.0,
        payload: mins,
      );
    }

    if (_contains(cleaned, ['cancel timer', 'stop timer', 'no timer'])) {
      return _intent(JbVoiceAction.cancelSleepTimer, cleaned, cleaned);
    }

    // ── PLAY SONG ──
    final playSongRegex = RegExp(
      r'(?:play(?:\s+(?:the\s+)?(?:song|track|music))?)\s+(.+)|'
      r'(?:i want to (?:hear|listen to)|put on|play me)\s+(.+)',
      caseSensitive: false,
    );

    final playMatch = playSongRegex.firstMatch(cleaned);

    if (playMatch != null) {
      final query =
          (playMatch.group(1) ?? playMatch.group(2) ?? '').trim();

      if (query.isNotEmpty && !_isStopword(query)) {
        return VoiceCommandIntent(
          action: JbVoiceAction.playSong,
          rawUtterance: cleaned,
          matchedPhrase: playMatch.group(0),
          confidenceScore: 0.95,
          payload: query,
        );
      }
    }

    // ── SEARCH ──
    final searchRegex = RegExp(
      r'(?:search(?:\s+for)?|find|look for|show me)\s+(.+)',
      caseSensitive: false,
    );

    final searchMatch = searchRegex.firstMatch(cleaned);

    if (searchMatch != null) {
      final query = (searchMatch.group(1) ?? '').trim();

      if (query.isNotEmpty && !_isStopword(query)) {
        return VoiceCommandIntent(
          action: JbVoiceAction.searchSong,
          rawUtterance: cleaned,
          matchedPhrase: searchMatch.group(0),
          confidenceScore: 0.95,
          payload: query,
        );
      }
    }

    // ── PLAYLIST ──
    final playlistRegex = RegExp(
      r'(?:play(?:list)?|open|switch to|go to)\s+(?:playlist\s+)?(.+)',
      caseSensitive: false,
    );

    final playlistMatch = playlistRegex.firstMatch(cleaned);

    if (playlistMatch != null && cleaned.contains('playlist')) {
      final name = (playlistMatch.group(1) ?? '').trim();

      if (name.isNotEmpty) {
        return VoiceCommandIntent(
          action: JbVoiceAction.playPlaylist,
          rawUtterance: cleaned,
          matchedPhrase: playlistMatch.group(0),
          confidenceScore: 0.9,
          payload: name,
        );
      }
    }

    // ── BASIC CONTROLS ──
    if (_contains(cleaned, ['play', 'start', 'resume'])) {
      return _intent(JbVoiceAction.play, cleaned, 'play');
    }

    if (_contains(cleaned, ['pause', 'stop'])) {
      return _intent(JbVoiceAction.pause, cleaned, 'pause');
    }

    if (_contains(cleaned, ['next', 'skip'])) {
      return _intent(JbVoiceAction.next, cleaned, 'next');
    }

    if (_contains(cleaned, ['previous', 'back'])) {
      return _intent(JbVoiceAction.previous, cleaned, 'previous');
    }

    return VoiceCommandIntent(
      action: JbVoiceAction.unknown,
      rawUtterance: cleaned,
      confidenceScore: 0.0,
    );
  }

  // ─────────────────────────────────────────────────────────────
  bool _contains(String text, List<String> phrases) =>
      phrases.any((p) => text.contains(p));

  bool _isStopword(String q) =>
      ['music', 'something', 'a song', 'anything'].contains(q.trim());

  VoiceCommandIntent _intent(
    JbVoiceAction action,
    String text,
    String phrase, {
    String? payload,
  }) {
    return VoiceCommandIntent(
      action: action,
      rawUtterance: text,
      matchedPhrase: phrase,
      confidenceScore: 1.0,
      payload: payload,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    await stopListening();
    _restartTimer?.cancel();
    _sessionTimer?.cancel();
    await _intentCtrl.close();
    await _resultCtrl.close();
    _isInitialized = false;
  }
}