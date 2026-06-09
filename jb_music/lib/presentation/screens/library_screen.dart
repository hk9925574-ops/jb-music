// ─────────────────────────────────────────────────────────────
// FILE: lib/presentation/screens/library_screen.dart
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/domain/entities/jb_song.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final List<String> _tabs = ['Liked', 'Recent', 'Albums', 'Artists'];

  

  final List<Map<String, String>> _recent = [
    {'title': 'Midnight Rain', 'artist': 'Taylor Swift', 'type': 'Song'},
    {'title': 'Chill Vibes', 'artist': 'Playlist', 'type': 'Playlist'},
    {'title': 'Anti-Hero', 'artist': 'Taylor Swift', 'type': 'Song'},
    {'title': 'Flowers', 'artist': 'Miley Cyrus', 'type': 'Song'},
    {'title': 'Lo-Fi Study', 'artist': 'Playlist', 'type': 'Playlist'},
    {'title': 'Golden Hour', 'artist': 'JVKE', 'type': 'Song'},
  ];

  final List<Map<String, String>> _albums = [
    {'title': 'After Hours', 'artist': 'The Weeknd', 'year': '2020', 'songs': '14'},
    {'title': 'Future Nostalgia', 'artist': 'Dua Lipa', 'year': '2020', 'songs': '11'},
    {'title': "Harry's House", 'artist': 'Harry Styles', 'year': '2022', 'songs': '13'},
    {'title': 'Midnights', 'artist': 'Taylor Swift', 'year': '2022', 'songs': '13'},
    {'title': 'Justice', 'artist': 'Justin Bieber', 'year': '2021', 'songs': '16'},
  ];

  final List<Map<String, String>> _artists = [
    {'name': 'The Weeknd', 'followers': '85.2M'},
    {'name': 'Taylor Swift', 'followers': '92.1M'},
    {'name': 'Dua Lipa', 'followers': '56.4M'},
    {'name': 'Harry Styles', 'followers': '48.7M'},
    {'name': 'Drake', 'followers': '78.3M'},
    {'name': 'Billie Eilish', 'followers': '67.9M'},
  ];

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
  final state = context.watch<MusicBloc>().state;

  final likedTracks =
      state is MusicTracksLoadedState ? state.likedTracks : <JBSong>[];

  return Scaffold(
    backgroundColor: RG.black,
    body: NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverAppBar(
          floating: true,
          backgroundColor: RG.black,
          title: const Text(
            'Your Library',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _showPlaylistSheet(context),
              icon: const Icon(Icons.add, color: RG.gold, size: 18),
              label: const Text(
                'Playlist',
                style: TextStyle(
                  color: RG.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          _buildLikedSongs(likedTracks),
          _buildRecent(),
          _buildAlbums(),
          _buildArtists(),
        ],
      ),
    ),
  );
}
  

  // ── LIKED SONGS ──────────────────────────────────────────────
Widget _buildLikedSongs(List<JBSong> likedTracks) {
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
                right: -20,
                bottom: -20,
                child: Icon(Icons.favorite,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.1)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PLAYLIST',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  const Text('Liked Songs',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      '${likedTracks.length} songs',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _heroBtn(Icons.shuffle, 'Shuffle', () {}),
                      const SizedBox(width: 12),
                      _heroBtn(Icons.play_arrow, 'Play', () {}),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        ...likedTracks.asMap().entries.map((e) {
          final i = e.key;
          final song = e.value;
          
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: CircleAvatar(
              backgroundColor: RG.surface,
              child: Text('${i + 1}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ),
            title: Text(song.title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(song.artist,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
  '${song.durationMs ~/ 60000}:${((song.durationMs ~/ 1000) % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    context.read<MusicBloc>().add(
                      ToggleLikeTrackEvent(song),
                    );
                  },
                  child:Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
                          size: 20,
                  ),
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
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
        ),
      );

  // ── RECENTLY PLAYED ──────────────────────────────────────────
  Widget _buildRecent() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.8),
      itemCount: _recent.length,
      itemBuilder: (_, i) {
        final item = _recent[i];
        return Container(
          decoration: BoxDecoration(
            color: RG.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                decoration: const BoxDecoration(
                  color: RG.roseDeep,
                  borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(10)),
                ),
                child: Icon(
                  item['type'] == 'Playlist'
                      ? Icons.queue_music
                      : Icons.music_note,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title']!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(item['artist']!,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── ALBUMS ───────────────────────────────────────────────────
  Widget _buildAlbums() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _albums.length,
      separatorBuilder: (_, __) => Divider(
          color: Colors.white.withValues(alpha: 0.07), height: 1),
      itemBuilder: (_, i) {
        final album = _albums[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          leading: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: RG.surface,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.album, color: RG.gold, size: 26),
          ),
          title: Text(album['title']!,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(
              '${album['artist']} · ${album['year']}',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${album['songs']} songs',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
              const Icon(Icons.chevron_right,
                  color: Colors.white38, size: 18),
            ],
          ),
        );
      },
    );
  }

  // ── ARTISTS ──────────────────────────────────────────────────
  Widget _buildArtists() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _artists.length,
      separatorBuilder: (_, __) => Divider(
          color: Colors.white.withValues(alpha: 0.07), height: 1),
      itemBuilder: (_, i) {
        final artist = _artists[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: RG.roseDeep.withValues(alpha: 0.3),
            child: Text(
              artist['name']![0],
              style: const TextStyle(
                  color: RG.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
          ),
          title: Text(artist['name']!,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text('${artist['followers']} followers',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right,
              color: Colors.white38, size: 20),
        );
      },
    );
  }

  // ── PLAYLIST BOTTOM SHEET ────────────────────────────────────
  void _showPlaylistSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => const _PlaylistSheet(),
    );
  }
}

// ── PLAYLIST SHEET ───────────────────────────────────────────
class _PlaylistSheet extends StatefulWidget {
  const _PlaylistSheet();
  @override
  State<_PlaylistSheet> createState() => _PlaylistSheetState();
}

class _PlaylistSheetState extends State<_PlaylistSheet> {
  final List<Map<String, dynamic>> _playlists = [
    {'name': 'Morning Boost', 'songs': 24, 'smart': false},
    {'name': 'Late Night Drive', 'songs': 18, 'smart': false},
    {'name': 'Top Played', 'songs': 50, 'smart': true},
    {'name': 'Workout Mix', 'songs': 30, 'smart': false},
  ];

  bool _creating = false;
  int? _editingIndex;
  final _nameCtrl = TextEditingController();
  bool _smart = false;

  void _create() {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() {
      _playlists.add({'name': _nameCtrl.text.trim(), 'songs': 0, 'smart': _smart});
      _nameCtrl.clear();
      _smart = false;
      _creating = false;
    });
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

  void _startEdit(int i) {
    setState(() {
      _editingIndex = i;
      _nameCtrl.text = _playlists[i]['name'];
      _smart = _playlists[i]['smart'];
    });
  }

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
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Playlists',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
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
              Text('New Playlist',
                  style: TextStyle(color: RG.gold, fontWeight: FontWeight.w600)),
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
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
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
                    onPressed: _create,
                    child: const Text('Create'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24)),
                    onPressed: () => setState(() => _creating = false),
                    child: const Text('Cancel'),
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
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: RG.gold, foregroundColor: Colors.black),
                    onPressed: () => _saveEdit(i),
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24)),
                    onPressed: () => setState(() => _editingIndex = null),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _playlistTile(Map<String, dynamic> p, int i) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: RG.surface, borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: RG.black, borderRadius: BorderRadius.circular(10)),
            child: Icon(
              p['smart'] == true ? Icons.auto_awesome : Icons.queue_music,
              color: RG.gold,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Text(p['name'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              if (p['smart'] == true) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: RG.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('SMART',
                      style: TextStyle(
                          color: RG.gold,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ),
              ],
            ],
          ),
          subtitle: Text('${p['songs']} songs',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 18),
                onPressed: () => _startEdit(i),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                onPressed: () => _delete(i),
              ),
            ],
          ),
        ),
      );
}