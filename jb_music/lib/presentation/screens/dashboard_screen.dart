// lib/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/presentation/widgets/equalizer_controls.dart';
import 'package:jb_music/screens/player_screen.dart';

enum TrackFilter { all, albums, artists }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  TrackFilter _filter = TrackFilter.all;

  void _openEqualizer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const EqualizerControls(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RG.black,
      body: BlocBuilder<MusicBloc, MusicState>(
        builder: (context, state) {
          if (state is MusicTracksLoadingState) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: RG.gold,
                      strokeWidth: 2,
                      backgroundColor: RG.gold.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Loading your music...',
                      style: RG.captionStyle.copyWith(
                          color: RG.textMuted, letterSpacing: 0.5)),
                ],
              ),
            );
          }

          if (state is MusicTracksLoadedState) {
            return Stack(
              children: [
                // ── Ambient background glow ──────────────────────────────
                Positioned(
                  top: -80,
                  left: -60,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RG.gold.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  right: -80,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RG.roseMid.withValues(alpha: 0.04),
                    ),
                  ),
                ),

                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── App bar ──────────────────────────────────────────
                    SliverAppBar(
                      expandedHeight: 110,
                      floating: true,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                RG.black,
                                RG.black.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                        titlePadding:
                            const EdgeInsets.only(left: 20, bottom: 16),
                        title: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: RG.gold,
                                boxShadow: RG.cyanGlow,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'JB Musiq',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${state.visibleTracks.length} tracks',
                            style: const TextStyle(
                              color: RG.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune_rounded,
                              color: RG.textSecondary, size: 22),
                          onPressed: _openEqualizer,
                        ),
                      ],
                    ),

                    // ── Search bar ───────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: _NeonSearchBar(
                            tracks: state.visibleTracks),
                      ),
                    ),

                    // ── Filter tabs ──────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _FilterTabs(
                          selected: _filter,
                          onChanged: (f) =>
                              setState(() => _filter = f),
                        ),
                      ),
                    ),

                    // ── Library header ───────────────────────────────────
                    if (state.visibleTracks.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Row(
                            children: [
                              Text('Your Library',
                                  style: RG.subtitleStyle.copyWith(
                                      fontSize: 15,
                                      letterSpacing: 0.3)),
                              const Spacer(),
                              Text('Sort',
                                  style: RG.captionStyle.copyWith(
                                      color: RG.gold, fontSize: 12)),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: RG.gold, size: 16),
                            ],
                          ),
                        ),
                      ),

                    // ── Track list ───────────────────────────────────────
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final track = state.visibleTracks[index];
                          return _TrackTile(
                            track: track,
                            index: index,
                            isActive:
                                state.currentTrackIndex == index,
                            isPlaying: state.isPlaying &&
                                state.currentTrackIndex == index,
                            onTap: () => context
                                .read<MusicBloc>()
                                .add(PlayTrackEvent(
                                  index: index,
                                  tracks: state.visibleTracks,
                                )),
                          );
                        },
                        childCount: state.visibleTracks.length,
                      ),
                    ),

                    const SliverToBoxAdapter(
                        child: SizedBox(height: 140)),
                  ],
                ),

                // ── Mini player ──────────────────────────────────────────
                if (state.visibleTracks.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 12,
                    right: 12,
                    child: _MiniPlayer(state: state),
                  ),
              ],
            );
          }

          if (state is MusicErrorState) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: RG.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style:
                          const TextStyle(color: Colors.redAccent)),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.music_off_rounded,
                    color: RG.textMuted, size: 56),
                const SizedBox(height: 16),
                Text('No tracks found',
                    style:
                        RG.bodyStyle.copyWith(color: RG.textMuted)),
                const SizedBox(height: 8),
                const Text('Add music to your device to get started',
                    style: RG.captionStyle),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Neon search bar ───────────────────────────────────────────────────────────
class _NeonSearchBar extends StatefulWidget {
  final List<JBSong> tracks;
  const _NeonSearchBar({required this.tracks});

  @override
  State<_NeonSearchBar> createState() => _NeonSearchBarState();
}

class _NeonSearchBarState extends State<_NeonSearchBar> {
  final _controller = TextEditingController();
  bool _focused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: RG.gold.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 0,
                )
              ]
            : [],
      ),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search songs, artists, albums...',
            hintStyle:
                const TextStyle(color: RG.textMuted, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded,
                color: _focused ? RG.gold : RG.textMuted, size: 20),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: RG.textMuted, size: 18),
                    onPressed: () {
                      _controller.clear();
                      context
                          .read<MusicBloc>()
                          .add(SearchTracksEvent(''));
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: RG.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: RG.gold.withValues(alpha: 0.5), width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (q) {
            setState(() {});
            context.read<MusicBloc>().add(SearchTracksEvent(q));
          },
        ),
      ),
    );
  }
}

// ── Filter tabs ───────────────────────────────────────────────────────────────
class _FilterTabs extends StatelessWidget {
  final TrackFilter selected;
  final ValueChanged<TrackFilter> onChanged;
  const _FilterTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TrackFilter.values.map((f) {
          final label = f.name[0].toUpperCase() + f.name.substring(1);
          final isActive = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? RG.gold : RG.surfaceHigh,
                  borderRadius:
                      BorderRadius.circular(RG.radiusFull),
                  boxShadow: isActive ? RG.cyanGlow : null,
                  border: isActive
                      ? null
                      : Border.all(
                          color: RG.cardStroke, width: 1),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? RG.black : RG.textSecondary,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.w400,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Track tile ────────────────────────────────────────────────────────────────
class _TrackTile extends StatelessWidget {
  final JBSong track;
  final int index;
  final bool isActive;
  final bool isPlaying;
  final VoidCallback onTap;

  const _TrackTile({
    required this.track,
    required this.index,
    required this.isActive,
    required this.isPlaying,
    required this.onTap,
  });

  String _fmt(int ms) {
    final d = Duration(milliseconds: ms);
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Color _artworkColor() {
    final colors = [
      const Color(0xFF1A3A4A),
      const Color(0xFF2A1A4A),
      const Color(0xFF1A4A2A),
      const Color(0xFF4A2A1A),
      const Color(0xFF3A1A3A),
      const Color(0xFF1A2A4A),
    ];
    final idx = track.id.hashCode.abs() % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, _) =>
                BlocProvider.value(
              value: BlocProvider.of<MusicBloc>(context),
              child: PlayerScreen(track: track),
            ),
            transitionsBuilder: (context, animation, _, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? RG.gold.withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(RG.radiusLG),
          border: isActive
              ? Border.all(
                  color: RG.gold.withValues(alpha: 0.25), width: 1)
              : null,
        ),
        child: Row(
          children: [
            // ── Artwork ────────────────────────────────────────────────
            Hero(
              tag: 'artwork_${track.id}',
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _artworkColor(),
                  borderRadius: BorderRadius.circular(RG.radiusMD),
                  border: isActive
                      ? Border.all(
                          color: RG.gold.withValues(alpha: 0.6),
                          width: 1.5)
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: RG.gold.withValues(alpha: 0.2),
                            blurRadius: 12,
                          )
                        ]
                      : null,
                ),
                child: isPlaying
                    ? const _PlayingIndicator()  // ← const added
                    : Icon(
                        Icons.music_note_rounded,
                        color: isActive ? RG.gold : RG.textMuted,
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Info ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      color: isActive ? RG.gold : RG.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.artist,
                    style: const TextStyle(
                      color: RG.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Duration ───────────────────────────────────────────────
            Text(
              _fmt(track.durationMs),
              style: TextStyle(
                color: isActive
                    ? RG.gold.withValues(alpha: 0.7)
                    : RG.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.more_vert_rounded,
                color: RG.textDisabled, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Animated playing indicator ────────────────────────────────────────────────
class _PlayingIndicator extends StatefulWidget {
  const _PlayingIndicator(); // ← const constructor added

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 100),
      )..repeat(reverse: true),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 4, end: 18).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, _) => Container(
              width: 3,
              height: _animations[i].value,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: RG.gold,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                      color: RG.gold.withValues(alpha: 0.6),
                      blurRadius: 4)
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Mini player ───────────────────────────────────────────────────────────────
class _MiniPlayer extends StatelessWidget {
  final MusicTracksLoadedState state;
  const _MiniPlayer({required this.state});

  @override
  Widget build(BuildContext context) {
    final track = state.visibleTracks[state.currentTrackIndex];
    final bloc = context.read<MusicBloc>();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => BlocProvider.value(
            value: BlocProvider.of<MusicBloc>(context),
            child: PlayerScreen(track: track),
          ),
          transitionsBuilder: (context, animation, _, child) =>
              SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: RG.surfaceHigh,
          borderRadius: BorderRadius.circular(RG.radiusXL),
          border: Border.all(color: RG.gold.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: RG.gold.withValues(alpha: 0.08),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Progress line ────────────────────────────────────────
            StreamBuilder<Duration>(
              stream: bloc.audioHandler.positionStream,
              builder: (context, posSnap) {
                return StreamBuilder<Duration?>(
                  stream: bloc.audioHandler.durationStream,
                  builder: (context, durSnap) {
                    final pos = posSnap.data ?? Duration.zero;
                    final dur = durSnap.data ?? Duration.zero;
                    final progress = dur.inMilliseconds > 0
                        ? (pos.inMilliseconds / dur.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0;
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(RG.radiusXL)),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 2,
                        backgroundColor:
                            RG.gold.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            RG.gold),
                      ),
                    );
                  },
                );
              },
            ),

            // ── Controls row ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: RG.surfacePop,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: RG.gold.withValues(alpha: 0.3),
                          width: 1),
                    ),
                    child: const Icon(Icons.music_note_rounded,
                        color: RG.gold, size: 20),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          track.artist,
                          style: const TextStyle(
                              color: RG.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded,
                        color: Colors.white54, size: 24),
                    onPressed: () =>
                        bloc.audioHandler.skipToPrevious(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),

                  GestureDetector(
                    onTap: () => bloc.add(TogglePlaybackEvent()),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: RG.gold,
                        boxShadow: RG.cyanGlow,
                      ),
                      child: Icon(
                        state.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: RG.black,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded,
                        color: Colors.white54, size: 24),
                    onPressed: () => bloc.audioHandler.skipToNext(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}