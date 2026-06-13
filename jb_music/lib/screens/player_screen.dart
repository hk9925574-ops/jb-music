// lib/screens/player_screen.dart
//
// JB Music — Player Screen
// Theme: AMOLED black + gold
// Tabs: Art | Lyrics | Queue
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

const _sleepOptions = [5, 10, 15, 30, 45, 60];

class PlayerScreen extends StatefulWidget {
  final JBSong track;
  const PlayerScreen({super.key, required this.track});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _vinylCtrl;
  late final AnimationController _pulseCtrl;
  late final TabController _tabCtrl;

  Color _bgA = const Color(0xFF000000);
  Color _bgB = const Color(0xFF0A0A0A);

  bool _is8D = false;
  Timer? _sleepTimer;
  int? _sleepMinutes;
  DateTime? _sleepEnd;

  int  _repeatMode = 0; // 0=none 1=all 2=one
  bool _shuffle    = false;

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

      final gen = await PaletteGenerator.fromImageProvider(
        MemoryImage(artwork),
        maximumColorCount: 8,
      );

      final dominant = gen.dominantColor?.color ?? Colors.black;
      if (!mounted) return;
      setState(() {
        _bgA = _darken(dominant, 0.25);
        _bgB = const Color(0xFF000000);
      });
    } catch (_) {}
  }

  // FIX: use Color.fromARGB with int values — avoid deprecated .r/.g/.b/.a doubles
  Color _darken(Color c, double factor) {
    final r = ((c.r * 255) * factor).round().clamp(0, 255);
    final g = ((c.g * 255) * factor).round().clamp(0, 255);
    final b = ((c.b * 255) * factor).round().clamp(0, 255);
    final a = (c.a * 255).round().clamp(0, 255);
    return Color.fromARGB(a, r, g, b);
  }

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
              _sleepEnd     = null;
            });
            return;
          }
          final end = DateTime.now().add(Duration(minutes: minutes));
          setState(() {
            _sleepMinutes = minutes;
            _sleepEnd     = end;
          });
          _sleepTimer = Timer(Duration(minutes: minutes), () {
            context.read<MusicBloc>().audioHandler.pause();
            if (mounted) {
              setState(() {
                _sleepMinutes = null;
                _sleepEnd     = null;
              });
            }
          });
        },
      ),
    );
  }

  void _cycleRepeat() {
    setState(() => _repeatMode = (_repeatMode + 1) % 3);
    final handler = context.read<MusicBloc>().audioHandler;
    switch (_repeatMode) {
      case 0: handler.setRepeatMode(AudioServiceRepeatMode.none);
      case 1: handler.setRepeatMode(AudioServiceRepeatMode.all);
      case 2: handler.setRepeatMode(AudioServiceRepeatMode.one);
    }
  }

  void _toggleShuffle() {
    setState(() => _shuffle = !_shuffle);
    final handler = context.read<MusicBloc>().audioHandler;
    handler.setShuffleMode(
      _shuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc    = context.read<MusicBloc>();
    final handler = bloc.audioHandler;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgA, _bgB],
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
                _GoldTabBar(controller: _tabCtrl),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    physics: const BouncingScrollPhysics(),
                    children: [
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
                        onRepeat:  _cycleRepeat,
                        fmtDuration: _fmt,
                      ),
                      const _LyricsTab(),
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
  final bool         sleepActive;
  final DateTime?    sleepEnd;

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
              Text(
                'NOW PLAYING',
                style: TextStyle(
                  color: RG.textMuted,
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
                      color: RG.goldGlow,
                      border: Border.all(
                          color: RG.gold.withValues(alpha: 0.5)),
                    )
                  : null,
              child: Icon(
                Icons.bedtime_rounded,
                color: sleepActive ? RG.gold : RG.textMuted,
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
// SLEEP COUNTDOWN
// ─────────────────────────────────────────────────────────────────────────────
class _SleepCountdown extends StatefulWidget {
  final DateTime sleepEnd;
  const _SleepCountdown({required this.sleepEnd});

  @override
  State<_SleepCountdown> createState() => _SleepCountdownState();
}

class _SleepCountdownState extends State<_SleepCountdown> {
  late Timer  _ticker;
  Duration    _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final r = widget.sleepEnd.difference(DateTime.now());
    if (mounted) setState(() => _remaining = r.isNegative ? Duration.zero : r);
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
          color: RG.gold, fontSize: 10, fontWeight: FontWeight.w700),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOLD TAB BAR
// ─────────────────────────────────────────────────────────────────────────────
class _GoldTabBar extends StatelessWidget {
  final TabController controller;
  const _GoldTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: RG.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RG.border),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: RG.gold.withValues(alpha: 0.15),
            border: Border.all(
                color: RG.gold.withValues(alpha: 0.6), width: 0.8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: RG.gold,
          unselectedLabelColor: RG.textMuted,
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
  final int  repeatMode;
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

            // ── Vinyl artwork ──────────────────────────────────────────
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
                        AnimatedBuilder(
                          animation: pulseCtrl,
                          builder: (_, __) => Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: RG.gold.withValues(
                                    alpha: playing
                                        ? 0.10 + 0.10 * pulseCtrl.value
                                        : 0.0),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 236,
                          height: 236,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: RG.gold.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                        ),
                        RotationTransition(
                          turns: vinylCtrl,
                          child: Hero(
                            tag: 'artwork_${track.id}',
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFF1A1A1A),
                                    Color(0xFF000000),
                                    Color(0xFF111111),
                                  ],
                                  stops: [0.0, 0.4, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: RG.gold.withValues(alpha: 0.20),
                                    blurRadius: 30,
                                    spreadRadius: 4,
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
                                      color: RG.gold.withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: RG.black,
                            border: Border.all(color: RG.border, width: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // ── Track info ─────────────────────────────────────────────
            // FIX: use BlocBuilder so title/artist update when track changes
            BlocBuilder<MusicBloc, MusicState>(
              buildWhen: (p, n) {
                if (p is MusicTracksLoadedState && n is MusicTracksLoadedState) {
                  return p.currentTrackIndex != n.currentTrackIndex;
                }
                return false;
              },
              builder: (context, state) {
                final current = state is MusicTracksLoadedState &&
                        state.visibleTracks.isNotEmpty
                    ? state.visibleTracks[state.currentTrackIndex
                        .clamp(0, state.visibleTracks.length - 1)]
                    : track;
                return Column(
                  children: [
                    Text(
                      current.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                              color: RG.gold.withValues(alpha: 0.35),
                              blurRadius: 10),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current.artist,
                      style: TextStyle(color: RG.textSecondary, fontSize: 14),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // ── Progress bar ───────────────────────────────────────────
            StreamBuilder<Duration>(
              stream: handler.positionStream,
              builder: (context, posSnap) {
                return StreamBuilder<Duration?>(
                  stream: handler.durationStream,
                  builder: (context, durSnap) {
                    final pos   = posSnap.data ?? Duration.zero;
                    final dur   = durSnap.data ?? Duration.zero;
                    final maxMs = dur.inMilliseconds > 0
                        ? dur.inMilliseconds.toDouble()
                        : 1.0;

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                          ),
                          child: Slider(
                            value: pos.inMilliseconds
                                .toDouble()
                                .clamp(0.0, maxMs),
                            max: maxMs,
                            onChanged: (v) => handler
                                .seek(Duration(milliseconds: v.toInt())),
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
                                  style: TextStyle(
                                      color: RG.textMuted, fontSize: 11)),
                              Text(fmtDuration(dur),
                                  style: TextStyle(
                                      color: RG.textMuted, fontSize: 11)),
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

            // ── Playback controls ──────────────────────────────────────
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
                          color: RG.gold,
                          boxShadow: [
                            BoxShadow(
                              color: RG.gold.withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.black,
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
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 22),

            // ── 8D Spatial Audio toggle ────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: RG.surface,
                border: Border.all(
                  color: is8D
                      ? RG.gold.withValues(alpha: 0.5)
                      : RG.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.spatial_audio_rounded,
                    color: is8D ? RG.gold : RG.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '8D Spatial Audio',
                      style: TextStyle(
                        color: is8D ? Colors.white : RG.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: is8D,
                    onChanged: onToggle8D,
                    activeThumbColor: RG.gold,
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
          Icon(Icons.lyrics_rounded, size: 48, color: RG.goldDim),
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
            style: TextStyle(color: RG.textSecondary, fontSize: 13),
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
  final dynamic   handler;

  const _QueueTab({required this.bloc, required this.handler});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, state) {
        final songs = state is MusicTracksLoadedState
            ? state.visibleTracks
            : <JBSong>[];
        final current =
            state is MusicTracksLoadedState ? state.currentTrackIndex : 0;

        if (songs.isEmpty) {
          return Center(
            child: Text('Queue is empty.',
                style:
                    TextStyle(color: RG.textSecondary, fontSize: 13)),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
  final bool   isCurrent;
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
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isCurrent
              ? RG.gold.withValues(alpha: 0.08)
              : RG.surface,
          border: Border.all(
            color: isCurrent ? RG.gold.withValues(alpha: 0.45) : RG.border,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: RG.surfaceHigh,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: QueryArtworkWidget(
                  id: int.tryParse(song.id) ?? 0,
                  type: ArtworkType.AUDIO,
                  artworkFit: BoxFit.cover,
                  artworkWidth: 44,
                  artworkHeight: 44,
                  nullArtworkWidget: Icon(Icons.music_note_rounded,
                      size: 22,
                      color: RG.gold.withValues(alpha: 0.35)),
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
                      color: isCurrent ? RG.gold : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist,
                    style:
                        TextStyle(color: RG.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Icon(Icons.equalizer_rounded, color: RG.gold, size: 20),
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
  final int?      activeMinutes;
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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: RG.surface.withValues(alpha: 0.95),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                  color: RG.gold.withValues(alpha: 0.2), width: 0.8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: RG.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.bedtime_rounded, color: RG.gold, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Sleep Timer',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700),
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
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isActive
                              ? RG.gold.withValues(alpha: 0.15)
                              : RG.surfaceHigh,
                          border: Border.all(
                            color: isActive
                                ? RG.gold.withValues(alpha: 0.6)
                                : RG.border,
                          ),
                        ),
                        child: Text(
                          '$min min',
                          style: TextStyle(
                            color: isActive ? RG.gold : RG.textSecondary,
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
                          color: RG.error.withValues(alpha: 0.10),
                          border: Border.all(
                              color: RG.error.withValues(alpha: 0.4)),
                        ),
                        child: Text('Cancel',
                            style: TextStyle(
                                color: RG.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
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
// CONTROL ICON — shuffle / repeat
// ─────────────────────────────────────────────────────────────────────────────
class _ControlIcon extends StatelessWidget {
  final IconData     icon;
  final bool         active;
  final VoidCallback onTap;

  const _ControlIcon({
    required this.icon,
    required this.active,
    required this.onTap,
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
                color: RG.goldGlow,
              ),
            ),
          Icon(icon, color: active ? RG.gold : RG.textMuted, size: 24),
          if (active)
            Positioned(
              bottom: 4,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: RG.gold),
              ),
            ),
        ],
      ),
    );
  }
}
