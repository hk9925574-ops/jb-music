// lib/presentation/widgets/song_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';
import 'package:jb_music/domain/entities/jb_song.dart';

class SongTile extends StatelessWidget {
  final JBSong song;
  final bool isPlaying;
  final bool isLiked;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final VoidCallback? onMore;
  final int? index;

  const SongTile({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.isLiked,
    required this.onTap,
    this.onLike,
    this.onMore,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RG.radiusMD),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: isPlaying ? RG.activeCardDecoration : null,
        padding: const EdgeInsets.symmetric(
          horizontal: RG.spaceMD,
          vertical: RG.spaceSM + 2,
        ),
        child: Row(
          children: [
            _ArtworkThumbnail(song: song, isPlaying: isPlaying),
            const SizedBox(width: RG.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPlaying ? RG.gold : RG.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RG.captionStyle,
                  ),
                ],
              ),
            ),
            // FIX: song.duration is non-nullable Duration, remove null check and !
            Padding(
              padding: const EdgeInsets.only(right: RG.spaceSM),
              child: Text(
                _formatDuration(song.duration),
                style: RG.labelStyle,
              ),
            ),
            if (onLike != null)
              GestureDetector(
                onTap: onLike,
                child: AnimatedSwitcher(
                  duration: 200.ms,
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(isLiked),
                    color: isLiked ? RG.gold : RG.textMuted,
                    size: 20,
                  ),
                ),
              ),
            if (onMore != null)
              GestureDetector(
                onTap: onMore,
                child: const Padding(
                  padding: EdgeInsets.only(left: RG.spaceSM),
                  child: Icon(Icons.more_vert, color: RG.textMuted, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _ArtworkThumbnail extends StatelessWidget {
  final JBSong song;
  final bool isPlaying;

  const _ArtworkThumbnail({required this.song, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RG.radiusSM),
        child: Stack(
          children: [
            QueryArtworkWidget(
              id: int.tryParse(song.id) ?? 0,
              type: ArtworkType.AUDIO,
              nullArtworkWidget: _placeholder(),
              artworkFit: BoxFit.cover,
              artworkWidth: 48,
              artworkHeight: 48,
              artworkBorder: BorderRadius.circular(RG.radiusSM),
            ),
            if (isPlaying)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Icon(
                    Icons.graphic_eq,
                    color: RG.gold,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 48,
        height: 48,
        color: RG.surfacePop,
        child: const Icon(Icons.music_note, color: RG.textMuted, size: 22),
      );
}
