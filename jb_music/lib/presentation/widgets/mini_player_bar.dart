// lib/presentation/widgets/mini_player_bar.dart
//
// JB MUSIC — NOVA MINI PLAYER
// ─────────────────────────────────────────────────────────────────────────────
// A stunning persistent mini-player bar.
//
// Features:
//  • Live progress track (glowing fill line)
//  • Album art with subtle pulse ring when playing
//  • Swipe right → next track
//  • Swipe left → previous track
//  • Swipe up → full player
//  • Glass morphism with blur
//  • Spring animation entry
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/jb_design_system.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/screens/player_screen.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      buildWhen: (prev, next) {
        if (prev is MusicTracksLoadedState && next is MusicTracksLoadedState) {
          final ps = prev.visibleTracks.isNotEmpty
              ? prev.visibleTracks[prev.currentTrackIndex.clamp(0, prev.visibleTracks.length - 1)]
              : null;
          final ns = next.visibleTracks.isNotEmpty
              ? next.visibleTracks[next.currentTrackIndex.clamp(0, next.visibleTracks.length - 1)]
              : null;
          return ps?.id != ns?.id || prev.isPlaying != next.isPlaying;
        }
        return prev.runtimeType != next.runtimeType;
      },
      builder: (context, state) {
        if (state is! MusicTracksLoadedState) return const SizedBox.shrink();
        if (state.visibleTracks.isEmpty) return const SizedBox.shrink();

        final idx = state.currentTrackIndex.clamp(0, state.visibleTracks.length - 1);
        final song = state.visibleTracks[idx];

        return _MiniPlayerWidget(song: song, isPlaying: state.isPlaying)
            .animate()
            .slideY(begin: 1, end: 0, duration: 400.ms, curve: JBAnim.spring)
            .fadeIn(duration: 300.ms);
      },
    );
  }
}

class _MiniPlayerWidget extends StatefulWidget {
  final JBSong song;
  final bool isPlaying;
  const _MiniPlayerWidget({required this.song, required this.isPlaying});

  @override
  State<_MiniPlayerWidget> createState() => _MiniPlayerWidgetState();
}

class _MiniPlayerWidgetState extends State<_MiniPlayerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.isPlaying) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_MiniPlayerWidget old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isPlaying) {
      _pulseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _openPlayer() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(JBAnim.slideUp(PlayerScreen(track: widget.song)));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MusicBloc>();

    return GestureDetector(
      onTap: _openPlayer,
      onVerticalDragEnd: (d) {
        if (d.primaryVelocity != null && d.primaryVelocity! < -200) {
          _openPlayer();
        }
      },
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity == null) return;
        if (d.primaryVelocity! < -300) {
          HapticFeedback.lightImpact();
          bloc.audioHandler.skipToNext();
        } else if (d.primaryVelocity! > 300) {
          HapticFeedback.lightImpact();
          bloc.audioHandler.skipToPrevious();
        }
      },
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            decoration: BoxDecoration(
              color: JBColors.void3.withValues(alpha: 0.92),
              borderRadius: JBRadius.card,
              border: Border.all(color: JBColors.glassBorder, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Progress track ────────────────────────────────────────
                StreamBuilder<Duration>(
                  stream: bloc.audioHandler.positionStream,
                  builder: (_, posSnap) {
                    return StreamBuilder<Duration?>(
                      stream: bloc.audioHandler.durationStream,
                      builder: (_, durSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final dur = durSnap.data ?? Duration.zero;
                        final prog = dur.inMilliseconds > 0
                            ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                            : 0.0;

                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(JBRadius.lg)),
                          child: LinearProgressIndicator(
                            value: prog,
                            minHeight: 2,
                            backgroundColor: JBColors.glassBorder,
                            valueColor: const AlwaysStoppedAnimation<Color>(JBColors.nova),
                          ),
                        );
                      },
                    );
                  },
                ),

                // ── Main row ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Album art with pulse ring
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) {
                          final ring = _pulseCtrl.value * 4;
                          return Container(
                            width: 44 + ring, height: 44 + ring,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(JBRadius.sm + ring / 2),
                              boxShadow: widget.isPlaying ? [
                                BoxShadow(
                                  color: JBColors.nova.withValues(alpha: 0.3 * _pulseCtrl.value),
                                  blurRadius: 12 + ring * 2,
                                  spreadRadius: ring * 0.5,
                                ),
                              ] : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(JBRadius.sm + ring / 2),
                              child: SizedBox(
                                width: 44, height: 44,
                                child: QueryArtworkWidget(
                                  id: int.tryParse(widget.song.id) ?? 0,
                                  type: ArtworkType.AUDIO,
                                  format: ArtworkFormat.JPEG,
                                  artworkBorder: BorderRadius.zero,
                                  artworkFit: BoxFit.cover,
                                  nullArtworkWidget: Container(
                                    color: JBColors.void4,
                                    child: Icon(Icons.music_note_rounded,
                                        color: JBColors.nova.withValues(alpha: 0.5), size: 22),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 12),

                      // Track info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.song.title,
                              style: JBType.bodyMedium.copyWith(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.song.artist,
                              style: JBType.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Like
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              context.read<MusicBloc>().add(ToggleLikeTrackEvent(widget.song));
                            },
                            child: Container(
                              width: 36, height: 36,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.favorite_border_rounded,
                                color: JBColors.textSecondary,
                                size: 18,
                              ),
                            ),
                          ),

                          // Play / Pause
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              if (widget.isPlaying) {
                                bloc.audioHandler.pause();
                              } else {
                                bloc.audioHandler.play();
                              }
                            },
                            child: AnimatedContainer(
                              duration: 200.ms,
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: JBGradients.nova,
                                boxShadow: JBShadow.nova,
                              ),
                              child: AnimatedSwitcher(
                                duration: 200.ms,
                                child: Icon(
                                  widget.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  key: ValueKey(widget.isPlaying),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),

                          // Next
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              bloc.audioHandler.skipToNext();
                            },
                            child: Container(
                              width: 36, height: 36,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.skip_next_rounded,
                                color: JBColors.textSecondary,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
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
