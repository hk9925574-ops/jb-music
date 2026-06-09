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
  Stream<String>             get resultStream        => _resultCtrl.stream;

  bool _isInitialized = false;
  bool _isListening   = false;
  bool _shouldListen  = false;

  bool get isReady     => _isInitialized;
  bool get isListening => _isListening;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> initializeVoicePipeline() async {
    if (_isInitialized) return;
    try {
      debugPrint('🎤 Initializing voice engine...');
      final available = await _speech.initialize(
        onError: (error) {
          debugPrint('⚠️ Voice error: ${error.errorMsg}');
          _isListening = false;
          if (!error.permanent && _shouldListen) _scheduleRestart();
        },
        onStatus: (status) {
          debugPrint('🎤 Status: $status');
          if ((status == 'done' || status == 'notListening') && _shouldListen) {
            _isListening = false;
            _scheduleRestart(delay: const Duration(milliseconds: 300));
          }
        },
      );
      _isInitialized = available;
      debugPrint(available ? '✅ Voice engine ready' : '❌ Not available');
    } catch (e) {
      debugPrint('❌ Voice init error: $e');
    }
  }

  // ── Start / Stop ──────────────────────────────────────────────────────────
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
          final text = result.recognizedWords.trim().toLowerCase();
          if (text.isEmpty) return;
          debugPrint('🎤 Heard: "$text"');
          _resultCtrl.add(text);
          final intent = _parseIntent(text);
          if (intent.action != JbVoiceAction.unknown) {
            debugPrint('✅ Intent: ${intent.action} | payload: "${intent.payload}"');
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

  void _scheduleRestart({Duration delay = const Duration(seconds: 1)}) {
    _restartTimer?.cancel();
    _restartTimer = Timer(delay, () {
      if (_shouldListen && !_isListening) _startSession();
    });
  }

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

  // ── Intent Parser ─────────────────────────────────────────────────────────
  VoiceCommandIntent _parseIntent(String text) {

    // ── SLEEP TIMER ───────────────────────────────────────────────────────
    // "set timer 30 minutes", "sleep in 20 minutes", "stop after 45 minutes"
    final timerRegex = RegExp(
      r'(set.*(timer|sleep)|sleep.*(in|after|for)|stop.*(in|after)|timer)\s+(\d+)\s*(min|minute|minutes|m\b)',
      caseSensitive: false,
    );
    final timerMatch = timerRegex.firstMatch(text);
    if (timerMatch != null) {
      final minutes = timerMatch.group(5) ?? timerMatch.group(6) ?? '';
      // extract the number
      final numMatch = RegExp(r'(\d+)').firstMatch(text.substring(timerMatch.start));
      final mins = numMatch?.group(1) ?? '30';
      return VoiceCommandIntent(
        action: JbVoiceAction.setSleepTimer,
        rawUtterance: text,
        matchedPhrase: timerMatch.group(0),
        confidenceScore: 1.0,
        payload: mins,
      );
    }
    // "cancel timer", "stop timer", "no timer"
    if (_contains(text, ['cancel timer', 'stop timer', 'no timer', 'remove timer', 'disable timer'])) {
      return _intent(JbVoiceAction.cancelSleepTimer, text, text);
    }

    // ── PLAY SONG BY NAME ────────────────────────────────────────────────
    // "play [song name]", "play the song [name]", "I want to hear [name]"
    final playSongRegex = RegExp(
      r'(?:play(?:\s+(?:the\s+)?(?:song|track|music))?)\s+(.+)|'
      r'(?:i want to (?:hear|listen to)|put on|play me)\s+(.+)',
      caseSensitive: false,
    );
    final playSongMatch = playSongRegex.firstMatch(text);
    if (playSongMatch != null) {
      final query = (playSongMatch.group(1) ?? playSongMatch.group(2) ?? '').trim();
      // Make sure it's not a bare "play" command
      if (query.isNotEmpty && !_isStopword(query)) {
        return VoiceCommandIntent(
          action: JbVoiceAction.playSong,
          rawUtterance: text,
          matchedPhrase: playSongMatch.group(0),
          confidenceScore: 0.95,
          payload: query,
        );
      }
    }

    // ── SEARCH SONG ───────────────────────────────────────────────────────
    // "search [name]", "find [name]", "look for [name]"
    final searchRegex = RegExp(
      r'(?:search(?:\s+for)?|find|look for|show me)\s+(.+)',
      caseSensitive: false,
    );
    final searchMatch = searchRegex.firstMatch(text);
    if (searchMatch != null) {
      final query = (searchMatch.group(1) ?? '').trim();
      if (query.isNotEmpty && !_isStopword(query)) {
        return VoiceCommandIntent(
          action: JbVoiceAction.searchSong,
          rawUtterance: text,
          matchedPhrase: searchMatch.group(0),
          confidenceScore: 0.95,
          payload: query,
        );
      }
    }

    // ── PLAY PLAYLIST ─────────────────────────────────────────────────────
    // "play playlist [name]", "open playlist [name]", "switch to [name]"
    final playlistRegex = RegExp(
      r'(?:play(?:list)?|open|switch to|go to)\s+(?:playlist\s+)?(.+)',
      caseSensitive: false,
    );
    final playlistMatch = playlistRegex.firstMatch(text);
    if (playlistMatch != null && text.contains('playlist')) {
      final name = (playlistMatch.group(1) ?? '').trim();
      if (name.isNotEmpty) {
        return VoiceCommandIntent(
          action: JbVoiceAction.playPlaylist,
          rawUtterance: text,
          matchedPhrase: playlistMatch.group(0),
          confidenceScore: 0.9,
          payload: name,
        );
      }
    }

    // ── PLAY / PAUSE ──────────────────────────────────────────────────────
    if (_contains(text, ['play', 'start', 'resume', 'continue', 'unpause', 'let it play', 'hit play', 'go'])) {
      return _intent(JbVoiceAction.play, text, 'play');
    }
    if (_contains(text, ['pause', 'stop', 'hold on', 'wait', 'halt', 'freeze', 'hold it'])) {
      return _intent(JbVoiceAction.pause, text, 'pause');
    }

    // ── NEXT / PREVIOUS ──────────────────────────────────────────────────
    if (_contains(text, ['next', 'skip', 'forward', 'next song', 'next track', 'skip this', 'change song', 'another one'])) {
      return _intent(JbVoiceAction.next, text, 'next');
    }
    if (_contains(text, ['previous', 'back', 'go back', 'last song', 'rewind', 'before', 'play again'])) {
      return _intent(JbVoiceAction.previous, text, 'previous');
    }

    // ── VOLUME ────────────────────────────────────────────────────────────
    if (_contains(text, ['volume up', 'louder', 'increase volume', 'turn it up', 'crank it up', 'turn up', 'more volume', 'boost'])) {
      return _intent(JbVoiceAction.volumeUp, text, 'volume up');
    }
    if (_contains(text, ['volume down', 'quieter', 'lower', 'turn it down', 'decrease volume', 'softer', 'turn down', 'less volume'])) {
      return _intent(JbVoiceAction.volumeDown, text, 'volume down');
    }

    // ── SHUFFLE / REPEAT ─────────────────────────────────────────────────
    if (_contains(text, ['shuffle', 'random', 'mix', 'mix it up', 'randomize', 'surprise me'])) {
      return _intent(JbVoiceAction.shuffle, text, 'shuffle');
    }
    if (_contains(text, ['repeat', 'loop', 'again', 'repeat this', 'loop this', 'on repeat'])) {
      return _intent(JbVoiceAction.repeat, text, 'repeat');
    }

    // ── SAFETY ───────────────────────────────────────────────────────────
    if (_contains(text, ['safety', 'safe', 'ear check', 'how loud', 'volume check', 'is it safe'])) {
      return _intent(JbVoiceAction.checkSafety, text, 'safety');
    }

    return VoiceCommandIntent(
      action: JbVoiceAction.unknown,
      rawUtterance: text,
      confidenceScore: 0.0,
    );
  }

  bool _contains(String text, List<String> phrases) =>
      phrases.any((p) => text.contains(p));

  bool _isStopword(String q) =>
      ['music', 'something', 'a song', 'anything'].contains(q.trim());

  VoiceCommandIntent _intent(JbVoiceAction action, String text, String phrase,
      {String? payload}) =>
      VoiceCommandIntent(
        action: action,
        rawUtterance: text,
        matchedPhrase: phrase,
        confidenceScore: 1.0,
        payload: payload,
      );

  // ── Dispose ───────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    await stopListening();
    _restartTimer?.cancel();
    _sessionTimer?.cancel();
    await _intentCtrl.close();
    await _resultCtrl.close();
    _isInitialized = false;
  }
}
