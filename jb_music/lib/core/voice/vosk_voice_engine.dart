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
            _isListening = false;
            // error_busy = recognizer not released yet; wait longer
            final delay = error.errorMsg == 'error_busy'
                ? const Duration(milliseconds: 1200)
                : const Duration(milliseconds: 600);
            _scheduleRestart(delay: delay);
          }
        },
        onStatus: (status) {
          debugPrint('🎤 Status: $status');
          if ((status == 'done' || status == 'notListening') &&
              _shouldListen) {
            _isListening = false;
            // Give Android time to fully release the recognizer
            _scheduleRestart(delay: const Duration(milliseconds: 800));
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

    // Force-stop any lingering session to avoid error_busy
    try { await _speech.stop(); } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 150));

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

      // FIX: use SpeechListenOptions instead of deprecated named params
      await _speech.listen(
        onResult: (result) {
          if (!result.finalResult) return;

          final text = result.recognizedWords.trim().toLowerCase();

          if (text.isEmpty) return;

          debugPrint('🎤 Heard: "$text"');

          _resultCtrl.add(text);

          final intent = _parseIntent(text);

          if (intent.action != JbVoiceAction.unknown) {
            debugPrint(
                '✅ Intent: ${intent.action} | payload: ${intent.payload}');
            _intentCtrl.add(intent);
          } else {
            debugPrint('❓ No intent matched for: "$text"');
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(milliseconds: 500),
          partialResults: false,
          cancelOnError: false,
          // FIX: use search mode — optimised for short commands, not long dictation
          listenMode: stt.ListenMode.search,
        ),
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
  VoiceCommandIntent _parseIntent(String raw) {
    // ── STEP 1: strip wake words + punctuation FIRST ──────────────────────
    // Remove "hey jb", "ok jb", "hey jb," (with optional comma/punctuation)
    // Also strips standalone "jb" prefix like "jb play something"
    final cleaned = raw
        .replaceAll(RegExp(r'\b(hey|ok|okay)\s+jb\b[,.]?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^jb\b[,.]?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'[,.]'), ' ')   // remove commas/dots
        .replaceAll(RegExp(r'\s+'), ' ')     // collapse spaces
        .trim();

    debugPrint('🔍 Cleaned: "$cleaned"');

    // ── SLEEP TIMER ──────────────────────────────────────────────────────
    final timerRegex = RegExp(
      r'(set.*(timer|sleep)|sleep.*(in|after|for)|stop.*(in|after)|timer).*?(\d+)\s*(min|minute|minutes|m\b)',
      caseSensitive: false,
    );

    final timerMatch = timerRegex.firstMatch(cleaned);
    if (timerMatch != null) {
      // Extract the number from the utterance
      final numMatch = RegExp(r'(\d+)').firstMatch(cleaned);
      final finalMins = numMatch?.group(1) ?? '30';
      return VoiceCommandIntent(
        action: JbVoiceAction.setSleepTimer,
        rawUtterance: cleaned,
        matchedPhrase: timerMatch.group(0),
        confidenceScore: 1.0,
        payload: finalMins,
      );
    }

    if (_contains(cleaned, ['cancel timer', 'stop timer', 'no timer', 'turn off timer'])) {
      return _intent(JbVoiceAction.cancelSleepTimer, cleaned, cleaned);
    }

    // ── SHUFFLE ──────────────────────────────────────────────────────────
    if (_contains(cleaned, ['shuffle'])) {
      return _intent(JbVoiceAction.shuffle, cleaned, 'shuffle');
    }

    // ── REPEAT ───────────────────────────────────────────────────────────
    if (_contains(cleaned, ['repeat', 'loop'])) {
      return _intent(JbVoiceAction.repeat, cleaned, 'repeat');
    }

    // ── VOLUME ───────────────────────────────────────────────────────────
    if (_contains(cleaned, ['volume up', 'turn up', 'louder', 'increase volume'])) {
      return _intent(JbVoiceAction.volumeUp, cleaned, 'volume up');
    }
    if (_contains(cleaned, ['volume down', 'turn down', 'quieter', 'lower volume', 'decrease volume'])) {
      return _intent(JbVoiceAction.volumeDown, cleaned, 'volume down');
    }

    // ── EAR SAFETY ───────────────────────────────────────────────────────
    if (_contains(cleaned, ['ear safety', 'check safety', 'hearing', 'volume safe'])) {
      return _intent(JbVoiceAction.checkSafety, cleaned, 'check safety');
    }

    // ── PLAY SONG (must come before generic "play") ───────────────────────
    // Matches: "play [song/track] <name>", "play me <name>", "i want to hear <name>", "put on <name>"
    final playSongRegex = RegExp(
      r'^(?:play(?:\s+(?:the\s+)?(?:song|track|music))?\s+(.+)|'
      r'(?:play\s+me|i\s+want\s+to\s+(?:hear|listen\s+to)|put\s+on)\s+(.+))$',
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

    // ── SEARCH ───────────────────────────────────────────────────────────
    final searchRegex = RegExp(
      r'^(?:search(?:\s+for)?|find|look\s+for|show\s+me)\s+(.+)$',
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

    // ── PLAYLIST ─────────────────────────────────────────────────────────
    if (cleaned.contains('playlist')) {
      final playlistRegex = RegExp(
        r'(?:play(?:list)?|open|switch\s+to|go\s+to)\s+(?:playlist\s+)?(.+)',
        caseSensitive: false,
      );
      final playlistMatch = playlistRegex.firstMatch(cleaned);
      if (playlistMatch != null) {
        // Remove trailing "playlist" word if user said "play my chill playlist"
        final name = (playlistMatch.group(1) ?? '')
            .replaceAll(RegExp(r'\bplaylist\b', caseSensitive: false), '')
            .trim();
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
    }

    // ── BASIC CONTROLS (last resort — after all payload-bearing checks) ──
    if (_contains(cleaned, ['pause', 'stop music', 'stop playing'])) {
      return _intent(JbVoiceAction.pause, cleaned, 'pause');
    }

    if (_contains(cleaned, ['next', 'skip', 'next song', 'next track'])) {
      return _intent(JbVoiceAction.next, cleaned, 'next');
    }

    if (_contains(cleaned, ['previous', 'back', 'last song', 'go back'])) {
      return _intent(JbVoiceAction.previous, cleaned, 'previous');
    }

    if (_contains(cleaned, ['play', 'start', 'resume', 'continue'])) {
      return _intent(JbVoiceAction.play, cleaned, 'play');
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

  bool _isStopword(String q) {
    const stopwords = {
      'music', 'something', 'a song', 'anything', 'song', 'track',
      'me', 'it', 'this', 'that',
    };
    return stopwords.contains(q.trim().toLowerCase());
  }

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