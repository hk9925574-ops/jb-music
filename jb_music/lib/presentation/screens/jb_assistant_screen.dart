// lib/presentation/screens/jb_assistant_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';
import 'package:jb_music/presentation/animations/orb_painter.dart';

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

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _orbCtrl;

  // ── TTS ───────────────────────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();

  // ── State ─────────────────────────────────────────────────────────────────
  OrbState         _orbState       = OrbState.idle;
  bool             _micActive      = false;
  String           _liveTranscript = '';
  final List<_HistoryItem> _history = [];
  StreamSubscription<String>? _transcriptSub;

  // ── TTS response map ──────────────────────────────────────────────────────
  static const Map<String, String> _responses = {
    'play':      'Playing music',
    'pause':     'Music paused',
    'next':      'Next song',
    'previous':  'Previous song',
    'shuffle':   'Shuffle on',
    'repeat':    'Repeat on',
    'volume_up': 'Volume increased',
    'volume_down': 'Volume decreased',
    'library':   'Opening library',
    'favorites': 'Playing your favourites',
    'search':    'Searching',
  };

  @override
  void initState() {
    super.initState();

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

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
      if (mounted) setState(() => _orbState = _micActive ? OrbState.listening : OrbState.idle);
    });
  }

  void _bindVoiceStream() {
    final voiceEngine = context.read<MusicBloc>().voiceEngine;
    _transcriptSub = voiceEngine.resultStream.listen((text) {
      if (!mounted) return;
      setState(() => _liveTranscript = text);
    });

    // Also listen for intents to update history + speak
    voiceEngine.commandIntentStream.listen((intent) {
      if (!mounted) return;
      final response = _responses[intent.action.name] ?? 'Got it';
      setState(() {
        _liveTranscript = '';
        _history.insert(
          0,
          _HistoryItem(
            command: intent.payload ?? intent.action.name,
            response: response,
            time: TimeOfDay.now(),
          ),
        );
        if (_history.length > 20) _history.removeLast();
        _orbState = OrbState.thinking;
      });

      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _speak(response);
      });
    });
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  void _toggleMic() {
    final bloc = context.read<MusicBloc>();
    setState(() => _micActive = !_micActive);
    if (_micActive) {
      bloc.add(StartVoiceListeningEvent());
      setState(() => _orbState = OrbState.listening);
    } else {
      bloc.add(StopVoiceListeningEvent());
      setState(() {
        _orbState       = OrbState.idle;
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
    _tts.stop();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RG.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('JB Assistant', style: RG.titleStyle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Command hint chips ─────────────────────────────────────────
            _CommandChips().animate().fadeIn(delay: 200.ms, duration: 500.ms),
            const Spacer(),
            // ── Live transcript ────────────────────────────────────────────
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
            // ── Orb ───────────────────────────────────────────────────────
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
            // ── Status ────────────────────────────────────────────────────
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
            // ── History ───────────────────────────────────────────────────
            if (_history.isNotEmpty) _HistoryPanel(history: _history),
            const SizedBox(height: RG.spaceLG),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMAND CHIPS
// ─────────────────────────────────────────────────────────────────────────────
class _CommandChips extends StatelessWidget {
  static const _commands = [
    'Play music',
    'Next song',
    'Pause',
    'Shuffle',
    'Play favourites',
    'Sleep timer',
    'Volume up',
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

// ─────────────────────────────────────────────────────────────────────────────
// HISTORY PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryItem {
  final String   command;
  final String   response;
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
      height: 160,
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
                    children: [
                      const Icon(Icons.mic, color: RG.gold, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.command,
                          style: const TextStyle(
                            color: RG.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}',
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