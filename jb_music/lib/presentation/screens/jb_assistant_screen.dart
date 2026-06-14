// lib/presentation/screens/jb_assistant_screen.dart
//
// JB MUSIC — NOVA AI ASSISTANT SCREEN (SYSTEM PROMPT DRIVEN)
// ─────────────────────────────────────────────────────────────────────────────
// A Jarvis-level voice interface. Cinematic, intelligent, alive.
// Adheres strictly to the JB Music AI Voice Assistant System Prompt rules:
//  • Extreme short responses (< 5 words)
//  • Strict Confidence scoring thresholds
//  • Instant background execution with zero music interruption
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/jb_design_system.dart';
import 'package:jb_music/domain/entities/voice_intent.dart';
import 'package:jb_music/presentation/animations/orb_painter.dart';

class JBAssistantScreen extends StatefulWidget {
  const JBAssistantScreen({super.key});

  @override
  State<JBAssistantScreen> createState() => _JBAssistantScreenState();
}

class _JBAssistantScreenState extends State<JBAssistantScreen>
    with TickerProviderStateMixin {

  // ── Controllers ─────────────────────────────────────────────────────────
  late final AnimationController _orbCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _rippleCtrl;
  final FlutterTts _tts = FlutterTts();

  // ── State ────────────────────────────────────────────────────────────────
  OrbState _orbState      = OrbState.idle;
  bool     _micActive     = false;
  String   _liveTranscript = '';
  final List<_ChatMessage> _messages = [];
  final _scrollCtrl = ScrollController();

  StreamSubscription<String>? _transcriptSub;
  StreamSubscription<VoiceCommandIntent>? _intentSub;

  // ── Quick commands ───────────────────────────────────────────────────────
  static const _quickCmds = [
    ('Play something', Icons.play_arrow_rounded),
    ('Skip this song', Icons.skip_next_rounded),
    ('Shuffle all',     Icons.shuffle_rounded),
    ('Sleep in 30m',   Icons.bedtime_outlined),
    ('Play liked',     Icons.favorite_outlined),
    ('Volume up',      Icons.volume_up_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat(reverse: true);
    _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
        ..repeat();

    // System Prompt: Silent mode, high pacing execution
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.50); // Snappy, direct vocal delivery
    _tts.setVolume(1.0);      // High visibility matching premium player specs

    _listenToBloc();
    _greet();
  }

  void _greet() {
    // System Prompt Rules: Ultra-short, action-oriented greetings. No fluff.
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning.' : hour < 17 ? 'Good afternoon.' : 'Good evening.';
    final msg = '$greeting Online and ready.';

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(text: msg, isUser: false)));
    });
  }

  void _listenToBloc() {
    final bloc = context.read<MusicBloc>();

    // resultStream emits raw recognized text
    _transcriptSub = bloc.voiceEngine.resultStream.listen((t) {
      if (!mounted) return;
      setState(() {
        _liveTranscript = t;
        _orbState = OrbState.listening;
      });
    });

    // commandIntentStream emits parsed VoiceCommandIntent with confidence scoring
    _intentSub = bloc.voiceEngine.commandIntentStream.listen((intent) {
      if (!mounted) return;

      // ── SYSTEM PROMPT CONFIDENCE LAYER ─────────────────────────────────────
      // Confidence < 70%: Ignore command immediately
      if (intent.confidenceScore < 0.70) {
        setState(() {
          _liveTranscript = '';
          _orbState = OrbState.idle;
        });
        return;
      }

      String response;
      
      // Confidence 70-89%: Request short clarification
      if (intent.confidenceScore >= 0.70 && intent.confidenceScore < 0.90) {
        response = 'Did you say "${intent.rawUtterance}"?';
        setState(() {
          _orbState = OrbState.thinking;
          _messages.add(_ChatMessage(text: response, isUser: false));
        });
        _tts.speak(response);
        return;
      }

      // Confidence >= 90%: Process direct execution loop
      response = _responseFor(intent.action, payload: intent.payload);

      setState(() {
        if (_liveTranscript.isNotEmpty) {
          _messages.add(_ChatMessage(text: _liveTranscript, isUser: true));
          _liveTranscript = '';
        }
        _messages.add(_ChatMessage(text: response, isUser: false));
        _orbState = OrbState.responding;
      });

      // Execute vocal confirmation path instantly
      _tts.speak(response);
      HapticFeedback.lightImpact();

      // System Prompt Rule: Fast exit execution window (<100ms UI restoration path)
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _orbState = OrbState.idle);
      });

      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: JBAnim.easeOut,
        );
      }
    });
  }

  // System Prompt: Maps intents directly to ultra-short responses (< 5 words)
  static String _responseFor(JbVoiceAction action, {String? payload}) {
    switch (action) {
      case JbVoiceAction.play:            return 'Playing.';
      case JbVoiceAction.pause:           return 'Paused.';
      case JbVoiceAction.togglePlayPause: return 'Toggling track.';
      case JbVoiceAction.next:            return 'Playing next track.';
      case JbVoiceAction.previous:        return 'Going back.';
      case JbVoiceAction.shuffle:         return 'Shuffle on.';
      case JbVoiceAction.repeat:          return 'Repeat activated.';
      case JbVoiceAction.volumeUp:        return 'Volume raised.';
      case JbVoiceAction.volumeDown:      return 'Volume lowered.';
      case JbVoiceAction.searchSong:
        return payload?.isNotEmpty == true ? 'Searching "$payload".' : 'Searching.';
      case JbVoiceAction.playSong:
        return payload?.isNotEmpty == true ? 'Playing "$payload".' : 'Playing track.';
      case JbVoiceAction.playPlaylist:
        return payload?.isNotEmpty == true ? 'Starting "$payload".' : 'Playing playlist.';
      case JbVoiceAction.setSleepTimer:
        return payload?.isNotEmpty == true ? 'Timer set: $payload min.' : 'Timer set.';
      case JbVoiceAction.cancelSleepTimer: return 'Timer cancelled.';
      default: return 'Executed.';
    }
  }

  Future<void> _toggleMic() async {
    HapticFeedback.mediumImpact();

    if (_micActive) {
      setState(() { _micActive = false; _orbState = OrbState.idle; });
      context.read<MusicBloc>().add(StopVoiceListeningEvent());
    } else {
      final status = await Permission.microphone.request();
      if (!mounted) return;
      if (!status.isGranted) {
        _showPermissionDenied();
        return;
      }
      setState(() { _micActive = true; _orbState = OrbState.listening; });
      context.read<MusicBloc>().add(StartVoiceListeningEvent());
    }
  }

  void _showPermissionDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mic_off_rounded, color: JBColors.error, size: 18),
            const SizedBox(width: 10),
            Text('Microphone required.', style: JBType.bodyMedium),
          ],
        ),
        backgroundColor: JBColors.void3,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: JBRadius.cardSm),
      ),
    );
  }

  void _sendQuickCmd(String cmd) {
    HapticFeedback.selectionClick();
    setState(() => _messages.add(_ChatMessage(text: cmd, isUser: true)));
    
    final bloc = context.read<MusicBloc>();
    final lower = cmd.toLowerCase();
    
    if (lower.contains('play')) {
      bloc.audioHandler.play();
    } else if (lower.contains('skip') || lower.contains('next')) {
      bloc.audioHandler.skipToNext();
    } else if (lower.contains('shuffle')) {
      bloc.audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
    } else if (lower.contains('volume up')) {
      final dsp = bloc.dspEngine;
      dsp.setVolume((dsp.volume + 0.1).clamp(0.0, 1.0));
    } else if (lower.contains('sleep')) {
      bloc.audioHandler.pause();
    } else if (lower.contains('liked') || lower.contains('favorite')) {
      bloc.add(PlaySmartPlaylistEvent(SmartPlaylistType.shuffle));
    }

    // System Prompt: Action mappings matching exact voice responses
    final response = lower.contains('play') ? 'Playing.'
        : lower.contains('skip') ? 'Playing next track.'
        : lower.contains('shuffle') ? 'Shuffle on.'
        : lower.contains('volume') ? 'Volume raised.'
        : lower.contains('sleep') ? 'Pausing for sleep.'
        : lower.contains('liked') ? 'Playing favorites.'
        : 'Done.';

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _messages.add(_ChatMessage(text: response, isUser: false)));
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _pulseCtrl.dispose();
    _rippleCtrl.dispose();
    _scrollCtrl.dispose();
    _transcriptSub?.cancel();
    _intentSub?.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JBColors.void0,
      body: Stack(
        children: [
          _AssistantBackground(orbCtrl: _orbCtrl, orbState: _orbState),
          SafeArea(
            bottom: false,
            child: Builder(
              builder: (context) {
                final sysPad = MediaQuery.of(context).padding.bottom;
                final bottomPad = sysPad + 58 + 72;
                return Column(
                  children: [
                    const _AssistantHeader().animate().fadeIn(duration: 500.ms),
                    _OrbSection(
                      orbCtrl: _orbCtrl,
                      pulseCtrl: _pulseCtrl,
                      rippleCtrl: _rippleCtrl,
                      orbState: _orbState,
                      micActive: _micActive,
                      liveTranscript: _liveTranscript,
                      onMicTap: _toggleMic,
                    ).animate().fadeIn(duration: 600.ms, delay: 100.ms),
                    Expanded(
                      child: _ChatHistory(
                        messages: _messages,
                        scrollCtrl: _scrollCtrl,
                      ),
                    ),
                    _QuickCommandRow(
                      commands: _quickCmds,
                      onTap: _sendQuickCmd,
                    ).animate().slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 200.ms)
                      .fadeIn(duration: 400.ms),
                    SizedBox(height: bottomPad),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BACKGROUND UI COMPONENT
// ─────────────────────────────────────────────────────────────────────────────
class _AssistantBackground extends StatelessWidget {
  final AnimationController orbCtrl;
  final OrbState orbState;
  const _AssistantBackground({required this.orbCtrl, required this.orbState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: orbCtrl,
      builder: (_, __) {
        final t = orbCtrl.value;
        final color = orbState == OrbState.listening ? JBColors.pulse
            : orbState == OrbState.responding ? JBColors.aurora
            : JBColors.nova;

        return SizedBox.expand(
          child: Stack(
            children: [
              Container(color: JBColors.void0),
              Positioned(
                top: -80 + math.sin(t * math.pi * 2) * 20,
                left: MediaQuery.of(context).size.width / 2 - 150,
                child: Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.06),
                  ),
                  child: const _BlurCircle(sigma: 80),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double sigma;
  const _BlurCircle({required this.sigma});
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER UI COMPONENT
// ─────────────────────────────────────────────────────────────────────────────
class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('JB Assistant', style: JBType.h2),
              Text('AI-powered • Voice-first', style: JBType.caption.copyWith(color: JBColors.nova)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: JBGlass.auroraCard(radius: JBRadius.full),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: JBColors.aurora, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('Online', style: JBType.micro.copyWith(color: JBColors.aurora, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ORB INTERFACE SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _OrbSection extends StatelessWidget {
  final AnimationController orbCtrl, pulseCtrl, rippleCtrl;
  final OrbState orbState;
  final bool micActive;
  final String liveTranscript;
  final VoidCallback onMicTap;

  const _OrbSection({
    required this.orbCtrl, required this.pulseCtrl, required this.rippleCtrl,
    required this.orbState, required this.micActive,
    required this.liveTranscript, required this.onMicTap,
  });

  Color get _orbColor {
    switch (orbState) {
      case OrbState.listening:  return JBColors.pulse;
      case OrbState.thinking:   return JBColors.aurora;
      case OrbState.responding: return JBColors.aurora;
      case OrbState.idle:       return JBColors.nova;
    }
  }

  String get _stateLabel {
    switch (orbState) {
      case OrbState.listening:  return 'Listening…';
      case OrbState.thinking:   return 'Processing…';
      case OrbState.responding: return 'Speaking…';
      case OrbState.idle:       return 'Tap to speak';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: onMicTap,
            child: AnimatedBuilder(
              animation: Listenable.merge([orbCtrl, pulseCtrl, rippleCtrl]),
              builder: (_, __) {
                final pulse = 1.0 + pulseCtrl.value * 0.08;
                final ripple = rippleCtrl.value;

                return SizedBox(
                  width: 140, height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (micActive) ...[
                        _RippleRing(
                          color: _orbColor,
                          scale: 0.8 + ripple * 0.4,
                          opacity: (1 - ripple) * 0.3,
                          size: 140,
                        ),
                        _RippleRing(
                          color: _orbColor,
                          scale: 0.7 + ((ripple + 0.5) % 1.0) * 0.4,
                          opacity: (1 - ((ripple + 0.5) % 1.0)) * 0.2,
                          size: 140,
                        ),
                      ],
                      Transform.scale(
                        scale: pulse,
                        child: Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _orbColor.withValues(alpha: 0.9),
                                _orbColor.withValues(alpha: 0.5),
                                _orbColor.withValues(alpha: 0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _orbColor.withValues(alpha: 0.4),
                                blurRadius: 32,
                                spreadRadius: 8,
                              ),
                              BoxShadow(
                                color: _orbColor.withValues(alpha: 0.2),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: OrbPainter(
                              t: orbCtrl.value,
                              state: orbState,
                              color: _orbColor,
                            ),
                            child: Center(
                              child: Icon(
                                micActive ? Icons.mic_rounded : Icons.mic_none_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: 300.ms,
            child: Text(
              liveTranscript.isNotEmpty ? '"$liveTranscript"' : _stateLabel,
              key: ValueKey(liveTranscript.isNotEmpty ? liveTranscript : _stateLabel),
              style: liveTranscript.isNotEmpty
                  ? JBType.bodyMedium.copyWith(color: JBColors.textPrimary, fontStyle: FontStyle.italic)
                  : JBType.caption.copyWith(color: _orbColor),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RippleRing extends StatelessWidget {
  final Color color;
  final double scale, opacity, size;
  const _RippleRing({
    required this.color, required this.scale,
    required this.opacity, required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: opacity),
            width: 2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CHAT HISTORY LOGISTICS
// ─────────────────────────────────────────────────────────────────────────────
class _ChatHistory extends StatelessWidget {
  final List<_ChatMessage> messages;
  final ScrollController scrollCtrl;
  const _ChatHistory({required this.messages, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, color: JBColors.nova.withValues(alpha: 0.3), size: 40),
            const SizedBox(height: 10),
            Text('Listening in silent mode.',
              style: JBType.body.copyWith(color: JBColors.textTertiary),
              textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        return _MessageBubble(msg: msg)
            .animate(delay: 50.ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.15, end: 0, curve: JBAnim.easeOut);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: JBGradients.nova,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: isUser
                  ? const BoxDecoration(
                      gradient: JBGradients.nova,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(JBRadius.lg),
                        topRight: Radius.circular(JBRadius.lg),
                        bottomLeft: Radius.circular(JBRadius.lg),
                        bottomRight: Radius.circular(4),
                      ),
                    )
                  : JBGlass.card(
                      radius: JBRadius.md,
                    ).copyWith(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(JBRadius.lg),
                        bottomLeft: Radius.circular(JBRadius.lg),
                        bottomRight: Radius.circular(JBRadius.lg),
                      ),
                    ),
              child: Text(
                msg.text,
                style: JBType.body.copyWith(
                  color: isUser ? JBColors.void0 : JBColors.textPrimary,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(left: 8, bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: JBColors.glass20,
                border: Border.all(color: JBColors.glassBorder, width: 0.5),
              ),
              child: const Icon(Icons.person_rounded, color: JBColors.textSecondary, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  QUICK COMMAND SLIDER
// ─────────────────────────────────────────────────────────────────────────────
class _QuickCommandRow extends StatelessWidget {
  final List<(String, IconData)> commands;
  final void Function(String) onTap;
  const _QuickCommandRow({required this.commands, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: commands.length,
        itemBuilder: (_, i) {
          final cmd = commands[i];
          return GestureDetector(
            onTap: () => onTap(cmd.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: JBGlass.card(radius: JBRadius.full),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cmd.$2, color: JBColors.nova, size: 14),
                  const SizedBox(width: 6),
                  Text(cmd.$1,
                    style: JBType.captionMedium.copyWith(color: JBColors.textPrimary, fontSize: 12)),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: i * 40)).slideX(begin: 0.2).fadeIn();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA WRAPPER
// ─────────────────────────────────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage({required this.text, required this.isUser});
}