// lib/presentation/screens/jb_assistant_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';
import 'package:jb_music/domain/entities/voice_intent.dart';
import 'package:jb_music/presentation/animations/orb_painter.dart';
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class JBAssistantScreen extends StatefulWidget {
  const JBAssistantScreen({super.key});

  @override
  State<JBAssistantScreen> createState() => _JBAssistantScreenState();
}

class _JBAssistantScreenState extends State<JBAssistantScreen>
    with TickerProviderStateMixin {

  late final AnimationController _orbCtrl;
  final FlutterTts _tts = FlutterTts();

  OrbState _orbState = OrbState.idle;
  bool _micActive = false;
  String _liveTranscript = '';
  final List<_HistoryItem> _history = [];
  StreamSubscription<String>? _transcriptSub;
  StreamSubscription<VoiceCommandIntent>? _intentSub;

  static String _responseFor(JbVoiceAction action, {String? payload}) {
    switch (action) {
      case JbVoiceAction.play:             return 'Playing music';
      case JbVoiceAction.pause:            return 'Music paused';
      case JbVoiceAction.togglePlayPause:  return 'Toggling playback';
      case JbVoiceAction.next:             return 'Next song';
      case JbVoiceAction.previous:         return 'Previous song';
      case JbVoiceAction.shuffle:          return 'Shuffle on';
      case JbVoiceAction.repeat:           return 'Repeat on';
      case JbVoiceAction.volumeUp:         return 'Volume up';
      case JbVoiceAction.volumeDown:       return 'Volume down';
      case JbVoiceAction.searchSong:
        return payload != null && payload.isNotEmpty
            ? 'Searching for $payload'
            : 'Searching';
      case JbVoiceAction.playSong:
        return payload != null && payload.isNotEmpty
            ? 'Playing $payload'
            : 'Playing song';
      case JbVoiceAction.playPlaylist:
        return payload != null && payload.isNotEmpty
            ? 'Playing $payload playlist'
            : 'Playing playlist';
      case JbVoiceAction.setSleepTimer:
        return payload != null && payload.isNotEmpty
            ? 'Sleep timer set for $payload minutes'
            : 'Sleep timer set';
      case JbVoiceAction.cancelSleepTimer: return 'Sleep timer cancelled';
      case JbVoiceAction.checkSafety:      return 'Opening ear safety';
      case JbVoiceAction.unknown:          return 'Sorry, I didn\'t understand that';
    }
  }

  static String _historyLabel(VoiceCommandIntent intent) {
    final p = intent.payload;
    switch (intent.action) {
      case JbVoiceAction.playSong:      return p != null ? 'Play "$p"' : 'Play song';
      case JbVoiceAction.searchSong:    return p != null ? 'Search "$p"' : 'Search';
      case JbVoiceAction.playPlaylist:  return p != null ? 'Playlist: $p' : 'Play playlist';
      case JbVoiceAction.setSleepTimer: return p != null ? 'Timer: $p min' : 'Set timer';
      default:                          return _capitalize(intent.action.name);
    }
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  void initState() {
    super.initState();

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _initTts();
    _bindVoiceStream();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(0.9);
    await _tts.setPitch(1.0);
    _tts.setStartHandler(() {
      if (mounted) setState(() => _orbState = OrbState.speaking);
    });
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _orbState = _micActive ? OrbState.listening : OrbState.idle);
      }
    });
  }

  void _bindVoiceStream() {
    final musicBloc = context.read<MusicBloc>();
    final voiceEngine = musicBloc.voiceEngine;

    if (voiceEngine == null) {
      debugPrint('❌ Voice engine is null');
      return;
    }

    _transcriptSub = voiceEngine.resultStream.listen(
      (text) {
        if (!mounted) return;
        setState(() => _liveTranscript = text);
      },
      onError: (error) {
        debugPrint('Transcript error: $error');
      },
    );

    _intentSub = voiceEngine.commandIntentStream.listen(
      (intent) {
        if (!mounted) return;

        final response = _responseFor(intent.action, payload: intent.payload);
        final label = _historyLabel(intent);

        setState(() {
          _liveTranscript = '';
          _history.insert(0, _HistoryItem(
            command: label,
            response: response,
            time: TimeOfDay.now(),
          ));
          if (_history.length > 20) _history.removeLast();
          _orbState = OrbState.thinking;
        });

        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _speak(response);
        });
      },
      onError: (error) {
        debugPrint('Intent error: $error');
      },
    );
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return true;
  }

  Future<void> _toggleMic() async {
    final bloc = context.read<MusicBloc>();
    
    if (!_micActive) {
      final hasPermission = await _checkMicrophonePermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
        return;
      }
      
      setState(() => _micActive = true);
      bloc.add(StartVoiceListeningEvent());
      setState(() => _orbState = OrbState.listening);
      _orbCtrl.repeat();
    } else {
      setState(() => _micActive = false);
      bloc.add(StopVoiceListeningEvent());
      _orbCtrl.stop();
      setState(() {
        _orbState = OrbState.idle;
        _liveTranscript = '';
      });
    }
  }

  Color get _orbColor {
    switch (_orbState) {
      case OrbState.idle:      return RG.gold;
      case OrbState.listening: return const Color(0xFF4CAF50);
      case OrbState.thinking:  return const Color(0xFF2196F3);
      case OrbState.speaking:  return RG.goldLight;
    }
  }

  String get _statusLabel {
    switch (_orbState) {
      case OrbState.idle:      return _micActive ? 'Tap to stop' : 'Tap to activate';
      case OrbState.listening: return 'Listening…';
      case OrbState.thinking:  return 'Thinking…';
      case OrbState.speaking:  return 'Speaking…';
    }
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _transcriptSub?.cancel();
    _intentSub?.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RG.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('JB Assistant', style: RG.titleStyle),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _CommandChips().animate().fadeIn(delay: 200.ms, duration: 500.ms),
            const Spacer(),
            
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _liveTranscript.isNotEmpty ? 1 : 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: RG.spaceLG),
                padding: const EdgeInsets.symmetric(
                  horizontal: RG.spaceMD,
                  vertical: RG.spaceSM,
                ),
                decoration: BoxDecoration(
                  color: RG.surfaceHigh,
                  borderRadius: BorderRadius.circular(RG.radiusLG),
                  border: Border.all(color: RG.borderGold),
                ),
                child: Text(
                  _liveTranscript.isEmpty ? ' ' : '"$_liveTranscript"',
                  style: RG.bodyStyle.copyWith(
                    color: RG.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: RG.spaceLG),
            
            GestureDetector(
              onTap: _toggleMic,
              child: AnimatedBuilder(
                animation: _orbCtrl,
                builder: (_, __) => SizedBox(
                  width: 220,
                  height: 220,
                  child: CustomPaint(
                    painter: OrbPainter(
                      animValue: _orbCtrl.value,
                      orbState: _orbState,
                      baseColor: _orbColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: RG.spaceMD),
            
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _statusLabel,
                key: ValueKey(_statusLabel),
                style: RG.subtitleStyle.copyWith(
                  color: _orbColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Say "Hey JB, play music" or tap the orb',
              style: RG.captionStyle,
            ),
            const Spacer(),
            
            if (_history.isNotEmpty) _HistoryPanel(history: _history),
            const SizedBox(height: RG.spaceLG),
          ],
        ),
      ),
    );
  }
}

class _CommandChips extends StatelessWidget {
  static const _commands = [
    'Play music',
    'Next song',
    'Pause',
    'Shuffle',
    'Play favourites',
    'Sleep timer 30 min',
    'Volume up',
    'Repeat',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(RG.spaceMD, RG.spaceLG, RG.spaceMD, 0),
      child: Wrap(
        spacing: RG.spaceSM,
        runSpacing: RG.spaceSM,
        alignment: WrapAlignment.center,
        children: _commands.map((cmd) => _Chip(label: cmd)).toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: RG.surfacePop,
        borderRadius: BorderRadius.circular(RG.radiusFull),
        border: Border.all(color: RG.border),
      ),
      child: Text(
        '"$label"',
        style: const TextStyle(
          color: RG.textSecondary,
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _HistoryItem {
  final String command;
  final String response;
  final TimeOfDay time;
  const _HistoryItem({
    required this.command,
    required this.response,
    required this.time,
  });
}

class _HistoryPanel extends StatelessWidget {
  final List<_HistoryItem> history;
  const _HistoryPanel({required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: RG.spaceMD),
      decoration: BoxDecoration(
        color: RG.surfaceHigh,
        borderRadius: BorderRadius.circular(RG.radiusLG),
        border: Border.all(color: RG.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RG.spaceMD,
              vertical: RG.spaceSM,
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: RG.textMuted, size: 16),
                const SizedBox(width: 6),
                Text('Command History', style: RG.captionStyle),
              ],
            ),
          ),
          const Divider(height: 0, color: RG.border),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (_, i) {
                final item = history[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RG.spaceMD,
                    vertical: 6,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.mic, color: RG.gold, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.command,
                              style: const TextStyle(
                                color: RG.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              item.response,
                              style: const TextStyle(
                                color: RG.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${item.time.hour.toString().padLeft(2, '0')}:'
                        '${item.time.minute.toString().padLeft(2, '0')}',
                        style: RG.labelStyle,
                      ),
                    ],
                  ),
                ).animate(delay: (i * 30).ms).fadeIn(duration: 200.ms);
              },
            ),
          ),
        ],
      ),
    );
  }
}