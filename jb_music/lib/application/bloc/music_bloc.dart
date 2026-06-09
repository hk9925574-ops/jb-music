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
// PLAYLIST MODEL
// ─────────────────────────────────────────────────────────────────────────────
class JBPlaylist {
  final String id;
  String name;
  final List<JBSong> songs;
  JBPlaylist({required this.id, required this.name, this.songs = const []});
  JBPlaylist copyWith({String? name, List<JBSong>? songs}) =>
      JBPlaylist(id: id, name: name ?? this.name, songs: songs ?? this.songs);
}

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
  final List<JBSong> recentTracks;
  final List<JBPlaylist> playlists;

  const MusicTracksLoadedState({
    required this.visibleTracks,
    required this.currentTrackIndex,
    required this.isPlaying,
    this.likedTracks = const [],
    this.recentTracks = const [],
    this.playlists = const [],
  });

  MusicTracksLoadedState copyWith({
    List<JBSong>? visibleTracks,
    int? currentTrackIndex,
    bool? isPlaying,
    List<JBSong>? likedTracks,
    List<JBSong>? recentTracks,
    List<JBPlaylist>? playlists,
  }) =>
      MusicTracksLoadedState(
        visibleTracks: visibleTracks ?? this.visibleTracks,
        currentTrackIndex: currentTrackIndex ?? this.currentTrackIndex,
        isPlaying: isPlaying ?? this.isPlaying,
        likedTracks: likedTracks ?? this.likedTracks,
        recentTracks: recentTracks ?? this.recentTracks,
        playlists: playlists ?? this.playlists,
      );

  @override
  List<Object> get props => [
        visibleTracks,
        currentTrackIndex,
        isPlaying,
        likedTracks,
        recentTracks,
        playlists,
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

// ── Playlist events ───────────────────────────────────────────────────────────
class CreatePlaylistEvent extends MusicEvent {
  final String name;
  CreatePlaylistEvent(this.name);
}

class DeletePlaylistEvent extends MusicEvent {
  final String playlistId;
  DeletePlaylistEvent(this.playlistId);
}

class AddSongToPlaylistEvent extends MusicEvent {
  final String playlistId;
  final JBSong song;
  AddSongToPlaylistEvent({required this.playlistId, required this.song});
}

class RemoveSongFromPlaylistEvent extends MusicEvent {
  final String playlistId;
  final JBSong song;
  RemoveSongFromPlaylistEvent({required this.playlistId, required this.song});
}

// ── Voice events ──────────────────────────────────────────────────────────────
class StartVoiceListeningEvent extends MusicEvent {}

class StopVoiceListeningEvent extends MusicEvent {}

class VoiceCommandEvent extends MusicEvent {
  final VoiceCommandIntent intent;
  VoiceCommandEvent({required this.intent});
}

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

  List<JBSong>    _allTracks    = [];
  List<JBSong>    _likedTracks  = [];
  List<JBSong>    _recentTracks = [];
  List<JBPlaylist> _playlists   = [];

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

    _playbackSub = audioHandler.playerStateStream.listen(
      (state) => add(PlaybackStateChangedEvent(state.playing)),
    );

    _voiceIntentSub = _voiceEngine.commandIntentStream.listen(
      (intent) {
        debugPrint('BLOC RECEIVED: ${intent.action}');
        add(VoiceCommandEvent(intent: intent));
      },
    );

    on<LoadAudioTracksEvent>(_onLoadTracks);
    on<TogglePlaybackEvent>(_onTogglePlayback);
    on<PlayTrackEvent>(_onPlayTrack);
    on<PlaybackStateChangedEvent>(_onPlaybackStateChanged);
    on<SearchTracksEvent>(_onSearch);
    on<ToggleLikeTrackEvent>(_onToggleLikeTrack);
    on<CreatePlaylistEvent>(_onCreatePlaylist);
    on<DeletePlaylistEvent>(_onDeletePlaylist);
    on<AddSongToPlaylistEvent>(_onAddSongToPlaylist);
    on<RemoveSongFromPlaylistEvent>(_onRemoveSongFromPlaylist);
    on<StartVoiceListeningEvent>(_onStartVoice);
    on<StopVoiceListeningEvent>(_onStopVoice);
    on<VoiceCommandEvent>(_onVoiceCommand);
  }

  MusicTracksLoadedState get _currentLoaded => state is MusicTracksLoadedState
      ? state as MusicTracksLoadedState
      : MusicTracksLoadedState(
          visibleTracks: _allTracks,
          currentTrackIndex: 0,
          isPlaying: false,
          likedTracks: _likedTracks,
          recentTracks: _recentTracks,
          playlists: _playlists,
        );

  MusicTracksLoadedState _buildState({
    List<JBSong>? visibleTracks,
    int? currentTrackIndex,
    bool? isPlaying,
  }) {
    final cur = _currentLoaded;
    return cur.copyWith(
      visibleTracks: visibleTracks ?? cur.visibleTracks,
      currentTrackIndex: currentTrackIndex ?? cur.currentTrackIndex,
      isPlaying: isPlaying ?? cur.isPlaying,
      likedTracks: List.from(_likedTracks),
      recentTracks: List.from(_recentTracks),
      playlists: List.from(_playlists),
    );
  }

  Future<void> _onLoadTracks(
      LoadAudioTracksEvent event, Emitter<MusicState> emit) async {
    emit(MusicTracksLoadingState());
    try {
      final tracks = await getTracksUseCase.call();
      _allTracks = tracks.cast<JBSong>();
      emit(MusicTracksLoadedState(
        visibleTracks: _allTracks,
        currentTrackIndex: 0,
        isPlaying: false,
        likedTracks: _likedTracks,
        recentTracks: _recentTracks,
        playlists: _playlists,
      ));
    } catch (e) {
      emit(MusicErrorState('Failed to load tracks: $e'));
    }
  }

  void _onTogglePlayback(
      TogglePlaybackEvent event, Emitter<MusicState> emit) {
    audioHandler.playing ? audioHandler.pause() : audioHandler.play();
  }

  Future<void> _onPlayTrack(
      PlayTrackEvent event, Emitter<MusicState> emit) async {
    final uris = event.tracks.map((t) => 'file://${t.path}').toList();
    await audioHandler.updatePlaylist(uris);
    await audioHandler.skipToQueueItem(event.index);

    final song = event.tracks[event.index];
    _recentTracks
      ..removeWhere((s) => s.path == song.path)
      ..insert(0, song);
    if (_recentTracks.length > 20) _recentTracks = _recentTracks.sublist(0, 20);

    emit(_buildState(
      visibleTracks: event.tracks,
      currentTrackIndex: event.index,
      isPlaying: true,
    ));
  }

  void _onPlaybackStateChanged(
      PlaybackStateChangedEvent event, Emitter<MusicState> emit) {
    if (state is MusicTracksLoadedState) {
      emit(_buildState(isPlaying: event.isPlaying));
    }
  }

  void _onSearch(SearchTracksEvent event, Emitter<MusicState> emit) {
    final q = event.query.toLowerCase();
    final filtered = q.isEmpty
        ? _allTracks
        : _allTracks
            .where((t) =>
                t.title.toLowerCase().contains(q) ||
                t.artist.toLowerCase().contains(q))
            .toList();
    final cur = _currentLoaded;
    emit(_buildState(
      visibleTracks: filtered,
      currentTrackIndex: cur.currentTrackIndex,
      isPlaying: cur.isPlaying,
    ));
  }

  void _onToggleLikeTrack(
      ToggleLikeTrackEvent event, Emitter<MusicState> emit) {
    if (state is! MusicTracksLoadedState) return;
    final exists = _likedTracks.any((s) => s.path == event.song.path);
    if (exists) {
      _likedTracks.removeWhere((s) => s.path == event.song.path);
    } else {
      _likedTracks.add(event.song);
    }
    emit(_buildState());
  }

  void _onCreatePlaylist(
      CreatePlaylistEvent event, Emitter<MusicState> emit) {
    final pl = JBPlaylist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: event.name,
      songs: [],
    );
    _playlists.add(pl);
    emit(_buildState());
  }

  void _onDeletePlaylist(
      DeletePlaylistEvent event, Emitter<MusicState> emit) {
    _playlists.removeWhere((p) => p.id == event.playlistId);
    emit(_buildState());
  }

  void _onAddSongToPlaylist(
      AddSongToPlaylistEvent event, Emitter<MusicState> emit) {
    final idx = _playlists.indexWhere((p) => p.id == event.playlistId);
    if (idx < 0) return;
    final pl = _playlists[idx];
    if (pl.songs.any((s) => s.path == event.song.path)) return;
    _playlists[idx] = pl.copyWith(songs: [...pl.songs, event.song]);
    emit(_buildState());
  }

  void _onRemoveSongFromPlaylist(
      RemoveSongFromPlaylistEvent event, Emitter<MusicState> emit) {
    final idx = _playlists.indexWhere((p) => p.id == event.playlistId);
    if (idx < 0) return;
    final pl = _playlists[idx];
    _playlists[idx] = pl.copyWith(
        songs: pl.songs.where((s) => s.path != event.song.path).toList());
    emit(_buildState());
  }

  Future<void> _onStartVoice(
      StartVoiceListeningEvent event, Emitter<MusicState> emit) async {
    try {
      if (!_voiceEngine.isReady) {
        await _voiceEngine.initializeVoicePipeline();
      } else {
        await _voiceEngine.startListening();
      }
    } catch (e) {
      debugPrint('❌ Voice start error: $e');
    }
  }

  Future<void> _onStopVoice(
      StopVoiceListeningEvent event, Emitter<MusicState> emit) async {
    await _voiceEngine.stopListening();
  }

  Future<void> _onVoiceCommand(
      VoiceCommandEvent event, Emitter<MusicState> emit) async {
    debugPrint('EXECUTING: ${event.intent.action}');
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
        await audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
        break;
      case JbVoiceAction.repeat:
        await audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
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

  @override
  Future<void> close() {
    _playbackSub.cancel();
    _voiceIntentSub.cancel();
    return super.close();
  }
}