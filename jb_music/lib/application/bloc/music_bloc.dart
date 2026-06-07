// lib/application/bloc/music_bloc.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:jb_music/core/audio/dsp_engine.dart';
import 'package:jb_music/core/safety/ear_safety_monitor.dart';
import 'package:jb_music/core/voice/vosk_voice_engine.dart';
import 'package:jb_music/core/services/audio_handler.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/domain/entities/voice_intent.dart';
import 'package:jb_music/domain/repositories/vault_repository.dart';
import 'package:jb_music/domain/repositories/playlist_repository.dart';
import 'package:jb_music/domain/usecases/get_tracks.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────────────────────────────────────
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
  final List<JBSong> likedTracks;

  const MusicTracksLoadedState({
    required this.visibleTracks,
    required this.currentTrackIndex,
    required this.isPlaying,
    this.likedTracks = const [],
  });

  @override
  List<Object> get props => [
        visibleTracks,
        currentTrackIndex,
        isPlaying,
        likedTracks,
      ];
}

class MusicErrorState extends MusicState {
  final String message;
  const MusicErrorState(this.message);
  @override
  List<Object> get props => [message];
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENTS
// ─────────────────────────────────────────────────────────────────────────────
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
class ToggleLikeTrackEvent extends MusicEvent {
  final JBSong song;

  ToggleLikeTrackEvent(this.song);
}

// ── Voice events ──────────────────────────────────────────────────────────────
class StartVoiceListeningEvent extends MusicEvent {}

class StopVoiceListeningEvent extends MusicEvent {}

/// Fired when VoskVoiceEngine recognises a command (via commandIntentStream)
class VoiceCommandEvent extends MusicEvent {
  final VoiceCommandIntent intent;

  VoiceCommandEvent({
    required this.intent,
  });
} // <-- ADD THIS
// ─────────────────────────────────────────────────────────────────────────────
// BLOC
// ─────────────────────────────────────────────────────────────────────────────
class MusicBloc extends Bloc<MusicEvent, MusicState> {
  final MyAudioHandler   audioHandler;
  final GetTracks        getTracksUseCase;
  final JBDspEngine      dspEngine;
  final EarSafetyMonitor safetyMonitor;
  final VoskVoiceEngine  _voiceEngine;
  final VaultRepository      vaultRepository;
  final PlaylistRepository   playlistRepository;

  late final StreamSubscription<PlayerState>       _playbackSub;
  late final StreamSubscription<VoiceCommandIntent> _voiceIntentSub;

  List<JBSong> _allTracks = [];
  List<JBSong> _likedTracks = [];

  // Expose voiceEngine so SettingsScreen can subscribe to resultStream
  VoskVoiceEngine get voiceEngine => _voiceEngine;

  MusicBloc({
    required this.audioHandler,
    required this.getTracksUseCase,
    required this.dspEngine,
    required this.safetyMonitor,
    required VoskVoiceEngine voiceEngine,
    required this.vaultRepository,
    required this.playlistRepository,
  })  : _voiceEngine = voiceEngine,
        super(MusicTracksLoadingState()) {

    // ── Playback state → bloc ────────────────────────────────────────────────
    _playbackSub = audioHandler.playerStateStream.listen(
      (state) => add(PlaybackStateChangedEvent(state.playing)),
    );

    // ── Voice intent → bloc ──────────────────────────────────────────────────
    _voiceIntentSub = _voiceEngine.commandIntentStream.listen(
      (intent) {
        debugPrint('BLOC RECEIVED: ${intent.action}');
        add(VoiceCommandEvent(intent: intent));
      },
    );

    // ── Event handlers ───────────────────────────────────────────────────────
    on<LoadAudioTracksEvent>(_onLoadTracks);
    on<TogglePlaybackEvent>(_onTogglePlayback);
    on<PlayTrackEvent>(_onPlayTrack);
    on<PlaybackStateChangedEvent>(_onPlaybackStateChanged);
    on<SearchTracksEvent>(_onSearch);
    on<ToggleLikeTrackEvent>(_onToggleLikeTrack);
    on<StartVoiceListeningEvent>(_onStartVoice);
    on<StopVoiceListeningEvent>(_onStopVoice);
    on<VoiceCommandEvent>(_onVoiceCommand);
  }

  // ── Track loading ──────────────────────────────────────────────────────────
  Future<void> _onLoadTracks(
      LoadAudioTracksEvent event, Emitter<MusicState> emit) async {
    emit(MusicTracksLoadingState());
    try {
      final tracks = await getTracksUseCase.call();
      _allTracks = tracks.cast<JBSong>();
      emit(
         MusicTracksLoadedState(
           visibleTracks: _allTracks,
           currentTrackIndex: 0,
           isPlaying: false,
           likedTracks: _likedTracks,
          ),
       );
    } catch (e) {
      emit(MusicErrorState('Failed to load tracks: $e'));
    }
  }

  // ── Playback ───────────────────────────────────────────────────────────────
  void _onTogglePlayback(
      TogglePlaybackEvent event, Emitter<MusicState> emit) {
    audioHandler.playing ? audioHandler.pause() : audioHandler.play();
  }

  Future<void> _onPlayTrack(
      PlayTrackEvent event, Emitter<MusicState> emit) async {
    final uris = event.tracks.map((t) => 'file://${t.path}').toList();
    await audioHandler.updatePlaylist(uris);
    await audioHandler.skipToQueueItem(event.index);
    emit(
      MusicTracksLoadedState(
        visibleTracks: event.tracks,
        currentTrackIndex: event.index,
        isPlaying: true,
        likedTracks: _likedTracks,
      ),
    );
  }

  void _onPlaybackStateChanged(
      PlaybackStateChangedEvent event, Emitter<MusicState> emit) {
    if (state is MusicTracksLoadedState) {
      final cur = state as MusicTracksLoadedState;
      emit(
        MusicTracksLoadedState(
          visibleTracks: cur.visibleTracks,
          currentTrackIndex: cur.currentTrackIndex,
          isPlaying: event.isPlaying,
          likedTracks: _likedTracks,
        ),
      );
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
    final isPlaying = state is MusicTracksLoadedState
        ? (state as MusicTracksLoadedState).isPlaying
        : false;
    emit(
      MusicTracksLoadedState(
        visibleTracks: filtered,
        currentTrackIndex: currentIndex,
        isPlaying: isPlaying,
        likedTracks: _likedTracks,
      ),
    );
  }

  // ── Voice ──────────────────────────────────────────────────────────────────
  Future<void> _onStartVoice(
      StartVoiceListeningEvent event, Emitter<MusicState> emit) async {
    try {
      await _voiceEngine.startListening();
    } catch (e) {
      debugPrint('❌ Voice start error: $e');
    }
  }

  Future<void> _onStopVoice(
      StopVoiceListeningEvent event, Emitter<MusicState> emit) async {
    await _voiceEngine.stopListening();
  }
Future<void> _onVoiceCommand(
  
  VoiceCommandEvent event,
  Emitter<MusicState> emit,
) async {debugPrint('EXECUTING: ${event.intent.action}');
  final action = event.intent.action;

  switch (action) {
    case JbVoiceAction.play:
      await audioHandler.play();
      break;

    case JbVoiceAction.pause:
      await audioHandler.pause();
      break;

    case JbVoiceAction.next:
      await audioHandler.skipToNext();
      break;

    case JbVoiceAction.previous:
      await audioHandler.skipToPrevious();
      break;

    case JbVoiceAction.shuffle:
      await audioHandler.setShuffleMode(
        AudioServiceShuffleMode.all,
      );
      break;

    case JbVoiceAction.repeat:
      await audioHandler.setRepeatMode(
        AudioServiceRepeatMode.all,
      );
      break;

    case JbVoiceAction.volumeUp:
      debugPrint('Volume up');
      break;

    case JbVoiceAction.volumeDown:
      debugPrint('Volume down');
      break;

    case JbVoiceAction.checkSafety:
      debugPrint('Safety check');
      break;

    case JbVoiceAction.unknown:
      debugPrint('Unknown command');
      break;
  }
}
  
  // ── Cleanup ────────────────────────────────────────────────────────────────
 void _onToggleLikeTrack(
  ToggleLikeTrackEvent event,
  Emitter<MusicState> emit,
) {
  if (state is! MusicTracksLoadedState) return;

  final current = state as MusicTracksLoadedState;

  final exists = _likedTracks.any(
    (song) => song.path == event.song.path,
  );

  if (exists) {
    _likedTracks.removeWhere(
      (song) => song.path == event.song.path,
    );
  } else {
    _likedTracks.add(event.song);
  }

  emit(
    MusicTracksLoadedState(
      visibleTracks: current.visibleTracks,
      currentTrackIndex: current.currentTrackIndex,
      isPlaying: current.isPlaying,
      likedTracks: List.from(_likedTracks),
    ),
  );
}
  @override
  Future<void> close() {
    _playbackSub.cancel();
    _voiceIntentSub.cancel();
    return super.close();
  }
}
