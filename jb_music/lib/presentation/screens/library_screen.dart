// lib/presentation/screens/library_screen.dart
// FIXED: No fake data — all tabs use real local songs from MusicBloc
import 'package:flutter/material.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';
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
  final List<String> _tabs = ['Liked', 'Recent', 'Albums', 'Artists'];

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, state) {
        final allTracks = state is MusicTracksLoadedState ? state.visibleTracks : <JBSong>[];
        final likedTracks = state is MusicTracksLoadedState ? state.likedTracks : <JBSong>[];

        // Recent = last 12 tracks
        final recentTracks = allTracks.reversed.take(12).toList();

        // Albums: group by album
        final albumMap = <String, List<JBSong>>{};
        for (final t in allTracks) {
          albumMap.putIfAbsent(t.album, () => []).add(t);
        }
        final albums = albumMap.entries.toList();

        // Artists: group by artist
        final artistMap = <String, List<JBSong>>{};
        for (final t in allTracks) {
          artistMap.putIfAbsent(t.artist, () => []).add(t);
        }
        final artists = artistMap.entries.toList();

        return Scaffold(
          backgroundColor: RG.black,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                floating: true,
                backgroundColor: RG.black,
                title: const Text('Your Library',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                actions: [
                  TextButton.icon(
                    onPressed: () => _showPlaylistSheet(context, allTracks),
                    icon: const Icon(Icons.add, color: RG.gold, size: 18),
                    label: const Text('Playlist',
                        style: TextStyle(color: RG.gold, fontWeight: FontWeight.w600)),
                  ),
                ],
                bottom: TabBar(
                  controller: _tab,
                  isScrollable: true,
                  labelColor: RG.gold,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: RG.gold,
                  indicatorWeight: 2,
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tab,
              children: [
                _buildLikedSongs(context, likedTracks),
                _buildRecent(context, recentTracks, state),
                _buildAlbums(context, albums, state),
                _buildArtists(context, artists, state),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── LIKED SONGS (real local) ─────────────────────────────────────────────
  Widget _buildLikedSongs(BuildContext context, List<JBSong> likedTracks) {
    return ListView(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF450AF5), Color(0xFF8E8EE5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, bottom: -20,
                child: Icon(Icons.favorite, size: 120,
                    color: Colors.white.withValues(alpha: 0.1)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PLAYLIST',
                      style: TextStyle(color: Colors.white70, fontSize: 11,
                          fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  const Text('Liked Songs',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${likedTracks.length} songs',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _heroBtn(Icons.shuffle, 'Shuffle', () {
                        if (likedTracks.isEmpty) return;
                        context.read<MusicBloc>().add(PlayTrackEvent(index: 0, tracks: likedTracks));
                      }),
                      const SizedBox(width: 12),
                      _heroBtn(Icons.play_arrow, 'Play', () {
                        if (likedTracks.isEmpty) return;
                        context.read<MusicBloc>().add(PlayTrackEvent(index: 0, tracks: likedTracks));
                      }),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (likedTracks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.favorite_border, color: Colors.white24, size: 56),
                  SizedBox(height: 12),
                  Text('No liked songs yet',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                  SizedBox(height: 6),
                  Text('Tap ♥ on any song to add it here',
                      style: TextStyle(color: Colors.white24, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ...likedTracks.asMap().entries.map((e) {
            final i = e.key;
            final song = e.value;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              onTap: () {
                context.read<MusicBloc>().add(PlayTrackEvent(index: i, tracks: likedTracks));
                Navigator.push(context, _playerRoute(context, song));
              },
              leading: CircleAvatar(
                backgroundColor: RG.surface,
                child: Text('${i + 1}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ),
              title: Text(song.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(song.artist,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${song.durationMs ~/ 60000}:${((song.durationMs ~/ 1000) % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.read<MusicBloc>().add(ToggleLikeTrackEvent(song)),
                    child: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _heroBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      );

  // ── RECENTLY PLAYED (real) ───────────────────────────────────────────────
  Widget _buildRecent(BuildContext context, List<JBSong> recentTracks, MusicState state) {
    if (recentTracks.isEmpty) {
      return const Center(
        child: Text('No recent tracks', style: TextStyle(color: Colors.white38)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.8),
      itemCount: recentTracks.length,
      itemBuilder: (_, i) {
        final track = recentTracks[i];
        return GestureDetector(
          onTap: () {
            context.read<MusicBloc>().add(PlayTrackEvent(index: i, tracks: recentTracks));
            Navigator.push(context, _playerRoute(context, track));
          },
          child: Container(
            decoration: BoxDecoration(
              color: RG.surface, borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  decoration: const BoxDecoration(
                    color: RG.roseDeep,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(track.artist,
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── ALBUMS (real, from local metadata) ──────────────────────────────────
  Widget _buildAlbums(BuildContext context, List<MapEntry<String, List<JBSong>>> albums, MusicState state) {
    if (albums.isEmpty) {
      return const Center(child: Text('No albums found', style: TextStyle(color: Colors.white38)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: albums.length,
      separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
      itemBuilder: (_, i) {
        final album = albums[i];
        final songs = album.value;
        final artist = songs.first.artist;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          onTap: () {
            if (songs.isNotEmpty) {
              context.read<MusicBloc>().add(PlayTrackEvent(index: 0, tracks: songs));
              Navigator.push(context, _playerRoute(context, songs.first));
            }
          },
          leading: Container(
            width: 54, height: 54,
            decoration: BoxDecoration(color: RG.surface, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.album, color: RG.gold, size: 26),
          ),
          title: Text(album.key,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(artist,  // FIX: removed unnecessary string interpolation
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${songs.length} songs',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
            ],
          ),
        );
      },
    );
  }

  // ── ARTISTS (real) ───────────────────────────────────────────────────────
  Widget _buildArtists(BuildContext context, List<MapEntry<String, List<JBSong>>> artists, MusicState state) {
    if (artists.isEmpty) {
      return const Center(child: Text('No artists found', style: TextStyle(color: Colors.white38)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: artists.length,
      separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
      itemBuilder: (_, i) {
        final artist = artists[i];
        final songs = artist.value;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          onTap: () {
            if (songs.isNotEmpty) {
              context.read<MusicBloc>().add(PlayTrackEvent(index: 0, tracks: songs));
              Navigator.push(context, _playerRoute(context, songs.first));
            }
          },
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: RG.roseDeep.withValues(alpha: 0.3),
            child: Text(
              artist.key.isNotEmpty ? artist.key[0].toUpperCase() : '?',
              style: const TextStyle(color: RG.gold, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          title: Text(artist.key,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text('${songs.length} songs',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
        );
      },
    );
  }

  // ── PLAYLIST SHEET ───────────────────────────────────────────────────────
  void _showPlaylistSheet(BuildContext context, List<JBSong> allTracks) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<MusicBloc>(context),
        child: _PlaylistSheet(allTracks: allTracks),
      ),
    );
  }

  PageRoute _playerRoute(BuildContext context, JBSong track) => PageRouteBuilder(
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
  );
}


// ── PLAYLIST SHEET ────────────────────────────────────────────────────────────
class _PlaylistSheet extends StatefulWidget {
  final List<JBSong> allTracks;
  const _PlaylistSheet({required this.allTracks});
  @override
  State<_PlaylistSheet> createState() => _PlaylistSheetState();
}

class _PlaylistSheetState extends State<_PlaylistSheet> {
  final List<Map<String, dynamic>> _playlists = [];
  bool _creating = false;
  int? _editingIndex;
  final _nameCtrl = TextEditingController();
  bool _smart = false;

  void _create() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _playlists.add({'name': name, 'songs': <JBSong>[], 'smart': _smart});
      _nameCtrl.clear();
      _smart = false;
      _creating = false;
    });
    context.read<MusicBloc>().add(CreatePlaylistEvent(name));
  }

  void _saveEdit(int i) {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() {
      _playlists[i]['name'] = _nameCtrl.text.trim();
      _playlists[i]['smart'] = _smart;
      _editingIndex = null;
      _nameCtrl.clear();
    });
  }

  void _delete(int i) => setState(() => _playlists.removeAt(i));
  void _startEdit(int i) => setState(() {
    _editingIndex = i;
    _nameCtrl.text = _playlists[i]['name'];
    _smart = _playlists[i]['smart'];
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Playlists',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_creating) _createForm() else _newPlaylistBtn(),
          const SizedBox(height: 8),
          ..._playlists.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            return _editingIndex == i ? _editForm(i) : _playlistTile(p, i);
          }),
        ],
      ),
    );
  }

  Widget _newPlaylistBtn() => GestureDetector(
        onTap: () => setState(() => _creating = true),
        child: Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: RG.gold.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(14),
            color: RG.gold.withValues(alpha: 0.05),
          ),
          child: const Row(
            children: [
              Icon(Icons.add, color: RG.gold, size: 20),
              SizedBox(width: 10),
              Text('New Playlist', style: TextStyle(color: RG.gold, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _createForm() => Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: RG.surface, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Playlist name...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true, fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Smart Playlist', style: TextStyle(color: Colors.white70)),
                Switch(value: _smart, onChanged: (v) => setState(() => _smart = v), activeThumbColor: RG.gold),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: RG.gold, foregroundColor: Colors.black),
                    onPressed: _create, child: const Text('Create'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24)),
                    onPressed: () => setState(() => _creating = false), child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _editForm(int i) => Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: RG.surface, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Playlist name...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true, fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: RG.gold, foregroundColor: Colors.black),
                    onPressed: () => _saveEdit(i), child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24)),
                    onPressed: () => setState(() => _editingIndex = null), child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _playlistTile(Map<String, dynamic> p, int i) {
    final songs = (p['songs'] as List<JBSong>);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: RG.surface, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () {
          if (songs.isNotEmpty) {
            context.read<MusicBloc>().add(PlayTrackEvent(index: 0, tracks: songs));
            Navigator.pop(context);
          }
        },
        leading: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: RG.black, borderRadius: BorderRadius.circular(10)),
          child: Icon(p['smart'] == true ? Icons.auto_awesome : Icons.queue_music, color: RG.gold, size: 22),
        ),
        title: Row(
          children: [
            Text(p['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            if (p['smart'] == true) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: RG.gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: const Text('SMART', style: TextStyle(color: RG.gold, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ),
            ],
          ],
        ),
        subtitle: Text('${songs.length} songs', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 18), onPressed: () => _startEdit(i)),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), onPressed: () => _delete(i)),
          ],
        ),
      ),
    );
  }
}