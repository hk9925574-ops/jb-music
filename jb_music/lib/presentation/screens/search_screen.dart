// lib/presentation/screens/search_screen.dart
//
// JB MUSIC — NOVA SEARCH SCREEN
// ─────────────────────────────────────────────────────────────────────────────
// Features:
//  • Animated search bar with voice input
//  • Mood/genre category grid with gradient tiles
//  • Live filtered results
//  • Voice search indicator
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

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl    = TextEditingController();
  final _focus   = FocusNode();
  bool  _focused = false;
  bool  _listening = false;
  String _query = '';
  late final AnimationController _voiceCtrl;

  static const _categories = [
    ('Tamil',       Icons.language_rounded,          Color(0xFF7C3AED), Color(0xFFDB2777)),
    ('Hindi',       Icons.music_note_rounded,         Color(0xFFB45309), Color(0xFFEF4444)),
    ('Pop',         Icons.star_rounded,               Color(0xFF0EA5E9), Color(0xFF6366F1)),
    ('Hip-Hop',     Icons.headphones_rounded,         Color(0xFF059669), Color(0xFF0EA5E9)),
    ('R&B',         Icons.favorite_rounded,           Color(0xFFDB2777), Color(0xFF7C3AED)),
    ('Rock',        Icons.bolt_rounded,               Color(0xFFB45309), Color(0xFFEF4444)),
    ('Electronic',  Icons.graphic_eq_rounded,         Color(0xFF6366F1), Color(0xFF0EA5E9)),
    ('Classical',   Icons.piano_rounded,              Color(0xFF059669), Color(0xFF6366F1)),
    ('Workout',     Icons.fitness_center_rounded,     Color(0xFFEF4444), Color(0xFFB45309)),
    ('Chill',       Icons.spa_rounded,                Color(0xFF0EA5E9), Color(0xFF059669)),
    ('Focus',       Icons.psychology_rounded,         Color(0xFF6366F1), Color(0xFF7C3AED)),
    ('Sleep',       Icons.bedtime_rounded,            Color(0xFF1E40AF), Color(0xFF6366F1)),
  ];

  List<JBSong> _filter(List<JBSong> all) {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return all.where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.artist.toLowerCase().contains(q) ||
        t.album.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _voiceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _voiceCtrl.dispose();
    super.dispose();
  }

  void _startVoice() {
    HapticFeedback.mediumImpact();
    setState(() => _listening = true);
    _voiceCtrl.repeat(reverse: true);
    context.read<MusicBloc>().add(StartVoiceListeningEvent());
    Future.delayed(const Duration(seconds: 8), _stopVoice);
  }

  void _stopVoice() {
    if (!mounted || !_listening) return;
    _voiceCtrl.stop();
    setState(() => _listening = false);
    context.read<MusicBloc>().add(StopVoiceListeningEvent());
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
        final allTracks = state is MusicTracksLoadedState ? state.visibleTracks : <JBSong>[];
        final results   = _filter(allTracks);
        final hasQuery  = _query.isNotEmpty;

        return Scaffold(
          backgroundColor: JBColors.void0,
          body: SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_focused && !hasQuery) ...[
                        Text('Search', style: JBType.h2)
                            .animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                        const SizedBox(height: 4),
                        Text('Find anything in your library',
                          style: JBType.caption)
                            .animate().fadeIn(duration: 400.ms, delay: 50.ms),
                        const SizedBox(height: 14),
                      ] else
                        const SizedBox(height: 4),

                      // Search bar
                      _SearchBar(
                        ctrl: _ctrl,
                        focus: _focus,
                        focused: _focused,
                        listening: _listening,
                        voiceCtrl: _voiceCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        onClear: () {
                          _ctrl.clear();
                          setState(() => _query = '');
                          _focus.unfocus();
                        },
                        onVoiceTap: _listening ? _stopVoice : _startVoice,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Content ─────────────────────────────────────────────
                Expanded(
                  child: AnimatedSwitcher(
                    duration: 300.ms,
                    child: hasQuery
                        ? _SearchResults(
                            key: const ValueKey('results'),
                            results: results,
                            allTracks: allTracks,
                            query: _query,
                            state: state is MusicTracksLoadedState ? state : null,
                            onTap: (t, i, ts) => _navToPlayer(context, t, i, ts),
                          )
                        : _BrowseGrid(
                            key: const ValueKey('browse'),
                            categories: _categories,
                            allTracks: allTracks,
                            onTap: (t, i, ts) => _navToPlayer(context, t, i, ts),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final bool focused, listening;
  final AnimationController voiceCtrl;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear, onVoiceTap;

  const _SearchBar({
    required this.ctrl, required this.focus,
    required this.focused, required this.listening,
    required this.voiceCtrl, required this.onChanged,
    required this.onClear, required this.onVoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 300.ms,
      curve: JBAnim.ease,
      decoration: BoxDecoration(
        color: focused ? JBColors.void3 : JBColors.glass10,
        borderRadius: JBRadius.pill,
        border: Border.all(
          color: focused ? JBColors.nova.withValues(alpha: 0.5) : JBColors.glassBorder,
          width: focused ? 1.0 : 0.5,
        ),
        boxShadow: focused ? JBShadow.novaSoft : null,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(Icons.search_rounded,
              color: focused ? JBColors.nova : JBColors.textTertiary,
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode: focus,
              onChanged: onChanged,
              style: JBType.bodyMedium.copyWith(fontSize: 15),
              cursorColor: JBColors.nova,
              decoration: InputDecoration(
                hintText: 'Songs, artists, albums…',
                hintStyle: JBType.body.copyWith(color: JBColors.textTertiary, fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              ),
            ),
          ),
          // Voice button
          GestureDetector(
            onTap: onVoiceTap,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AnimatedBuilder(
                animation: voiceCtrl,
                builder: (_, __) {
                  return AnimatedContainer(
                    duration: 200.ms,
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: listening
                          ? JBColors.pulse.withValues(alpha: 0.15 + voiceCtrl.value * 0.1)
                          : Colors.transparent,
                      border: listening
                          ? Border.all(color: JBColors.pulse.withValues(alpha: 0.4 + voiceCtrl.value * 0.2))
                          : null,
                    ),
                    child: Icon(
                      listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: listening ? JBColors.pulse : JBColors.textTertiary,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),
          // Clear button
          if (ctrl.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 38, height: 38,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(right: 4),
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: JBColors.textTertiary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BROWSE GRID
// ─────────────────────────────────────────────────────────────────────────────
class _BrowseGrid extends StatelessWidget {
  final List<(String, IconData, Color, Color)> categories;
  final List<JBSong> allTracks;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _BrowseGrid({
    super.key,
    required this.categories,
    required this.allTracks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        return _CategoryTile(
          label: cat.$1,
          icon: cat.$2,
          colorA: cat.$3,
          colorB: cat.$4,
          onTap: () {
            if (allTracks.isEmpty) return;
            HapticFeedback.lightImpact();
            onTap(allTracks.first, 0, allTracks);
          },
        ).animate(delay: Duration(milliseconds: i * 35))
          .fadeIn(duration: 350.ms)
          .scale(begin: const Offset(0.92, 0.92), curve: JBAnim.spring);
      },
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color colorA, colorB;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label, required this.icon,
    required this.colorA, required this.colorB,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [widget.colorA, widget.colorB],
              ),
              borderRadius: JBRadius.card,
              boxShadow: [
                BoxShadow(
                  color: widget.colorA.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background icon (decorative)
                Positioned(
                  right: -8, bottom: -8,
                  child: Icon(widget.icon,
                    color: Colors.white.withValues(alpha: 0.15),
                    size: 64),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 16),
                      ),
                      const Spacer(),
                      Text(
                        widget.label,
                        style: JBType.h4.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                          shadows: [
                            Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SEARCH RESULTS
// ─────────────────────────────────────────────────────────────────────────────
class _SearchResults extends StatelessWidget {
  final List<JBSong> results;
  final List<JBSong> allTracks;
  final String query;
  final MusicTracksLoadedState? state;
  final void Function(JBSong, int, List<JBSong>) onTap;

  const _SearchResults({
    super.key,
    required this.results, required this.allTracks,
    required this.query, required this.state, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, color: JBColors.textTertiary, size: 48),
            const SizedBox(height: 12),
            Text('No results for "$query"', style: JBType.h4),
            const SizedBox(height: 4),
            Text('Try a different search term', style: JBType.body),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text('${results.length} results', style: JBType.caption),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            itemCount: results.length,
            itemBuilder: (_, i) {
              final track = results[i];
              final realIdx = allTracks.indexWhere((t) => t.id == track.id);
              final isActive = state != null && state!.currentTrackIndex == realIdx && realIdx >= 0;
              final isPlaying = state?.isPlaying ?? false;

              return GestureDetector(
                onTap: () => onTap(track, realIdx < 0 ? i : realIdx, allTracks),
                child: AnimatedContainer(
                  duration: 250.ms,
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: isActive
                      ? JBDecor.activeCard
                      : JBGlass.card(radius: JBRadius.md),
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
                            _HighlightText(
                              text: track.title,
                              highlight: query,
                              style: JBType.bodyMedium.copyWith(
                                color: isActive ? JBColors.nova : JBColors.textPrimary,
                                fontSize: 14,
                              ),
                              highlightStyle: JBType.bodyMedium.copyWith(
                                color: JBColors.nova,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(track.artist,
                              style: JBType.caption,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (isActive && isPlaying)
                        const Icon(Icons.graphic_eq_rounded, color: JBColors.nova, size: 18),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: i * 25)).fadeIn(duration: 300.ms);
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HIGHLIGHT TEXT WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _HighlightText extends StatelessWidget {
  final String text, highlight;
  final TextStyle style, highlightStyle;

  const _HighlightText({
    required this.text, required this.highlight,
    required this.style, required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty) {
      return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final lower = text.toLowerCase();
    final idx   = lower.indexOf(highlight.toLowerCase());
    if (idx < 0) {
      return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: [
        if (idx > 0) TextSpan(text: text.substring(0, idx), style: style),
        TextSpan(text: text.substring(idx, idx + highlight.length), style: highlightStyle),
        if (idx + highlight.length < text.length)
          TextSpan(text: text.substring(idx + highlight.length), style: style),
      ]),
    );
  }
}
