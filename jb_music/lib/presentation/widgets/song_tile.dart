// lib/presentation/widgets/song_tile.dart
//
// JB MUSIC — NOVA SONG TILE
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:jb_music/core/theme/jb_design_system.dart';
import 'package:jb_music/domain/entities/jb_song.dart';

class SongTile extends StatelessWidget {
  final JBSong track;
  final int index;
  final List<JBSong> tracks;
  final bool isActive;
  final bool isPlaying;
  final bool isLiked;
  final void Function(JBSong, int, List<JBSong>) onTap;
  final VoidCallback? onMoreTap;

  const SongTile({
    super.key,
    required this.track,
    required this.index,
    required this.tracks,
    required this.isActive,
    required this.isPlaying,
    required this.isLiked,
    required this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(track, index, tracks);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showContextMenu(context);
      },
      child: AnimatedContainer(
        duration: 250.ms,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: isActive
            ? JBDecor.activeCard
            : JBGlass.card(radius: JBRadius.md),
        child: Row(
          children: [
            // Index / wave
            SizedBox(
              width: 28,
              child: Center(
                child: isActive && isPlaying
                    ? const _MiniWave(color: JBColors.nova)
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

            // Info
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

            // Like
            if (isLiked)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.favorite_rounded, color: JBColors.pulse, size: 13),
              ),

            // Duration
            Text(_fmtDur(track.duration), style: JBType.micro),
            const SizedBox(width: 6),

            // More
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onMoreTap?.call();
              },
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

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrackContextSheet(track: track),
    );
  }
}

class _TrackContextSheet extends StatelessWidget {
  final JBSong track;
  const _TrackContextSheet({required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: JBColors.void2,
        borderRadius: JBRadius.sheet,
        border: Border.all(color: JBColors.glassBorder, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: JBColors.glassBorder, borderRadius: JBRadius.pill),
            ),
          ),
          const SizedBox(height: 20),

          // Track header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(JBRadius.sm),
                child: SizedBox(
                  width: 48, height: 48,
                  child: QueryArtworkWidget(
                    id: int.tryParse(track.id) ?? 0,
                    type: ArtworkType.AUDIO,
                    artworkBorder: BorderRadius.zero,
                    artworkFit: BoxFit.cover,
                    nullArtworkWidget: Container(
                      color: JBColors.void4,
                      child: const Icon(Icons.music_note_rounded, color: JBColors.nova, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title, style: JBType.h4, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(track.artist, style: JBType.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Actions
          ..._actions(context),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    final actions = [
      (Icons.favorite_border_rounded, 'Add to Favorites', JBColors.pulse),
      (Icons.queue_music_rounded, 'Add to Queue', JBColors.nova),
      (Icons.playlist_add_rounded, 'Add to Playlist', JBColors.aurora),
      (Icons.share_outlined, 'Share', JBColors.textSecondary),
      (Icons.info_outline_rounded, 'Track Info', JBColors.textSecondary),
    ];

    return actions.map((a) => GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: JBGlass.card(radius: JBRadius.md),
        child: Row(
          children: [
            Icon(a.$1, color: a.$3, size: 20),
            const SizedBox(width: 14),
            Text(a.$2, style: JBType.bodyMedium),
          ],
        ),
      ),
    )).toList();
  }
}

// ── Mini wave used in SongTile ────────────────────────────────────────────────
class _MiniWave extends StatefulWidget {
  final Color color;
  const _MiniWave({required this.color});

  @override
  State<_MiniWave> createState() => _MiniWaveState();
}

class _MiniWaveState extends State<_MiniWave> with TickerProviderStateMixin {
  late final List<AnimationController> _cs;

  @override
  void initState() {
    super.initState();
    _cs = List.generate(3, (i) => AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + i * 120),
    )..repeat(reverse: true));
  }

  @override
  void dispose() {
    for (final c in _cs) { c.dispose(); }
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
          width: 2.5,
          height: 4 + c.value * 8,
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
