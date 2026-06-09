// lib/presentation/screens/dashboard_screen.dart
// FIXED: time-based greeting, real local songs, trending section, like button
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

  // ── Time-based greeting ──────────────────────────────────────────────────
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  String _greetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    if (hour < 21) return '🌆';
    return '🌙';
  }

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
                    width: 48, height: 48,
                    child: CircularProgressIndicator(
                      color: RG.gold, strokeWidth: 2,
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
            final likedCount = state.likedTracks.length;
            // "Trending" = most recently added (first 5 tracks)
            final trending = state.visibleTracks.take(5).toList();

            return Stack(
              children: [
                // Ambient glow
                Positioned(
                  top: -80, left: -60,
                  child: Container(
                    width: 280, height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RG.gold.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  top: 60, right: -80,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RG.roseMid.withValues(alpha: 0.04),
                    ),
                  ),
                ),

                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── App bar ────────────────────────────────────────────
                    SliverAppBar(
                      expandedHeight: 120,
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
                              colors: [RG.black, RG.black.withValues(alpha: 0)],
                            ),
                          ),
                        ),
                        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                        title: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greetingEmoji()} ${_greeting()}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: RG.textMuted,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
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
                                    fontSize: 22, fontWeight: FontWeight.w800,
                                    color: Colors.white, letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text('${state.visibleTracks.length} tracks',
                              style: const TextStyle(color: RG.textMuted, fontSize: 12)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune_rounded, color: RG.textSecondary, size: 22),
                          onPressed: _openEqualizer,
                        ),
                      ],
                    ),

                    // ── Stats cards ───────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(child: _HomeStatCard(
                              title: 'Library',
                              value: '${state.visibleTracks.length}',
                              icon: Icons.library_music_rounded,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _HomeStatCard(
                              title: 'Liked',
                              value: '$likedCount',
                              icon: Icons.favorite_rounded,
                            )),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ── Trending / Recently Added ─────────────────────────
                    if (trending.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Row(
                            children: [
                              const Text('🔥 Today\'s Trending',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  )),
                              const Spacer(),
                              Text('See all',
                                  style: TextStyle(color: RG.gold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 130,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: trending.length,
                            itemBuilder: (ctx, i) {
                              final track = trending[i];
                              final isActive = state.currentTrackIndex == i;
                              return GestureDetector(
                                onTap: () {
                                  context.read<MusicBloc>().add(
                                    PlayTrackEvent(index: i, tracks: state.visibleTracks),
                                  );
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (ctx, anim, _) => BlocProvider.value(
                                        value: BlocProvider.of<MusicBloc>(ctx),
                                        child: PlayerScreen(track: track),
                                      ),
                                      transitionsBuilder: (ctx, anim, _, child) =>
                                          SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 1), end: Offset.zero,
                                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                        child: child,
                                      ),
                                      transitionDuration: const Duration(milliseconds: 400),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 110,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? RG.gold.withValues(alpha: 0.15)
                                        : RG.surfaceHigh,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isActive
                                          ? RG.gold.withValues(alpha: 0.5)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 56, height: 56,
                                        decoration: BoxDecoration(
                                          color: _artworkColor(track),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.music_note_rounded,
                                          color: isActive ? RG.gold : RG.textMuted,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          track.title,
                                          style: TextStyle(
                                            color: isActive ? RG.gold : Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          track.artist,
                                          style: const TextStyle(
                                            color: RG.textMuted, fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],

                    // ── Filter tabs ───────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _FilterTabs(
                          selected: _filter,
                          onChanged: (f) => setState(() => _filter = f),
                        ),
                      ),
                    ),

                    // ── Library header ────────────────────────────────────
                    if (state.visibleTracks.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Row(
                            children: [
                              Text('Your Library',
                                  style: RG.subtitleStyle.copyWith(
                                      fontSize: 15, letterSpacing: 0.3)),
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

                    // ── Track list ────────────────────────────────────────
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final track = state.visibleTracks[index];
                          final isLiked = state.likedTracks.any((s) => s.path == track.path);
                          return _TrackTile(
                            track: track,
                            index: index,
                            isActive: state.currentTrackIndex == index,
                            isPlaying: state.isPlaying && state.currentTrackIndex == index,
                            isLiked: isLiked,
                            onTap: () => context.read<MusicBloc>().add(
                              PlayTrackEvent(index: index, tracks: state.visibleTracks),
                            ),
                            onLike: () => context.read<MusicBloc>().add(
                              ToggleLikeTrackEvent(track),
                            ),
                          );
                        },
                        childCount: state.visibleTracks.length,
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 140)),
                  ],
                ),

                // ── Mini player ───────────────────────────────────────────
                if (state.visibleTracks.isNotEmpty)
                  Positioned(
                    bottom: 16, left: 12, right: 12,
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
                  const Icon(Icons.error_outline_rounded, color: RG.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message, style: const TextStyle(color: Colors.redAccent)),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.music_off_rounded, color: RG.textMuted, size: 56),
                const SizedBox(height: 16),
                Text('No tracks found', style: RG.bodyStyle.copyWith(color: RG.textMuted)),
                const SizedBox(height: 8),
                const Text('Add music to your device to get started', style: RG.captionStyle),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _artworkColor(JBSong track) {
    final colors = [
      const Color(0xFF1A3A4A), const Color(0xFF2A1A4A),
      const Color(0xFF1A4A2A), const Color(0xFF4A2A1A),
      const Color(0xFF3A1A3A), const Color(0xFF1A2A4A),
    ];
    return colors[track.id.hashCode.abs() % colors.length];
  }
}

// ── Filter tabs ────────────────────────────────────────────────────────────────
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? RG.gold : RG.surfaceHigh,
                  borderRadius: BorderRadius.circular(RG.radiusFull),
                  boxShadow: isActive ? RG.cyanGlow : null,
                  border: isActive ? null : Border.all(color: RG.cardStroke, width: 1),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? RG.black : RG.textSecondary,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13, letterSpacing: 0.3,
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

// ── Track tile ─────────────────────────────────────────────────────────────────
class _TrackTile extends StatelessWidget {
  final JBSong track;
  final int index;
  final bool isActive, isPlaying, isLiked;
  final VoidCallback onTap, onLike;

  const _TrackTile({
    required this.track, required this.index,
    required this.isActive, required this.isPlaying,
    required this.isLiked, required this.onTap, required this.onLike,
  });

  String _fmt(int ms) {
    final d = Duration(milliseconds: ms);
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Color _artworkColor() {
    final colors = [
      const Color(0xFF1A3A4A), const Color(0xFF2A1A4A),
      const Color(0xFF1A4A2A), const Color(0xFF4A2A1A),
      const Color(0xFF3A1A3A), const Color(0xFF1A2A4A),
    ];
    return colors[track.id.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (ctx, anim, _) => BlocProvider.value(
              value: BlocProvider.of<MusicBloc>(ctx),
              child: PlayerScreen(track: track),
            ),
            transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? RG.gold.withValues(alpha: 0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(RG.radiusLG),
          border: isActive
              ? Border.all(color: RG.gold.withValues(alpha: 0.25), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Hero(
              tag: 'artwork_${track.id}',
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: _artworkColor(),
                  borderRadius: BorderRadius.circular(RG.radiusMD),
                  border: isActive
                      ? Border.all(color: RG.gold.withValues(alpha: 0.6), width: 1.5)
                      : null,
                  boxShadow: isActive
                      ? [BoxShadow(color: RG.gold.withValues(alpha: 0.2), blurRadius: 12)]
                      : null,
                ),
                child: isPlaying
                    ? const _PlayingIndicator()
                    : Icon(Icons.music_note_rounded,
                        color: isActive ? RG.gold : RG.textMuted, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      color: isActive ? RG.gold : RG.textPrimary,
                      fontWeight: FontWeight.w600, fontSize: 14,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.artist,
                    style: const TextStyle(color: RG.textMuted, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              _fmt(track.durationMs),
              style: TextStyle(
                color: isActive ? RG.gold.withValues(alpha: 0.7) : RG.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onLike,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.redAccent : RG.textDisabled,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.more_vert_rounded, color: RG.textDisabled, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Playing indicator ─────────────────────────────────────────────────────────
class _PlayingIndicator extends StatefulWidget {
  const _PlayingIndicator();
  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(vsync: this, duration: Duration(milliseconds: 400 + i * 100))
        ..repeat(reverse: true),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 4, end: 18)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
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
            builder: (_, __) => Container(
              width: 3,
              height: _animations[i].value,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: RG.gold,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: RG.gold.withValues(alpha: 0.6), blurRadius: 4)],
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
    final isLiked = state.likedTracks.any((s) => s.path == track.path);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (ctx, anim, _) => BlocProvider.value(
            value: BlocProvider.of<MusicBloc>(ctx),
            child: PlayerScreen(track: track),
          ),
          transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 24, offset: const Offset(0, 8)),
            BoxShadow(color: RG.gold.withValues(alpha: 0.08), blurRadius: 20),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress line
            StreamBuilder<Duration>(
              stream: bloc.audioHandler.positionStream,
              builder: (_, posSnap) => StreamBuilder<Duration?>(
                stream: bloc.audioHandler.durationStream,
                builder: (_, durSnap) {
                  final pos = posSnap.data ?? Duration.zero;
                  final dur = durSnap.data ?? Duration.zero;
                  final progress = dur.inMilliseconds > 0
                      ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                      : 0.0;
                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(RG.radiusXL)),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 2,
                      backgroundColor: RG.gold.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(RG.gold),
                    ),
                  );
                },
              ),
            ),
            // Controls row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: RG.surfacePop,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: RG.gold.withValues(alpha: 0.3), width: 1),
                    ),
                    child: const Icon(Icons.music_note_rounded, color: RG.gold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(track.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(track.artist,
                            style: const TextStyle(color: RG.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  // Like button in mini player
                  GestureDetector(
                    onTap: () => bloc.add(ToggleLikeTrackEvent(track)),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.redAccent : Colors.white38,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white54, size: 24),
                    onPressed: () => bloc.audioHandler.skipToPrevious(),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => bloc.add(TogglePlaybackEvent()),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: RG.gold, boxShadow: RG.cyanGlow),
                      child: Icon(
                        state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: RG.black, size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white54, size: 24),
                    onPressed: () => bloc.audioHandler.skipToNext(),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
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

// ── Stat card ──────────────────────────────────────────────────────────────────
class _HomeStatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const _HomeStatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }
}