import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:jb_music/core/audio/dsp_engine.dart';
import 'package:jb_music/core/safety/ear_safety_monitor.dart';
import 'package:jb_music/core/voice/vosk_voice_engine.dart';
import 'package:jb_music/core/services/audio_handler.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/domain/repositories/vault_repository.dart';
import 'package:jb_music/domain/repositories/playlist_repository.dart';
import 'package:jb_music/domain/usecases/get_tracks.dart';

// ── States ────────────────────────────────────────────────────────────────────
abstract class MusicState extends Equatable {
  const MusicState();
  @override
  List<Object> get props => [];
}

class MusicTracksLoadingState extends MusicState {}

class MusicTracksLoadedState extends MusicState {
  final List<JBSong> visibleTracks;
  final int currentTrackIndex;
  final bool isPlaying;

  const MusicTracksLoadedState(
      this.visibleTracks, this.currentTrackIndex, this.isPlaying);

  @override
  List<Object> get props => [visibleTracks, currentTrackIndex, isPlaying];
}

class MusicErrorState extends MusicState {
  final String message;
  const MusicErrorState(this.message);
  @override
  List<Object> get props => [message];
}

// ── Events ────────────────────────────────────────────────────────────────────
abstract class MusicEvent {}

class LoadAudioTracksEvent extends MusicEvent {}
class TogglePlaybackEvent extends MusicEvent {}

class PlayTrackEvent extends MusicEvent {
  final int index;
  final List<JBSong> tracks;
  PlayTrackEvent({required this.index, required this.tracks});
}

class PlaybackStateChangedEvent extends MusicEvent {
  final bool isPlaying;
  PlaybackStateChangedEvent(this.isPlaying);
}

class SearchTracksEvent extends MusicEvent {
  final String query;
  SearchTracksEvent(this.query);
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class MusicBloc extends Bloc<MusicEvent, MusicState> {
  final MyAudioHandler audioHandler;
  final GetTracks getTracksUseCase;
  final JBDspEngine dspEngine;
  final EarSafetyMonitor safetyMonitor;
  final VoskVoiceEngine voiceEngine;
  final VaultRepository vaultRepository;
  final PlaylistRepository playlistRepository;

  late StreamSubscription<PlayerState> _playbackSubscription;
  List<JBSong> _allTracks = [];

  MusicBloc({
    required this.audioHandler,
    required this.getTracksUseCase,
    required this.dspEngine,
    required this.safetyMonitor,
    required this.voiceEngine,
    required this.vaultRepository,
    required this.playlistRepository,
  }) : super(MusicTracksLoadingState()) {
    _playbackSubscription = audioHandler.playerStateStream.listen((state) {
      add(PlaybackStateChangedEvent(state.playing));
    });

    on<LoadAudioTracksEvent>(_onLoadTracks);
    on<TogglePlaybackEvent>(_onTogglePlayback);
    on<PlayTrackEvent>(_onPlayTrack);
    on<PlaybackStateChangedEvent>(_onPlaybackStateChanged);
    on<SearchTracksEvent>(_onSearch);
  }

  Future<void> _onLoadTracks(
      LoadAudioTracksEvent event, Emitter<MusicState> emit) async {
    emit(MusicTracksLoadingState());
    try {
      final tracks = await getTracksUseCase.call();
      _allTracks = tracks.cast<JBSong>();
      emit(MusicTracksLoadedState(_allTracks, 0, false));
    } catch (e) {
      emit(MusicErrorState('Failed to load tracks: $e'));
    }
  }

  void _onTogglePlayback(
      TogglePlaybackEvent event, Emitter<MusicState> emit) {
    if (audioHandler.playing) {
      audioHandler.pause();
    } else {
      audioHandler.play();
    }
  }

  Future<void> _onPlayTrack(
      PlayTrackEvent event, Emitter<MusicState> emit) async {
    final uris = event.tracks
        .map((t) => 'file://${t.path}')
        .toList();
    await audioHandler.updatePlaylist(uris);
    await audioHandler.skipToQueueItem(event.index);
    emit(MusicTracksLoadedState(event.tracks, event.index, true));
  }

  void _onPlaybackStateChanged(
      PlaybackStateChangedEvent event, Emitter<MusicState> emit) {
    if (state is MusicTracksLoadedState) {
      final cur = state as MusicTracksLoadedState;
      emit(MusicTracksLoadedState(
          cur.visibleTracks, cur.currentTrackIndex, event.isPlaying));
    }
  }

  void _onSearch(SearchTracksEvent event, Emitter<MusicState> emit) {
    final q = event.query.toLowerCase();
    final filtered = _allTracks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q))
        .toList();
    final currentIndex = state is MusicTracksLoadedState
        ? (state as MusicTracksLoadedState).currentTrackIndex
        : 0;
    emit(MusicTracksLoadedState(filtered, currentIndex, false));
  }

  @override
  Future<void> close() {
    _playbackSubscription.cancel();
    return super.close();
  }
}