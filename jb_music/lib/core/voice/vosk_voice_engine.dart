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

  // FIX #7: Keep listenFor / sessionTimer in sync — single source of truth.
  static const Duration _listenFor = Duration(seconds: 8);
  static const Duration _pauseFor = Duration(seconds: 2);
  // Session timer fires slightly after listenFor to let the plugin fire
  // its own done/notListening status first, avoiding a double-stop race.
  static const Duration _sessionTimeout = Duration(milliseconds: 8500);

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
            // error_busy = recognizer not released yet; wait longer.
            final delay = error.errorMsg == 'error_busy'
                ? const Duration(milliseconds: 1200)
                : const Duration(milliseconds: 600);
            _scheduleRestart(delay: delay);
          }
        },
        onStatus: (status) {
          debugPrint(
            'STATUS => $status | listening=$_isListening | shouldListen=$_shouldListen',
          );

          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _sessionTimer?.cancel(); // FIX #2: always cancel on done
            if (_shouldListen) {
              _scheduleRestart(delay: const Duration(milliseconds: 800));
            }
          }
        },
      );

      debugPrint('SPEECH AVAILABLE = $available');

      final locales = await _speech.locales();
      debugPrint('AVAILABLE LOCALES = ${locales.length}');

      _isInitialized = available;
      debugPrint(
        available ? '✅ Voice engine ready' : '❌ Voice engine not available',
      );
    } catch (e) {
      debugPrint('❌ Voice init error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // START LISTENING
  // ─────────────────────────────────────────────────────────────
  Future<void> startListening() async {
    if (_shouldListen) return;

    debugPrint('🎤 START LISTENING');

    if (!_isInitialized) await initializeVoicePipeline();
    if (!_isInitialized) return;

    _shouldListen = true;
    await _startSession();
  }

  Future<void> _startSession() async {
    if (_isListening || !_shouldListen) return;

    _restartTimer?.cancel();

    // Force-stop any lingering session to avoid error_busy.
    try {
      await _speech.stop();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 150));

    // Guard again — stopListening() might have been called during the delay.
    if (!_shouldListen) return;

    try {
      // FIX #1: set _isListening = true ONLY after listen() succeeds, not before.
      // We use a local flag to track the attempt.

      _sessionTimer?.cancel();
      _sessionTimer = Timer(_sessionTimeout, () {
        // FIX #7: fires at 8500 ms, after the plugin's own listenFor (8000 ms),
        // so this is a safety net, not the primary stop path.
        if (_shouldListen && _isListening) {
          debugPrint('⏱️ Session timeout — restarting');
          _speech.stop().then((_) {
            _isListening = false;
            _scheduleRestart(delay: const Duration(milliseconds: 200));
          });
        }
      });

      debugPrint('🎤 Calling speech.listen()');

      await _speech.listen(
        onResult: (result) {
          debugPrint(
            'WORDS=${result.recognizedWords} FINAL=${result.finalResult}',
          );

          if (result.recognizedWords.trim().isEmpty) return;

          final text = result.recognizedWords.trim().toLowerCase();
          debugPrint('PROCESSING => $text');

          // Always emit raw text so the UI can show live feedback.
          _resultCtrl.add(text);

          // FIX #4: Only parse intent on final results, not partials.
          // Parsing mid-word causes wrong song names / false positives.
          if (!result.finalResult) return;

          final intent = _parseIntent(text);

          if (intent.action != JbVoiceAction.unknown) {
            debugPrint(
              '✅ Intent: ${intent.action} | payload: ${intent.payload}',
            );
            _intentCtrl.add(intent);

            // Stop listening after a recognized command.
            Future.microtask(() async {
              await stopListening();
            });
          } else {
            debugPrint('❓ No intent matched for: "$text"');
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: _listenFor,
          pauseFor: _pauseFor,
          partialResults: true, // keep true for live UI feedback
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
        ),
      );

      // FIX #1: mark listening only after listen() returns without throwing.
      _isListening = true;
      debugPrint('🎤 speech.listen() started');
    } catch (e) {
      debugPrint('❌ Session error: $e');
      _isListening = false;
      _sessionTimer?.cancel();

      if (_shouldListen) {
        _scheduleRestart();
      }
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

    // FIX #3: cancel timers BEFORE the early return so they never fire late.
    _restartTimer?.cancel();
    _sessionTimer?.cancel();

    if (!_isListening) return;

    try {
      _isListening = false;
      await _speech.stop();
    } catch (e) {
      debugPrint('⚠️ Stop error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // INTENT PARSER
  // ─────────────────────────────────────────────────────────────
  VoiceCommandIntent _parseIntent(String raw) {
    // ── STEP 1: strip wake words + punctuation ─────────────────────────────
    // FIX #8: broader wake-word regex — handles "hey jb,", "okay jb.", "jb,"
    // mid-sentence and at any position before the command.
    final cleaned = raw
        .replaceAll(
          RegExp(
            r'\b(hey|ok|okay)\s+jb\b[,.]?\s*',
            caseSensitive: false,
          ),
          '',
        )
        // Handles bare "jb" prefix anywhere it appears before the command,
        // not just at the start of the string (e.g. "play jb shuffle").
        .replaceAll(
          RegExp(r'\bjb\b[,.]?\s*', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'[,.]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    debugPrint('🔍 Cleaned: "$cleaned"');

    // ── SLEEP TIMER ────────────────────────────────────────────────────────
    final timerRegex = RegExp(
      r'(set.*(timer|sleep)|sleep.*(in|after|for)|stop.*(in|after)|timer)'
      r'.*?(\d+)\s*(min|minute|minutes|m\b)',
      caseSensitive: false,
    );

    final timerMatch = timerRegex.firstMatch(cleaned);
    if (timerMatch != null) {
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

    if (_containsPhrase(
      cleaned,
      ['cancel timer', 'stop timer', 'no timer', 'turn off timer'],
    )) {
      return _intent(JbVoiceAction.cancelSleepTimer, cleaned, cleaned);
    }

    // ── SHUFFLE ────────────────────────────────────────────────────────────
    if (_containsPhrase(cleaned, ['shuffle'])) {
      return _intent(JbVoiceAction.shuffle, cleaned, 'shuffle');
    }

    // ── REPEAT ─────────────────────────────────────────────────────────────
    if (_containsPhrase(cleaned, ['repeat', 'loop'])) {
      return _intent(JbVoiceAction.repeat, cleaned, 'repeat');
    }

    // ── VOLUME ─────────────────────────────────────────────────────────────
    if (_containsPhrase(
      cleaned,
      ['volume up', 'turn up', 'louder', 'increase volume'],
    )) {
      return _intent(JbVoiceAction.volumeUp, cleaned, 'volume up');
    }
    if (_containsPhrase(
      cleaned,
      ['volume down', 'turn down', 'quieter', 'lower volume', 'decrease volume'],
    )) {
      return _intent(JbVoiceAction.volumeDown, cleaned, 'volume down');
    }

    // ── EAR SAFETY ─────────────────────────────────────────────────────────
    if (_containsPhrase(
      cleaned,
      ['ear safety', 'check safety', 'hearing', 'volume safe'],
    )) {
      return _intent(JbVoiceAction.checkSafety, cleaned, 'check safety');
    }

    // ── PLAY SONG (must come before generic "play") ────────────────────────
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

    // ── SEARCH ─────────────────────────────────────────────────────────────
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

    // ── PLAYLIST ───────────────────────────────────────────────────────────
    if (cleaned.contains('playlist')) {
      final playlistRegex = RegExp(
        r'(?:play(?:list)?|open|switch\s+to|go\s+to)\s+(?:playlist\s+)?(.+)',
        caseSensitive: false,
      );
      final playlistMatch = playlistRegex.firstMatch(cleaned);
      if (playlistMatch != null) {
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

    // ── BASIC CONTROLS (last resort) ───────────────────────────────────────
    // FIX #5: use word-boundary regex instead of plain substring contains
    // to prevent "next" matching "connect", "repeat" matching "repeated", etc.
    if (_containsWord(cleaned, ['pause', 'stop music', 'stop playing'])) {
      return _intent(JbVoiceAction.pause, cleaned, 'pause');
    }

    if (_containsWord(cleaned, ['next', 'skip', 'next song', 'next track'])) {
      return _intent(JbVoiceAction.next, cleaned, 'next');
    }

    if (_containsWord(
      cleaned,
      ['previous', 'back', 'last song', 'go back'],
    )) {
      return _intent(JbVoiceAction.previous, cleaned, 'previous');
    }

    if (_containsWord(cleaned, ['play', 'start', 'resume', 'continue'])) {
      return _intent(JbVoiceAction.play, cleaned, 'play');
    }

    return VoiceCommandIntent(
      action: JbVoiceAction.unknown,
      rawUtterance: cleaned,
      confidenceScore: 0.0,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  /// Substring match — fine for multi-word phrases like "volume up"
  /// where the phrase itself is specific enough to avoid false positives.
  bool _containsPhrase(String text, List<String> phrases) =>
      phrases.any((p) => text.contains(p));

  /// FIX #5: Word-boundary match for single words that could appear inside
  /// longer words (e.g. "next" inside "connect", "play" inside "replay").
  bool _containsWord(String text, List<String> phrases) {
    return phrases.any((p) {
      // Multi-word phrases: plain contains is safe enough.
      if (p.contains(' ')) return text.contains(p);
      // Single words: require word boundaries.
      return RegExp(r'\b' + RegExp.escape(p) + r'\b').hasMatch(text);
    });
  }

  bool _isStopword(String q) {
    const stopwords = {
      'music',
      'something',
      'a song',
      'anything',
      'song',
      'track',
      'me',
      'it',
      'this',
      'that',
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
    // FIX #6: stopListening already cancels both timers; no need to
    // re-cancel them here. Reset _isInitialized after stop completes.
    await stopListening();
    await _intentCtrl.close();
    await _resultCtrl.close();
    _isInitialized = false;
  }
}