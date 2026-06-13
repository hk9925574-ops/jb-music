// lib/presentation/screens/search_screen.dart
// FIX: Searches real tracks from MusicBloc instead of hardcoded fake data
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/screens/player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl      = TextEditingController();
  bool   _listening = false;
  String _query     = '';

  final List<String> _categories = [
    'Tamil', 'Hindi', 'Pop', 'Hip-Hop',
    'R&B', 'Rock', 'Electronic', 'Classical'
  ];

  final List<Color> _catColors = [
    Colors.purpleAccent, Colors.redAccent, Colors.blueAccent,
    Colors.orangeAccent, Colors.tealAccent, Colors.pinkAccent,
    Colors.greenAccent, Colors.cyan,
  ];

  // FIX: filter against real tracks from bloc, not hardcoded list
  List<JBSong> _filterTracks(List<JBSong> all) {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return all.where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.artist.toLowerCase().contains(q) ||
        t.album.toLowerCase().contains(q)).toList();
  }

  void _startVoiceSearch() {
    setState(() => _listening = true);
    // Trigger real voice via bloc
    context.read<MusicBloc>().add(StartVoiceListeningEvent());
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _listening) {
        setState(() => _listening = false);
        context.read<MusicBloc>().add(StopVoiceListeningEvent());
      }
    });
  }

  void _stopVoiceSearch() {
    setState(() => _listening = false);
    context.read<MusicBloc>().add(StopVoiceListeningEvent());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MusicBloc, MusicState>(
      // FIX: pick up voice search query emitted by bloc
      listener: (context, state) {
        if (state is MusicTracksLoadedState &&
            state.voiceSearchQuery.isNotEmpty &&
            state.voiceSearchQuery != _query) {
          setState(() {
            _query = state.voiceSearchQuery;
            _ctrl.text = state.voiceSearchQuery;
            _listening = false;
          });
        }
      },
      child: BlocBuilder<MusicBloc, MusicState>(
        builder: (context, state) {
          final allTracks = state is MusicTracksLoadedState
              ? state.visibleTracks
              : <JBSong>[];
          final results = _filterTracks(allTracks);

          return Scaffold(
            backgroundColor: RG.black,
            appBar: AppBar(
              backgroundColor: RG.black,
              title: const Text('Search',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22)),
            ),
            body: Column(
              children: [
                // ── Search bar ───────────────────────────────────────
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
                            hintStyle:
                                const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.search,
                                color: Colors.white38),
                            suffixIcon: _query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Colors.white38, size: 18),
                                    onPressed: () =>
                                        setState(() { _query = ''; _ctrl.clear(); }),
                                  )
                                : null,
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
                        onTap: _listening ? _stopVoiceSearch : _startVoiceSearch,
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

                // ── Listening indicator ──────────────────────────────
                if (_listening)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.08),
                      border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.3)),
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
                            style: TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),

                // ── Results or categories ────────────────────────────
                Expanded(
                  child: results.isNotEmpty
                      ? _buildResults(context, results, allTracks)
                      : _query.isEmpty
                          ? _buildCategories()
                          : const Center(
                              child: Text('No results found',
                                  style: TextStyle(color: Colors.white38))),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults(
      BuildContext context, List<JBSong> results, List<JBSong> allTracks) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      separatorBuilder: (_, __) =>
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
      itemBuilder: (_, i) {
        final song = results[i];
        // Find index in allTracks for proper queue order
        final queueIdx =
            allTracks.indexWhere((t) => t.id == song.id);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          onTap: () {
            final idx = queueIdx >= 0 ? queueIdx : 0;
            context
                .read<MusicBloc>()
                .add(PlayTrackEvent(index: idx, tracks: allTracks));
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (ctx, anim, _) => BlocProvider.value(
                value: BlocProvider.of<MusicBloc>(ctx),
                child: PlayerScreen(track: song),
              ),
              transitionsBuilder: (_, anim, __, child) => FadeTransition(
                  opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 300),
            ));
          },
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: QueryArtworkWidget(
              id: int.tryParse(song.id) ?? 0,
              type: ArtworkType.AUDIO,
              artworkWidth: 44,
              artworkHeight: 44,
              artworkFit: BoxFit.cover,
              nullArtworkWidget: Container(
                width: 44,
                height: 44,
                color: RG.surface,
                child: const Icon(Icons.music_note,
                    color: RG.textMuted, size: 20),
              ),
            ),
          ),
          title: Text(song.title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text('${song.artist} · ${song.album}',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12)),
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
  }

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
            border:
                Border.all(color: _catColors[i].withValues(alpha: 0.3)),
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
