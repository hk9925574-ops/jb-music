// lib/presentation/screens/dashboard_screen.dart
//
// JB MUSIC — NOVA HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────
// A living, breathing home screen that feels entirely handcrafted.
//
// Sections:
//  1. Dynamic Hero — greeting + ambient orb + stats ribbon
//  2. Continue Listening — horizontal cards with album glow
//  3. Quick Picks — 2×3 grid of mood cards
//  4. Favorites — pill scroll row
//  5. All Tracks — glass list tiles
//
// Animations:
//  • Staggered entry (each section fades + slides in sequence)
//  • Hero ambient pulsing orb background
//  • Card press scale with haptics
//  • Playing state indicator (waveform animation on active tile)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/jb_design_system.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/presentation/widgets/equalizer_controls.dart';
import 'package:jb_music/screens/player_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _heroCtrl;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5)  return 'Late night 🌙';
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening 🌆';
    return 'Good night 🌙';
  }

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  void _navigateToPlayer(JBSong track, int index, List<JBSong> tracks) {
    HapticFeedback.lightImpact();
    context.read<MusicBloc>().add(PlayTrackEvent(index: index, tracks: tracks));
    Navigator.of(context).push(JBAnim.slideUp(PlayerScreen(track: track)));
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
      backgroundColor: JBColors.void0,
      body: BlocBuilder<MusicBloc, MusicState>(
        builder: (context, state) {
          if (state is MusicTracksLoadingState) return const _LoadingView();
          if (state is MusicErrorState) return _ErrorView(message: state.message);
          if (state is MusicTracksLoadedState) {
            return _LoadedView(
              state: state,
              greeting: _greeting,
              heroCtrl: _heroCtrl,
              onTrackTap: _navigateToPlayer,
              onEqualizerTap: _openEqualizer,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOADED VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _LoadedView extends StatelessWidget {
  final MusicTracksLoadedState state;
  final String greeting;
  final AnimationController heroCtrl;
  final void Function(JBSong, int, List<JBSong>) onTrackTap;
  final VoidCallback onEqualizerTap;

  const _LoadedView({
    required this.state, required this.greeting,
    required this.heroCtrl, required this.onTrackTap,
    required this.onEqualizerTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _HeroSection(
            greeting: greeting,
            state: state,
            ctrl: heroCtrl,
            onEqualizerTap: onEqualizerTap,
          ),
        ),

        // ── Continue Listening ────────────────────────────────────────────
        if (state.recentTracks.isNotEmpty)
          SliverToBoxAdapter(
            child: const _SectionLabel(
              title: 'Continue Listening',
              subtitle: 'Pick up where you left off',
            ).animate(delay: 100.ms).fadeIn(duration: 500.ms).slideX(begin: -0.1),
          ),
        if (state.recentTracks.isNotEmpty)
          SliverToBoxAdapter(
            child: _ContinueListeningRow(
              tracks: state.recentTracks,
              currentIndex: state.currentTrackIndex,
              isPlaying: state.isPlaying,
              onTap: onTrackTap,
            ).animate(delay: 150.ms).fadeIn(duration: 500.ms),
          ),

        // ── Quick Picks ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _SectionLabel(
            title: 'Quick Picks',
            subtitle: '${state.visibleTracks.length} tracks',
            action: 'Shuffle All',
            onAction: () {
              if (state.visibleTracks.isNotEmpty) {
                final tracks = [...state.visibleTracks]..shuffle();
                onTrackTap(tracks.first, 0, tracks);
              }
            },
          ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideX(begin: -0.1),
        ),
        SliverToBoxAdapter(
          child: _QuickPicksGrid(
            tracks: state.visibleTracks,
            currentIndex: state.currentTrackIndex,
            isPlaying: state.isPlaying,
            onTap: onTrackTap,
          ).animate(delay: 250.ms).fadeIn(duration: 500.ms),
        ),

        // ── Favorites ─────────────────────────────────────────────────────
        if (state.likedTracks.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionLabel(
              title: 'Your Favorites',
              subtitle: '${state.likedTracks.length} songs you love',
            ).animate(delay: 300.ms).fadeIn(duration: 500.ms).slideX(begin: -0.1),
          ),
          SliverToBoxAdapter(
            child: _FavoritesPillRow(
              tracks: state.likedTracks,
              currentIndex: state.currentTrackIndex,
              isPlaying: state.isPlaying,
              onTap: onTrackTap,
            ).animate(delay: 350.ms).fadeIn(duration: 500.ms),
          ),
        ],

        // ── All Tracks ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: const _SectionLabel(
            title: 'All Music',
            subtitle: 'Your complete library',
          ).animate(delay: 400.ms).fadeIn(duration: 500.ms).slideX(begin: -0.1),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _TrackListTile(
                track: state.visibleTracks[i],
                index: i,
                tracks: state.visibleTracks,
                isActive: i == state.currentTrackIndex,
                isPlaying: state.isPlaying,
                isLiked: state.likedTracks.any((t) => t.id == state.visibleTracks[i].id),
                onTap: onTrackTap,
              ).animate(delay: Duration(milliseconds: 420 + i * 15))
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.15, end: 0),
              childCount: state.visibleTracks.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HERO SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatefulWidget {
  final String greeting;
  final MusicTracksLoadedState state;
  final AnimationController ctrl;
  final VoidCallback onEqualizerTap;

  const _HeroSection({
    required this.greeting, required this.state,
    required this.ctrl, required this.onEqualizerTap,
  });

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        final t = _orbCtrl.value;
        return Container(
          height: 220,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Stack(
            children: [
              // Ambient orb
              Positioned(
                right: -30 + t * 20,
                top: -20 + t * 15,
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: JBColors.nova.withValues(alpha: 0.08 + t * 0.04),
                  ),
                  child: const _BlurredCircle(sigma: 60),
                ),
              ),
              Positioned(
                left: 0 + t * 10,
                bottom: 0,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: JBColors.pulse.withValues(alpha: 0.05 + t * 0.02),
                  ),
                  child: const _BlurredCircle(sigma: 50),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 56, 4, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.greeting, style: JBType.caption.copyWith(
                              color: JBColors.nova, fontWeight: FontWeight.w600,
                            ))
                                .animate(controller: widget.ctrl)
                                .fadeIn(duration: 600.ms),
                            const SizedBox(height: 2),
                            ShaderMask(
                              shaderCallback: (r) => JBGradients.sectionTitle.createShader(r),
                              child: Text('JB Music',
                                style: JBType.h1.copyWith(color: Colors.white),
                              ),
                            )
                                .animate(controller: widget.ctrl)
                                .fadeIn(duration: 700.ms, delay: 50.ms)
                                .slideX(begin: -0.1, end: 0),
                          ],
                        ),
                        Row(
                          children: [
                            _HeaderBtn(
                              icon: Icons.equalizer_rounded,
                              color: JBColors.nova,
                              onTap: widget.onEqualizerTap,
                            ),
                            const SizedBox(width: 10),
                            _HeaderBtn(
                              icon: Icons.search_rounded,
                              onTap: () {},
                            ),
                          ],
                        ).animate(controller: widget.ctrl)
                          .fadeIn(duration: 600.ms, delay: 100.ms),
                      ],
                    ),

                    const Spacer(),

                    // Stats ribbon
                    _StatsRibbon(state: widget.state)
                        .animate(controller: widget.ctrl)
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideY(begin: 0.3, end: 0),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BlurredCircle extends StatelessWidget {
  final double sigma;
  const _BlurredCircle({required this.sigma});
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

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, this.color = JBColors.textSecondary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 40, height: 40,
        decoration: JBGlass.card(radius: JBRadius.full),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _StatsRibbon extends StatelessWidget {
  final MusicTracksLoadedState state;
  const _StatsRibbon({required this.state});

  @override
  Widget build(BuildContext context) {
    final h = state.todayListened.inHours;
    final m = state.todayListened.inMinutes % 60;
    final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';

    return Row(
      children: [
        _StatPill(icon: Icons.library_music_outlined, label: '${state.visibleTracks.length}', sub: 'tracks'),
        const SizedBox(width: 8),
        _StatPill(icon: Icons.favorite_outline_rounded, label: '${state.likedTracks.length}', sub: 'liked'),
        const SizedBox(width: 8),
        _StatPill(icon: Icons.access_time_rounded, label: timeStr, sub: 'today'),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  const _StatPill({required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: JBGlass.card(radius: JBRadius.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: JBColors.nova, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: JBType.bodyMedium.copyWith(fontSize: 13, color: JBColors.textPrimary)),
              Text(sub, style: JBType.micro),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title, subtitle;
  final String? action;
  final VoidCallback? onAction;

  const _SectionLabel({
    required this.title, required this.subtitle,
    this.action, this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: JBType.h3),
                const SizedBox(height: 2),
                Text(subtitle, style: JBType.caption),
              ],
            ),
          ),
          if (action != null && onAction != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onAction!();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: JBGlass.novaCard(radius: JBRadius.full),
                child: Text(
                  action!,
                  style: JBType.caption.copyWith(color: JBColors.nova, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONTINUE LISTENING ROW
// ─────────────────────────────────────────────────────────────────────────────
class _ContinueListeningRow extends StatelessWidget {
  final List<JBSong> tracks;
  final int currentIndex;
  final bool isPlaying;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _ContinueListeningRow({
    required this.tracks, required this.currentIndex,
    required this.isPlaying, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tracks.take(10).length,
        itemBuilder: (ctx, i) {
          final track = tracks[i];
          final isActive = track.id == (tracks.isNotEmpty ? tracks[currentIndex.clamp(0, tracks.length - 1)].id : '');
          return _RecentCard(
            track: track,
            index: i,
            tracks: tracks,
            isActive: isActive,
            isPlaying: isPlaying,
            onTap: onTap,
          ).animate(delay: Duration(milliseconds: i * 50)).slideX(begin: 0.2, end: 0).fadeIn();
        },
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final JBSong track;
  final int index;
  final List<JBSong> tracks;
  final bool isActive, isPlaying;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _RecentCard({
    required this.track, required this.index, required this.tracks,
    required this.isActive, required this.isPlaying, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(track, index, tracks),
      child: Container(
        width: 112,
        margin: const EdgeInsets.only(right: 10),
        decoration: isActive ? JBDecor.activeCard : JBDecor.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Art
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(JBRadius.lg)),
                child: QueryArtworkWidget(
                  id: int.tryParse(track.id) ?? 0,
                  type: ArtworkType.AUDIO,
                  format: ArtworkFormat.JPEG,
                  artworkBorder: BorderRadius.zero,
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: Container(
                    color: JBColors.void4,
                    child: Icon(Icons.music_note_rounded,
                        color: JBColors.nova.withValues(alpha: 0.5), size: 28),
                  ),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isActive && isPlaying)
                    Row(children: [
                      const _MiniWave(color: JBColors.nova),
                      const SizedBox(width: 4),
                      Text('PLAYING', style: JBType.micro.copyWith(
                        color: JBColors.nova, letterSpacing: 1,
                      )),
                    ])
                  else
                    const SizedBox(height: 12),
                  const SizedBox(height: 2),
                  Text(track.title,
                    style: JBType.captionMedium.copyWith(color: JBColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
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
//  QUICK PICKS GRID
// ─────────────────────────────────────────────────────────────────────────────
class _QuickPicksGrid extends StatelessWidget {
  final List<JBSong> tracks;
  final int currentIndex;
  final bool isPlaying;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _QuickPicksGrid({
    required this.tracks, required this.currentIndex,
    required this.isPlaying, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = tracks.take(6).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (int row = 0; row < 3; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (int col = 0; col < 2; col++) ...[
                    if (col > 0) const SizedBox(width: 8),
                    () {
                      final i = row * 2 + col;
                      if (i >= items.length) return const Expanded(child: SizedBox.shrink());
                      final track = items[i];
                      final isActive = i == currentIndex;
                      return Expanded(
                        child: _GridTile(
                          track: track, index: i, tracks: tracks,
                          isActive: isActive, isPlaying: isPlaying, onTap: onTap,
                        ).animate(delay: Duration(milliseconds: i * 40)).fadeIn(duration: 400.ms),
                      );
                    }(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final JBSong track;
  final int index;
  final List<JBSong> tracks;
  final bool isActive, isPlaying;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _GridTile({
    required this.track, required this.index, required this.tracks,
    required this.isActive, required this.isPlaying, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(track, index, tracks),
      child: AnimatedContainer(
        duration: 250.ms,
        height: 62,
        decoration: isActive ? JBDecor.activeCard : JBDecor.card,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(JBRadius.lg),
                bottomLeft: Radius.circular(JBRadius.lg),
              ),
              child: SizedBox(
                width: 62, height: 62,
                child: QueryArtworkWidget(
                  id: int.tryParse(track.id) ?? 0,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.zero,
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: Container(
                    color: JBColors.void4,
                    child: Icon(Icons.music_note_rounded,
                        color: JBColors.nova.withValues(alpha: 0.4), size: 22),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title,
                      style: JBType.captionMedium.copyWith(
                        color: isActive ? JBColors.nova : JBColors.textPrimary,
                        fontSize: 12,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(track.artist,
                      style: JBType.micro,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
            if (isActive && isPlaying)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: _MiniWave(color: JBColors.nova),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FAVORITES PILL ROW
// ─────────────────────────────────────────────────────────────────────────────
class _FavoritesPillRow extends StatelessWidget {
  final List<JBSong> tracks;
  final int currentIndex;
  final bool isPlaying;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _FavoritesPillRow({
    required this.tracks, required this.currentIndex,
    required this.isPlaying, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tracks.take(20).length,
        itemBuilder: (ctx, i) {
          final track = tracks[i];
          final isActive = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(track, i, tracks),
            child: AnimatedContainer(
              duration: 250.ms,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: isActive
                  ? BoxDecoration(
                      gradient: JBGradients.nova,
                      borderRadius: JBRadius.pill,
                      boxShadow: JBShadow.nova,
                    )
                  : JBGlass.card(radius: JBRadius.full),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive && isPlaying) ...[
                    const _MiniWave(color: JBColors.void0),
                    const SizedBox(width: 6),
                  ] else ...[
                    Icon(Icons.favorite_rounded,
                        color: isActive ? JBColors.void0 : JBColors.pulse,
                        size: 12),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    track.title,
                    style: JBType.captionMedium.copyWith(
                      color: isActive ? JBColors.void0 : JBColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: i * 30)).slideX(begin: 0.3).fadeIn();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TRACK LIST TILE
// ─────────────────────────────────────────────────────────────────────────────
class _TrackListTile extends StatelessWidget {
  final JBSong track;
  final int index;
  final List<JBSong> tracks;
  final bool isActive, isPlaying, isLiked;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _TrackListTile({
    required this.track, required this.index, required this.tracks,
    required this.isActive, required this.isPlaying,
    required this.isLiked, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(track, index, tracks),
      child: AnimatedContainer(
        duration: 250.ms,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: isActive ? JBDecor.activeCard : JBGlass.card(radius: JBRadius.md),
        child: Row(
          children: [
            // Number / playing indicator
            SizedBox(
              width: 28,
              child: Center(
                child: isActive && isPlaying
                    ? const _MiniWave(color: JBColors.nova, barCount: 3)
                    : Text(
                        '${index + 1}',
                        style: JBType.label.copyWith(
                          color: isActive ? JBColors.nova : JBColors.textTertiary,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 10),

            // Art
            ClipRRect(
              borderRadius: BorderRadius.circular(JBRadius.sm),
              child: SizedBox(
                width: 44, height: 44,
                child: QueryArtworkWidget(
                  id: int.tryParse(track.id) ?? 0,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.zero,
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: Container(
                    color: JBColors.void4,
                    child: Icon(Icons.music_note_rounded,
                        color: JBColors.nova.withValues(alpha: 0.4), size: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Title + artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track.title,
                    style: JBType.bodyMedium.copyWith(
                      color: isActive ? JBColors.nova : JBColors.textPrimary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    style: JBType.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Like indicator
            if (isLiked)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.favorite_rounded, color: JBColors.pulse, size: 14),
              ),

            // Duration
            Text(
              _fmtDur(track.duration),
              style: JBType.micro,
            ),

            const SizedBox(width: 6),

            GestureDetector(
              onTap: () {},
              child: const Icon(Icons.more_vert_rounded, color: JBColors.textTertiary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDur(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MINI WAVE INDICATOR
// ─────────────────────────────────────────────────────────────────────────────
class _MiniWave extends StatefulWidget {
  final Color color;
  final int barCount;
  const _MiniWave({required this.color, this.barCount = 4});

  @override
  State<_MiniWave> createState() => _MiniWaveState();
}

class _MiniWaveState extends State<_MiniWave> with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(widget.barCount, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + i * 80 + _rng.nextInt(200)),
      )..repeat(reverse: true);
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _ctrls.asMap().entries.map((e) {
        return AnimatedBuilder(
          animation: e.value,
          builder: (_, __) {
            final h = 4.0 + e.value.value * 8;
            return Container(
              width: 2.5, height: h,
              margin: const EdgeInsets.symmetric(horizontal: 0.8),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOADING VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: JBGradients.nova,
              boxShadow: JBShadow.nova,
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 36),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.05, 1.05), duration: 900.ms, curve: Curves.easeInOut),
          const SizedBox(height: 20),
          Text('Loading your music…', style: JBType.body),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: JBColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: JBColors.error.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.error_outline_rounded, color: JBColors.error, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Something went wrong', style: JBType.h3),
            const SizedBox(height: 8),
            Text(message, style: JBType.body, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.read<MusicBloc>().add(LoadAudioTracksEvent()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(gradient: JBGradients.nova, borderRadius: JBRadius.pill),
                child: Text('Retry', style: JBType.bodyMedium.copyWith(color: JBColors.void0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
