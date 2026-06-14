// lib/presentation/screens/library_screen.dart
//
// JB MUSIC — NOVA LIBRARY SCREEN
// ─────────────────────────────────────────────────────────────────────────────
// Tabs: Liked | Playlists | Albums | Artists
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/jb_design_system.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/screens/player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _tabs = ['Liked', 'Playlists', 'Albums', 'Artists'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _navToPlayer(BuildContext ctx, JBSong track, int index, List<JBSong> tracks) {
    HapticFeedback.lightImpact();
    ctx.read<MusicBloc>().add(PlayTrackEvent(index: index, tracks: tracks));
    Navigator.of(ctx).push(JBAnim.slideUp(PlayerScreen(track: track)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, state) {
        final allTracks   = state is MusicTracksLoadedState ? state.visibleTracks : <JBSong>[];
        final likedTracks = state is MusicTracksLoadedState ? state.likedTracks   : <JBSong>[];
        final playlists   = state is MusicTracksLoadedState ? state.playlists      : <JBPlaylist>[];

        final albumMap = <String, List<JBSong>>{};
        for (final t in allTracks) { albumMap.putIfAbsent(t.album, () => []).add(t); }

        final artistMap = <String, List<JBSong>>{};
        for (final t in allTracks) { artistMap.putIfAbsent(t.artist, () => []).add(t); }

        return Scaffold(
          backgroundColor: JBColors.void0,
          body: NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              SliverAppBar(
                floating: true,
                backgroundColor: JBColors.void0,
                expandedHeight: 100,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your', style: JBType.caption.copyWith(color: JBColors.nova)),
                            Text('Library', style: JBType.h2),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _showCreatePlaylistSheet(context, allTracks);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: JBGlass.novaCard(radius: JBRadius.full),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, color: JBColors.nova, size: 16),
                              const SizedBox(width: 4),
                              Text('Playlist',
                                style: JBType.captionMedium.copyWith(color: JBColors.nova)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(44),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(3),
                    decoration: JBGlass.card(radius: JBRadius.full),
                    child: TabBar(
                      controller: _tab,
                      isScrollable: false,
                      indicator: BoxDecoration(
                        gradient: JBGradients.nova,
                        borderRadius: JBRadius.pill,
                        boxShadow: JBShadow.nova,
                      ),
                      labelStyle: JBType.captionMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                      unselectedLabelStyle: JBType.captionMedium.copyWith(fontSize: 12),
                      labelColor: JBColors.void0,
                      unselectedLabelColor: JBColors.textTertiary,
                      dividerColor: Colors.transparent,
                      tabs: _tabs.map((t) => Tab(text: t, height: 34)).toList(),
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tab,
              children: [
                // ── LIKED ──
                _TrackListTab(
                  tracks: likedTracks,
                  emptyIcon: Icons.favorite_outline_rounded,
                  emptyTitle: 'No favorites yet',
                  emptySubtitle: 'Tap the heart on any track to save it here.',
                  state: state is MusicTracksLoadedState ? state : null,
                  onTap: (track, i, tracks) => _navToPlayer(context, track, i, tracks),
                ),

                // ── PLAYLISTS ──
                _PlaylistsTab(
                  playlists: playlists,
                  allTracks: allTracks,
                  onTap: (track, i, tracks) => _navToPlayer(context, track, i, tracks),
                ),

                // ── ALBUMS ──
                _AlbumsTab(
                  albums: albumMap.entries.toList(),
                  onTap: (track, i, tracks) => _navToPlayer(context, track, i, tracks),
                ),

                // ── ARTISTS ──
                _ArtistsTab(
                  artists: artistMap.entries.toList(),
                  onTap: (track, i, tracks) => _navToPlayer(context, track, i, tracks),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreatePlaylistSheet(BuildContext ctx, List<JBSong> tracks) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CreatePlaylistSheet(allTracks: tracks),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TRACK LIST TAB (Liked)
// ─────────────────────────────────────────────────────────────────────────────
class _TrackListTab extends StatelessWidget {
  final List<JBSong> tracks;
  final IconData emptyIcon;
  final String emptyTitle, emptySubtitle;
  final MusicTracksLoadedState? state;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _TrackListTab({
    required this.tracks,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return _EmptyState(icon: emptyIcon, title: emptyTitle, subtitle: emptySubtitle);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: tracks.length,
      itemBuilder: (_, i) {
        final track = tracks[i];
        final isActive = state?.currentTrackIndex == i && state?.visibleTracks == tracks;
        final isPlaying = state?.isPlaying ?? false;

        return _LibraryTrackTile(
          track: track,
          index: i,
          tracks: tracks,
          isActive: isActive,
          isPlaying: isPlaying && isActive,
          onTap: onTap,
        ).animate(delay: Duration(milliseconds: i * 20)).fadeIn(duration: 350.ms).slideY(begin: 0.1);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LIBRARY TRACK TILE
// ─────────────────────────────────────────────────────────────────────────────
class _LibraryTrackTile extends StatelessWidget {
  final JBSong track;
  final int index;
  final List<JBSong> tracks;
  final bool isActive, isPlaying;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _LibraryTrackTile({
    required this.track, required this.index, required this.tracks,
    required this.isActive, required this.isPlaying, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(track, index, tracks);
      },
      child: AnimatedContainer(
        duration: 250.ms,
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: isActive ? JBDecor.activeCard : JBGlass.card(radius: JBRadius.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(JBRadius.sm),
              child: SizedBox(
                width: 46, height: 46,
                child: QueryArtworkWidget(
                  id: int.tryParse(track.id) ?? 0,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.zero,
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: Container(
                    color: JBColors.void4,
                    child: Icon(Icons.music_note_rounded,
                        color: JBColors.nova.withValues(alpha: 0.4), size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(track.title,
                    style: JBType.bodyMedium.copyWith(
                      color: isActive ? JBColors.nova : JBColors.textPrimary,
                      fontSize: 14,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(track.artist,
                    style: JBType.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isPlaying)
              const _SmallWave(color: JBColors.nova)
            else
              Text(_fmtDur(track.duration), style: JBType.micro),
            const SizedBox(width: 8),
            const Icon(Icons.more_vert_rounded, color: JBColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }

  String _fmtDur(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
//  PLAYLISTS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _PlaylistsTab extends StatelessWidget {
  final List<JBPlaylist> playlists;
  final List<JBSong> allTracks;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _PlaylistsTab({
    required this.playlists, required this.allTracks, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return const _EmptyState(
        icon: Icons.queue_music_rounded,
        title: 'No playlists yet',
        subtitle: 'Create a playlist to organise your music.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: playlists.length,
      itemBuilder: (_, i) {
        final pl = playlists[i];
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (pl.songs.isNotEmpty) onTap(pl.songs.first, 0, pl.songs);
          },
          child: Container(
            decoration: JBDecor.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(JBRadius.lg)),
                    child: pl.songs.isNotEmpty
                        ? QueryArtworkWidget(
                            id: int.tryParse(pl.songs.first.id) ?? 0,
                            type: ArtworkType.AUDIO,
                            artworkBorder: BorderRadius.zero,
                            artworkFit: BoxFit.cover,
                            nullArtworkWidget: _PlaylistArtFallback(name: pl.name),
                          )
                        : _PlaylistArtFallback(name: pl.name),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pl.name,
                        style: JBType.bodyMedium.copyWith(fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${pl.songs.length} songs', style: JBType.micro),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: i * 40)).fadeIn(duration: 350.ms);
      },
    );
  }
}

class _PlaylistArtFallback extends StatelessWidget {
  final String name;
  const _PlaylistArtFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: JBColors.void4,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.queue_music_rounded, color: JBColors.nova, size: 36),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(name,
                style: JBType.captionMedium.copyWith(color: JBColors.textSecondary),
                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ALBUMS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _AlbumsTab extends StatelessWidget {
  final List<MapEntry<String, List<JBSong>>> albums;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _AlbumsTab({required this.albums, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const _EmptyState(
        icon: Icons.album_outlined,
        title: 'No albums found',
        subtitle: 'Albums from your local library will appear here.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: albums.length,
      itemBuilder: (_, i) {
        final entry = albums[i];
        final tracks = entry.value;
        final first = tracks.first;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap(first, 0, tracks);
          },
          child: Container(
            decoration: JBDecor.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(JBRadius.lg)),
                    child: QueryArtworkWidget(
                      id: int.tryParse(first.id) ?? 0,
                      type: ArtworkType.AUDIO,
                      artworkBorder: BorderRadius.zero,
                      artworkFit: BoxFit.cover,
                      nullArtworkWidget: Container(
                        color: JBColors.void4,
                        child: const Icon(Icons.album_outlined, color: JBColors.nova, size: 40),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key,
                        style: JBType.bodyMedium.copyWith(fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${tracks.length} tracks • ${first.artist}',
                        style: JBType.micro,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: i * 30)).fadeIn(duration: 350.ms);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ARTISTS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _ArtistsTab extends StatelessWidget {
  final List<MapEntry<String, List<JBSong>>> artists;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _ArtistsTab({required this.artists, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const _EmptyState(
        icon: Icons.person_outline_rounded,
        title: 'No artists found',
        subtitle: 'Artists from your library will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: artists.length,
      itemBuilder: (_, i) {
        final entry = artists[i];
        final tracks = entry.value;
        final first = tracks.first;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap(first, 0, tracks);
          },
          child: AnimatedContainer(
            duration: 250.ms,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: JBGlass.card(radius: JBRadius.md),
            child: Row(
              children: [
                // Artist avatar (circle)
                ClipOval(
                  child: SizedBox(
                    width: 52, height: 52,
                    child: QueryArtworkWidget(
                      id: int.tryParse(first.id) ?? 0,
                      type: ArtworkType.AUDIO,
                      artworkBorder: BorderRadius.zero,
                      artworkFit: BoxFit.cover,
                      nullArtworkWidget: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: JBGradients.nova,
                        ),
                        child: Center(
                          child: Text(
                            entry.key.isNotEmpty ? entry.key[0].toUpperCase() : '?',
                            style: JBType.h3.copyWith(color: JBColors.void0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(entry.key,
                        style: JBType.bodyMedium.copyWith(fontSize: 15),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${tracks.length} songs',
                        style: JBType.caption),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: JBColors.textTertiary, size: 20),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: i * 20)).fadeIn(duration: 300.ms).slideX(begin: 0.1);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CREATE PLAYLIST SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _CreatePlaylistSheet extends StatefulWidget {
  final List<JBSong> allTracks;
  const _CreatePlaylistSheet({required this.allTracks});

  @override
  State<_CreatePlaylistSheet> createState() => _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends State<_CreatePlaylistSheet> {
  final _ctrl = TextEditingController();
  final _selected = <String>{};

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: JBColors.void2,
        borderRadius: JBRadius.sheet,
        border: Border.all(color: JBColors.glassBorder, width: 0.5),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: JBColors.glassBorder, borderRadius: JBRadius.pill),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('New Playlist', style: JBType.h3),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (_ctrl.text.trim().isEmpty) return;
                    context.read<MusicBloc>().add(
                      CreatePlaylistEvent(_ctrl.text.trim()),
                    );
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: JBGradients.nova,
                      borderRadius: JBRadius.pill,
                      boxShadow: JBShadow.nova,
                    ),
                    child: Text('Create',
                      style: JBType.captionMedium.copyWith(color: JBColors.void0, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Name field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _ctrl,
              style: JBType.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Playlist name',
                hintStyle: JBType.body.copyWith(color: JBColors.textTertiary),
                filled: true,
                fillColor: JBColors.glass10,
                border: OutlineInputBorder(
                  borderRadius: JBRadius.cardSm,
                  borderSide: const BorderSide(color: JBColors.glassBorder, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: JBRadius.cardSm,
                  borderSide: const BorderSide(color: JBColors.glassBorder, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: JBRadius.cardSm,
                  borderSide: const BorderSide(color: JBColors.nova, width: 1),
                ),
                prefixIcon: const Icon(Icons.queue_music_rounded, color: JBColors.nova, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('Add songs', style: JBType.caption),
              const Spacer(),
              Text('${_selected.length} selected',
                style: JBType.caption.copyWith(color: JBColors.nova)),
            ]),
          ),
          const SizedBox(height: 6),

          // Song list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.allTracks.length,
              itemBuilder: (_, i) {
                final track = widget.allTracks[i];
                final sel = _selected.contains(track.id);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (sel) {
                        _selected.remove(track.id);
                      } else {
                        _selected.add(track.id);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: 200.ms,
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: sel ? JBDecor.activeCard : JBGlass.card(radius: JBRadius.sm),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: 200.ms,
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sel ? JBColors.nova : Colors.transparent,
                            border: Border.all(
                              color: sel ? JBColors.nova : JBColors.glassBorder, width: 1.5),
                          ),
                          child: sel
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(track.title,
                                style: JBType.bodyMedium.copyWith(
                                  color: sel ? JBColors.nova : JBColors.textPrimary, fontSize: 13),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(track.artist, style: JBType.micro,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: JBGradients.void_,
              shape: BoxShape.circle,
              border: Border.all(color: JBColors.glassBorder, width: 0.8),
            ),
            child: Icon(icon, color: JBColors.nova, size: 36),
          ),
          const SizedBox(height: 16),
          Text(title, style: JBType.h3),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle, style: JBType.body, textAlign: TextAlign.center),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

// ── Small wave indicator ──────────────────────────────────────────────────────
class _SmallWave extends StatefulWidget {
  final Color color;
  const _SmallWave({required this.color});

  @override
  State<_SmallWave> createState() => _SmallWaveState();
}

class _SmallWaveState extends State<_SmallWave> with TickerProviderStateMixin {
  late final List<AnimationController> _cs;

  @override
  void initState() {
    super.initState();
    _cs = List.generate(3, (i) => AnimationController(
      vsync: this, duration: Duration(milliseconds: 380 + i * 100),
    )..repeat(reverse: true));
  }

  @override
  void dispose() {
    for (final c in _cs) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _cs.map((c) => AnimatedBuilder(
        animation: c,
        builder: (_, __) => Container(
          width: 2.5, height: 4 + c.value * 8,
          margin: const EdgeInsets.symmetric(horizontal: 0.8),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      )).toList(),
    );
  }
}
