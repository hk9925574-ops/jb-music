// lib/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/presentation/widgets/section_header.dart';
import 'package:jb_music/presentation/widgets/song_tile.dart';
import 'package:jb_music/presentation/widgets/equalizer_controls.dart';
import 'package:jb_music/screens/player_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
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
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  void _navigateToPlayer(JBSong track, int index, List<JBSong> tracks) {
    context.read<MusicBloc>().add(PlayTrackEvent(index: index, tracks: tracks));
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PlayerScreen(track: track),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
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
            return const _LoadingView();
          }
          if (state is MusicErrorState) {
            return _ErrorView(message: state.message);
          }
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
// LOADED STATE VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _LoadedView extends StatelessWidget {
  final MusicTracksLoadedState state;
  final String greeting;
  final AnimationController heroCtrl;
  final void Function(JBSong, int, List<JBSong>) onTrackTap;
  final VoidCallback onEqualizerTap;

  const _LoadedView({
    required this.state,
    required this.greeting,
    required this.heroCtrl,
    required this.onTrackTap,
    required this.onEqualizerTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _DashboardAppBar(
          greeting: greeting,
          onEqualizerTap: onEqualizerTap,
        ),
        if (state.recentTracks.isNotEmpty)
          SliverToBoxAdapter(
            child: _RecentlyPlayedSection(
              tracks: state.recentTracks,
              currentIndex: state.currentTrackIndex,
              isPlaying: state.isPlaying,
              likedTracks: state.likedTracks,
              onTap: onTrackTap,
            ),
          ),
        SliverToBoxAdapter(
          child: _QuickPicksSection(
            tracks: state.visibleTracks,
            currentIndex: state.currentTrackIndex,
            isPlaying: state.isPlaying,
            likedTracks: state.likedTracks,
            onTap: onTrackTap,
          ),
        ),
        if (state.likedTracks.isNotEmpty)
          SliverToBoxAdapter(
            child: _FavoritesSection(
              tracks: state.likedTracks,
              currentIndex: state.currentTrackIndex,
              isPlaying: state.isPlaying,
              onTap: onTrackTap,
            ),
          ),
        SliverToBoxAdapter(
          child: _AllTracksSection(
            tracks: state.visibleTracks,
            currentIndex: state.currentTrackIndex,
            isPlaying: state.isPlaying,
            likedTracks: state.likedTracks,
            onTap: onTrackTap,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardAppBar extends StatelessWidget {
  final String greeting;
  final VoidCallback onEqualizerTap;

  const _DashboardAppBar({
    required this.greeting,
    required this.onEqualizerTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: false,
      backgroundColor: RG.black,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting, style: RG.captionStyle)
                      .animate()
                      .fadeIn(duration: 600.ms),
                  Text('JB Music', style: RG.titleStyle)
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 600.ms)
                      .slideX(begin: -0.1, end: 0),
                ],
              ),
            ),
            GestureDetector(
              onTap: onEqualizerTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RG.surfacePop,
                  borderRadius: BorderRadius.circular(RG.radiusFull),
                  border: Border.all(color: RG.border),
                ),
                child: const Icon(Icons.equalizer, color: RG.gold, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECENTLY PLAYED — Horizontal card strip
// ─────────────────────────────────────────────────────────────────────────────
class _RecentlyPlayedSection extends StatelessWidget {
  final List<JBSong> tracks;
  final List<JBSong> likedTracks;
  final int currentIndex;
  final bool isPlaying;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _RecentlyPlayedSection({
    required this.tracks,
    required this.likedTracks,
    required this.currentIndex,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recently Played'),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: RG.spaceMD),
            itemCount: tracks.take(10).length,
            separatorBuilder: (_, __) => const SizedBox(width: RG.spaceMD),
            itemBuilder: (context, i) {
              final song = tracks[i];
              final playing = isPlaying && tracks[currentIndex] == song;
              return _RecentCard(
                song: song,
                isPlaying: playing,
                onTap: () => onTap(song, i, tracks),
              ).animate(delay: (i * 60).ms).fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0);
            },
          ),
        ),
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  final JBSong song;
  final bool   isPlaying;
  final VoidCallback onTap;

  const _RecentCard({required this.song, required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(RG.radiusMD),
              child: Stack(
                children: [
                  QueryArtworkWidget(
                    id: int.tryParse(song.id) ?? 0,
                    type: ArtworkType.AUDIO,
                    artworkWidth: 100,
                    artworkHeight: 100,
                    artworkFit: BoxFit.cover,
                    nullArtworkWidget: Container(
                      width: 100,
                      height: 100,
                      color: RG.surfacePop,
                      child: const Icon(Icons.album, color: RG.textMuted, size: 40),
                    ),
                  ),
                  if (isPlaying)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: const Icon(Icons.graphic_eq, color: RG.gold, size: 28),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: RG.textPrimary),
            ),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: RG.labelStyle,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK PICKS — Top 6 tracks in a 2-col grid
// ─────────────────────────────────────────────────────────────────────────────
class _QuickPicksSection extends StatelessWidget {
  final List<JBSong> tracks;
  final List<JBSong> likedTracks;
  final int currentIndex;
  final bool isPlaying;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _QuickPicksSection({
    required this.tracks,
    required this.likedTracks,
    required this.currentIndex,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final top = tracks.take(6).toList();
    if (top.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Picks'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: RG.spaceMD),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: RG.spaceSM,
              crossAxisSpacing: RG.spaceSM,
              childAspectRatio: 3.4,
            ),
            itemCount: top.length,
            itemBuilder: (context, i) {
              final song   = top[i];
              final active = isPlaying && currentIndex == i;
              return _QuickPickTile(
                song: song,
                isPlaying: active,
                onTap: () => onTap(song, i, tracks),
              ).animate(delay: (i * 50).ms).fadeIn(duration: 350.ms);
            },
          ),
        ),
      ],
    );
  }
}

class _QuickPickTile extends StatelessWidget {
  final JBSong song;
  final bool   isPlaying;
  final VoidCallback onTap;

  const _QuickPickTile({required this.song, required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isPlaying ? RG.gold.withValues(alpha: 0.15) : RG.surfaceHigh,
          borderRadius: BorderRadius.circular(RG.radiusSM),
          border: Border.all(
            color: isPlaying ? RG.gold.withValues(alpha: 0.5) : RG.border,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(RG.radiusSM),
                bottomLeft: Radius.circular(RG.radiusSM),
              ),
              child: QueryArtworkWidget(
                id: int.tryParse(song.id) ?? 0,
                type: ArtworkType.AUDIO,
                artworkWidth: 48,
                artworkHeight: 48,
                artworkFit: BoxFit.cover,
                nullArtworkWidget: Container(
                  width: 48,
                  height: 48,
                  color: RG.surfacePop,
                  child: const Icon(Icons.music_note, color: RG.textMuted, size: 20),
                ),
              ),
            ),
            const SizedBox(width: RG.spaceSM),
            Expanded(
              child: Text(
                song.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPlaying ? RG.gold : RG.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAVORITES STRIP
// ─────────────────────────────────────────────────────────────────────────────
class _FavoritesSection extends StatelessWidget {
  final List<JBSong> tracks;
  final int currentIndex;
  final bool isPlaying;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _FavoritesSection({
    required this.tracks,
    required this.currentIndex,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Favourites', actionLabel: 'See all'),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: RG.spaceMD),
            itemCount: tracks.take(15).length,
            separatorBuilder: (_, __) => const SizedBox(width: RG.spaceSM),
            itemBuilder: (_, i) {
              final song = tracks[i];
              return GestureDetector(
                onTap: () => onTap(song, i, tracks),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(RG.radiusMD),
                  child: QueryArtworkWidget(
                    id: int.tryParse(song.id) ?? 0,
                    type: ArtworkType.AUDIO,
                    artworkWidth: 60,
                    artworkHeight: 60,
                    artworkFit: BoxFit.cover,
                    nullArtworkWidget: Container(
                      width: 60,
                      height: 60,
                      color: RG.surfacePop,
                      child: const Icon(Icons.favorite, color: RG.gold, size: 22),
                    ),
                  ),
                ),
              ).animate(delay: (i * 40).ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALL TRACKS LIST
// ─────────────────────────────────────────────────────────────────────────────
class _AllTracksSection extends StatelessWidget {
  final List<JBSong> tracks;
  final List<JBSong> likedTracks;
  final int currentIndex;
  final bool isPlaying;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _AllTracksSection({
    required this.tracks,
    required this.likedTracks,
    required this.currentIndex,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) return const _EmptyLibrary();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'All Songs',
          actionLabel: '${tracks.length} tracks',
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tracks.length,
          itemBuilder: (context, i) {
            final song   = tracks[i];
            final active = isPlaying && currentIndex == i;
            final liked  = likedTracks.any((s) => s.path == song.path);
            return SongTile(
              song: song,
              isPlaying: active,
              isLiked: liked,
              onTap: () => onTap(song, i, tracks),
              onLike: () => context.read<MusicBloc>().add(ToggleLikeTrackEvent(song)),
              index: i,
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY / LOADING / ERROR
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: RG.spaceLG),
    child: Center(
      child: Column(
        children: [
          const Icon(Icons.library_music_outlined, size: 64, color: RG.textMuted),
          const SizedBox(height: RG.spaceMD),
          Text('No music found', style: RG.subtitleStyle),
          const SizedBox(height: RG.spaceSM),
          Text(
            'Add music files to your device storage to get started.',
            textAlign: TextAlign.center,
            style: RG.bodyStyle,
          ),
        ],
      ),
    ),
  );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: RG.black,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: RG.gold, strokeWidth: 2),
          const SizedBox(height: RG.spaceMD),
          Text('Loading your library…', style: RG.bodyStyle),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: RG.black,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(RG.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: RG.error),
            const SizedBox(height: RG.spaceMD),
            Text('Something went wrong', style: RG.subtitleStyle),
            const SizedBox(height: RG.spaceSM),
            Text(message, textAlign: TextAlign.center, style: RG.bodyStyle),
            const SizedBox(height: RG.spaceLG),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: RG.gold, foregroundColor: Colors.black),
              onPressed: () => context.read<MusicBloc>().add(LoadAudioTracksEvent()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    ),
  );
}