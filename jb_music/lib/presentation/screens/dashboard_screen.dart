// lib/presentation/screens/dashboard_screen.dart
// Spotify-style home screen with voice command support
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/presentation/widgets/equalizer_controls.dart';
import 'package:jb_music/screens/player_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _heroAnim;
  late final AnimationController _voicePulse;
  bool _voiceActive = false;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _voicePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    _voicePulse.dispose();
    super.dispose();
  }

  void _openEqualizer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const EqualizerControls(),
    );
  }

  void _toggleVoice(BuildContext ctx) {
    final bloc = ctx.read<MusicBloc>();
    setState(() => _voiceActive = !_voiceActive);
    if (_voiceActive) {
      bloc.add(StartVoiceListeningEvent());
      _showVoiceSnackBar(ctx);
    } else {
      bloc.add(StopVoiceListeningEvent());
    }
  }

  void _showVoiceSnackBar(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1DB954),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(children: [
            Icon(Icons.mic, color: Colors.black, size: 20),
            SizedBox(width: 10),
            Text('Listening… say "play", "next", "pause"',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  void _navigateToPlayer(BuildContext ctx, JBSong track, int index,
      List<JBSong> tracks) {
    ctx.read<MusicBloc>().add(PlayTrackEvent(index: index, tracks: tracks));
    Navigator.push(
      ctx,
      PageRouteBuilder(
        pageBuilder: (c, a, _) => BlocProvider.value(
          value: BlocProvider.of<MusicBloc>(ctx),
          child: PlayerScreen(track: track),
        ),
        transitionsBuilder: (c, a, _, child) => SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: BlocBuilder<MusicBloc, MusicState>(
        builder: (context, state) {
          if (state is MusicTracksLoadingState) {
            return const _LoadingView();
          }
          if (state is MusicTracksLoadedState) {
            return _LoadedView(
              state: state,
              greeting: _greeting(),
              voiceActive: _voiceActive,
              voicePulse: _voicePulse,
              heroAnim: _heroAnim,
              onEqualizer: _openEqualizer,
              onVoiceToggle: () => _toggleVoice(context),
              onTrackTap: (track, index) =>
                  _navigateToPlayer(context, track, index, state.visibleTracks),
              onLike: (track) =>
                  context.read<MusicBloc>().add(ToggleLikeTrackEvent(track)),
            );
          }
          if (state is MusicErrorState) {
            return _ErrorView(message: state.message);
          }
          return const _EmptyView();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADED VIEW — the full Spotify-style home
// ─────────────────────────────────────────────────────────────────────────────
class _LoadedView extends StatelessWidget {
  final MusicTracksLoadedState state;
  final String greeting;
  final bool voiceActive;
  final AnimationController voicePulse;
  final AnimationController heroAnim;
  final VoidCallback onEqualizer;
  final VoidCallback onVoiceToggle;
  final void Function(JBSong, int) onTrackTap;
  final void Function(JBSong) onLike;

  const _LoadedView({
    required this.state,
    required this.greeting,
    required this.voiceActive,
    required this.voicePulse,
    required this.heroAnim,
    required this.onEqualizer,
    required this.onVoiceToggle,
    required this.onTrackTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final tracks = state.visibleTracks;
    final recent = state.recentTracks.isNotEmpty
        ? state.recentTracks.take(6).toList()
        : tracks.take(6).toList();
    final featured = tracks.take(8).toList();
    final liked = state.likedTracks;

    return Stack(
      children: [
        // ── Spotify-style ambient gradient at top ─────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          height: 280,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1DB954), Color(0xFF121212)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),

        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top bar ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          greeting,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      // Voice mic button
                      AnimatedBuilder(
                        animation: voicePulse,
                        builder: (_, __) {
                          return GestureDetector(
                            onTap: onVoiceToggle,
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: voiceActive
                                    ? Color.lerp(
                                        const Color(0xFF1DB954),
                                        const Color(0xFF14833B),
                                        voicePulse.value)!
                                    : Colors.white12,
                                boxShadow: voiceActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF1DB954)
                                              .withValues(
                                                  alpha: 0.4 *
                                                      voicePulse.value),
                                          blurRadius: 16,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                voiceActive ? Icons.mic : Icons.mic_none,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded,
                            color: Colors.white70, size: 22),
                        onPressed: onEqualizer,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Quick-access recently played grid ─────────────────────────
            if (recent.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final track = recent[i];
                      final isActive =
                          state.currentTrackIndex < state.visibleTracks.length &&
                          state.visibleTracks[state.currentTrackIndex].path ==
                              track.path;
                      return _QuickCard(
                        track: track,
                        isActive: isActive,
                        isPlaying: isActive && state.isPlaying,
                        onTap: () {
                          final idx = state.visibleTracks
                              .indexWhere((t) => t.path == track.path);
                          onTrackTap(track, idx >= 0 ? idx : 0);
                        },
                      );
                    },
                    childCount: recent.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 3.5,
                  ),
                ),
              ),
            ],

            // ── "Made for you" — featured cards ───────────────────────────
            if (featured.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Row(
                    children: [
                      const Text(
                        'Made for you',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'See all',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: featured.length,
                    itemBuilder: (ctx, i) {
                      final track = featured[i];
                      final isActive =
                          state.currentTrackIndex < state.visibleTracks.length &&
                          state.visibleTracks[state.currentTrackIndex].path ==
                              track.path;
                      return _FeaturedCard(
                        track: track,
                        isActive: isActive,
                        isPlaying: isActive && state.isPlaying,
                        onTap: () {
                          final idx = state.visibleTracks
                              .indexWhere((t) => t.path == track.path);
                          onTrackTap(track, idx >= 0 ? idx : 0);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],

            // ── Liked songs section ────────────────────────────────────────
            if (liked.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Text(
                    'Your Liked Songs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: liked.length,
                    itemBuilder: (ctx, i) {
                      final track = liked[i];
                      return _LikedChip(
                        track: track,
                        onTap: () {
                          final idx = state.visibleTracks
                              .indexWhere((t) => t.path == track.path);
                          onTrackTap(track, idx >= 0 ? idx : 0);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],

            // ── All tracks ────────────────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Row(
                  children: [
                    const Text(
                      'Your Library',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text('${tracks.length} songs',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12)),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, index) {
                  final track = tracks[index];
                  final isActive = state.currentTrackIndex == index;
                  final isLiked =
                      state.likedTracks.any((s) => s.path == track.path);
                  return _TrackRow(
                    track: track,
                    index: index,
                    isActive: isActive,
                    isPlaying: isActive && state.isPlaying,
                    isLiked: isLiked,
                    onTap: () => onTrackTap(track, index),
                    onLike: () => onLike(track),
                  );
                },
                childCount: tracks.length,
              ),
            ),

            // Bottom padding for mini player
            const SliverToBoxAdapter(child: SizedBox(height: 160)),
          ],
        ),

        // ── Mini player ───────────────────────────────────────────────────
        if (tracks.isNotEmpty)
          Positioned(
            bottom: 12, left: 10, right: 10,
            child: _SpotifyMiniPlayer(
              state: state,
              onTap: () {
                final track =
                    tracks[state.currentTrackIndex.clamp(0, tracks.length - 1)];
                onTrackTap(track, state.currentTrackIndex);
              },
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK CARD — 2-column grid item (Spotify "recent" style)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickCard extends StatelessWidget {
  final JBSong track;
  final bool isActive, isPlaying;
  final VoidCallback onTap;

  const _QuickCard({
    required this.track,
    required this.isActive,
    required this.isPlaying,
    required this.onTap,
  });

  Color _color() {
    const palette = [
      Color(0xFF8D65C8), Color(0xFF1DB954), Color(0xFFE91E63),
      Color(0xFF2196F3), Color(0xFFFF9800), Color(0xFF009688),
      Color(0xFFF44336), Color(0xFF3F51B5),
    ];
    return palette[track.id.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive ? _color().withValues(alpha: 0.3) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: double.infinity,
              decoration: BoxDecoration(
                color: _color(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
              ),
              child: isPlaying
                  ? const _MiniEqualizer()
                  : const Icon(Icons.music_note, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                track.title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURED CARD — horizontal scroll album-style
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final JBSong track;
  final bool isActive, isPlaying;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.track,
    required this.isActive,
    required this.isPlaying,
    required this.onTap,
  });

  Color _color() {
    const palette = [
      Color(0xFF8D65C8), Color(0xFF1DB954), Color(0xFFE91E63),
      Color(0xFF2196F3), Color(0xFFFF9800), Color(0xFF009688),
      Color(0xFFF44336), Color(0xFF3F51B5),
    ];
    return palette[track.id.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art
            Stack(
              children: [
                Container(
                  width: 148, height: 148,
                  decoration: BoxDecoration(
                    color: _color().withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: isActive
                        ? Border.all(
                            color: const Color(0xFF1DB954), width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Music note icon as album art placeholder
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: _color(),
                          shape: BoxShape.circle,
                        ),
                        child: isPlaying
                            ? const _MiniEqualizer()
                            : const Icon(Icons.music_note,
                                color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1DB954),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black, size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 2),
            Text(
              track.artist,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIKED CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _LikedChip extends StatelessWidget {
  final JBSong track;
  final VoidCallback onTap;
  const _LikedChip({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Color(0xFF1DB954), size: 16),
            const SizedBox(width: 8),
            Text(
              track.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRACK ROW — Spotify list item style
// ─────────────────────────────────────────────────────────────────────────────
class _TrackRow extends StatelessWidget {
  final JBSong track;
  final int index;
  final bool isActive, isPlaying, isLiked;
  final VoidCallback onTap, onLike;

  const _TrackRow({
    required this.track, required this.index,
    required this.isActive, required this.isPlaying,
    required this.isLiked, required this.onTap, required this.onLike,
  });

  String _fmt(int ms) {
    final d = Duration(milliseconds: ms);
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Color _color() {
    const palette = [
      Color(0xFF8D65C8), Color(0xFF1DB954), Color(0xFFE91E63),
      Color(0xFF2196F3), Color(0xFFFF9800), Color(0xFF009688),
    ];
    return palette[track.id.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withValues(alpha: 0.04),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // Track art
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _color().withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isPlaying
                      ? const _MiniEqualizer()
                      : Icon(Icons.music_note,
                          color: _color(), size: 20),
                ),
                if (isActive && !isPlaying)
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.pause, color: Colors.white, size: 18),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Title + artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF1DB954)
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.artist,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Duration
            Text(
              _fmt(track.durationMs),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12),
            ),
            const SizedBox(width: 8),
            // Like button
            GestureDetector(
              onTap: onLike,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked
                      ? const Color(0xFF1DB954)
                      : Colors.white38,
                  size: 18,
                ),
              ),
            ),
            // More menu
            const Icon(Icons.more_vert,
                color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPOTIFY-STYLE MINI PLAYER
// ─────────────────────────────────────────────────────────────────────────────
class _SpotifyMiniPlayer extends StatelessWidget {
  final MusicTracksLoadedState state;
  final VoidCallback onTap;
  const _SpotifyMiniPlayer({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tracks = state.visibleTracks;
    final idx = state.currentTrackIndex.clamp(0, tracks.length - 1);
    final track = tracks[idx];
    final bloc = context.read<MusicBloc>();
    final isLiked = state.likedTracks.any((s) => s.path == track.path);

    Color artColor() {
      const palette = [
        Color(0xFF8D65C8), Color(0xFF1DB954), Color(0xFFE91E63),
        Color(0xFF2196F3), Color(0xFFFF9800), Color(0xFF009688),
      ];
      return palette[track.id.hashCode.abs() % palette.length];
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            StreamBuilder<Duration>(
              stream: bloc.audioHandler.positionStream,
              builder: (_, posSnap) => StreamBuilder<Duration?>(
                stream: bloc.audioHandler.durationStream,
                builder: (_, durSnap) {
                  final pos = posSnap.data ?? Duration.zero;
                  final dur = durSnap.data ?? Duration.zero;
                  final progress = dur.inMilliseconds > 0
                      ? (pos.inMilliseconds / dur.inMilliseconds)
                          .clamp(0.0, 1.0)
                      : 0.0;
                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1DB954)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Art thumb
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: artColor(),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: state.isPlaying
                        ? const _MiniEqualizer()
                        : const Icon(Icons.music_note,
                            color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Title/artist
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          track.artist,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Like
                  GestureDetector(
                    onTap: () => bloc.add(ToggleLikeTrackEvent(track)),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked
                          ? const Color(0xFF1DB954)
                          : Colors.white38,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Controls
                  GestureDetector(
                    onTap: () => bloc.audioHandler.skipToPrevious(),
                    child: const Icon(Icons.skip_previous_rounded,
                        color: Colors.white70, size: 28),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => bloc.add(TogglePlaybackEvent()),
                    child: Container(
                      width: 38, height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        state.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => bloc.audioHandler.skipToNext(),
                    child: const Icon(Icons.skip_next_rounded,
                        color: Colors.white70, size: 28),
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

// ─────────────────────────────────────────────────────────────────────────────
// MINI EQUALIZER ANIMATION
// ─────────────────────────────────────────────────────────────────────────────
class _MiniEqualizer extends StatefulWidget {
  const _MiniEqualizer();
  @override
  State<_MiniEqualizer> createState() => _MiniEqualizerState();
}

class _MiniEqualizerState extends State<_MiniEqualizer>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
              vsync: this,
              duration: Duration(milliseconds: 300 + _rng.nextInt(300)))
          ..repeat(reverse: true),
    );
    _anims = _ctrls
        .map((c) => Tween<double>(begin: 3, end: 14)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) => Container(
              width: 3,
              height: _anims[i].value,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING / ERROR / EMPTY VIEWS
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44, height: 44,
            child: CircularProgressIndicator(
              color: Color(0xFF1DB954),
              strokeWidth: 2,
            ),
          ),
          SizedBox(height: 16),
          Text('Loading your music…',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_off_rounded, color: Colors.white24, size: 56),
          SizedBox(height: 16),
          Text('No music found',
              style: TextStyle(color: Colors.white54, fontSize: 16,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Add songs to your device to get started',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}