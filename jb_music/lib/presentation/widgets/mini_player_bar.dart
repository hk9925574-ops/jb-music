// lib/presentation/widgets/mini_player_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/screens/player_screen.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      // FIX: also rebuild when the actual current song changes (id), not just index
      buildWhen: (prev, next) {
        if (prev is MusicTracksLoadedState && next is MusicTracksLoadedState) {
          final prevSong = prev.visibleTracks.isNotEmpty
              ? prev.visibleTracks[prev.currentTrackIndex.clamp(0, prev.visibleTracks.length - 1)]
              : null;
          final nextSong = next.visibleTracks.isNotEmpty
              ? next.visibleTracks[next.currentTrackIndex.clamp(0, next.visibleTracks.length - 1)]
              : null;
          return prevSong?.id != nextSong?.id ||
              prev.isPlaying != next.isPlaying ||
              prev.visibleTracks.length != next.visibleTracks.length;
        }
        return prev.runtimeType != next.runtimeType;
      },
      builder: (context, state) {
        if (state is! MusicTracksLoadedState) return const SizedBox.shrink();
        if (state.visibleTracks.isEmpty) return const SizedBox.shrink();

        final idx = state.currentTrackIndex.clamp(
          0, state.visibleTracks.length - 1,
        );
        final song = state.visibleTracks[idx];

        return _MiniPlayer(
          song: song,
          isPlaying: state.isPlaying,
        ).animate().slideY(
          begin: 1,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
      },
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final JBSong song;
  final bool   isPlaying;

  const _MiniPlayer({required this.song, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => PlayerScreen(track: song),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 380),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: RG.surfaceHigh.withValues(alpha: 0.92),
              border: const Border(
                top: BorderSide(color: RG.borderGold, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: RG.spaceMD),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(RG.radiusSM),
                  child: QueryArtworkWidget(
                    id: int.tryParse(song.id) ?? 0,
                    type: ArtworkType.AUDIO,
                    artworkWidth: 44,
                    artworkHeight: 44,
                    artworkFit: BoxFit.cover,
                    nullArtworkWidget: Container(
                      width: 44,
                      height: 44,
                      color: RG.surfacePop,
                      child: const Icon(Icons.music_note, color: RG.textMuted, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: RG.spaceMD),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: RG.textPrimary,
                        ),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: RG.captionStyle,
                      ),
                    ],
                  ),
                ),
                _PlayButton(isPlaying: isPlaying),
                const SizedBox(width: RG.spaceSM),
                _NextButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  const _PlayButton({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<MusicBloc>().add(TogglePlaybackEvent()),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: RG.gold,
          borderRadius: BorderRadius.circular(RG.radiusFull),
        ),
        child: AnimatedSwitcher(
          duration: 200.ms,
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            key: ValueKey(isPlaying),
            color: Colors.black,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<MusicBloc>().audioHandler.skipToNext(),
      child: const Icon(Icons.skip_next, color: RG.textSecondary, size: 28),
    );
  }
}
