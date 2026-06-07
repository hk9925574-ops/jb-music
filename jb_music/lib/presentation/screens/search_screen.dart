// ─────────────────────────────────────────────────────────────
// FILE: lib/presentation/screens/search_screen.dart
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  bool _listening = false;
  String _query = '';

  final List<Map<String, String>> _all = [
    {'title': 'Dandelions', 'artist': 'Ruth B.', 'type': 'song'},
    {'title': 'Dheema', 'artist': 'Anirudh Ravichander', 'type': 'song'},
    {'title': 'Blinding Lights', 'artist': 'The Weeknd', 'type': 'song'},
    {'title': 'After Hours', 'artist': 'The Weeknd', 'type': 'album'},
    {'title': 'The Weeknd', 'artist': 'Artist', 'type': 'artist'},
    {'title': 'Chill Vibes', 'artist': '32 songs', 'type': 'playlist'},
  ];

  final List<String> _categories = [
    'Tamil', 'Hindi', 'Pop', 'Hip-Hop',
    'R&B', 'Rock', 'Electronic', 'Classical'
  ];

  final List<Color> _catColors = [
    Colors.purpleAccent, Colors.redAccent, Colors.blueAccent,
    Colors.orangeAccent, Colors.tealAccent, Colors.pinkAccent,
    Colors.greenAccent, Colors.cyan
  ];

  List<Map<String, String>> get _results => _query.isEmpty
      ? []
      : _all
          .where((r) =>
              r['title']!.toLowerCase().contains(_query.toLowerCase()) ||
              r['artist']!.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  void _startVoiceSearch() {
    setState(() => _listening = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _listening = false;
          _query = 'Dandelions';
          _ctrl.text = 'Dandelions';
        });
      }
    });
  }

  IconData _typeIcon(String type) => type == 'album'
      ? Icons.album
      : type == 'artist'
          ? Icons.person
          : type == 'playlist'
              ? Icons.queue_music
              : Icons.music_note;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RG.black,
      appBar: AppBar(
        backgroundColor: RG.black,
        title: const Text('Search',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Songs, artists, albums...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38),
                      filled: true,
                      fillColor: RG.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _listening ? null : _startVoiceSearch,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _listening ? Colors.redAccent : RG.gold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _listening ? Icons.stop : Icons.mic,
                      color: Colors.black,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Voice listening indicator ─────────────────────────
          if (_listening)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.mic, color: Colors.redAccent, size: 36),
                  SizedBox(height: 8),
                  Text('Listening...',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Speak now',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),

          // ── Results or category grid ──────────────────────────
          Expanded(
            child: _results.isNotEmpty
                ? _buildResults()
                : _query.isEmpty
                    ? _buildCategories()
                    : const Center(
                        child: Text('No results found',
                            style: TextStyle(color: Colors.white38))),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() => ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _results.length,
        separatorBuilder: (_, __) =>
            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
        itemBuilder: (_, i) {
          final r = _results[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: RG.surface,
                borderRadius: r['type'] == 'artist'
                    ? BorderRadius.circular(22)
                    : BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(r['type']!), color: RG.gold, size: 20),
            ),
            title: Text(r['title']!,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text('${r['type']} · ${r['artist']}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: RG.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_arrow, color: RG.gold, size: 20),
            ),
          );
        },
      );

  Widget _buildCategories() => GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2),
        itemCount: _categories.length,
        itemBuilder: (_, i) => Container(
          decoration: BoxDecoration(
            color: _catColors[i].withValues(alpha: 0.12),
            border: Border.all(color: _catColors[i].withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(_categories[i],
                style: TextStyle(
                    color: _catColors[i],
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ),
      );
}