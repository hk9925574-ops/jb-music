// lib/screens/player_screen.dart
//
// JB Musiq — Player Screen (neon redesign)
// Tabs: Art | Lyrics | Queue
// Features: palette_generator bg, sleep timer, shuffle/repeat cycling,
//           8D spatial toggle, animated vinyl ring, progress bar.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';
import 'package:jb_music/domain/entities/jb_song.dart';

// ─── Sleep-timer options ───────────────────────────────────────────────────────
const _sleepOptions = [5, 10, 15, 30, 45, 60]; // minutes

class PlayerScreen extends StatefulWidget {
  final JBSong track;
  const PlayerScreen({super.key, required this.track});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  late final AnimationController _vinylCtrl;
  late final AnimationController _pulseCtrl;
  late final TabController _tabCtrl;

  // ── Palette ────────────────────────────────────────────────────────────────
  Color _bgA = const Color(0xFF080B14);
  Color _bgB = const Color(0xFF0D1526);

  // ── State ──────────────────────────────────────────────────────────────────
  bool _is8D = false;
  Timer? _sleepTimer;
  int? _sleepMinutes;
  DateTime? _sleepEnd;

  // ── Shuffle / Repeat cycling ───────────────────────────────────────────────
  // 0 = none, 1 = repeat-all, 2 = repeat-one
  int _repeatMode = 0;
  bool _shuffle = false;

  @override
  void initState() {
    super.initState();

    _vinylCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _tabCtrl = TabController(length: 3, vsync: this);

    _extractPalette();
  }

  Future<void> _extractPalette() async {
    try {
      final artwork = await OnAudioQuery().queryArtwork(
        int.tryParse(widget.track.id) ?? 0,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 200,
      );
      if (artwork == null || artwork.isEmpty) return;

      final provider = MemoryImage(artwork);
      final gen = await PaletteGenerator.fromImageProvider(
        provider,
        maximumColorCount: 8,
      );

      final dominant =
          gen.dominantColor?.color ?? const Color(0xFF080B14);
      final vibrant =
          gen.vibrantColor?.color ?? const Color(0xFF0D1526);

      if (!mounted) return;
      setState(() {
        _bgA = _darken(dominant, 0.65);
        _bgB = _darken(vibrant, 0.55);
      });
    } catch (_) {
      // Palette extraction is best-effort; fall back silently.
    }
  }

  Color _darken(Color c, double factor) => Color.fromARGB(
        (c.a * 255).round().clamp(0, 255),
        (c.r * 255 * factor).round().clamp(0, 255),
        (c.g * 255 * factor).round().clamp(0, 255),
        (c.b * 255 * factor).round().clamp(0, 255),
      );

  @override
  void dispose() {
    _vinylCtrl.dispose();
    _pulseCtrl.dispose();
    _tabCtrl.dispose();
    _sleepTimer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ── Sleep timer ────────────────────────────────────────────────────────────
  void _showSleepTimer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SleepTimerSheet(
        activeMinutes: _sleepMinutes,
        sleepEnd: _sleepEnd,
        onSelect: (minutes) {
          _sleepTimer?.cancel();
          if (minutes == null) {
            setState(() {
              _sleepMinutes = null;
              _sleepEnd = null;
            });
            return;
          }
          final end = DateTime.now().add(Duration(minutes: minutes));
          setState(() {
            _sleepMinutes = minutes;
            _sleepEnd = end;
          });
          _sleepTimer = Timer(Duration(minutes: minutes), () {
            final handler = context.read<MusicBloc>().audioHandler;
            handler.pause();
            setState(() {
              _sleepMinutes = null;
              _sleepEnd = null;
            });
          });
        },
      ),
    );
  }

  // ── Repeat cycling ─────────────────────────────────────────────────────────
  void _cycleRepeat() {
    setState(() => _repeatMode = (_repeatMode + 1) % 3);
    final handler = context.read<MusicBloc>().audioHandler;
    switch (_repeatMode) {
      case 0:
        handler.setRepeatMode(AudioServiceRepeatMode.none);
        break;
      case 1:
        handler.setRepeatMode(AudioServiceRepeatMode.all);
        break;
      case 2:
        handler.setRepeatMode(AudioServiceRepeatMode.one);
        break;
    }
  }

  void _toggleShuffle() {
    setState(() => _shuffle = !_shuffle);
    final handler = context.read<MusicBloc>().audioHandler;
    handler.setShuffleMode(
      _shuffle
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MusicBloc>();
    final handler = bloc.audioHandler;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bgA, _bgB, const Color(0xFF080B14)],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  onBack: () => Navigator.pop(context),
                  onSleep: _showSleepTimer,
                  sleepActive: _sleepMinutes != null,
                  sleepEnd: _sleepEnd,
                ),
                _NeonTabBar(controller: _tabCtrl),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // ── Tab 0: Art + Controls ────────────────────────
                      _ArtTab(
                        track: widget.track,
                        handler: handler,
                        vinylCtrl: _vinylCtrl,
                        pulseCtrl: _pulseCtrl,
                        is8D: _is8D,
                        shuffle: _shuffle,
                        repeatMode: _repeatMode,
                        onToggle8D: (v) {
                          setState(() => _is8D = v);
                          handler.set8DMode(v);
                        },
                        onShuffle: _toggleShuffle,
                        onRepeat: _cycleRepeat,
                        fmtDuration: _fmt,
                      ),

                      // ── Tab 1: Lyrics ────────────────────────────────
                      const _LyricsTab(),

                      // ── Tab 2: Queue ─────────────────────────────────
                      _QueueTab(bloc: bloc, handler: handler),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSleep;
  final bool sleepActive;
  final DateTime? sleepEnd;

  const _TopBar({
    required this.onBack,
    required this.onSleep,
    required this.sleepActive,
    required this.sleepEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                size: 30, color: Colors.white),
            onPressed: onBack,
          ),
          const Spacer(),
          Column(
            children: [
              const Text(
                'NOW PLAYING',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (sleepActive && sleepEnd != null)
                _SleepCountdown(sleepEnd: sleepEnd!),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSleep,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: sleepActive
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      color: RG.cyan.withValues(alpha: 0.15),
                      border: Border.all(
                          color: RG.cyan.withValues(alpha: 0.5)),
                    )
                  : null,
              child: Icon(
                Icons.bedtime_rounded,
                color: sleepActive ? RG.cyan : Colors.white38,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLEEP COUNTDOWN (live ticker)
// ─────────────────────────────────────────────────────────────────────────────
class _SleepCountdown extends StatefulWidget {
  final DateTime sleepEnd;
  const _SleepCountdown({required this.sleepEnd});

  @override
  State<_SleepCountdown> createState() => _SleepCountdownState();
}

class _SleepCountdownState extends State<_SleepCountdown> {
  late Timer _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final r = widget.sleepEnd.difference(DateTime.now());
    if (mounted) {
      setState(() => _remaining = r.isNegative ? Duration.zero : r);
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    return Text(
      '${m}m ${s.toString().padLeft(2, '0')}s',
      style: const TextStyle(
          color: RG.cyan, fontSize: 10, fontWeight: FontWeight.w700),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEON TAB BAR
// ─────────────────────────────────────────────────────────────────────────────
class _NeonTabBar extends StatelessWidget {
  final TabController controller;
  const _NeonTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                RG.cyan.withValues(alpha: 0.25),
                RG.pink.withValues(alpha: 0.25),
              ],
            ),
            border: Border.all(
                color: RG.cyan.withValues(alpha: 0.6), width: 0.8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: RG.cyan,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2),
          tabs: const [
            Tab(text: 'ART'),
            Tab(text: 'LYRICS'),
            Tab(text: 'QUEUE'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0 — ART + CONTROLS
// ─────────────────────────────────────────────────────────────────────────────
class _ArtTab extends StatelessWidget {
  final JBSong track;
  final dynamic handler;
  final AnimationController vinylCtrl;
  final AnimationController pulseCtrl;
  final bool is8D;
  final bool shuffle;
  final int repeatMode;
  final ValueChanged<bool> onToggle8D;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;
  final String Function(Duration) fmtDuration;

  const _ArtTab({
    required this.track,
    required this.handler,
    required this.vinylCtrl,
    required this.pulseCtrl,
    required this.is8D,
    required this.shuffle,
    required this.repeatMode,
    required this.onToggle8D,
    required this.onShuffle,
    required this.onRepeat,
    required this.fmtDuration,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // ── Vinyl artwork ────────────────────────────────────────────
            StreamBuilder<PlayerState>(
              stream: handler.playerStateStream,
              builder: (context, snap) {
                final playing = snap.data?.playing ?? false;
                if (playing) {
                  vinylCtrl.forward();
                } else {
                  vinylCtrl.stop();
                }

                return Center(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow pulse ring
                        AnimatedBuilder(
                          animation: pulseCtrl,
                          builder: (_, __) => Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: RG.cyan.withValues(
                                    alpha: playing
                                        ? 0.15 + 0.12 * pulseCtrl.value
                                        : 0.0),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // Mid ring
                        Container(
                          width: 236,
                          height: 236,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: RG.pink.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                        ),
                        // Rotating vinyl disc
                        RotationTransition(
                          turns: vinylCtrl,
                          child: Hero(
                            tag: 'artwork_${track.id}',
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.05),
                                    const Color(0xFF080B14),
                                    Colors.white.withValues(alpha: 0.03),
                                    const Color(0xFF0D1526),
                                  ],
                                  stops: const [0.0, 0.3, 0.6, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: RG.cyan.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: RG.pink.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: QueryArtworkWidget(
                                  id: int.tryParse(track.id) ?? 0,
                                  type: ArtworkType.AUDIO,
                                  artworkFit: BoxFit.cover,
                                  artworkWidth: 220,
                                  artworkHeight: 220,
                                  nullArtworkWidget: Container(
                                    width: 220,
                                    height: 220,
                                    color: Colors.transparent,
                                    child: Icon(
                                      Icons.music_note_rounded,
                                      size: 80,
                                      color: RG.cyan.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Centre hole
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF080B14),
                            border: Border.all(
                                color: Colors.white24, width: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // ── Track info ───────────────────────────────────────────────
            Text(
              track.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                shadows: [
                  Shadow(
                      color: RG.cyan.withValues(alpha: 0.5),
                      blurRadius: 12),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              track.artist,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 28),

            // ── Progress bar ─────────────────────────────────────────────
            StreamBuilder<Duration>(
              stream: handler.positionStream,
              builder: (context, posSnap) {
                return StreamBuilder<Duration?>(
                  stream: handler.durationStream,
                  builder: (context, durSnap) {
                    final pos = posSnap.data ?? Duration.zero;
                    final dur = durSnap.data ?? Duration.zero;
                    final maxMs = dur.inMilliseconds > 0
                        ? dur.inMilliseconds.toDouble()
                        : 1.0;

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.5,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5),
                            overlayShape:
                                const RoundSliderOverlayShape(
                                    overlayRadius: 14),
                            activeTrackColor: RG.cyan,
                            inactiveTrackColor:
                                Colors.white.withValues(alpha: 0.1),
                            thumbColor: Colors.white,
                            overlayColor:
                                RG.cyan.withValues(alpha: 0.18),
                          ),
                          child: Slider(
                            value: pos.inMilliseconds
                                .toDouble()
                                .clamp(0.0, maxMs),
                            max: maxMs,
                            onChanged: (v) => handler.seek(
                                Duration(milliseconds: v.toInt())),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(fmtDuration(pos),
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11)),
                              Text(fmtDuration(dur),
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // ── Playback controls ────────────────────────────────────────
            StreamBuilder<PlayerState>(
              stream: handler.playerStateStream,
              builder: (context, snap) {
                final playing = snap.data?.playing ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlIcon(
                      icon: Icons.shuffle_rounded,
                      active: shuffle,
                      onTap: onShuffle,
                      activeColor: RG.cyan,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded,
                          color: Colors.white, size: 42),
                      onPressed: () => handler.skipToPrevious(),
                    ),
                    GestureDetector(
                      onTap: () =>
                          playing ? handler.pause() : handler.play(),
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [RG.cyan, RG.pink],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: RG.cyan.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: RG.pink.withValues(alpha: 0.25),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded,
                          color: Colors.white, size: 42),
                      onPressed: () => handler.skipToNext(),
                    ),
                    _ControlIcon(
                      icon: repeatMode == 2
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      active: repeatMode > 0,
                      onTap: onRepeat,
                      activeColor: RG.pink,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 22),

            // ── 8D Spatial Audio toggle ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: is8D
                      ? RG.cyan.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.spatial_audio_rounded,
                    color: is8D ? RG.cyan : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '8D Spatial Audio',
                      style: TextStyle(
                        color: is8D ? Colors.white : Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: is8D,
                    activeTrackColor:
                        RG.cyan.withValues(alpha: 0.35),
                    activeThumbColor: RG.cyan,
                    inactiveThumbColor: Colors.white24,
                    inactiveTrackColor:
                        Colors.white.withValues(alpha: 0.08),
                    onChanged: onToggle8D,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — LYRICS
// ─────────────────────────────────────────────────────────────────────────────
class _LyricsTab extends StatelessWidget {
  const _LyricsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [RG.cyan, RG.pink],
            ).createShader(bounds),
            child: const Icon(Icons.lyrics_rounded,
                size: 48, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Lyrics Unavailable',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'No lyrics found for this track.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — QUEUE
// ─────────────────────────────────────────────────────────────────────────────
class _QueueTab extends StatelessWidget {
  final MusicBloc bloc;
  final dynamic handler;

  const _QueueTab({required this.bloc, required this.handler});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, state) {
        final songs = state is MusicTracksLoadedState
            ? state.visibleTracks
            : <JBSong>[];
        final current = state is MusicTracksLoadedState
            ? state.currentTrackIndex
            : 0;

        if (songs.isEmpty) {
          return Center(
            child: Text(
              'Queue is empty.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13),
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: songs.length,
          itemBuilder: (context, i) {
            final song = songs[i];
            final isCurrent = i == current;
            return _QueueTile(
              song: song,
              isCurrent: isCurrent,
              onTap: () => handler.skipToQueueItem(i),
            );
          },
        );
      },
    );
  }
}

class _QueueTile extends StatelessWidget {
  final JBSong song;
  final bool isCurrent;
  final VoidCallback onTap;

  const _QueueTile({
    required this.song,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isCurrent
              ? RG.cyan.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: isCurrent
                ? RG.cyan.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withValues(alpha: 0.06),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: QueryArtworkWidget(
                  id: int.tryParse(song.id) ?? 0,
                  type: ArtworkType.AUDIO,
                  artworkFit: BoxFit.cover,
                  artworkWidth: 44,
                  artworkHeight: 44,
                  nullArtworkWidget: Icon(
                    Icons.music_note_rounded,
                    size: 22,
                    color: RG.cyan.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      color: isCurrent ? RG.cyan : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isCurrent)
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                        colors: [RG.cyan, RG.pink])
                    .createShader(b),
                child: const Icon(Icons.equalizer_rounded,
                    color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLEEP TIMER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _SleepTimerSheet extends StatelessWidget {
  final int? activeMinutes;
  final DateTime? sleepEnd;
  final void Function(int? minutes) onSelect;

  const _SleepTimerSheet({
    required this.activeMinutes,
    required this.sleepEnd,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1526).withValues(alpha: 0.92),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                  color: RG.cyan.withValues(alpha: 0.25), width: 0.8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.bedtime_rounded,
                      color: RG.cyan, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Sleep Timer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._sleepOptions.map((min) {
                    final isActive = activeMinutes == min;
                    return GestureDetector(
                      onTap: () {
                        onSelect(isActive ? null : min);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: isActive
                              ? LinearGradient(
                                  colors: [
                                    RG.cyan.withValues(alpha: 0.25),
                                    RG.pink.withValues(alpha: 0.15),
                                  ],
                                )
                              : null,
                          color: isActive
                              ? null
                              : Colors.white.withValues(alpha: 0.07),
                          border: Border.all(
                            color: isActive
                                ? RG.cyan.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          '$min min',
                          style: TextStyle(
                            color: isActive ? RG.cyan : Colors.white70,
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                  if (activeMinutes != null)
                    GestureDetector(
                      onTap: () {
                        onSelect(null);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: RG.pink.withValues(alpha: 0.12),
                          border: Border.all(
                              color: RG.pink.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                              color: RG.pink,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER — small icon control with active neon state
// ─────────────────────────────────────────────────────────────────────────────
class _ControlIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;

  const _ControlIcon({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withValues(alpha: 0.12),
              ),
            ),
          Icon(
            icon,
            color: active ? activeColor : Colors.white38,
            size: 24,
          ),
          if (active)
            Positioned(
              bottom: 4,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}